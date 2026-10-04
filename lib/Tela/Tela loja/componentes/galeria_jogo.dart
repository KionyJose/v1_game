import 'package:flutter/material.dart';
import 'imagem_jogo.dart';

class GaleriaJogo extends StatefulWidget {
  final List<Uri> imagens;
  const GaleriaJogo({super.key, required this.imagens});
  @override
  State<GaleriaJogo> createState() => _GaleriaJogoState();
}

class _GaleriaJogoState extends State<GaleriaJogo> {
  final _paginas = PageController();
  int _indice = 0;
  @override
  void dispose() {
    _paginas.dispose();
    super.dispose();
  }

  void _ampliar() => showDialog<void>(
      context: context,
      builder: (context) => Dialog(
          backgroundColor: const Color(0xFF10121B),
          insetPadding: const EdgeInsets.all(16),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                    tooltip: 'Fechar imagem',
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context))),
            Flexible(
                child: InteractiveViewer(
                    minScale: 1,
                    maxScale: 4,
                    child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: ImagemJogo(
                            url: widget.imagens[_indice],
                            fit: BoxFit.contain)))),
          ])));

  @override
  Widget build(BuildContext context) {
    if (widget.imagens.isEmpty) {
      return const Text('Este jogo não tem imagens cadastradas.');
    }
    return Column(children: [
      ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: AspectRatio(
              aspectRatio: 16 / 9,
              child: Stack(children: [
                PageView.builder(
                    controller: _paginas,
                    itemCount: widget.imagens.length,
                    onPageChanged: (i) => setState(() => _indice = i),
                    itemBuilder: (_, i) => GestureDetector(
                        onTap: _ampliar,
                        child: ImagemJogo(url: widget.imagens[i]))),
                Positioned(
                    right: 12,
                    bottom: 12,
                    child: FilledButton.tonalIcon(
                        onPressed: _ampliar,
                        icon: const Icon(Icons.fullscreen),
                        label:
                            Text('${_indice + 1} / ${widget.imagens.length}'))),
                if (widget.imagens.length > 1)
                  Positioned(
                      left: 4,
                      top: 0,
                      bottom: 0,
                      child: Center(
                          child: IconButton.filledTonal(
                              tooltip: 'Imagem anterior',
                              onPressed: _indice == 0
                                  ? null
                                  : () => _paginas.previousPage(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      curve: Curves.easeOut),
                              icon: const Icon(Icons.chevron_left)))),
                if (widget.imagens.length > 1)
                  Positioned(
                      right: 4,
                      top: 0,
                      bottom: 0,
                      child: Center(
                          child: IconButton.filledTonal(
                              tooltip: 'Próxima imagem',
                              onPressed: _indice == widget.imagens.length - 1
                                  ? null
                                  : () => _paginas.nextPage(
                                      duration:
                                          const Duration(milliseconds: 220),
                                      curve: Curves.easeOut),
                              icon: const Icon(Icons.chevron_right)))),
              ]))),
      const SizedBox(height: 12),
      SizedBox(
          height: 72,
          child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.imagens.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (_, i) => Semantics(
                  label: 'Ver imagem ${i + 1}',
                  button: true,
                  child: InkWell(
                      onTap: () => _paginas.animateToPage(i,
                          duration: const Duration(milliseconds: 220),
                          curve: Curves.easeOut),
                      child: Container(
                          width: 120,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: i == _indice
                                      ? const Color(0xFFAFA3FF)
                                      : Colors.transparent,
                                  width: 2)),
                          child: ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: ImagemJogo(url: widget.imagens[i]))))))),
    ]);
  }
}
