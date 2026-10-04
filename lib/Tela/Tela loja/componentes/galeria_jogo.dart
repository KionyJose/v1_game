import 'package:flutter/material.dart';
import 'imagem_jogo.dart';
import '../scraps/jogo_detalhes.dart';
import 'trailer_player.dart';
import '../../../Interface/launcher_pad_scope.dart';
import '../../../Interface/pad_directional_group.dart';

class GaleriaJogo extends StatefulWidget {
  final List<Uri> imagens;
  final List<TrailerJogo> trailers;
  final Widget Function(TrailerJogo)? trailerBuilder;
  final bool autofocus;
  final bool Function(TraversalDirection)? onVertical;
  const GaleriaJogo(
      {super.key,
      required this.imagens,
      this.trailers = const [],
      this.trailerBuilder,
      this.autofocus = false,
      this.onVertical});
  @override
  State<GaleriaJogo> createState() => GaleriaJogoState();
}

class GaleriaJogoState extends State<GaleriaJogo> {
  final _scroll = ScrollController();
  final _nodes = <FocusNode>[];
  int _indice = 0;
  int? _focused;
  bool _playing = false;
  var _player = GlobalKey<TrailerPlayerState>();
  int get _count => widget.imagens.length + widget.trailers.length;
  bool get hasMedia => _count > 0;
  bool get _isTrailer => _indice >= widget.imagens.length;
  TrailerJogo get _trailer => widget.trailers[_indice - widget.imagens.length];
  bool command(String command) =>
      _player.currentState?.command(command) ?? false;
  void _activate() {
    if (!_isTrailer) {
      _ampliar();
      return;
    }
    if (_playing) {
      _player.currentState?.togglePlayback();
    } else {
      setState(() => _playing = true);
    }
  }

  Widget _preview(int index) {
    if (index < widget.imagens.length) {
      return ImagemJogo(url: widget.imagens[index]);
    }
    final trailer = widget.trailers[index - widget.imagens.length];
    return Stack(fit: StackFit.expand, children: [
      ImagemJogo(url: trailer.miniatura),
      const Center(
          child: Icon(Icons.play_circle_fill, size: 36, color: Colors.white)),
      Positioned(
          left: 4,
          right: 4,
          bottom: 2,
          child: ColoredBox(
              color: Colors.black87,
              child: Text(trailer.titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, color: Colors.white)))),
    ]);
  }

  @override
  void initState() {
    super.initState();
    _syncNodes();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted &&
          widget.autofocus &&
          (ModalRoute.of(context)?.isCurrent ?? true)) {
        focusSelected();
      }
    });
  }

  void _syncNodes() {
    while (_nodes.length < _count) {
      _nodes.add(FocusNode());
    }
    if (_indice >= _count) _indice = 0;
  }

  @override
  void didUpdateWidget(GaleriaJogo oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncNodes();
  }

  @override
  void dispose() {
    for (final node in _nodes) {
      node.dispose();
    }
    _scroll.dispose();
    super.dispose();
  }

  void focusSelected() {
    if (_count > 0) _nodes[_indice].requestFocus();
  }

  void _select(int index) {
    setState(() {
      if (_indice != index) {
        _playing = false;
        _player = GlobalKey<TrailerPlayerState>();
      }
      _indice = index;
      _focused = index;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scroll.hasClients) return;
      final left = index * 138.0;
      final right = left + 128;
      if (left < _scroll.offset ||
          right > _scroll.offset + _scroll.position.viewportDimension) {
        final target = (left - (_scroll.position.viewportDimension - 128) / 2)
            .clamp(0.0, _scroll.position.maxScrollExtent);
        _scroll.animateTo(target,
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOutCubic);
      }
    });
  }

  bool _move(TraversalDirection direction) {
    if (direction == TraversalDirection.up ||
        direction == TraversalDirection.down) {
      return widget.onVertical?.call(direction) ?? false;
    }
    if (_count == 0) return false;
    final next = (_indice + (direction == TraversalDirection.right ? 1 : -1))
        .clamp(0, _count - 1);
    _nodes[next].requestFocus();
    return true;
  }

  Future<void> _ampliar() async {
    await showDialog<void>(
        context: context,
        builder: (context) => LauncherPadScope(
              menu: false,
              child: Dialog(
                  backgroundColor: Colors.black,
                  insetPadding: const EdgeInsets.all(16),
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    Align(
                        alignment: Alignment.centerRight,
                        child: IconButton(
                            tooltip: 'Fechar imagem',
                            autofocus: true,
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
                  ])),
            ));
    if (mounted) focusSelected();
  }

  @override
  Widget build(BuildContext context) {
    if (_count == 0) {
      return const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Este jogo não tem imagens cadastradas.'),
            Text('Este jogo não tem trailers cadastrados.'),
          ]);
    }
    return PadDirectionalGroup(
        onMove: _move,
        child: Column(children: [
          ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(fit: StackFit.expand, children: [
                    GestureDetector(
                        onTap: _activate,
                        child: _isTrailer && _playing
                            ? KeyedSubtree(
                                key: ValueKey(_trailer.youtubeId),
                                child: widget.trailerBuilder?.call(_trailer) ??
                                    TrailerPlayer(
                                        key: _player,
                                        trailer: _trailer,
                                        inline: true))
                            : AnimatedSwitcher(
                                duration: const Duration(milliseconds: 160),
                                child: SizedBox.expand(
                                    key: ValueKey(_indice),
                                    child: _preview(_indice)))),
                    Positioned(
                        right: 12,
                        bottom: 12,
                        child: IgnorePointer(
                            child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: .8),
                                    borderRadius: BorderRadius.circular(12)),
                                child: Text('${_indice + 1} / $_count')))),
                  ]))),
          const SizedBox(height: 12),
          SingleChildScrollView(
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              child: Row(children: [
                for (var index = 0; index < _count; index++) ...[
                  if (index > 0) const SizedBox(width: 10),
                  Semantics(
                      label: index < widget.imagens.length
                          ? 'Ampliar imagem ${index + 1}'
                          : 'Reproduzir trailer',
                      button: true,
                      selected: index == _indice,
                      child: InkWell(
                          key: ValueKey(index < widget.imagens.length
                              ? 'game-image-$index'
                              : 'game-trailer-${index - widget.imagens.length}'),
                          focusNode: _nodes[index],
                          autofocus: widget.autofocus && index == 0,
                          onFocusChange: (focused) {
                            if (focused) {
                              _select(index);
                            } else if (_focused == index) {
                              setState(() => _focused = null);
                            }
                          },
                          onTap: () {
                            _nodes[index].requestFocus();
                            _select(index);
                            _activate();
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                              duration: const Duration(milliseconds: 120),
                              width: 128,
                              height: 80,
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                  color: index == _focused
                                      ? const Color(0xFFB6A8FF)
                                      : const Color(0xFF171717),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                      color: index == _focused
                                          ? Colors.white
                                          : index == _indice
                                              ? const Color(0xFFB6A8FF)
                                              : const Color(0xFF444444),
                                      width: 3)),
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(7),
                                  child: _preview(index))))),
                ],
              ])),
        ]));
  }
}
