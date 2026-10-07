import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'futuristic_material.dart';

/// The image moves behind the UI; navigation icons never share its transform.
class FuturisticLandscape extends StatefulWidget {
  const FuturisticLandscape({super.key, required this.category});
  final int category;
  @override
  State<FuturisticLandscape> createState() => _FuturisticLandscapeState();
}

class _FuturisticLandscapeState extends State<FuturisticLandscape>
    with SingleTickerProviderStateMixin {
  late final AnimationController _drift;
  @override
  void initState() {
    super.initState();
    _drift =
        AnimationController(vsync: this, duration: const Duration(seconds: 36));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _drift.stop();
    } else {
      _drift.repeat();
    }
  }

  @override
  void dispose() {
    _drift.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduce = MediaQuery.disableAnimationsOf(context);
    return ClipRect(
        child: Stack(fit: StackFit.expand, children: [
      TweenAnimationBuilder<double>(
        tween: Tween(end: reduce ? 0 : (widget.category - 1.5) * 12),
        duration: reduce ? Duration.zero : const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
        builder: (_, pageOffset, child) => AnimatedBuilder(
            animation: _drift,
            child: child,
            builder: (_, image) {
              final phase = _drift.value * math.pi * 2;
              return Transform.translate(
                  offset: Offset(
                      pageOffset + (reduce ? 0 : math.sin(phase) * 16),
                      reduce ? 0 : math.cos(phase) * 7),
                  child: Transform.scale(scale: 1.08, child: image));
            }),
        child: RepaintBoundary(
            child: Image.asset('assets/Futurista/aurora_lake.png',
                fit: BoxFit.cover,
                filterQuality: FilterQuality.medium,
                errorBuilder: (_, __, ___) => const WaterLandscape())),
      ),
      const DecoratedBox(
          decoration: BoxDecoration(
              gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
            Color(0x55040915),
            Color(0x200B1327),
            Color(0x99040A17)
          ],
                  stops: [
            0,
            .5,
            1
          ]))),
    ]));
  }
}
