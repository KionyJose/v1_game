import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'futuristic_material.dart';

/// A vertically mirrored card face; no input or extra glass capture.
class FuturisticCardMirror extends StatelessWidget {
  const FuturisticCardMirror(
      {super.key,
      required this.size,
      required this.child,
      this.focused = false});
  final double size;
  final Widget child;
  final bool focused;

  /// Desfoque do reflexo. É a única camada nova: entra por cima do reflexo
  /// pronto, sem tocar no esvaimento nem no brilho da borda — mexer nos três
  /// ao mesmo tempo fazia um anular o outro.
  static const desfoque = 3.5;

  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: IgnorePointer(
          child: SizedBox(
              width: size,
              height: size * .5,
              child: RepaintBoundary(
                  child: ImageFiltered(
                      imageFilter: ui.ImageFilter.blur(
                          sigmaX: desfoque,
                          sigmaY: desfoque,
                          // Decal mantém o borrão dentro de si: sem ele a
                          // borda do recorte é esticada para dentro da imagem.
                          tileMode: ui.TileMode.decal),
                      child: ShaderMask(
                          blendMode: BlendMode.dstIn,
                          shaderCallback: (bounds) => const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0x88FFFFFF),
                                    Color(0x40FFFFFF),
                                    Colors.transparent
                                  ],
                                  stops: [
                                    0,
                                    .4,
                                    1
                                  ]).createShader(bounds),
                          child: ClipRect(
                              child: OverflowBox(
                                  alignment: Alignment.topCenter,
                                  minHeight: size,
                                  maxHeight: size,
                                  child: Transform.flip(
                                      flipY: true,
                                      child: DecoratedBox(
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(25),
                                              border: Border.all(
                                                  color: FuturisticPalette.pearl
                                                      .withValues(alpha: focused ? .85 : .5),
                                                  width: 5)),
                                          child: child))))))))));
}
