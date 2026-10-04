import 'package:flutter/material.dart';
import '../../Downloads/downloads_tela.dart';
import 'detalhes_jogo_tela.dart';
import 'componentes/jogo_card.dart';
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

  @override
  void initState() {
    super.initState();
    _catalogo = CatalogoController(widget.scraper ?? GamesTorrentsScraper());
    _catalogo.atualizar();
  }

  @override
  void dispose() {
    _catalogo.dispose();
    super.dispose();
  }

  Future<void> _abrir(JogoCatalogo jogo) async {
    await Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => DetalhesJogoTela(jogo: jogo)));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFF10121B),
        appBar: AppBar(
          title: const Text('V1 • Jogos para PC'),
          actions: [
            IconButton(
                tooltip: 'Downloads',
                onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                        builder: (_) => const DownloadsTela())),
                icon: const Icon(Icons.download_for_offline_outlined)),
            AnimatedBuilder(
                animation: _catalogo,
                builder: (_, __) => IconButton(
                    tooltip: 'Atualizar catálogo',
                    onPressed: _catalogo.carregando
                        ? null
                        : () => _catalogo.atualizar(),
                    icon: const Icon(Icons.refresh)))
          ],
        ),
        body: SafeArea(
            child: AnimatedBuilder(
          animation: _catalogo,
          builder: (context, _) {
            final jogos = _catalogo.jogos
                .where((jogo) =>
                    jogo.nome.toLowerCase().contains(_busca.toLowerCase()))
                .toList();
            return CustomScrollView(slivers: [
              SliverPadding(
                  padding: const EdgeInsets.all(24),
                  sliver: SliverToBoxAdapter(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Explore seu próximo jogo',
                              style:
                                  Theme.of(context).textTheme.headlineMedium),
                          const SizedBox(height: 8),
                          Text(
                              'Catálogo ${_catalogo.scraper.nome} • ${_catalogo.total.isEmpty ? 'PC' : _catalogo.total}'),
                          const SizedBox(height: 20),
                          TextField(
                              onChanged: (valor) =>
                                  setState(() => _busca = valor),
                              decoration: const InputDecoration(
                                  hintText: 'Buscar nos jogos carregados',
                                  prefixIcon: Icon(Icons.search),
                                  border: OutlineInputBorder())),
                          const SizedBox(height: 12),
                          if (_catalogo.generos.isNotEmpty)
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                  children: _catalogo.generos.entries
                                      .map((item) => Padding(
                                            padding:
                                                const EdgeInsets.only(right: 8),
                                            child: ChoiceChip(
                                                label: Text(item.value),
                                                selected: item.key ==
                                                    _catalogo.genero,
                                                onSelected: _catalogo.carregando
                                                    ? null
                                                    : (_) =>
                                                        _catalogo.atualizar(
                                                            filtroGenero:
                                                                item.key)),
                                          ))
                                      .toList()),
                            ),
                          if (_catalogo.carregando)
                            const Padding(
                                padding: EdgeInsets.only(top: 16),
                                child: LinearProgressIndicator()),
                          if (_catalogo.erro != null)
                            Padding(
                                padding: const EdgeInsets.only(top: 16),
                                child: Wrap(
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    spacing: 12,
                                    children: [
                                      Text(_catalogo.erro!),
                                      TextButton(
                                          onPressed: _catalogo.carregando
                                              ? null
                                              : _catalogo.tentarNovamente,
                                          child:
                                              const Text('Tentar novamente')),
                                    ])),
                          const SizedBox(height: 8),
                          Text('${_catalogo.jogos.length} jogos carregados'),
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
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverLayoutBuilder(builder: (context, constraints) {
                    final colunas =
                        (constraints.crossAxisExtent / 220).floor().clamp(1, 8);
                    return SliverGrid(
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: colunas,
                          mainAxisExtent: 410,
                          crossAxisSpacing: 12,
                          mainAxisSpacing: 12),
                      delegate: SliverChildBuilderDelegate(
                          (_, index) => JogoCard(
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
                                  icon: const Icon(Icons.expand_more),
                                  label: const Text('Carregar mais jogos'))
                              : Text(_catalogo.jogos.isEmpty
                                  ? ''
                                  : 'Fim do catálogo carregado')))),
            ]);
          },
        )),
      );
}
