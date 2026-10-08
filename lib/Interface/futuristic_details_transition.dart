import 'package:flutter/material.dart';

/// Keeps the curve continuous when Play interrupts the entrance animation.
class FuturisticDetailsTransition extends StatefulWidget {
  const FuturisticDetailsTransition(
      {super.key, required this.animation, required this.child});

  final Animation<double> animation;
  final Widget child;

  @override
  State<FuturisticDetailsTransition> createState() =>
      _FuturisticDetailsTransitionState();
}

class _FuturisticDetailsTransitionState
    extends State<FuturisticDetailsTransition> {
  late CurvedAnimation _curve;

  void _createCurve() {
    _curve = CurvedAnimation(
        parent: widget.animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic);
  }

  @override
  void initState() {
    super.initState();
    _createCurve();
  }

  @override
  void didUpdateWidget(FuturisticDetailsTransition oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animation != oldWidget.animation) {
      _curve.dispose();
      _createCurve();
    }
  }

  @override
  void dispose() {
    _curve.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _curve,
      child: RepaintBoundary(child: widget.child),
      builder: (_, child) {
        final t = _curve.value;
        return Transform(
            alignment: Alignment.bottomCenter,
            transform: Matrix4.identity()
              ..setEntry(3, 2, .0005)
              ..rotateX((1 - t) * .45),
            child: Opacity(opacity: t, child: child));
      });
}
