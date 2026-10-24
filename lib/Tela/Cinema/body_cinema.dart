// Aba Cinema: catálogo de filmes e séries em mosaico.
//
// Substitui a grade de canais (`BodyIconesCinema`, preservada e intacta) sem
// jogar os canais fora: eles viram a coluna fixa da esquerda, com os mesmos
// índices e FocusNode de antes, enquanto o miolo da tela passa a ser o
// catálogo do TMDB.
//
// A tela é desenho e navegação; quem busca é [CinemaCatalogo], quem desenha
// cada peça é `cinema_ladrilho.dart`. Ver README.md desta pasta.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../Controllers/SonsSistema.dart';
import '../../Modelos/MediaCanal.dart';
import 'package:v1_game/Tela/Tela%20Principal/PrincipalCtrl.dart';
import 'cinema_catalogo.dart';
import 'cinema_efeitos.dart';
import 'cinema_ficha.dart';
import 'cinema_ladrilho.dart';
import 'cinema_trailer.dart';
import 'cinema_trilho_canais.dart';
import 'tmdb_cine.dart';

/// Onde o direcional está.
enum ZonaCine { canais, mosaico }

/// O ciclo do cartão em foco, na ordem em que acontece: parado, virado de
/// costas, e aberto com cartaz e trailer deslizando em sequência.
enum EtapaCartao { parado, virado, aberto, recolhendo }

/// Medidas do mosaico. Ficam juntas e fixas porque o salto do Pad é
/// calculado por aritmética, e não perguntando ao RenderObject onde o
/// cartão foi parar — com faixas de formatos diferentes, perguntar depois do
/// quadro desenhado atrasa a rolagem em um frame visível.
class MedidaCine {
  MedidaCine._();

  static const double vao = 16;
  static const double escalaCartoes = PreviaCine.escalaCartoes;

  /// Recuo das pontas da faixa. Entra na conta da rolagem: sem ele, o alvo
  /// sai 44 px curto e o último cartão para cortado na borda da tela.
  static const double margemFaixa = 44;

  /// Sobra extra à direita, para o último cartão nunca encostar na borda.
  static const double respiroDireita = 30;

  /// Faixa reservada no alto para a barra de abas. Nada selecionável pode
  /// parar debaixo dela: é a distância que a rolagem deixa acima do item em
  /// foco, e onde o cabeçalho começa.
  static const double topo = 80;
  static const Size largo = Size(420, 236);
  static const Size poster = PreviaCine.tamanhoCartaz;
  static const double quadrado = 232;
  static const double reflexo = 74;
  static const double circulo = 150;

  /// Respiro abaixo do círculo. Era o rótulo com o nome; sem ele, resta só
  /// a folga para o círculo não encostar na faixa de baixo.
  static const double rotuloCirculo = 16;
  static const double mosaico = 300 * escalaCartoes;
  static const double cabecalhoFaixa = 48;
  static const double respiro = 34;

  /// Sobra acima e abaixo do ladrilho.
  ///
  /// O item em foco cresce (até +9%) e projeta brilho (raio 34). A faixa é
  /// uma lista, e lista recorta no próprio limite: com folga menor que o
  /// raio do brilho, o glow aparecia cortado em linha reta na borda de cima
  /// e de baixo. Metade disto, 50 px, é o que sobra de cada lado — mais que
  /// o raio mais a crescida.
  static const double folga = 100;

  static double alturaConteudo(FormaCine forma) => switch (forma) {
        FormaCine.largo => largo.height,
        FormaCine.poster => poster.height,
        FormaCine.quadrado => quadrado + reflexo,
        FormaCine.circulo => circulo + rotuloCirculo,
        FormaCine.mosaico => poster.height,
      };

  static double alturaFaixa(FormaCine forma) =>
      cabecalhoFaixa + alturaConteudo(forma) + folga + respiro;

  /// Passo horizontal de um item, nas faixas de item uniforme.
  static double passo(FormaCine forma) => switch (forma) {
        FormaCine.largo => largo.width + vao,
        FormaCine.poster => poster.width + vao,
        FormaCine.quadrado => quadrado + vao,
        FormaCine.circulo => circulo + vao + 12,
        FormaCine.mosaico => 0,
      };

  static Size tamanho(FormaCine forma) => switch (forma) {
        FormaCine.largo => largo,
        FormaCine.poster => poster,
        FormaCine.quadrado => const Size(quadrado, quadrado),
        FormaCine.circulo => const Size(circulo, circulo + rotuloCirculo),
        FormaCine.mosaico => const Size(mosaico, mosaico),
      };

  /// Retângulos do mosaico assimétrico, em grupos de quatro: um bloco
  /// grande, dois pequenos empilhados e um alto. A mesma conta serve para
  /// desenhar e para rolar até o item escolhido.
  /// Lado maior do mosaico. Serve de enquadramento: é nesta proporção que
  /// o trailer de um bloco pequeno é exibido.
  static const double mosaicoGrandeLargura = 372 * escalaCartoes;
  static const Size mosaicoBlocoGrande = Size(mosaicoGrandeLargura, mosaico);

  static List<Rect> geometriaMosaico(int quantidade) {
    const vaoM = 12.0 * escalaCartoes;
    const grande = mosaicoGrandeLargura;
    const pequeno = 208.0 * escalaCartoes;
    const meia = (mosaico - vaoM) / 2;
    final retangulos = <Rect>[];
    var x = 0.0;
    var i = 0;
    while (i < quantidade) {
      retangulos.add(Rect.fromLTWH(x, 0, grande, mosaico));
      i++;
      if (i >= quantidade) break;
      x += grande + vaoM;

      retangulos.add(Rect.fromLTWH(x, 0, pequeno, meia));
      i++;
      if (i < quantidade) {
        retangulos.add(Rect.fromLTWH(x, meia + vaoM, pequeno, meia));
        i++;
      }
      if (i >= quantidade) break;
      x += pequeno + vaoM;

      retangulos.add(Rect.fromLTWH(x, 0, pequeno, mosaico));
      i++;
      x += pequeno + vaoM;
    }
    return retangulos;
  }

  /// Vizinho na direção do Pad, usando as posições visuais dos cartões.
  static int? vizinhoMosaico(int quantidade, int indice,
      {required Axis eixo, required int passo, double? linha}) {
    final blocos = geometriaMosaico(quantidade);
    if (indice < 0 || indice >= blocos.length) return null;
    final atual = blocos[indice];
    int? destino;
    var menorDistancia = double.infinity;
    var menorDesvio = double.infinity;
    for (var i = 0; i < blocos.length; i++) {
      if (i == indice) continue;
      final candidato = blocos[i];
      final double distancia;
      final double desvio;
      if (eixo == Axis.vertical) {
        // Subir/descer só alcança cartões na mesma coluna visual.
        if (candidato.left >= atual.right || candidato.right <= atual.left) {
          continue;
        }
        distancia = passo > 0
            ? candidato.top - atual.bottom
            : atual.top - candidato.bottom;
        desvio = (candidato.center.dx - atual.center.dx).abs();
      } else {
        distancia = passo > 0
            ? candidato.left - atual.right
            : atual.left - candidato.right;
        desvio = (candidato.center.dy - (linha ?? atual.center.dy)).abs();
      }
      if (distancia < 0) continue;
      if (distancia < menorDistancia ||
          (distancia == menorDistancia && desvio < menorDesvio)) {
        destino = i;
        menorDistancia = distancia;
        menorDesvio = desvio;
      }
    }
    return destino;
  }
}

class BodyCinema extends StatefulWidget {
  const BodyCinema({
    super.key,
    required this.ctrl,
    this.catalogo,
    this.sons = true,
    this.abrirUrl,
  });

  final PrincipalCtrl ctrl;

  /// Injetável nos testes, que não falam com a rede.
  final CinemaCatalogo? catalogo;

  /// Desligado nos testes: o motor de áudio não sobe no ambiente de teste.
  final bool sons;

  /// Como abrir um endereço. O padrão é o caminho do launcher
  /// (`PrincipalCtrl.sairDaTelaMedia`), que solta a janela, chama o
  /// navegador e devolve o foco; os testes passam um registrador no lugar,
  /// para não abrir navegador de verdade.
  final Future<void> Function(String url, String texto)? abrirUrl;

  @override
  State<BodyCinema> createState() => BodyCinemaState();
}

class BodyCinemaState extends State<BodyCinema> {
  late final CinemaCatalogo _catalogo =
      widget.catalogo ?? CinemaCatalogo.sessao;

  final ScrollController _vertical = ScrollController();
  final Map<int, ScrollController> _horizontais = {};

  ZonaCine _zona = ZonaCine.mosaico;
  int _faixa = 0;
  double? _linhaMosaico;
  int _item = 0;

  /// Ficha aberta; nula quando o mosaico está à mostra.
  TituloCine? _ficha;
  AcaoFicha _acao = AcaoFicha.fechar;
  bool _trailerFicha = false;
  ZonaFicha _zonaFicha = ZonaFicha.acoes;
  int _provedor = 0;

  /// Alça do trailer da ficha: pausa, salto e progresso.
  final ControleTrailer _controleTrailer = ControleTrailer();
  final VolumeTrailerCine _volumeTrailer = VolumeTrailerCine();

  /// Recado curto no canto da tela; nulo quando não há nada a dizer.
  String? _aviso;
  Timer? _avisoAgendado;

  /// Salto de LB/RB dentro do trailer.
  static const Duration _salto = Duration(seconds: 10);

  Timer? _detalheAgendado;
  Timer? _viradaAgendada;
  Timer? _aberturaAgendada;
  Timer? _recolhimentoAgendado;
  bool _cargaPedida = false;

  /// Em que ponto do ciclo está o cartão em foco.
  EtapaCartao _etapa = EtapaCartao.parado;

  /// Título para o qual o ciclo atual foi agendado.
  int? _cicloDoTitulo;

  /// Última visibilidade conhecida da aba.
  bool _visivelAntes = false;

  /// Verdadeiro enquanto algum trailer está no ar — o que manda as escritas
  /// sobre ele saírem de cena.
  bool _videoTocando = false;

  /// Quanto o cartão precisa ficar parado antes de virar.
  static const Duration ociosidade = Duration(seconds: 2);

  /// Quanto o texto demora para sumir depois que o vídeo entra.
  static const Duration saidaDoTexto = Duration(seconds: 2);

  @override
  void initState() {
    super.initState();
    _catalogo.addListener(_catalogoMudou);
    // O PrincipalCtrl roteia os comandos do Pad da aba de cinema para cá; o
    // que esta tela não consome (abrir canal, opções) segue para o fluxo
    // antigo, que continua valendo para a coluna da esquerda.
    widget.ctrl.cinemaPadHandler = comando;
  }

  @override
  void dispose() {
    if (widget.ctrl.cinemaPadHandler == comando) {
      widget.ctrl.cinemaPadHandler = null;
    }
    _detalheAgendado?.cancel();
    _viradaAgendada?.cancel();
    _aberturaAgendada?.cancel();
    _recolhimentoAgendado?.cancel();
    _avisoAgendado?.cancel();
    _controleTrailer.dispose();
    _volumeTrailer.dispose();
    _catalogo.removeListener(_catalogoMudou);
    for (final controlador in _horizontais.values) {
      controlador.dispose();
    }
    _vertical.dispose();
    super.dispose();
  }

  void _catalogoMudou() {
    if (!mounted) return;
    setState(() {
      _faixa = _faixa.clamp(0, (_catalogo.faixas.length - 1).clamp(0, 999));
      _item = _item.clamp(0, (_itens.length - 1).clamp(0, 9999));
    });
    // A chegada do catálogo põe um cartão em foco sem ninguém ter apertado
    // nada: o ciclo precisa começar aí também. A comparação por id evita
    // reiniciá-lo a cada ficha que termina de carregar — isso empurraria a
    // virada para sempre.
    if (_destaque?.id != _cicloDoTitulo) _itemMudou();
  }

  // --------------------------------------------------- leitura para testes

  @visibleForTesting
  ZonaCine get zona => _zona;

  @visibleForTesting
  int get faixaSelecionada => _faixa;

  @visibleForTesting
  int get itemSelecionado => _item;

  @visibleForTesting
  TituloCine? get fichaAberta => _ficha;

  @visibleForTesting
  AcaoFicha get acaoDaFicha => _acao;

  @visibleForTesting
  EtapaCartao get etapaDoCartao => _etapa;

  @visibleForTesting
  bool get videoTocando => _videoTocando;

  @visibleForTesting
  ZonaFicha get zonaDaFicha => _zonaFicha;

  @visibleForTesting
  bool get trailerDestaqueVisivel => _mostrarTrailerDestaque;

  @visibleForTesting
  int get provedorSelecionado => _provedor;

  @visibleForTesting
  String? enderecoDoProvedorParaTeste(ProvedorCine provedor) =>
      _enderecoDoProvedor(provedor);

  @visibleForTesting
  Future<void> abrirProvedorParaTeste(int indice) async {
    final titulo = _ficha;
    if (titulo == null) return;
    final lista = titulo.provedores;
    if (indice >= lista.length) return;
    await _abrirProvedor(titulo, lista[indice]);
  }

  // ------------------------------------------------------------------ dados

  List<FaixaCine> get _faixas => _catalogo.faixas;

  List<TituloCine> get _itens =>
      _faixa < _faixas.length ? _faixas[_faixa].itens : const [];

  /// A faixa de destaque é a dos quadros largos — a primeira da tela.
  bool get _faixaAtualEhDestaque =>
      _faixa < _faixas.length && _faixas[_faixa].forma == FormaCine.largo;

  /// O trailer do destaque toca sozinho: basta selecionar o cartão, sem
  /// confirmar nada. Só vale na faixa de destaque, com o mosaico em foco e
  /// sem ficha por cima — as mesmas condições que o deixam visível na tela.
  bool get _mostrarTrailerDestaque =>
      _visivel &&
      _ficha == null &&
      _zona == ZonaCine.mosaico &&
      _faixaAtualEhDestaque;

  /// Se o cartão em foco é dos que viram. Quem não vira não abre prévia
  /// nem toca trailer — o ciclo inteiro é dos cartazes e dos blocos
  /// pequenos do mosaico.
  bool get _cartaoAtualVira {
    if (_faixa >= _faixas.length) return false;
    final forma = _faixas[_faixa].forma;
    if (forma != FormaCine.mosaico) {
      return LadrilhoCine.podeVirar(forma, MedidaCine.tamanho(forma));
    }
    final geometria = MedidaCine.geometriaMosaico(_itens.length);
    if (_item >= geometria.length) return false;
    return LadrilhoCine.podeVirar(forma, geometria[_item].size);
  }

  /// Título que manda no fundo da tela e no cabeçalho.
  TituloCine? get _destaque {
    if (_ficha != null) return _ficha;
    final itens = _itens;
    if (itens.isEmpty) return null;
    return itens[_item.clamp(0, itens.length - 1)];
  }

  bool get _visivel =>
      widget.ctrl.selectedIndexAbaGuias == 1 &&
      widget.ctrl.stateTela &&
      !widget.ctrl.gameIniciado;

  void _som(void Function() tocar) {
    if (widget.sons) tocar();
  }

  ScrollController _controladorDa(int faixa) =>
      _horizontais[faixa] ??= ScrollController();

  // ------------------------------------------------------------- navegação

  /// Comandos do Pad na aba de cinema.
  ///
  /// Devolve `true` quando a tela consumiu o evento. O `false` é o que
  /// mantém o comportamento antigo dos canais vivo: com o direcional na
  /// coluna da esquerda, A e SELECT voltam ao PrincipalCtrl, que abre o
  /// streaming e edita os cartões como sempre fez.
  bool comando(String evento) {
    if (!mounted) return false;

    final volume = VolumeTrailerCine.passoDoGatilho(evento);
    final temTrailer = (_destaque?.trailer ?? '').isNotEmpty;
    final tocandoOuPreparando = _ficha != null
        ? _trailerFicha
        : (_mostrarTrailerDestaque ||
            (_zona == ZonaCine.mosaico && _etapa == EtapaCartao.aberto));
    if (volume != null && _visivel && temTrailer && tocandoOuPreparando) {
      _volumeTrailer.ajustar(volume);
      return true;
    }

    if (_ficha != null) return _comandoFicha(evento);

    switch (evento) {
      case 'CIMA':
        return _vertical1(-1);
      case 'BAIXO':
        return _vertical1(1);
      case 'ESQUERDA':
        return _horizontal(-1);
      case 'DIREITA':
        return _horizontal(1);
      case '2':
        if (_zona == ZonaCine.canais) return false; // canal: fluxo antigo
        _abrirFicha();
        return true;
      case '3':
        return false;
      default:
        // START, SELECT e o resto pertencem aos canais; o mosaico não os usa.
        return false;
    }
  }

  bool _comandoFicha(String evento) {
    final titulo = _ficha;
    if (titulo == null) return false;
    if (_zonaFicha == ZonaFicha.player) return _comandoPlayer(evento);

    final completo = _catalogo.completo(titulo);
    final acoes = FichaCine.acoesDe(completo);
    final provedores = completo.provedores;

    switch (evento) {
      case 'ESQUERDA':
      case 'DIREITA':
        final passo = evento == 'DIREITA' ? 1 : -1;
        // A ordem do Pad acompanha os alvos visíveis: play, serviços, voltar.
        final alvos = <({AcaoFicha? acao, int? provedor})>[
          for (final item in acoes) ...[
            if (item == AcaoFicha.fechar)
              for (var i = 0; i < provedores.length; i++)
                (acao: null, provedor: i),
            (acao: item, provedor: null),
          ],
        ];
        final atual = alvos.indexWhere((alvo) =>
            _zonaFicha == ZonaFicha.provedores
                ? alvo.provedor == _provedor
                : alvo.acao == _acao);
        final destino = alvos[(atual + passo) % alvos.length];
        setState(() {
          if (destino.provedor != null) {
            _zonaFicha = ZonaFicha.provedores;
            _provedor = destino.provedor!;
          } else {
            _zonaFicha = ZonaFicha.acoes;
            _acao = destino.acao!;
          }
        });
        _som(SonsSistema.directionAtual);
        return true;

      case 'BAIXO':
        // Baixo também dá acesso direto aos serviços.
        if (_zonaFicha == ZonaFicha.acoes && provedores.isNotEmpty) {
          setState(() {
            _zonaFicha = ZonaFicha.provedores;
            _provedor = _provedor.clamp(0, provedores.length - 1);
          });
          _som(SonsSistema.directionAtual);
        }
        return true;

      case 'CIMA':
        if (_zonaFicha == ZonaFicha.provedores) {
          setState(() => _zonaFicha = ZonaFicha.acoes);
          _som(SonsSistema.directionAtual);
        }
        return true;

      case '2':
        if (_zonaFicha == ZonaFicha.provedores) {
          if (_provedor < provedores.length) {
            unawaited(_abrirProvedor(completo, provedores[_provedor]));
          }
          return true;
        }
        _executarAcao(_acao);
        return true;

      case '3':
        if (_zonaFicha == ZonaFicha.provedores) {
          setState(() => _zonaFicha = ZonaFicha.acoes);
          return true;
        }
        _fecharFicha();
        return true;

      case 'LB':
      case 'RB':
        // Fora do player, LB/RB continuam sendo troca de aba: a ficha fecha
        // e o evento segue adiante, para não deixar uma tela cheia aberta
        // atrás da aba seguinte.
        _fecharFicha();
        return false;

      default:
        // Qualquer outra tecla fica presa na ficha: soltá-la faria o mosaico
        // andar por trás de uma tela que cobre tudo.
        return true;
    }
  }

  /// Com o texto fora de cena, o direcional vira controle de vídeo.
  ///
  /// B não fecha a ficha aqui: ele traz as escritas de volta **com o trailer
  /// rodando atrás**, e A na ação de trailer devolve a tela ao player. Sair
  /// da ficha continua sendo B, um passo acima.
  bool _comandoPlayer(String evento) {
    switch (evento) {
      case '2':
        _controleTrailer.alternarPausa();
        return true;
      case '3':
        setState(() => _zonaFicha = ZonaFicha.acoes);
        _som(SonsSistema.click);
        return true;
      case 'RB':
      case 'DIREITA':
        _controleTrailer.pular(_salto);
        _som(SonsSistema.directionAtual);
        return true;
      case 'LB':
      case 'ESQUERDA':
        _controleTrailer.pular(-_salto);
        _som(SonsSistema.directionAtual);
        return true;
      default:
        return true;
    }
  }

  /// Copia o nome do título, avisa, e abre o serviço.
  ///
  /// O endereço sai do cartão de canal do próprio usuário quando o nome
  /// bate — é a conta dele, com o login dele — e só cai numa tabela de
  /// endereços conhecidos quando não bate. Copiar o nome antes de abrir é o
  /// que torna o passo seguinte um colar na busca do serviço.
  Future<void> _abrirProvedor(TituloCine titulo, ProvedorCine provedor) async {
    await Clipboard.setData(ClipboardData(text: titulo.titulo));
    final url = _enderecoDoProvedor(provedor) ?? titulo.ondeAssistir;
    _avisar('“${titulo.titulo}” copiado · abrindo ${provedor.nome}');
    _som(SonsSistema.pim);
    if (url == null || url.isEmpty) return;
    await _abrir(url);
  }

  Future<void> _abrir(String url) async {
    final abrir = widget.abrirUrl;
    if (abrir != null) return abrir(url, 'Comendo pipoca.');
    return widget.ctrl.sairDaTelaMedia(url, 'Comendo pipoca.');
  }

  /// Endereço do serviço: primeiro entre os canais do usuário, depois na
  /// tabela de conhecidos.
  String? _enderecoDoProvedor(ProvedorCine provedor) {
    final procurado = _simplifica(provedor.nome);
    for (final canal in widget.ctrl.listCinema) {
      final nome = _simplifica(canal.nome);
      if (nome.isEmpty || canal.url.isEmpty) continue;
      if (nome.contains(procurado) || procurado.contains(nome)) {
        return canal.url;
      }
    }
    for (final conhecido in _enderecosConhecidos.entries) {
      if (procurado.contains(conhecido.key)) return conhecido.value;
    }
    return null;
  }

  static String _simplifica(String texto) =>
      texto.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  static const Map<String, String> _enderecosConhecidos = {
    'netflix': 'https://www.netflix.com/br/',
    'primevideo': 'https://www.primevideo.com',
    'amazon': 'https://www.primevideo.com',
    'disney': 'https://www.disneyplus.com/pt-br',
    'max': 'https://www.max.com/br/pt',
    'hbo': 'https://www.max.com/br/pt',
    'appletv': 'https://tv.apple.com/br',
    'apple': 'https://tv.apple.com/br',
    'globoplay': 'https://globoplay.globo.com',
    'paramount': 'https://www.paramountplus.com/br/',
    'telecine': 'https://telecineplay.com.br',
    'crunchyroll': 'https://www.crunchyroll.com/pt-br',
    'claro': 'https://www.clarotvmais.com.br',
    'looke': 'https://www.looke.com.br',
    'mubi': 'https://mubi.com/pt',
    'youtube': 'https://www.youtube.com',
  };

  /// Recado curto no canto, que se apaga sozinho.
  void _avisar(String texto) {
    _avisoAgendado?.cancel();
    setState(() => _aviso = texto);
    _avisoAgendado = Timer(const Duration(milliseconds: 3200), () {
      if (mounted) setState(() => _aviso = null);
    });
  }

  bool _vertical1(int passo) {
    if (_zona == ZonaCine.canais) {
      final canais = widget.ctrl.listCinema.length;
      if (canais == 0) return true;
      final destino =
          (widget.ctrl.selectedIndexCinema + passo).clamp(0, canais - 1);
      if (destino == widget.ctrl.selectedIndexCinema) return true;
      _apontarCanal(destino);
      return true;
    }
    // Catálogo ainda carregando, ou sem faixa nenhuma: a coluna de canais
    // não pode ficar inalcançável enquanto o mosaico não existe.
    if (_faixas.isEmpty) {
      if (passo < 0) _entrarNosCanais();
      return true;
    }
    if (_faixas[_faixa].forma == FormaCine.mosaico) {
      final vizinho = MedidaCine.vizinhoMosaico(_itens.length, _item,
          eixo: Axis.vertical, passo: passo);
      if (vizinho != null) {
        _linhaMosaico =
            MedidaCine.geometriaMosaico(_itens.length)[vizinho].center.dy;
        _selecionarItemPad(vizinho);
        return true;
      }
    }
    final destino = (_faixa + passo).clamp(0, _faixas.length - 1);
    if (destino == _faixa) {
      // Subir na primeira faixa entra na coluna de canais. É o único lugar
      // acima dela, e sem isso alcançar a coluna dependeria de voltar coluna
      // por coluna até a primeira.
      if (passo < 0) _entrarNosCanais();
      return true;
    }
    setState(() {
      _linhaMosaico = null;
      _faixa = destino;
      _item =
          _item.clamp(0, (_faixas[destino].itens.length - 1).clamp(0, 9999));
    });
    _som(SonsSistema.directionAtual);
    _revelarFaixa();
    _revelarItem();
    _itemMudou();
    return true;
  }

  bool _horizontal(int passo) {
    if (_zona == ZonaCine.canais) {
      if (passo > 0) {
        setState(() => _zona = ZonaCine.mosaico);
        _som(SonsSistema.directionAtual);
        _revelarItem();
        _itemMudou();
      }
      return true;
    }
    final itens = _itens;
    if (itens.isEmpty) {
      if (passo < 0) _entrarNosCanais();
      return true;
    }
    if (_etapa != EtapaCartao.parado) {
      _recolherCartao();
      return true;
    }
    final int destino;
    if (_faixas[_faixa].forma == FormaCine.mosaico) {
      _linhaMosaico ??=
          MedidaCine.geometriaMosaico(itens.length)[_item].center.dy;
      final vizinho = MedidaCine.vizinhoMosaico(itens.length, _item,
          eixo: Axis.horizontal, passo: passo, linha: _linhaMosaico);
      if (vizinho == null) {
        if (passo < 0) _entrarNosCanais();
        return true;
      }
      destino = vizinho;
    } else {
      destino = _item + passo;
    }
    // Passar da primeira coluna para a esquerda sai para os canais: é o
    // caminho natural, e evita que a coluna fique inalcançável pelo Pad.
    if (destino < 0) {
      _entrarNosCanais();
      return true;
    }
    if (destino > itens.length - 1) return true;
    _selecionarItemPad(destino);
    return true;
  }

  void _selecionarItemPad(int destino) {
    setState(() => _item = destino);
    _som(SonsSistema.directionAtual);
    _revelarItem();
    _itemMudou();
  }

  /// Mudou o item em foco: a ficha completa é pedida e o ciclo do cartão
  /// recomeça do zero.
  void _itemMudou() {
    _cicloDoTitulo = _destaque?.id;
    _agendarDetalhe();
    _agendarCartao();
  }

  /// Pede a ficha completa do item parado em foco.
  ///
  /// Só depois de uma pausa: o direcional atravessa uma faixa inteira em
  /// menos de um segundo, e detalhar cada cartão de passagem seria uma
  /// requisição por tecla. Parado, o título ganha logo e trailer — é o que
  /// faz o cabeçalho e o fundo da tela se completarem sozinhos. A espera é
  /// menor que a do ciclo do cartão de propósito: quando o painel abrir, o
  /// id do trailer já precisa estar na mão.
  void _agendarDetalhe() {
    _detalheAgendado?.cancel();
    final titulo = _destaque;
    if (titulo == null || titulo.detalhado) return;
    _detalheAgendado = Timer(const Duration(milliseconds: 450), () {
      if (!mounted || !_visivel) return;
      final atual = _destaque;
      if (atual == null || atual.id != titulo.id) return;
      unawaited(_catalogo.detalhar(atual));
    });
  }

  /// Reinicia o ciclo do cartão em foco: **2 s parado → vira → desliza o
  /// painel → trailer**.
  ///
  /// Cada passo é um relógio só, aqui, e não um temporizador dentro de cada
  /// ladrilho: com vinte cartões na faixa, vinte relógios correndo em
  /// paralelo acabariam abrindo dois painéis quando a rolagem reaproveitasse
  /// um widget. Trocar de item reinicia o ciclo; o primeiro toque lateral
  /// apenas recolhe a prévia.
  void _agendarCartao() {
    _viradaAgendada?.cancel();
    _aberturaAgendada?.cancel();
    _recolhimentoAgendado?.cancel();
    if (_etapa != EtapaCartao.parado) {
      setState(() => _etapa = EtapaCartao.parado);
    }
    if (_zona != ZonaCine.mosaico ||
        _ficha != null ||
        _destaque == null ||
        !_visivel ||
        !_cartaoAtualVira) {
      return;
    }

    _viradaAgendada = Timer(ociosidade, () {
      if (!mounted ||
          !_visivel ||
          _zona != ZonaCine.mosaico ||
          _ficha != null) {
        return;
      }
      setState(() => _etapa = EtapaCartao.virado);
      _aberturaAgendada = Timer(ViradaCine.duracao, () {
        if (!mounted || _etapa != EtapaCartao.virado) return;
        setState(() => _etapa = EtapaCartao.aberto);
        // A faixa cresceu para o lado: o painel precisa caber na tela.
        _revelarItem();
      });
    });
  }

  /// O primeiro toque lateral fecha a prévia sem trocar o filme em foco.
  void _recolherCartao() {
    if (_etapa == EtapaCartao.recolhendo) return;
    _viradaAgendada?.cancel();
    _aberturaAgendada?.cancel();
    if (_etapa != EtapaCartao.aberto) {
      _agendarCartao();
      return;
    }
    setState(() => _etapa = EtapaCartao.recolhendo);
    _recolhimentoAgendado = Timer(PreviaCine.recolhimento, () {
      if (mounted && _etapa == EtapaCartao.recolhendo) _agendarCartao();
    });
  }

  /// Chamado pelo player: o texto só sai quando existe vídeo rodando por
  /// baixo dele.
  ///
  /// O aviso pode chegar de dentro de um `dispose` ou de um
  /// `didUpdateWidget` do player — reconstruir a tela ali é erro —, então
  /// ele é sempre adiado para depois do quadro.
  void _videoMudou(bool tocando) {
    if (!mounted || _videoTocando == tocando) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _videoTocando == tocando) return;
      setState(() => _videoTocando = tocando);
    });
  }

  /// Leva o direcional para a coluna de canais, devolvendo o foco ao mesmo
  /// FocusNode que o fluxo antigo usa — é o que mantém A e SELECT abrindo e
  /// editando o cartão sem código novo.
  void _entrarNosCanais() {
    final ctrl = widget.ctrl;
    if (ctrl.listCinema.isEmpty || _zona == ZonaCine.canais) return;
    setState(() => _zona = ZonaCine.canais);
    _som(SonsSistema.directionAtual);
    _agendarCartao();
    if (ctrl.focusNodeCinema.isNotEmpty) {
      ctrl.focusNodeCinema[ctrl.selectedIndexCinema
              .clamp(0, ctrl.focusNodeCinema.length - 1)]
          .requestFocus();
    }
  }

  void _apontarCanal(int indice) {
    final ctrl = widget.ctrl;
    if (indice < 0 || indice >= ctrl.listCinema.length) return;
    // O mouse repousando sobre o canal já apontado não é movimento: sem esta
    // saída, cada quadro do hover tocaria o som de novo.
    if (_zona == ZonaCine.canais && ctrl.selectedIndexCinema == indice) return;
    setState(() {
      _zona = ZonaCine.canais;
      ctrl.selectedIndexCinema = indice;
    });
    if (indice < ctrl.focusNodeCinema.length) {
      ctrl.focusNodeCinema[indice].requestFocus();
    }
    _som(SonsSistema.directionAtual);
  }

  void _apontarItem(int faixa, int item) {
    if (_zona == ZonaCine.mosaico && _faixa == faixa && _item == item) return;
    setState(() {
      _linhaMosaico = null;
      _zona = ZonaCine.mosaico;
      _faixa = faixa;
      _item = item;
    });
    _som(SonsSistema.directionAtual);
    _itemMudou();
  }

  // --------------------------------------------------------------- rolagem

  void _revelarFaixa() {
    if (!_vertical.hasClients) return;
    var alvo = 0.0;
    for (var i = 0; i < _faixa; i++) {
      alvo += MedidaCine.alturaFaixa(_faixas[i].forma);
    }
    // A faixa em foco para 80 px abaixo do topo: parada rente à borda, ela
    // ficaria atrás da barra de abas, que é desenhada por cima desta tela.
    if (_faixa > 0) alvo += _alturaCabecalho - MedidaCine.topo;
    final maximo = _vertical.position.maxScrollExtent;
    _vertical.animateTo(
      alvo.clamp(0.0, maximo),
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOutCubic,
    );
  }

  void _revelarItem() {
    final controlador = _controladorDa(_faixa);
    if (!controlador.hasClients || _faixa >= _faixas.length) return;
    final forma = _faixas[_faixa].forma;
    final double esquerda;
    var largura = 0.0;
    if (forma == FormaCine.mosaico) {
      final geometria = MedidaCine.geometriaMosaico(_itens.length);
      if (_item >= geometria.length) return;
      esquerda = MedidaCine.margemFaixa + geometria[_item].left;
      largura = geometria[_item].width;
    } else {
      esquerda = MedidaCine.margemFaixa + _item * MedidaCine.passo(forma);
      largura = MedidaCine.tamanho(forma).width;
    }
    // Com a prévia aberta, o que precisa caber na tela é o cartão mais o
    // painel ao lado dele.
    if (_etapa == EtapaCartao.aberto) {
      largura += PreviaCine.espaco;
    }
    final posicao = controlador.position;
    final visivelEsq = posicao.pixels;
    final visivelDir = posicao.pixels + posicao.viewportDimension;
    const folga = 40.0;
    double alvo = posicao.pixels;
    if (esquerda - folga < visivelEsq) {
      alvo = esquerda - folga;
    } else if (esquerda + largura + MedidaCine.respiroDireita + folga >
        visivelDir) {
      // O respiro entra aqui também: o cartão tem de parar com folga da
      // borda direita, e não rente a ela.
      alvo = esquerda +
          largura +
          MedidaCine.respiroDireita +
          folga -
          posicao.viewportDimension;
    } else {
      return;
    }
    // Em janela estreita, não esconda o verso para tentar mostrar o trailer.
    controlador.animateTo(
      alvo.clamp(
        0.0,
        (esquerda - folga).clamp(0.0, posicao.maxScrollExtent),
      ),
      duration: const Duration(milliseconds: 380),
      curve: Curves.easeOutCubic,
    );
  }

  // ----------------------------------------------------------------- ficha

  void _abrirFicha() {
    final titulo = _destaque;
    if (titulo == null) return;
    setState(() {
      _ficha = _catalogo.completo(titulo);
      _acao = AcaoFicha.fechar;
      _trailerFicha = false;
      _zonaFicha = ZonaFicha.acoes;
      _provedor = 0;
    });
    _som(SonsSistema.pim);
    _agendarCartao();
    unawaited(_catalogo.detalhar(titulo).then((completo) {
      if (!mounted || _ficha?.id != completo.id) return;
      setState(() {
        _ficha = completo;
        // Com trailer disponível, ele vira a ação em foco: é o que quase
        // todo mundo quer ao abrir a ficha.
        _acao = FichaCine.acoesDe(completo).first;
        if (completo.trailer == null && completo.provedores.isNotEmpty) {
          _zonaFicha = ZonaFicha.provedores;
          _provedor = 0;
        }
      });
    }));
  }

  void _fecharFicha() {
    setState(() {
      _ficha = null;
      _trailerFicha = false;
      _zonaFicha = ZonaFicha.acoes;
    });
    _som(SonsSistema.click);
    _itemMudou();
  }

  void _executarAcao(AcaoFicha acao) {
    final titulo = _ficha;
    if (titulo == null) return;
    switch (acao) {
      case AcaoFicha.trailer:
        // Já rodando: A volta para o player em vez de desligar o vídeo —
        // desligar é trabalho de B, um passo acima.
        setState(() {
          _trailerFicha = true;
          _zonaFicha = ZonaFicha.player;
        });
      case AcaoFicha.ondeAssistir:
        final tipo = titulo.tipo == TipoCine.serie ? 'série' : 'filme';
        final url = Uri.https(
                'www.google.com', '/search', {'q': '${titulo.titulo} $tipo'})
            .toString();
        setState(() => _trailerFicha = false);
        unawaited(_abrir(url));
      case AcaoFicha.fechar:
        _fecharFicha();
    }
  }

  // --------------------------------------------------------------- desenho

  double get _alturaCabecalho {
    final altura = MediaQuery.sizeOf(context).height;
    // A caixa do trailer do destaque, aumentada a pedido, pede bem mais
    // altura que o cabeçalho comum: o teto só sobe enquanto ela está na
    // tela, pra não inflar o cabeçalho das outras faixas à toa.
    final teto = _mostrarTrailerDestaque ? 620.0 : 560.0;
    return (altura * .52).clamp(360.0, teto);
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final visivel = _visivel;
    // A carga é pedida quando a aba aparece pela primeira vez, e não no
    // arranque: o PageView monta as quatro abas juntas e ninguém abriu o
    // cinema ainda.
    if (visivel && !_cargaPedida) {
      _cargaPedida = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_catalogo.garantirCarga());
      });
    }
    // Entrar na aba recomeça o ciclo do cartão; sair o desarma, para a aba
    // não voltar do zero com um painel de trailer já aberto.
    if (visivel != _visivelAntes) {
      _visivelAntes = visivel;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _itemMudou();
      });
    }

    return EscopoVolumeTrailer(
      volume: _volumeTrailer,
      child: FocusScope(
        node: ctrl.focusScopeCinema,
        // Fora de vista, a aba congela: o PageView mantém as quatro montadas e
        // animação de cartaz rodando atrás da tela de jogos custa quadro.
        child: TickerMode(
          enabled: visivel,
          child: ColoredBox(
            color: Cine.fundo,
            child: Stack(fit: StackFit.expand, children: [
              _fundo(),
              // A foto do canal cobre a tela inteira; a coluna vem depois na
              // pilha, e por isso fica por cima dela.
              Positioned.fill(child: _capaDoCanal()),
              Positioned.fill(
                child: Row(children: [
                  // A coluna vai de ponta a ponta da tela; quem desce para
                  // baixo da barra de abas é a primeira capa, pelo padding de
                  // dentro dela.
                  //
                  // Ela nunca sai de cena: é nela que se vê qual canal está
                  // escolhido. O que troca é o miolo da tela, ao lado.
                  TrilhoCanais(
                    canais: ctrl.listCinema,
                    focos: ctrl.focusNodeCinema,
                    selecionado: ctrl.selectedIndexCinema,
                    ativo: _zona == ZonaCine.canais && _ficha == null,
                    onApontar: _apontarCanal,
                    onAbrir: (i) {
                      _apontarCanal(i);
                      unawaited(Future.microtask(() => ctrl.movFilmes('2')));
                    },
                  ),
                  // O miolo é um lugar só, com dois conteúdos que se cruzam:
                  // o catálogo e a capa do canal escolhido. Nenhum dos dois
                  // aparece ou some de estalo — é sempre fusão.
                  Expanded(child: _miolo()),
                ]),
              ),
              _rodape(),
              _fichaSobreposta(visivel),
            ]),
          ),
        ),
      ),
    );
  }

  /// Canal apontado, enquanto o direcional está na coluna da esquerda.
  MediaCanal? get _canalApontado {
    if (_zona != ZonaCine.canais || _ficha != null) return null;
    final canais = widget.ctrl.listCinema;
    if (canais.isEmpty) return null;
    return canais[widget.ctrl.selectedIndexCinema.clamp(0, canais.length - 1)];
  }

  /// Fundo vivo: a arte do título apontado, desfocada e escurecida, com o
  /// trailer entrando por cima depois de alguns instantes parado. Na coluna
  /// de canais quem ocupa o fundo é a capa do canal, e a troca entre um e
  /// outro é sempre em fusão — nada aparece ou some de estalo.
  Widget _fundo() {
    final destaque = _destaque;
    return Stack(fit: StackFit.expand, children: [
      AnimatedSwitcher(
        duration: const Duration(milliseconds: 620),
        switchInCurve: Curves.easeOut,
        switchOutCurve: Curves.easeIn,
        // A capa que entra e a que sai ocupam a tela inteira, uma por cima
        // da outra: é o que faz a troca ser uma fusão, e não um corte.
        layoutBuilder: (atual, anteriores) => Stack(
          fit: StackFit.expand,
          children: [...anteriores, if (atual != null) atual],
        ),
        child: destaque == null
            ? const SizedBox.expand(key: ValueKey('vazio'))
            : AnimatedBuilder(
                key: ValueKey(destaque.id),
                animation: _vertical,
                // A arte vai como `child`: ela é a mesma durante toda a
                // rolagem, e reconstruí-la a cada pixel era jogar fora
                // uma imagem de tela cheia por quadro.
                child: RepaintBoundary(
                  child: ArteCine(
                    url: destaque.fundoUrl(tamanho: 'w1280') ??
                        destaque.arteLarga(),
                    nome: destaque.titulo,
                    semente: destaque.id,
                    // O fundo já nasce desfocado: desfocar aqui, na
                    // imagem parada, custa uma vez — um BackdropFilter de
                    // tela cheia custaria a cada quadro, e ainda borraria
                    // o trailer que toca por cima.
                    desfoque: 16,
                    larguraCache: 1280,
                  ),
                ),
                builder: (_, filho) {
                  final deslocamento =
                      _vertical.hasClients ? _vertical.offset : 0.0;
                  // Paralaxe do fundo: ele sobe a um terço da velocidade
                  // do conteúdo, o que dá profundidade sem descolar.
                  return Transform.translate(
                    offset: Offset(0, -deslocamento * .12),
                    child: Transform.scale(scale: 1.08, child: filho),
                  );
                },
              ),
      ),
      // Sem vídeo no fundo: o trailer do título em foco toca numa caixa
      // própria — na prévia ao lado do cartão (faixas que viram) ou na
      // caixa fixa do cabeçalho (faixa de destaque). Um vídeo de tela
      // cheia aqui já existiu e subia por meio segundo só para ser
      // derrubado em seguida — decodificar vídeo para jogar fora é peso
      // que não aparece na tela, só no ventilador.
      const Positioned.fill(child: ColoredBox(color: Color(0x66000000))),
      const Positioned.fill(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [Color(0xF206060B), Color(0xA606060B), Color(0x4D06060B)],
              stops: [0, .55, 1],
            ),
          ),
        ),
      ),
    ]);
  }

  /// O miolo da tela: o catálogo, que recua quando o canal assume.
  Widget _miolo() {
    final canal = _canalApontado;
    return AnimatedOpacity(
      key: const ValueKey('catalogo'),
      opacity: canal == null ? 1 : 0,
      duration: const Duration(milliseconds: 420),
      curve: Curves.easeOut,
      child: IgnorePointer(ignoring: canal != null, child: _corpo()),
    );
  }

  /// A capa do canal escolhido, preenchendo a tela inteira.
  ///
  /// É uma camada abaixo da coluna na pilha: a foto toma a tela toda e a
  /// barra da esquerda fica **por cima** dela, que é o que deixa ver qual
  /// canal está escolhido enquanto se olha a arte.
  ///
  /// A troca entre um canal e outro é fusão: a capa que entra se sobrepõe à
  /// que sai, no mesmo lugar.
  Widget _capaDoCanal() {
    final canais = widget.ctrl.listCinema;
    if (canais.isEmpty) return const SizedBox.expand();
    final indice = widget.ctrl.selectedIndexCinema.clamp(0, canais.length - 1);
    return IgnorePointer(
      child: AnimatedOpacity(
        key: const ValueKey('capa-canal'),
        opacity: _canalApontado == null ? 0 : 1,
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOut,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 520),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          layoutBuilder: (atual, anteriores) => Stack(
            fit: StackFit.expand,
            children: [...anteriores, if (atual != null) atual],
          ),
          child: ArteCanal(
            key: ValueKey('canal-$indice'),
            canal: canais[indice],
            fit: BoxFit.cover,
          ),
        ),
      ),
    );
  }

  Widget _corpo() {
    if (_catalogo.carregando && _faixas.isEmpty) return _carregando();
    if (_faixas.isEmpty) return _vazio();
    return ScrollConfiguration(
      behavior: const _SemBrilho(),
      child: CustomScrollView(
        controller: _vertical,
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(child: _cabecalho()),
          for (var i = 0; i < _faixas.length; i++)
            SliverToBoxAdapter(child: _faixaWidget(i)),
          const SliverToBoxAdapter(child: SizedBox(height: 72)),
        ],
      ),
    );
  }

  /// Cabeçalho: o título apontado em tamanho de cartaz, sem caixa. O texto
  /// desliza um pouco mais devagar que a rolagem, então ele parece estar
  /// atrás do mosaico.
  Widget _cabecalho() {
    final destaque = _destaque;
    final altura = _alturaCabecalho;
    if (destaque == null) return SizedBox(height: altura);
    final mostrarCaixa = _mostrarTrailerDestaque;

    // Tamanho da caixa do trailer: aumentado a pedido para cerca de quatro
    // vezes a área de antes (dobro em cada lado — 236→472, 460→920), mas
    // sempre dentro do que os dois eixos realmente têm de sobra, pra nunca
    // estourar o cabeçalho nem espremer a coluna de texto a ponto de não
    // caber frase nenhuma.
    final disponivelAltura =
        (altura - (MedidaCine.topo + 16) - 28 - 4).clamp(140.0, 472.0);
    final larguraTela = MediaQuery.sizeOf(context).width;
    final disponivelLargura =
        (larguraTela - 44 * 2 - 28 - 320).clamp(220.0, 920.0);
    // 16:9 a partir do menor dos dois limites: se a altura disponível
    // pedir mais largura do que cabe, é a largura que manda, e a altura
    // encolhe junto — a proporção nunca distorce.
    final larguraPorAltura = disponivelAltura * 16 / 9;
    final larguraCaixa = larguraPorAltura <= disponivelLargura
        ? larguraPorAltura
        : disponivelLargura;
    final alturaCaixa = larguraCaixa * 9 / 16;

    // O texto do cabeçalho vai inteiro como `child` do AnimatedBuilder: ele
    // não muda durante a rolagem, só se desloca. Reconstruí-lo a cada pixel
    // remontava o logo da rede junto.
    final conteudo = AnimatedOpacity(
      // Com vídeo rodando atrás, a escrita sai de cena em dois segundos e
      // deixa a imagem falar. Volta do mesmo jeito quando o vídeo para.
      opacity: _videoTocando ? 0 : 1,
      duration: saidaDoTexto,
      curve: Curves.easeInOut,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(44, MedidaCine.topo + 16, 44, 28),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(
                    _faixas.isEmpty
                        ? 'CINEMA'
                        : _faixas[_faixa].titulo.toUpperCase(),
                    style: Cine.etiqueta(10, cor: Cine.cor(destaque.id)),
                  ),
                  const SizedBox(height: 18),
                  _marcaDestaque(destaque),
                  const SizedBox(height: 16),
                  Row(children: [
                    Text(destaque.notaTexto, style: Cine.titulo(20)),
                    const SizedBox(width: 16),
                    Flexible(
                      child: Text(destaque.linhaMeta,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: Cine.etiqueta(10)),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 680),
                    child: Text(
                      destaque.sinopse,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style:
                          Cine.corpo(14.5).copyWith(shadows: Cine.sombraTexto),
                    ),
                  ),
                ],
              ),
            ),
            // Só na faixa de destaque, e só pela seleção: nada de confirmar
            // nada. A caixa fica fixa no canto direito, em frente aos
            // títulos e à descrição — não por cima deles, ao lado.
            if (mostrarCaixa) ...[
              const SizedBox(width: 28),
              _caixaTrailerDestaque(destaque, larguraCaixa, alturaCaixa),
            ],
          ],
        ),
      ),
    );

    return SizedBox(
      height: altura,
      child: AnimatedBuilder(
        animation: _vertical,
        child: conteudo,
        builder: (_, filho) {
          final deslocamento = _vertical.hasClients ? _vertical.offset : 0.0;
          final desvanecer = (1 - deslocamento / (altura * .7)).clamp(0.0, 1.0);
          if (desvanecer == 0) return const SizedBox.shrink();
          return Opacity(
            opacity: desvanecer,
            child: Transform.translate(
              offset: Offset(0, deslocamento * .38),
              child: filho,
            ),
          );
        },
      ),
    );
  }

  /// A caixa do trailer de "Em alta esta semana".
  ///
  /// Fica parada — não desliza, não cresce, não espera confirmação. Basta o
  /// cartão estar selecionado. A arte do título preenche a caixa desde o
  /// primeiro quadro; o trailer funde por cima assim que resolve, e some do
  /// mesmo jeito se a pessoa mudar de cartão ou sair da faixa — é a própria
  /// troca de `youtubeId` no `TrailerCine` que faz o crossfade de um vídeo
  /// para o outro, sem precisar de nada aqui.
  Widget _caixaTrailerDestaque(
      TituloCine destaque, double largura, double altura) {
    const raio = 32.0;
    return ClipRRect(
      borderRadius: BorderRadius.circular(raio),
      child: Container(
        width: largura,
        height: altura,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(raio),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: .5),
              blurRadius: 36,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Stack(fit: StackFit.expand, children: [
          ArteCine(
            url: destaque.arteLarga(tamanho: 'w780'),
            nome: destaque.titulo,
            semente: destaque.id,
            larguraCache: (largura * 1.6).round(),
          ),
          if (destaque.trailer != null)
            IgnorePointer(
              child: TrailerCine(
                youtubeId: destaque.trailer,
                tocar: _mostrarTrailerDestaque,
              ),
            ),
          IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(raio),
                border: Border.all(
                    color: Colors.white.withValues(alpha: .16), width: 1.2),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _marcaDestaque(TituloCine destaque) {
    final logo = destaque.logoUrl(tamanho: 'w500');
    if (_faixaAtualEhDestaque) {
      return LogoDestaqueCine(key: ValueKey(destaque.id), url: logo);
    }
    final nome = Text(
      destaque.titulo,
      maxLines: 2,
      overflow: TextOverflow.ellipsis,
      style: Cine.titulo(58).copyWith(shadows: Cine.sombraTexto),
    );
    if (logo == null) return nome;
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 560, maxHeight: 132),
      child: Image.network(
        logo,
        fit: BoxFit.contain,
        alignment: Alignment.centerLeft,
        errorBuilder: (_, __, ___) => nome,
      ),
    );
  }

  Widget _faixaWidget(int indice) {
    final faixa = _faixas[indice];
    final naFaixa = _zona == ZonaCine.mosaico && _faixa == indice;
    return SizedBox(
      height: MedidaCine.alturaFaixa(faixa.forma),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(44, 0, 44, 14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 240),
                style: Cine.titulo(naFaixa ? 25 : 21,
                    cor: naFaixa ? Cine.tinta : Cine.tintaFraca),
                child: Text(faixa.titulo),
              ),
              const SizedBox(width: 14),
              if (faixa.chamada.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(faixa.chamada, style: Cine.etiqueta(8.5)),
                ),
            ]),
          ),
          Expanded(
            child: faixa.forma == FormaCine.mosaico
                ? _mosaico(indice, faixa)
                : _faixaSimples(indice, faixa),
          ),
        ],
      ),
    );
  }

  Widget _faixaSimples(int indice, FaixaCine faixa) {
    final tamanho = MedidaCine.tamanho(faixa.forma);
    return ListView.builder(
      controller: _controladorDa(indice),
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: MedidaCine.margemFaixa,
        right: MedidaCine.margemFaixa + MedidaCine.respiroDireita,
      ),
      itemCount: faixa.itens.length,
      itemBuilder: (context, i) {
        final selecionado =
            _zona == ZonaCine.mosaico && _faixa == indice && _item == i;
        return Padding(
          padding: const EdgeInsets.only(right: MedidaCine.vao),
          child: Align(
            alignment: Alignment.center,
            child: LadrilhoCine(
              titulo: _catalogo.completo(faixa.itens[i]),
              forma: faixa.forma,
              selecionado: selecionado,
              indice: i,
              tamanho: tamanho,
              virado: selecionado && _etapa != EtapaCartao.parado,
              expandido: selecionado && _etapa == EtapaCartao.aberto,
              tocarTrailer:
                  selecionado && _etapa == EtapaCartao.aberto && _visivel,
              onVideo: _videoMudou,
              onPreviaAberta: _revelarItem,
              onApontar: () => _apontarItem(indice, i),
              onAbrir: _abrirFicha,
            ),
          ),
        );
      },
    );
  }

  /// Mosaico assimétrico: blocos de tamanhos diferentes num plano só.
  Widget _mosaico(int indice, FaixaCine faixa) {
    final geometria = MedidaCine.geometriaMosaico(faixa.itens.length);
    final largura = geometria.isEmpty
        ? 0.0
        : geometria.map((r) => r.right).reduce((a, b) => a > b ? a : b);
    final abertoAqui = _zona == ZonaCine.mosaico &&
        _faixa == indice &&
        (_etapa == EtapaCartao.aberto || _etapa == EtapaCartao.recolhendo) &&
        _item < geometria.length;
    final alvo = abertoAqui ? geometria[_item] : null;
    // Conteúdo estável enquanto a animação abre espaço entre as colunas.
    final cartoes = [
      for (var i = 0; i < geometria.length; i++)
        RepaintBoundary(
            child: LadrilhoCine(
          key: ValueKey('mosaico-$indice-$i'),
          titulo: _catalogo.completo(faixa.itens[i]),
          forma: FormaCine.mosaico,
          selecionado:
              _zona == ZonaCine.mosaico && _faixa == indice && _item == i,
          indice: i,
          tamanho: geometria[i].size,
          comPrevia: false,
          virado: _zona == ZonaCine.mosaico &&
              _faixa == indice &&
              _item == i &&
              _etapa != EtapaCartao.parado,
          onApontar: () => _apontarItem(indice, i),
          onAbrir: _abrirFicha,
        )),
    ];
    final previa = alvo == null
        ? null
        : PreviaCine(
            key: ValueKey('previa-$indice-$_item'),
            titulo: _catalogo.completo(faixa.itens[_item]),
            aberta: _etapa == EtapaCartao.aberto,
            tocar: _visivel && _etapa == EtapaCartao.aberto,
            onVideo: _videoMudou,
            onAberta: _revelarItem,
          );
    return SingleChildScrollView(
      controller: _controladorDa(indice),
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(
        left: MedidaCine.margemFaixa,
        right: MedidaCine.margemFaixa + MedidaCine.respiroDireita,
      ),
      child: Center(
          child: TweenAnimationBuilder<double>(
        tween: Tween(
            begin: 0, end: abertoAqui && _etapa == EtapaCartao.aberto ? 1 : 0),
        duration: _etapa == EtapaCartao.recolhendo
            ? PreviaCine.recolhimento
            : PreviaCine.duracao,
        builder: (_, t, __) => SizedBox(
          width: largura + PreviaCine.espacoEm(t),
          height: MedidaCine.poster.height,
          child: Stack(clipBehavior: Clip.none, children: [
            for (var i = 0; i < geometria.length; i++)
              Positioned.fromRect(
                rect: geometria[i].shift(Offset(
                    alvo != null && geometria[i].left >= alvo.right
                        ? PreviaCine.espacoEm(t)
                        : 0,
                    0)),
                child: cartoes[i],
              ),
            if (alvo != null)
              Positioned(left: alvo.right, top: 0, child: previa!),
          ]),
        ),
      )),
    );
  }

  Widget _carregando() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 34,
              height: 34,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Cine.realce.withValues(alpha: .8)),
            ),
            const SizedBox(height: 22),
            Text('montando a sessão', style: Cine.etiqueta(10)),
          ],
        ),
      );

  Widget _vazio() => Center(
        child: Padding(
          padding: const EdgeInsets.all(48),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Sem catálogo', style: Cine.titulo(34)),
              const SizedBox(height: 14),
              Text(
                _catalogo.aviso ??
                    'O catálogo não pôde ser carregado agora. '
                        'Troque de aba e volte para tentar de novo.',
                style: Cine.corpo(14),
              ),
            ],
          ),
        ),
      );

  /// Rodapé: o recado do momento — o que foi copiado, o serviço que está
  /// abrindo — e, enquanto faltar chave, onde colá-la. Nada de legenda de
  /// botões.
  Widget _rodape() {
    final aviso = _aviso;
    return Positioned(
      left: 140,
      right: 44,
      bottom: 16,
      child: IgnorePointer(
        child: Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 260),
              child: aviso == null
                  ? const SizedBox(key: ValueKey('sem-aviso'), height: 18)
                  : Text(
                      aviso,
                      key: ValueKey(aviso),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Cine.titulo(13, cor: Cine.realce)
                          .copyWith(shadows: Cine.sombraTexto),
                    ),
            ),
          ),
          if (_catalogo.demonstracao)
            Flexible(
              child: Text(
                'catálogo de demonstração · chave TMDB em '
                '${ChaveTmdb.caminhoArquivo}',
                textAlign: TextAlign.right,
                maxLines: 2,
                style: Cine.etiqueta(8, cor: const Color(0x99FFB4A8)),
              ),
            ),
        ]),
      ),
    );
  }

  Widget _fichaSobreposta(bool visivel) {
    final ficha = _ficha;
    return IgnorePointer(
      ignoring: ficha == null,
      child: AnimatedOpacity(
        opacity: ficha == null ? 0 : 1,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        child: ficha == null
            ? const SizedBox.expand()
            : TweenAnimationBuilder<double>(
                key: ValueKey(ficha.id),
                tween: Tween(begin: .96, end: 1),
                duration: const Duration(milliseconds: 420),
                curve: Curves.easeOutCubic,
                builder: (_, escala, filho) =>
                    Transform.scale(scale: escala, child: filho),
                child: FichaCine(
                  titulo: ficha,
                  acoes: FichaCine.acoesDe(ficha),
                  acao: _acao,
                  onAcao: (acao) {
                    setState(() => _acao = acao);
                    _executarAcao(acao);
                  },
                  visivel: visivel,
                  carregando: !ficha.detalhado,
                  trailerLigado: _trailerFicha,
                  escritasVisiveis:
                      !(_videoTocando && _zonaFicha == ZonaFicha.player),
                  onVideo: _videoMudou,
                  zona: _zonaFicha,
                  provedor: _provedor,
                  onProvedor: (i) {
                    setState(() {
                      _zonaFicha = ZonaFicha.provedores;
                      _provedor = i;
                    });
                    final atual = _ficha;
                    if (atual == null) return;
                    final lista = atual.provedores;
                    if (i < lista.length) {
                      unawaited(_abrirProvedor(atual, lista[i]));
                    }
                  },
                  controle: _controleTrailer,
                ),
              ),
      ),
    );
  }
}

/// Sem o brilho de fim de lista do Android: numa tela escura ele aparece
/// como uma mancha clara na borda.
class _SemBrilho extends ScrollBehavior {
  const _SemBrilho();

  @override
  Widget buildOverscrollIndicator(
          BuildContext context, Widget child, ScrollableDetails details) =>
      child;
}
