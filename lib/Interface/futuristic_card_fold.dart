import 'dart:math' as math;
import 'package:flutter/material.dart';

class FuturisticCardFold extends StatelessWidget {
  const FuturisticCardFold(
      {super.key, required this.opening, required this.child});
  final bool opening;
  final Widget child;
  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
      tween: Tween(end: opening ? math.pi / 2 : 0),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 450),
      curve: Curves.easeInOutCubic,
      child: child,
      builder: (_, angle, face) => Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.identity()
            ..setEntry(3, 2, .0015)
            ..rotateX(-angle),
          child: face));
}
