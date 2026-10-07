import 'package:flutter/material.dart';
import 'futuristic_material.dart';
import '../Controllers/SonsSistema.dart';

/// One focus target for keyboard, pad and mouse, including large visual tiles.
class FuturisticActionTile extends StatelessWidget {
  const FuturisticActionTile(
      {super.key,
      required this.node,
      required this.onActivate,
      required this.child,
      this.prominent = false});
  final FocusNode node;
  final VoidCallback onActivate;
  final Widget child;
  final bool prominent;
  @override
  Widget build(BuildContext context) => Actions(
          actions: {
            ActivateIntent: CallbackAction<ActivateIntent>(onInvoke: (_) {
              onActivate();
              return null;
            }),
          },
          child: Focus(
              focusNode: node,
              onFocusChange: (focused) {
                if (focused) SonsSistema.futuristicMove();
              },
              child: Builder(builder: (context) {
                final focused = Focus.of(context).hasFocus;
                return Semantics(
                    button: true,
                    child: GestureDetector(
                        onTap: () {
                          node.requestFocus();
                          onActivate();
                        },
                        child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            curve: Curves.easeOutCubic,
                            padding: const EdgeInsets.all(2.5),
                            foregroundDecoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                  width: focused ? 2.5 : 1,
                                  color: focused
                                      ? FuturisticPalette.water
                                      : Colors.white24),
                            ),
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                gradient: prominent
                                    ? const LinearGradient(colors: [
                                        Color(0xFF795CE6),
                                        Color(0xFF423889),
                                        Color(0xFF295F68)
                                      ])
                                    : null,
                                color: prominent
                                    ? null
                                    : Colors.white.withValues(
                                        alpha: focused ? .15 : .045),
                                boxShadow: prominent && focused
                                    ? const [
                                        BoxShadow(
                                            color: Color(0x607E67E8),
                                            blurRadius: 28)
                                      ]
                                    : null),
                            child: child)));
              })));
}
