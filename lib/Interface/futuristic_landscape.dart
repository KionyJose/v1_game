import 'dart:math' as math;
import 'dart:ui' as ui;
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
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final landscape = Image.asset(
      'assets/Futurista/aurora_lake.png',
      fit: BoxFit.cover,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => const WaterLandscape(),
    );
    return ClipRect(
        child: Stack(fit: StackFit.expand, children: [
      if (!reduce)
        RepaintBoundary(
          child: ImageFiltered(
            imageFilter: ui.ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Transform.scale(scale: 1.08, child: landscape),
          ),
        ),
      TweenAnimationBuilder<double>(
        tween: Tween(end: reduce ? 0 : (widget.category - 1.5) * 12),
        duration: reduce ? Duration.zero : const Duration(milliseconds: 650),
        curve: Curves.easeInOutCubic,
        builder: (_, pageOffset, child) => AnimatedBuilder(
            animation: _drift,
            child: child,
            builder: (_, image) {
              final phase = _drift.value * math.pi * 2;
              final dx = pageOffset + (reduce ? 0 : math.sin(phase) * 16);
              final dy = reduce ? 0.0 : math.cos(phase) * 7;
              return Transform.translate(
                  offset: Offset(
                      (dx * devicePixelRatio).roundToDouble() /
                          devicePixelRatio,
                      (dy * devicePixelRatio).roundToDouble() /
                          devicePixelRatio),
                  child: image);
            }),
        child: RepaintBoundary(child: landscape),
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
