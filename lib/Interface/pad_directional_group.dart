import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'pad_direction_intent.dart';

/// Uma ordem de navegação compartilhada pelo Pad e pelas setas do teclado.
class PadDirectionalGroup extends StatelessWidget {
  final Widget child;
  final bool Function(TraversalDirection) onMove;
  const PadDirectionalGroup(
      {super.key, required this.child, required this.onMove});

  @override
  Widget build(BuildContext context) => Actions(
        actions: {
          PadDirectionIntent: CallbackAction<PadDirectionIntent>(
              onInvoke: (intent) => onMove(intent.direction))
        },
        child: Focus(
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                return KeyEventResult.ignored;
              }
              final direction = {
                LogicalKeyboardKey.arrowUp: TraversalDirection.up,
                LogicalKeyboardKey.arrowDown: TraversalDirection.down,
                LogicalKeyboardKey.arrowLeft: TraversalDirection.left,
                LogicalKeyboardKey.arrowRight: TraversalDirection.right,
              }[event.logicalKey];
              return direction != null && onMove(direction)
                  ? KeyEventResult.handled
                  : KeyEventResult.ignored;
            },
            child: child),
      );
}
