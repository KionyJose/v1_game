import 'package:flutter/material.dart';
import '../scraps/jogo_detalhes.dart';
import '../../../Interface/pad_directional_group.dart';

/// Leitura com foco e rolagem própria, sem perder a seleção da galeria.
class JogoMidia extends StatefulWidget {
  final JogoDetalhes jogo;
  final VoidCallback? onUp;
  const JogoMidia({super.key, required this.jogo, this.onUp});
  @override
  State<JogoMidia> createState() => JogoMidiaState();
}

class JogoMidiaState extends State<JogoMidia> {
  final _focus = FocusNode();
  final _scroll = ScrollController();
  bool _focused = false;
  void focusDescription() {
    if (widget.jogo.descricao.isNotEmpty) _focus.requestFocus();
  }

  @override
  void dispose() {
    _focus.dispose();
    _scroll.dispose();
    super.dispose();
  }

  bool _move(TraversalDirection direction) {
    if (direction == TraversalDirection.up &&
        (!_scroll.hasClients || _scroll.offset <= 1)) {
      widget.onUp?.call();
      return true;
    }
    if (_scroll.hasClients &&
        (direction == TraversalDirection.up ||
            direction == TraversalDirection.down)) {
      _scroll.animateTo(
          (_scroll.offset + (direction == TraversalDirection.down ? 160 : -160))
              .clamp(0.0, _scroll.position.maxScrollExtent),
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic);
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.jogo.descricao.isEmpty) return const SizedBox.shrink();
    return PadDirectionalGroup(
        onMove: _move,
        child: Focus(
          key: const ValueKey('game-description'),
          focusNode: _focus,
          onFocusChange: (value) => setState(() => _focused = value),
          child: GestureDetector(
              onTap: focusDescription,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 160),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                    color: _focused
                        ? const Color(0xFF201C2C)
                        : const Color(0xFF111111),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                        color: _focused
                            ? const Color(0xFFB6A8FF)
                            : const Color(0xFF333333),
                        width: 2)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Sobre o jogo',
                          style: Theme.of(context).textTheme.titleLarge),
                      const SizedBox(height: 12),
                      ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 260),
                          child: SingleChildScrollView(
                              controller: _scroll,
                              child: ExcludeFocus(
                                  child: SelectableText(widget.jogo.descricao,
                                      style: const TextStyle(
                                          fontSize: 18,
                                          height: 1.7,
                                          color: Colors.white))))),
                    ]),
              )),
        ));
  }
}
