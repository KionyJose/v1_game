import 'package:flutter/material.dart';
import '../Controllers/SonsSistema.dart';
import 'futuristic_material.dart';

/// A section name that participates in pad navigation without a button surface.
class FuturisticTopicLabel extends StatelessWidget {
  const FuturisticTopicLabel(
      {super.key,
      required this.text,
      required this.node,
      required this.onActivate});
  final String text;
  final FocusNode node;
  final VoidCallback onActivate;

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
                final duration = Duration(
                    milliseconds:
                        MediaQuery.disableAnimationsOf(context) ? 0 : 240);
                return Semantics(
                    header: true,
                    child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: node.requestFocus,
                        child: SizedBox(
                            height: 52,
                            child: Align(
                                alignment: Alignment.centerLeft,
                                child: Stack(
                                    alignment: Alignment.centerLeft,
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                          left: -24,
                                          right: -40,
                                          top: -18,
                                          bottom: -18,
                                          child: IgnorePointer(
                                              child: AnimatedOpacity(
                                                  opacity: focused ? 1 : 0,
                                                  duration: duration,
                                                  curve: Curves.easeOutCubic,
                                                  child: const DecoratedBox(
                                                      decoration: BoxDecoration(
                                                          gradient:
                                                              RadialGradient(
                                                                  radius: .8,
                                                                  colors: [
                                                        Color(0x503FBDBB),
                                                        Color(0x186E59AD),
                                                        Colors.transparent,
                                                      ],
                                                                  stops: [
                                                        0,
                                                        .45,
                                                        1
                                                      ])))))),
                                      Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8),
                                          child: AnimatedScale(
                                              scale: focused ? 1.2 : 1,
                                              alignment: Alignment.centerLeft,
                                              duration: duration,
                                              curve: Curves.easeOutCubic,
                                              child: AnimatedDefaultTextStyle(
                                                  duration: duration,
                                                  style: TextStyle(
                                                      fontFamily: 'Oxanium',
                                                      fontSize: 16,
                                                      letterSpacing: 3,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                      color: focused
                                                          ? FuturisticPalette
                                                              .pearl
                                                          : FuturisticPalette
                                                              .water,
                                                      shadows: focused
                                                          ? const [
                                                              Shadow(
                                                                  color: Color(
                                                                      0xAA73E3DD),
                                                                  blurRadius:
                                                                      16)
                                                            ]
                                                          : const []),
                                                  child: Text(text)))),
                                    ])))));
              })));
}
