import '../../Interface/launcher_header.dart';
import 'package:flutter/material.dart';
import '../../Interface/launcher_pad_scope.dart';
import '../../Interface/launcher_routes.dart';
import '../../Interface/pad_keyboard.dart';
import 'detalhes_jogo_tela.dart';
import 'componentes/jogo_card.dart';
import 'componentes/loja_intro.dart';
import 'scraps/catalogo_controller.dart';
import 'scraps/catalogo_scraper.dart';
import 'scraps/gamestorrents_scraper.dart';

class ScrapLoja extends StatefulWidget {
  final CatalogoScraper? scraper;
  const ScrapLoja({super.key, this.scraper});

  @override
  State<ScrapLoja> createState() => _ScrapLojaState();
}

class _ScrapLojaState extends State<ScrapLoja> {
  late final CatalogoController _catalogo;
  String _busca = '';
  final _buscaController = TextEditingController();
  final _buscaFocus = FocusNode();
  bool _tecladoAberto = false;
  bool _focoInicialDefinido = false;
  final _categoriasFocus =
      FocusNode(skipTraversal: true, canRequestFocus: false);
  final _categorias = <String, FocusNode>{};
  final _jogosFocus = <Uri, FocusNode>{};
  List<JogoCatalogo> _visiveis = [];
  int _colunas = 1;

  bool _navegar(String command) {
    final primeiraCategoria = _catalogo.generos.keys.firstOrNull;
    final categoria =
        primeiraCategoria == null ? null : _categorias[primeiraCategoria];
    final primeiroJogo =
        _visiveis.isEmpty ? null : _jogosFocus[_visiveis.first.pagina];
    if (command == 'BAIXO' && _buscaFocus.hasFocus) {
      (categoria ?? primeiroJogo)?.requestFocus();
      return categoria != null || primeiroJogo != null;
    }
    if (_categoriasFocus.hasFocus) {
      if (command == 'BAIXO' && primeiroJogo != null) {
        primeiroJogo.requestFocus();
        return true;
      }
      if (command == 'CIMA') {
        _buscaFocus.requestFocus();
        return true;
      }
    }
    if (command == 'CIMA' &&
        _visiveis
            .take(_colunas)
            .any((jogo) => _jogosFocus[jogo.pagina]?.hasFocus ?? false)) {
      (categoria ?? _buscaFocus).requestFocus();
      return true;
    }
    return false;
  }

  @override
  void initState() {
    super.initState();
    _catalogo = CatalogoController(widget.scraper ?? GamesTorrentsScraper());
    _catalogo.atualizar();
  }

  @override
  void dispose() {
    _catalogo.dispose();
    _buscaController.dispose();
    _buscaFocus.dispose();
    _categoriasFocus.dispose();
    for (final node in [..._categorias.values, ..._jogosFocus.values]) {
      node.dispose();
    }
    super.dispose();
  }

  Future<void> _abrir(JogoCatalogo jogo) async {
    await abrirTelaLauncher<void>(context, DetalhesJogoTela(jogo: jogo));
  }

  Future<void> _teclado() async {
    if (_tecladoAberto) return;
    _tecladoAberto = true;
    final value = await abrirTecladoPad(context, texto: _buscaController.text);
    _tecladoAberto = false;
    if (!mounted) return;
    if (value != null) {
      _buscaController.text = value;
      setState(() => _busca = value);
    }
    _buscaFocus.requestFocus();
  }

  @override
  Widget build(BuildContext context) => LauncherPadScope(
      revealInitialFocus: false,
      onCommand: (command) {
        if (command == '2' && _buscaFocus.hasFocus) {
          _teclado();
          return true;
        }
        return _navegar(command);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF000000),
        appBar: const LauncherHeader(),
        body: SafeArea(
            child: LayoutBuilder(
                builder: (context, viewport) => AnimatedBuilder(
                      animation: _catalogo,
                      builder: (context, _) {
                        if (_catalogo.carregando && _catalogo.jogos.isEmpty) {
                          return SingleChildScrollView(
                            child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: LojaIntro(
                                viewportWidth: viewport.maxWidth,
                                descricao: 'Catálogo ${_catalogo.scraper.nome}',
                                carregando: true,
                                busca: const SizedBox.shrink(),
                              ),
                            ),
                          );
                        }
                        final jogos = _catalogo.jogos
                            .where((jogo) => jogo.nome
                                .toLowerCase()
                                .contains(_busca.toLowerCase()))
                            .toList();
                        _visiveis = jogos;
                        for (final jogo in jogos) {
                          _jogosFocus.putIfAbsent(
                              jogo.pagina, () => FocusNode());
                        }
                        if (!_focoInicialDefinido && jogos.isNotEmpty) {
                          _focoInicialDefinido = true;
                          final primeiro = jogos.first.pagina;
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted ||
                                !(ModalRoute.of(context)?.isCurrent ?? true) ||
                                _buscaFocus.hasFocus ||
                                _categoriasFocus.hasFocus) {
                              return;
                            }
                            _jogosFocus[primeiro]?.requestFocus();
                          });
                        }
                        return CustomScrollView(slivers: [
                          SliverPadding(
                              padding: const EdgeInsets.all(24),
                              sliver: SliverToBoxAdapter(
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      LojaIntro(
                                        viewportWidth: viewport.maxWidth,
                                        descricao:
                                            'Catálogo ${_catalogo.scraper.nome} • ${_catalogo.total.isEmpty ? '${_catalogo.jogos.length} jogos' : _catalogo.total}',
                                        busca: TextField(
                                            controller: _buscaController,
                                            focusNode: _buscaFocus,
                                            onSubmitted: (_) => _teclado(),
                                            onChanged: (valor) =>
                                                setState(() => _busca = valor),
                                            decoration: InputDecoration(
                                                hintText:
                                                    'Buscar nos jogos carregados',
                                                prefixIcon:
                                                    const Icon(Icons.search),
                                                suffixIcon: IconButton(
                                                    tooltip: 'Teclado interno',
                                                    onPressed: _teclado,
                                                    icon: const Icon(Icons
                                                        .keyboard_rounded)),
                                                border: OutlineInputBorder(
                                                    borderRadius: BorderRadius.circular(
                                                        28)),
                                                enabledBorder: OutlineInputBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            28),
                                                    borderSide: const BorderSide(
                                                        color:
                                                            Color(0xFF444444))),
                                                focusedBorder:
                                                    OutlineInputBorder(borderRadius: BorderRadius.circular(28), borderSide: const BorderSide(color: Color(0xFFB6A8FF), width: 2)))),
                                      ),
                                      const SizedBox(height: 12),
                                      if (_catalogo.generos.isNotEmpty)
                                        Focus(
                                            focusNode: _categoriasFocus,
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                  children:
                                                      _catalogo.generos.entries
                                                          .map(
                                                              (item) => Padding(
                                                                    padding: const EdgeInsets
                                                                        .only(
                                                                        right:
                                                                            8),
                                                                    child: ChoiceChip(
                                                                        focusNode: _categorias.putIfAbsent(item.key, () => FocusNode()),
                                                                        showCheckmark: true,
                                                                        checkmarkColor: Colors.black,
                                                                        selectedColor: const Color(0xFFB6A8FF),
                                                                        backgroundColor: const Color(0xFF171717),
                                                                        labelStyle: TextStyle(color: item.key == _catalogo.genero ? Colors.black : Colors.white, fontWeight: item.key == _catalogo.genero ? FontWeight.w800 : FontWeight.w500),
                                                                        side: WidgetStateBorderSide.resolveWith((states) => BorderSide(
                                                                            color: states.contains(WidgetState.focused)
                                                                                ? Colors.white
                                                                                : item.key == _catalogo.genero
                                                                                    ? const Color(0xFFB6A8FF)
                                                                                    : const Color(0xFF444444),
                                                                            width: states.contains(WidgetState.focused) ? 3 : 1)),
                                                                        label: Text(item.value),
                                                                        selected: item.key == _catalogo.genero,
                                                                        // Mantém o foco enquanto a categoria carrega.
                                                                        // O controller já bloqueia solicitações simultâneas.
                                                                        onSelected: (_) => _catalogo.atualizar(filtroGenero: item.key)),
                                                                  ))
                                                          .toList()),
                                            )),
                                      if (_catalogo.carregando)
                                        const Padding(
                                            padding: EdgeInsets.only(top: 16),
                                            child: LinearProgressIndicator()),
                                      if (_catalogo.erro != null)
                                        Padding(
                                            padding:
                                                const EdgeInsets.only(top: 16),
                                            child: Wrap(
                                                crossAxisAlignment:
                                                    WrapCrossAlignment.center,
                                                spacing: 12,
                                                children: [
                                                  Text(_catalogo.erro!),
                                                  TextButton(
                                                      onPressed: _catalogo
                                                              .carregando
                                                          ? null
                                                          : _catalogo
                                                              .tentarNovamente,
                                                      child: const Text(
                                                          'Tentar novamente')),
                                                ])),
                                      const SizedBox(height: 8),
                                      Text(
                                          '${_catalogo.jogos.length} jogos carregados'),
                                    ]),
                              )),
                          if (jogos.isEmpty &&
                              !_catalogo.carregando &&
                              _catalogo.erro == null)
                            const SliverToBoxAdapter(
                                child: Padding(
                                    padding: EdgeInsets.all(24),
                                    child: Text(
                                        'Nenhum jogo encontrado. Ajuste a busca ou carregue mais jogos.'))),
                          SliverPadding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              sliver: SliverLayoutBuilder(
                                  builder: (context, constraints) {
                                final colunas =
                                    (constraints.crossAxisExtent / 220)
                                        .floor()
                                        .clamp(1, 8);
                                _colunas = colunas;
                                return SliverGrid(
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                          crossAxisCount: colunas,
                                          mainAxisExtent: 410,
                                          crossAxisSpacing: 12,
                                          mainAxisSpacing: 12),
                                  delegate: SliverChildBuilderDelegate(
                                      (_, index) => JogoCard(
                                          key: ValueKey(jogos[index].pagina),
                                          focusNode:
                                              _jogosFocus[jogos[index].pagina],
                                          jogo: jogos[index],
                                          onAbrir: () => _abrir(jogos[index])),
                                      childCount: jogos.length),
                                );
                              })),
                          SliverToBoxAdapter(
                              child: Padding(
                                  padding: const EdgeInsets.all(24),
                                  child: Center(
                                      child: _catalogo.proxima != null
                                          ? FilledButton.icon(
                                              onPressed: _catalogo.carregando
                                                  ? null
                                                  : _catalogo.carregarMais,
                                              icon:
                                                  const Icon(Icons.expand_more),
                                              label: const Text(
                                                  'Carregar mais jogos'))
                                          : Text(_catalogo.jogos.isEmpty
                                              ? ''
                                              : 'Fim do catálogo carregado')))),
                        ]);
                      },
                    ))),
      ));
}
