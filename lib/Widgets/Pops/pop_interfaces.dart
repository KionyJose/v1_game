import 'package:flutter/material.dart';
import 'package:v1_game/Controllers/SonsSistema.dart';
import 'package:v1_game/Controllers/slim_mode_config_controller.dart';
import 'package:v1_game/Global.dart';

import '../../Interface/launcher_pad_scope.dart';

/// Um ajuste de uma tela, do jeito que o Pad consegue mexer nele.
sealed class AjusteDeTela {
  const AjusteDeTela(this.nome);
  final String nome;
}

/// Liga/desliga, alternado com A.
class AjusteLiga extends AjusteDeTela {
  const AjusteLiga(super.nome, {required this.ler, required this.gravar});
  final bool Function() ler;
  final void Function(bool) gravar;
}

/// Valor de 0 a 1, movido com LB/RB — o direcional já troca de coluna.
class AjusteVolume extends AjusteDeTela {
  const AjusteVolume(super.nome, {required this.ler, required this.gravar});
  final double Function() ler;
  final void Function(double) gravar;

  static const passo = .1;
}

/// Uma tela do launcher e os ajustes que pertencem só a ela.
class TelaDoLauncher {
  const TelaDoLauncher({
    required this.id,
    required this.nome,
    required this.icone,
    required this.resumo,
    this.ajustes = const [],
  });

  /// `viewType` da tela, ou [idSlim] para o modo de janela.
  final String id;
  final String nome;
  final IconData icone;

  /// Uma linha dizendo o que a tela é.
  final String resumo;

  final List<AjusteDeTela> ajustes;

  static const idSlim = 'slim';
  bool get ehSlim => id == idSlim;
}

/// Todas as telas, com o que cada uma tem de ajuste próprio.
///
/// Só entram aqui os ajustes que pertencem **àquela** tela. Volume geral,
/// FPS e sequências do controle valem para o launcher inteiro e continuam em
/// Configurações — repeti-los aqui faria parecer que mudam por tela.
List<TelaDoLauncher> telasDoLauncher() => [
      TelaDoLauncher(
        id: 'list',
        nome: 'Principal',
        icone: Icons.view_agenda_rounded,
        resumo: 'Lista de capas com vídeo de fundo.',
        ajustes: [
          AjusteLiga('Vídeos na tela',
              ler: () => configSistema.videosTelaPrincipal,
              gravar: (v) => configSistema.videosTelaPrincipal = v),
          AjusteLiga('Notícias no card',
              ler: () => configSistema.noticias,
              gravar: (v) => configSistema.noticias = v),
        ],
      ),
      TelaDoLauncher(
        id: 'moderno',
        nome: 'Moderno',
        icone: Icons.auto_awesome_mosaic_rounded,
        resumo: 'Capas grandes com faixa de notícias.',
        ajustes: [
          AjusteLiga('Notícias no card',
              ler: () => configSistema.noticias,
              gravar: (v) => configSistema.noticias = v),
        ],
      ),
      const TelaDoLauncher(
        id: 'retro',
        nome: 'Retro',
        icone: Icons.videogame_asset_rounded,
        resumo: 'Visual de console antigo.',
      ),
      const TelaDoLauncher(
        id: 'grid',
        nome: 'Grade',
        icone: Icons.grid_view_rounded,
        resumo: 'Todos os jogos de uma vez.',
      ),
      const TelaDoLauncher(
        id: 'transversal',
        nome: 'Transversal',
        icone: Icons.view_carousel_rounded,
        resumo: 'Painéis inclinados em movimento.',
      ),
      TelaDoLauncher(
        id: 'futurista',
        nome: 'Futurista',
        icone: Icons.blur_on_rounded,
        resumo: 'Vidro, água e som ambiente.',
        ajustes: [
          AjusteVolume('Música ambiente',
              ler: () => configSistema.volumeMusicaFuturista,
              gravar: (v) => configSistema.volumeMusicaFuturista = v),
          AjusteVolume('Som ao abrir',
              ler: () => configSistema.volumeSomInicioFuturista,
              gravar: (v) => configSistema.volumeSomInicioFuturista = v),
        ],
      ),
      const TelaDoLauncher(
        id: TelaDoLauncher.idSlim,
        nome: 'Slim',
        icone: Icons.width_normal_rounded,
        resumo: 'Faixa no pé da tela, por cima do Windows.',
      ),
    ];

/// Escolha e ajuste de telas, em uma grade grande.
///
/// Devolve `'salvar'` quando algo mudou — quem chama aplica a interface —, ou
/// vazio ao sair sem mexer.
class PopInterfaces {
  static const colunas = 3;

  /// [gravar] e [definirSlim] existem para o teste não escrever por cima da
  /// configuração real do usuário: `configSistema` é global e `save()` vai
  /// direto ao disco.
  static Future<String> abrir(
    BuildContext context, {
    Future<bool> Function()? gravar,
    Future<void> Function(bool)? definirSlim,
  }) async =>
      await showDialog<String>(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
            _PopInterfaces(gravar: gravar, definirSlim: definirSlim),
      ) ??
      '';
}

class _PopInterfaces extends StatefulWidget {
  const _PopInterfaces({this.gravar, this.definirSlim});
  final Future<bool> Function()? gravar;
  final Future<void> Function(bool)? definirSlim;

  @override
  State<_PopInterfaces> createState() => _PopInterfacesState();
}

/// Uma parada do Pad: o cartão da tela, ou um ajuste dentro dele.
class _Parada {
  const _Parada(this.tela, [this.ajuste]);
  final int tela;
  final int? ajuste;
  bool get ehCartao => ajuste == null;
}

class _PopInterfacesState extends State<_PopInterfaces> {
  late final List<TelaDoLauncher> _telas = telasDoLauncher();
  late final List<_Parada> _paradas = _montarParadas();
  final _slim = const SlimModeConfigController();

  Future<void> _escreverSlim(bool ativo) =>
      widget.definirSlim?.call(ativo) ?? _slim.writeActive(ativo);

  int _parada = 0;
  bool _mudou = false;
  bool _fechando = false;

  static const _violeta = Color(0xFFB6A8FF);

  /// Cartão e, logo abaixo dele, os seus ajustes — nessa ordem, para o
  /// direcional descer de um para o outro sem truque.
  List<_Parada> _montarParadas() => [
        for (var t = 0; t < _telas.length; t++) ...[
          _Parada(t),
          for (var a = 0; a < _telas[t].ajustes.length; a++) _Parada(t, a),
        ],
      ];

  int get _telaAtual => _paradas[_parada].tela;

  bool _ehAtual(TelaDoLauncher tela) => tela.ehSlim
      ? SlimModeConfigController.active.value
      : !SlimModeConfigController.active.value &&
          configSistema.viewType == tela.id;

  // --------------------------------------------------------------- navegação

  /// Índice da primeira parada de uma tela.
  int _inicioDaTela(int tela) =>
      _paradas.indexWhere((p) => p.tela == tela && p.ehCartao);

  void _irPara(int destino) {
    final alvo = destino.clamp(0, _paradas.length - 1);
    if (alvo == _parada) return;
    setState(() => _parada = alvo);
    SonsSistema.direction();
  }

  /// Última parada de uma tela: o seu último ajuste, ou o próprio cartão.
  int _fimDaTela(int tela) =>
      _paradas.lastIndexWhere((p) => p.tela == tela);

  /// A parada equivalente em outra tela.
  ///
  /// Estando no segundo ajuste e andando de lado, cai no segundo ajuste do
  /// vizinho — e no que houver, quando o vizinho tiver menos. Voltar sempre
  /// ao cartão fazia perder o lugar a cada passo horizontal.
  int _paradaEquivalente(int tela, int? ajuste) {
    if (ajuste == null) return _inicioDaTela(tela);
    final quantos = _telas[tela].ajustes.length;
    if (quantos == 0) return _inicioDaTela(tela);
    return _inicioDaTela(tela) + 1 + ajuste.clamp(0, quantos - 1);
  }

  /// Esquerda e direita andam por **tela**, preservando a profundidade.
  void _trocarDeTela(int delta) {
    final alvo = (_telaAtual + delta).clamp(0, _telas.length - 1);
    if (alvo == _telaAtual) return;
    _irPara(_paradaEquivalente(alvo, _paradas[_parada].ajuste));
  }

  /// Cima e baixo percorrem **tudo** dentro da coluna: cartão, ajustes dele,
  /// e então a tela de baixo. Subindo, entra pelo último ajuste da tela de
  /// cima, para o caminho de volta ser o mesmo da ida.
  void _mover(int delta) {
    final parada = _paradas[_parada];
    if (delta > 0) {
      final proxima = _parada + 1;
      if (proxima < _paradas.length && _paradas[proxima].tela == parada.tela) {
        _irPara(proxima);
        return;
      }
      final abaixo = parada.tela + PopInterfaces.colunas;
      if (abaixo < _telas.length) _irPara(_inicioDaTela(abaixo));
      return;
    }
    if (!parada.ehCartao) {
      _irPara(_parada - 1);
      return;
    }
    final acima = parada.tela - PopInterfaces.colunas;
    if (acima >= 0) _irPara(_fimDaTela(acima));
  }

  bool _comando(String comando) {
    if (_fechando) return true;
    final parada = _paradas[_parada];
    switch (comando) {
      case 'ESQUERDA':
        _trocarDeTela(-1);
      case 'DIREITA':
        _trocarDeTela(1);
      case 'CIMA':
        _mover(-1);
      case 'BAIXO':
        _mover(1);
      case 'LB':
        _mexerNoVolume(-AjusteVolume.passo);
      case 'RB':
        _mexerNoVolume(AjusteVolume.passo);
      case '2':
        parada.ehCartao
            ? _aplicar(_telas[parada.tela])
            : _acionarAjuste(_telas[parada.tela].ajustes[parada.ajuste!]);
      case '3':
      case 'START':
        _fechar();
    }
    return true;
  }

  // ------------------------------------------------------------------- ações

  void _acionarAjuste(AjusteDeTela ajuste) {
    if (ajuste is! AjusteLiga) return;
    SonsSistema.click();
    setState(() {
      ajuste.gravar(!ajuste.ler());
      _mudou = true;
    });
  }

  void _mexerNoVolume(double delta) {
    final parada = _paradas[_parada];
    if (parada.ehCartao) return;
    final ajuste = _telas[parada.tela].ajustes[parada.ajuste!];
    if (ajuste is! AjusteVolume) return;
    final novo = (ajuste.ler() + delta).clamp(0.0, 1.0);
    if (novo == ajuste.ler()) return;
    SonsSistema.direction();
    setState(() {
      ajuste.gravar(novo);
      _mudou = true;
    });
  }

  Future<void> _aplicar(TelaDoLauncher tela) async {
    if (_fechando) return;
    SonsSistema.click();
    if (tela.ehSlim) {
      await _escreverSlim(true);
    } else {
      configSistema.viewType = tela.id;
      if (SlimModeConfigController.active.value) {
        await _escreverSlim(false);
      }
    }
    _mudou = true;
    await _fechar();
  }

  Future<void> _fechar() async {
    if (_fechando || !mounted) return;
    _fechando = true;
    // Gravar só na saída: mexer no disco a cada toque de LB/RB seria um
    // arquivo por passo de volume.
    if (_mudou) await (widget.gravar?.call() ?? configSistema.save());
    if (!mounted) return;
    Navigator.of(context).pop(_mudou ? 'salvar' : '');
  }

  // ------------------------------------------------------------------ dicas

  /// Onde o Pad está, em uma linha: tela, ou tela › ajuste.
  String _ondeEstou() {
    final parada = _paradas[_parada];
    final tela = _telas[parada.tela];
    if (parada.ehCartao) return tela.nome;
    return '${tela.nome}  ›  ${tela.ajustes[parada.ajuste!].nome}';
  }

  /// O que A e os ombros fazem na posição atual.
  String _oQueOsBotoesFazem() {
    final parada = _paradas[_parada];
    final tela = _telas[parada.tela];
    if (parada.ehCartao) {
      final descer = tela.ajustes.isEmpty
          ? 'esta tela não tem ajuste próprio'
          : '↓ abre os ${tela.ajustes.length} ajustes dela';
      return 'A usa esta tela  ·  $descer  ·  B fecha';
    }
    final ajuste = tela.ajustes[parada.ajuste!];
    return switch (ajuste) {
      AjusteLiga() => 'A liga e desliga  ·  ↑↓ troca de ajuste  ·  B fecha',
      AjusteVolume() =>
        'LB diminui  ·  RB aumenta  ·  ↑↓ troca de ajuste  ·  B fecha',
    };
  }

  // ----------------------------------------------------------------- desenho

  @override
  Widget build(BuildContext context) {
    final tamanho = MediaQuery.sizeOf(context);
    return LauncherPadScope(
      menu: false,
      revealFocus: false,
      onCommand: _comando,
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.all(20),
        child: SizedBox(
          width: (tamanho.width - 40).clamp(320.0, 1180.0),
          height: (tamanho.height - 40).clamp(320.0, 760.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xF00D0B14),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0x40FFFFFF)),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        const Icon(Icons.dashboard_rounded,
                            color: _violeta, size: 26),
                        const SizedBox(width: 10),
                        const Text('Interfaces',
                            style: TextStyle(
                                fontSize: 24, fontWeight: FontWeight.w600)),
                        const Spacer(),
                        Flexible(
                          child: Text(_ondeEstou(),
                              textAlign: TextAlign.right,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white)),
                        ),
                      ]),
                      const SizedBox(height: 6),
                      // A dica muda com a posição: ela diz o que os botões
                      // fazem **aqui**, não uma legenda fixa que vale para
                      // metade dos lugares.
                      Align(
                        alignment: Alignment.centerRight,
                        child: Text(_oQueOsBotoesFazem(),
                            style: const TextStyle(
                                fontSize: 11, color: Color(0xFF8E88A3))),
                      ),
                      const SizedBox(height: 12),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: PopInterfaces.colunas,
                            crossAxisSpacing: 14,
                            mainAxisSpacing: 14,
                            childAspectRatio: 1.45,
                          ),
                          itemCount: _telas.length,
                          itemBuilder: (context, i) => _cartao(i),
                        ),
                      ),
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _cartao(int indice) {
    final tela = _telas[indice];
    final parada = _paradas[_parada];
    final naTela = parada.tela == indice;
    final cartaoApontado = naTela && parada.ehCartao;
    final atual = _ehAtual(tela);
    return GestureDetector(
      onTap: () {
        _irPara(_inicioDaTela(indice));
        _aplicar(tela);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: cartaoApontado
              ? const Color(0xFF221C38)
              : const Color(0xFF14121E),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: cartaoApontado
                  ? Colors.white
                  : atual
                      ? _violeta
                      : const Color(0xFF2A2740),
              width: cartaoApontado || atual ? 2 : 1),
        ),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(tela.icone,
                    size: 22, color: atual ? _violeta : Colors.white70),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(tela.nome,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                if (atual) const _Etiqueta(texto: 'Atual', cor: _violeta),
                if (tela.ajustes.isNotEmpty) ...[
                  const SizedBox(width: 6),
                  // Diz que há algo abaixo antes de o jogador descer às cegas.
                  Icon(Icons.keyboard_arrow_down_rounded,
                      size: 18,
                      color: cartaoApontado
                          ? Colors.white
                          : const Color(0xFF6B6681)),
                ],
              ]),
              const SizedBox(height: 4),
              Text(tela.resumo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: Color(0xFF8E88A3))),
              const SizedBox(height: 10),
              Expanded(
                child: tela.ajustes.isEmpty
                    // Sem ajuste próprio: dizer "OK" é mais honesto que
                    // mostrar controles que pertencem ao launcher inteiro.
                    ? const Align(
                        alignment: Alignment.centerLeft,
                        child: _Etiqueta(
                            texto: 'OK', cor: Color(0xFF7BD88F)))
                    : ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          for (var a = 0; a < tela.ajustes.length; a++)
                            _linhaDeAjuste(tela.ajustes[a],
                                apontada: naTela && parada.ajuste == a),
                        ],
                      ),
              ),
            ]),
      ),
    );
  }

  Widget _linhaDeAjuste(AjusteDeTela ajuste, {required bool apontada}) {
    final valor = switch (ajuste) {
      AjusteLiga() => ajuste.ler() ? 'Ligado' : 'Desligado',
      AjusteVolume() => '${(ajuste.ler() * 100).round()}%',
    };
    return GestureDetector(
      onTap: () => _acionarAjuste(ajuste),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        // Recuo à esquerda: o ajuste pertence ao cartão, e a margem é o que
        // mostra isso sem precisar de outra moldura.
        margin: const EdgeInsets.only(left: 10, bottom: 6),
        padding: const EdgeInsets.fromLTRB(8, 7, 10, 7),
        decoration: BoxDecoration(
          color: apontada ? const Color(0xFF2E2750) : const Color(0xFF1B1830),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
              color: apontada ? Colors.white : Colors.transparent, width: 1.5),
        ),
        child: Row(children: [
          Container(
            width: 3,
            height: 16,
            margin: const EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
                color: apontada ? _violeta : const Color(0xFF3A3458),
                borderRadius: BorderRadius.circular(2)),
          ),
          Expanded(
            child: Text(ajuste.nome,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12)),
          ),
          Text(valor,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _violeta)),
        ]),
      ),
    );
  }
}

class _Etiqueta extends StatelessWidget {
  const _Etiqueta({required this.texto, required this.cor});
  final String texto;
  final Color cor;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
            color: cor.withValues(alpha: .16),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: cor)),
        child: Text(texto,
            style: TextStyle(
                fontSize: 10, fontWeight: FontWeight.w800, color: cor)),
      );
}
