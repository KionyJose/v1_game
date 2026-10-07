import 'package:flutter/material.dart';

/// A vertically mirrored card face; no input or extra glass capture.
class FuturisticCardMirror extends StatelessWidget {
  const FuturisticCardMirror(
      {super.key, required this.size, required this.child});
  final double size;
  final Widget child;
  @override
  Widget build(BuildContext context) => ExcludeSemantics(
      child: IgnorePointer(
          child: SizedBox(
              width: size,
              height: size * .5,
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
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), border: Border.all(color: const Color(0x80F4F0FF), width: 1.2)),
                                  child: child))))))));
}
