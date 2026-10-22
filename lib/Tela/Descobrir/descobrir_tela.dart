import 'dart:async';

import 'package:flutter/material.dart';

import '../../Controllers/SonsSistema.dart';
import '../../Interface/launcher_header.dart';
import '../../Interface/launcher_pad_scope.dart';
import '../../Interface/launcher_routes.dart';
import '../../Interface/pad_keyboard.dart';
import '../Tela loja/componentes/erro_catalogo_painel.dart';
import '../Tela loja/scraps/catalogo_controller.dart';
import '../Tela loja/scraps/catalogo_scraper.dart';
import '../Tela loja/scraps/jogo_detalhes.dart';
import '../Tela loja/scraps/steam_scraper.dart';
import 'descobrir_card.dart';
import 'descobrir_detalhes.dart';

/// Grade de descoberta: cinco jogos por linha, cartões 21:9.
///
/// Tudo aqui se percorre pelo Pad. A tela tem três faixas — busca, gêneros e
/// grade — e o movimento entre elas é explícito, em vez de depender da
/// travessia automática de foco, que em grade larga pula para onde ninguém
/// espera.
class DescobrirTela extends StatefulWidget {
  const DescobrirTela({
    super.key,
    this.scraper,
    this.detalhesScraper,
    this.sons = true,
  });

  final CatalogoScraper? scraper;
  final DetalhesScraper Function()? detalhesScraper;

  /// Desligado nos testes: o motor de áudio não sobe no ambiente de teste.
  final bool sons;

  /// Cartões por linha. Fixo: é o enquadramento pedido para a tela.
  static const colunas = 5;

  /// Proporção do cartão. Bem mais larga que a capa da loja: a imagem
  /// preenche a altura inteira e sobra nas pontas, a linha fica baixa e cabem
  /// mais linhas na tela sem encolher a largura de cada capa.
  static const proporcao = 21 / 9;

  @override
  State<DescobrirTela> createState() => _DescobrirTelaState();
}

/// Onde o Pad está agora.
enum _Faixa { busca, generos, grade }

class _DescobrirTelaState extends State<DescobrirTela> {
  late final CatalogoController _catalogo;
  final _rolagem = ScrollController();
  final _buscaController = TextEditingController();
  final _buscaFocus = FocusNode(debugLabel: 'busca');
  final _gradeFocus = FocusNode(debugLabel: 'grade');
  final _generosFocus = FocusNode(debugLabel: 'generos');

  _Faixa _faixa = _Faixa.grade;
  int _indice = 0;
  int _genero = 0;
  bool _tecladoAberto = false;
  bool _abrindo = false;

  static const _violeta = DescobrirCard.violeta;

  /// Chaves de gênero na ordem desenhada: a primeira é "Todos".
  List<String> get _chavesDeGenero => ['', ..._catalogo.generos.keys];

  @override
  void initState() {
    super.initState();
    _catalogo = CatalogoController(widget.scraper ?? SteamScraper());
    _catalogo.addListener(_catalogoMudou);
    _catalogo.atualizar();
  }

  @override
  void dispose() {
    _catalogo.removeListener(_catalogoMudou);
    _catalogo.dispose();
    _rolagem.dispose();
    _buscaController.dispose();
    _buscaFocus.dispose();
    _gradeFocus.dispose();
    _generosFocus.dispose();
    super.dispose();
  }

  /// Uma lista nova recomeça do primeiro cartão; sem isto o índice ficava
  /// apontando para um jogo que a nova consulta nem tem.
  void _catalogoMudou() {
    if (_indice >= _catalogo.jogos.length && mounted) {
      setState(() => _indice = 0);
    }
  }

  void _som(void Function() tocar) {
    if (widget.sons) tocar();
  }

  // ---------------------------------------------------------------- navegação

  void _irParaCartao(int destino) {
    final jogos = _catalogo.jogos;
    if (jogos.isEmpty) return;
    final alvo = destino.clamp(0, jogos.length - 1);
    if (alvo == _indice && _faixa == _Faixa.grade) return;
    setState(() {
      _indice = alvo;
      _faixa = _Faixa.grade;
    });
    _gradeFocus.requestFocus();
    _som(SonsSistema.futuristicMove);
    _revelarLinha(alvo ~/ DescobrirTela.colunas);
    // Pede a próxima página uma linha antes do fim, para a grade não parar
    // debaixo do dedo de quem está descendo.
    if (alvo >= jogos.length - DescobrirTela.colunas) _carregarMais();
  }

  /// Mantém a linha inteira à vista, não só o cartão.
  void _revelarLinha(int linha) {
    if (!_rolagem.hasClients) return;
    final posicao = _rolagem.position;
    final altura = _alturaDaLinha;
    final topo = linha * altura;
    final base = topo + altura;
    final alvo = topo < posicao.pixels
        ? topo
        : base > posicao.pixels + posicao.viewportDimension
            ? base - posicao.viewportDimension
            : posicao.pixels;
    _rolagem.animateTo(alvo.clamp(0.0, posicao.maxScrollExtent),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic);
  }

  double _alturaDaLinha = 1;

  void _irParaGenero(int destino) {
    final chaves = _chavesDeGenero;
    if (chaves.isEmpty) return;
    final alvo = destino.clamp(0, chaves.length - 1);
    setState(() {
      _genero = alvo;
      _faixa = _Faixa.generos;
    });
    _generosFocus.requestFocus();
    _som(SonsSistema.futuristicMove);
  }

  void _irParaBusca() {
    setState(() => _faixa = _Faixa.busca);
    _buscaFocus.requestFocus();
    _som(SonsSistema.futuristicMove);
  }

  bool _comando(String comando) {
    switch (_faixa) {
      case _Faixa.busca:
        if (comando == '2') {
          _teclado();
          return true;
        }
        if (comando == 'BAIXO') {
          _chavesDeGenero.length > 1 ? _irParaGenero(_genero) : _irParaCartao(_indice);
          return true;
        }
        return false;

      case _Faixa.generos:
        switch (comando) {
          case 'ESQUERDA':
            _irParaGenero(_genero - 1);
            return true;
          case 'DIREITA':
            _irParaGenero(_genero + 1);
            return true;
          case 'CIMA':
            _irParaBusca();
            return true;
          case 'BAIXO':
            _irParaCartao(_indice);
            return true;
          case '2':
            _filtrar(_chavesDeGenero[_genero]);
            return true;
        }
        return false;

      case _Faixa.grade:
        const colunas = DescobrirTela.colunas;
        switch (comando) {
          case 'ESQUERDA':
            // Na primeira coluna, sobe para o fim da linha de cima.
            _irParaCartao(_indice - 1);
            return true;
          case 'DIREITA':
            _irParaCartao(_indice + 1);
            return true;
          case 'CIMA':
            if (_indice < colunas) {
              _chavesDeGenero.length > 1 ? _irParaGenero(_genero) : _irParaBusca();
            } else {
              _irParaCartao(_indice - colunas);
            }
            return true;
          case 'BAIXO':
            _irParaCartao(_indice + colunas);
            return true;
          case 'LB':
            _irParaCartao(_indice - colunas * 2);
            return true;
          case 'RB':
            _irParaCartao(_indice + colunas * 2);
            return true;
          case '2':
            _abrir();
            return true;
        }
        return false;
    }
  }

  // ------------------------------------------------------------------- ações

  void _carregarMais() {
    if (!_catalogo.carregando && _catalogo.proxima != null) {
      unawaited(_catalogo.carregarMais());
    }
  }

  Future<void> _abrir() async {
    final jogos = _catalogo.jogos;
    if (_abrindo || jogos.isEmpty) return;
    _abrindo = true;
    _som(SonsSistema.futuristicOpen);
    try {
      await abrirTelaLauncher<void>(
          context,
          DescobrirDetalhes(
            jogo: jogos[_indice.clamp(0, jogos.length - 1)],
            scraper: widget.detalhesScraper?.call() ?? SteamDetalhesScraper(),
            sons: widget.sons,
          ));
    } finally {
      _abrindo = false;
      if (mounted) _gradeFocus.requestFocus();
    }
  }

  Future<void> _teclado() async {
    if (_tecladoAberto) return;
    _tecladoAberto = true;
    final valor = await abrirTecladoPad(context, texto: _buscaController.text);
    _tecladoAberto = false;
    if (!mounted) return;
    if (valor != null) {
      _buscaController.text = valor;
      await _buscar();
      if (!mounted) return;
    }
    _buscaFocus.requestFocus();
  }

  Future<void> _buscar() async {
    setState(() => _indice = 0);
    if (_rolagem.hasClients) _rolagem.jumpTo(0);
    await _catalogo.buscar(_buscaController.text);
  }

  Future<void> _filtrar(String genero) async {
    _som(SonsSistema.click);
    setState(() => _indice = 0);
    if (_rolagem.hasClients) _rolagem.jumpTo(0);
    await _catalogo.atualizar(filtroGenero: genero);
  }

  // ---------------------------------------------------------------- desenho

  @override
  Widget build(BuildContext context) => LauncherPadScope(
        revealInitialFocus: false,
        onCommand: _comando,
        child: Scaffold(
          backgroundColor: const Color(0xFF07060C),
          appBar: const LauncherHeader(title: Text('Descobrir')),
          body: AnimatedBuilder(
            animation: _catalogo,
            builder: (context, _) => SafeArea(
              // Margens curtas: o conteúdo é que tem de ocupar a tela.
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                child: Column(children: [
                  _cabecalho(context),
                  const SizedBox(height: 10),
                  Expanded(child: _corpo(context)),
                ]),
              ),
            ),
          ),
        ),
      );

  Widget _cabecalho(BuildContext context) => Row(children: [
        SizedBox(
          width: 360,
          child: Focus(
            focusNode: _buscaFocus,
            onFocusChange: (temFoco) {
              if (temFoco && _faixa != _Faixa.busca) {
                setState(() => _faixa = _Faixa.busca);
              }
            },
            child: TextField(
              controller: _buscaController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _buscar(),
              onTap: () => setState(() => _faixa = _Faixa.busca),
              style: const TextStyle(fontSize: 14),
              decoration: InputDecoration(
                isDense: true,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                hintText: 'Buscar na ${_catalogo.scraper.nome}',
                prefixIcon: const Icon(Icons.search_rounded, size: 20),
                suffixIcon: IconButton(
                    tooltip: 'Teclado interno',
                    onPressed: _teclado,
                    icon: const Icon(Icons.keyboard_rounded, size: 20)),
                filled: true,
                fillColor: const Color(0xFF12101C),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(
                        color: _faixa == _Faixa.busca
                            ? _violeta
                            : const Color(0xFF2A2740),
                        width: _faixa == _Faixa.busca ? 2 : 1)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: const BorderSide(color: _violeta, width: 2)),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: _generos()),
      ]);

  Widget _generos() {
    final chaves = _chavesDeGenero;
    if (chaves.length <= 1) return const SizedBox.shrink();
    return Focus(
      focusNode: _generosFocus,
      child: SizedBox(
        height: 36,
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: chaves.length,
          itemBuilder: (context, i) {
            final chave = chaves[i];
            final ativo = chave == _catalogo.genero;
            // Dois estados distintos: `ativo` é o filtro valendo, `apontado`
            // é onde o Pad está. Juntar os dois escondia para onde o
            // direcional tinha andado antes de confirmar.
            final apontado = _faixa == _Faixa.generos && i == _genero;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _genero = i;
                    _faixa = _Faixa.generos;
                  });
                  _filtrar(chave);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  alignment: Alignment.center,
                  padding: const EdgeInsets.symmetric(horizontal: 15),
                  decoration: BoxDecoration(
                    color: ativo ? _violeta : const Color(0xFF14121E),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                        color: apontado
                            ? Colors.white
                            : ativo
                                ? _violeta
                                : const Color(0xFF2A2740),
                        width: apontado ? 2 : 1),
                  ),
                  child: Text(
                    i == 0 ? 'Todos' : _catalogo.generos[chave] ?? chave,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: ativo ? FontWeight.w800 : FontWeight.w500,
                        color: ativo ? Colors.black : Colors.white70),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _corpo(BuildContext context) {
    if (_catalogo.erro != null) {
      return SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ErroCatalogoPainel(
              mensagem: _catalogo.erro!,
              diagnostico: _catalogo.diagnostico,
              carregando: _catalogo.carregando,
              onTentarNovamente: _catalogo.tentarNovamente,
            ),
          ),
        ),
      );
    }
    final jogos = _catalogo.jogos;
    if (jogos.isEmpty) {
      return Center(
        child: _catalogo.carregando
            ? const CircularProgressIndicator(color: _violeta)
            : const Text('Nenhum jogo encontrado. Tente outra busca.'),
      );
    }
    return Focus(
      focusNode: _gradeFocus,
      autofocus: true,
      onFocusChange: (temFoco) {
        if (temFoco && _faixa != _Faixa.grade) {
          setState(() => _faixa = _Faixa.grade);
        }
      },
      child: LayoutBuilder(builder: (context, limites) {
        const colunas = DescobrirTela.colunas;
        const folga = 12.0;
        final largura =
            (limites.maxWidth - folga * (colunas - 1)) / colunas;
        final altura = largura / DescobrirTela.proporcao;
        _alturaDaLinha = altura + folga;
        return GridView.builder(
          controller: _rolagem,
          padding: EdgeInsets.zero,
          itemCount: jogos.length,
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: colunas,
            crossAxisSpacing: folga,
            mainAxisSpacing: folga,
            childAspectRatio: DescobrirTela.proporcao,
          ),
          itemBuilder: (context, i) => DescobrirCard(
            jogo: jogos[i],
            selecionado: i == _indice && _faixa == _Faixa.grade,
            onAbrir: () => i == _indice ? _abrir() : _irParaCartao(i),
          ),
        );
      }),
    );
  }
}
