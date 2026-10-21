import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../Controllers/SonsSistema.dart';
import '../../Interface/launcher_header.dart';
import '../../Interface/launcher_pad_scope.dart';
import '../Tela loja/componentes/erro_catalogo_painel.dart';
import '../Tela loja/scraps/catalogo_scraper.dart';
import '../Tela loja/scraps/diagnostico_catalogo.dart';
import '../Tela loja/scraps/jogo_detalhes.dart';

/// Ficha do jogo vinda do Descobrir.
///
/// Segue a mesma leitura da ficha da Loja Interna — capa à esquerda, mídia no
/// centro, ação à direita — mas sem o painel de compra: a loja oficial não
/// entrega torrent, e oferecer download aqui seria mentira. No lugar entram
/// preço e o botão que abre a página oficial.
class DescobrirDetalhes extends StatefulWidget {
  const DescobrirDetalhes({
    super.key,
    required this.jogo,
    required this.scraper,
    this.sons = true,
  });

  final JogoCatalogo jogo;
  final DetalhesScraper scraper;
  final bool sons;

  @override
  State<DescobrirDetalhes> createState() => _DescobrirDetalhesState();
}

class _DescobrirDetalhesState extends State<DescobrirDetalhes> {
  late Future<JogoDetalhes> _ficha;
  final _abrirFocus = FocusNode();
  int _imagem = 0;

  static const _violeta = Color(0xFFB6A8FF);

  @override
  void initState() {
    super.initState();
    _ficha = widget.scraper.carregar(widget.jogo.pagina);
  }

  @override
  void dispose() {
    _abrirFocus.dispose();
    widget.scraper.dispose();
    super.dispose();
  }

  void _recarregar() =>
      setState(() => _ficha = widget.scraper.carregar(widget.jogo.pagina));

  void _som(void Function() tocar) {
    if (widget.sons) tocar();
  }

  Future<void> _abrirLoja(Uri endereco) async {
    _som(SonsSistema.futuristicOpen);
    try {
      if (await launchUrl(endereco, mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {/* Mostra o aviso sem derrubar a ficha. */}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a loja.')));
  }

  bool _comando(String comando, JogoDetalhes? ficha) {
    final total = ficha?.imagens.length ?? 0;
    if (total == 0) return false;
    if (comando == 'ESQUERDA' && _imagem > 0) {
      setState(() => _imagem--);
      _som(SonsSistema.futuristicMove);
      return true;
    }
    if (comando == 'DIREITA' && _imagem < total - 1) {
      setState(() => _imagem++);
      _som(SonsSistema.futuristicMove);
      return true;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<JogoDetalhes>(
        future: _ficha,
        builder: (context, snapshot) => LauncherPadScope(
          onCommand: (comando) => _comando(comando, snapshot.data),
          child: Scaffold(
            backgroundColor: const Color(0xFF07060C),
            appBar: LauncherHeader(title: Text(widget.jogo.nome)),
            body: _corpo(context, snapshot),
          ),
        ),
      );

  Widget _corpo(BuildContext context, AsyncSnapshot<JogoDetalhes> snapshot) {
    if (snapshot.connectionState != ConnectionState.done) {
      return const Center(child: CircularProgressIndicator(color: _violeta));
    }
    final erro = snapshot.error;
    if (erro != null || snapshot.data == null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ErroCatalogoPainel(
              mensagem: erro is ErroCatalogo
                  ? erro.mensagem
                  : 'Não foi possível carregar a ficha deste jogo.',
              diagnostico: erro is ErroCatalogo
                  ? erro.diagnostico
                  : (erro == null
                      ? null
                      : DiagnosticoCatalogo.de(erro,
                          endereco: widget.jogo.pagina)),
              carregando: false,
              onTentarNovamente: _recarregar,
            ),
          ),
        ),
      );
    }
    return _ficha_(context, snapshot.data!);
  }

  Widget _ficha_(BuildContext context, JogoDetalhes jogo) =>
      SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1400),
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: LayoutBuilder(builder: (context, limites) {
                final largo = limites.maxWidth >= 1000;
                final galeria = _Galeria(
                    imagens: jogo.imagens,
                    indice: _imagem,
                    onSelecionar: (i) {
                      setState(() => _imagem = i);
                      _som(SonsSistema.futuristicMove);
                    });
                final painel = _painel(context, jogo);
                return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (largo)
                        Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(flex: 3, child: galeria),
                              const SizedBox(width: 28),
                              SizedBox(width: 320, child: painel),
                            ])
                      else ...[
                        galeria,
                        const SizedBox(height: 24),
                        painel,
                      ],
                      const SizedBox(height: 28),
                      if (jogo.descricao.isNotEmpty)
                        _Bloco(
                          titulo: 'Sobre',
                          child: Text(jogo.descricao,
                              style: const TextStyle(height: 1.5)),
                        ),
                    ]);
              }),
            ),
          ),
        ),
      );

  Widget _painel(BuildContext context, JogoDetalhes jogo) => _Bloco(
        titulo: 'Nesta loja',
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (jogo.capa != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                      imageUrl: jogo.capa.toString(),
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => const SizedBox.shrink()),
                ),
                const SizedBox(height: 18),
              ],
              if (jogo.preco.isNotEmpty) ...[
                Text(jogo.preco,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.w900)),
                const SizedBox(height: 16),
              ],
              if (jogo.generos.isNotEmpty) ...[
                Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final genero in jogo.generos)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                              color: const Color(0xFF14121E),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                  color: const Color(0xFF2A2740))),
                          child: Text(genero,
                              style: const TextStyle(fontSize: 12)),
                        ),
                    ]),
                const SizedBox(height: 18),
              ],
              FilledButton.icon(
                  autofocus: true,
                  focusNode: _abrirFocus,
                  style: FilledButton.styleFrom(
                      backgroundColor: _violeta,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14))),
                  onPressed: () =>
                      _abrirLoja(jogo.urlLoja ?? widget.jogo.pagina),
                  icon: const Icon(Icons.open_in_new_rounded),
                  label: const Text('Abrir na loja')),
              const SizedBox(height: 10),
              const Text(
                  'Abre a página oficial no navegador. Esta loja não '
                  'entrega download pelo launcher.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11, color: Color(0xFF8E88A3))),
            ]),
      );
}

class _Bloco extends StatelessWidget {
  const _Bloco({required this.titulo, required this.child});
  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
            color: const Color(0xFF0D0B14),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF23203a))),
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(titulo,
                  style: const TextStyle(
                      fontSize: 13,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF8E88A3))),
              const SizedBox(height: 14),
              child,
            ]),
      );
}

class _Galeria extends StatelessWidget {
  const _Galeria(
      {required this.imagens, required this.indice, required this.onSelecionar});
  final List<Uri> imagens;
  final int indice;
  final ValueChanged<int> onSelecionar;

  @override
  Widget build(BuildContext context) {
    if (imagens.isEmpty) {
      return _Bloco(
          titulo: 'Imagens',
          child: Container(
            height: 200,
            alignment: Alignment.center,
            child: const Text('Este jogo não tem capturas publicadas.',
                style: TextStyle(color: Color(0xFF8E88A3))),
          ));
    }
    final atual = indice.clamp(0, imagens.length - 1);
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: AspectRatio(
          aspectRatio: 16 / 9,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 260),
            child: CachedNetworkImage(
              key: ValueKey(imagens[atual]),
              imageUrl: imagens[atual].toString(),
              fit: BoxFit.cover,
              placeholder: (_, __) => const ColoredBox(color: Color(0xFF14121E)),
              errorWidget: (_, __, ___) =>
                  const ColoredBox(color: Color(0xFF14121E)),
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 64,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: imagens.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) => GestureDetector(
            onTap: () => onSelecionar(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 110,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: i == atual
                        ? const Color(0xFFB6A8FF)
                        : const Color(0xFF2A2740),
                    width: i == atual ? 2 : 1),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(11),
                child: CachedNetworkImage(
                    imageUrl: imagens[i].toString(),
                    fit: BoxFit.cover,
                    errorWidget: (_, __, ___) =>
                        const ColoredBox(color: Color(0xFF14121E))),
              ),
            ),
          ),
        ),
      ),
    ]);
  }
}
