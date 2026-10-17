import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'launcher_pad_scope.dart';

/// One opening sequence per mounted launcher. The dashboard loads underneath.
class ModernStartupIntro extends StatefulWidget {
  const ModernStartupIntro(
      {super.key, required this.enabled, required this.child, this.onFinished});
  final bool enabled;
  final Widget child;
  final VoidCallback? onFinished;

  @override
  State<ModernStartupIntro> createState() => _ModernStartupIntroState();
}

class _ModernStartupIntroState extends State<ModernStartupIntro>
    with SingleTickerProviderStateMixin {
  late final AnimationController _timeline;
  late final Animation<double> _reveal;
  late bool _active;
  bool _started = false, _skipping = false, _reduced = false;

  @override
  void initState() {
    super.initState();
    _active = widget.enabled;
    _timeline =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..addStatusListener(_status);
    _reveal = _timeline.drive(
        CurveTween(curve: const Interval(.9, 1, curve: Curves.easeInOutCubic)));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_active || _started) return;
    _started = true;
    _reduced = MediaQuery.disableAnimationsOf(context);
    if (_reduced) _timeline.duration = const Duration(milliseconds: 700);
    _timeline.forward();
  }

  void _status(AnimationStatus status) {
    if (status != AnimationStatus.completed || !mounted || !_active) return;
    setState(() => _active = false);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onFinished?.call();
    });
  }

  void _skip() {
    if (!_active || _skipping) return;
    _skipping = true;
    // Continue into the final reveal instead of abruptly removing the overlay.
    _timeline.value = math.max(.9, _timeline.value);
    _timeline.animateTo(1,
        duration: Duration(milliseconds: _reduced ? 100 : 650));
  }

  @override
  void dispose() {
    _timeline.removeStatusListener(_status);
    _timeline.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(fit: StackFit.expand, children: [
      ExcludeSemantics(
          excluding: _active,
          child: ExcludeFocus(
              excluding: _active,
              child: IgnorePointer(
                  ignoring: _active,
                  child: TickerMode(
                      enabled: !_active,
                      child: FadeTransition(
                          opacity: _active
                              ? _reveal
                              : const AlwaysStoppedAnimation<double>(1),
                          child: widget.child))))),
      if (_active)
        LauncherPadScope(
            menu: false,
            revealFocus: false,
            onCommand: (command) {
              if (const ['2', '3', 'START'].contains(command)) _skip();
              return true;
            },
            child: Focus(
                autofocus: true,
                onKeyEvent: (_, event) {
                  if (event is KeyDownEvent &&
                      const [
                        LogicalKeyboardKey.enter,
                        LogicalKeyboardKey.space,
                        LogicalKeyboardKey.escape
                      ].contains(event.logicalKey)) {
                    _skip();
                  }
                  return KeyEventResult.handled;
                },
                child: FadeTransition(
                    opacity: ReverseAnimation(_reveal),
                    child: RepaintBoundary(
                        child: AnimatedBuilder(
                            animation: _timeline,
                            builder: (context, _) => _scene())))))
    ]);
  }

  Widget _scene() {
    final t = _timeline.value;
    final entrance = Curves.easeOutCubic.transform((t / .22).clamp(0, 1));
    final caption = Curves.easeOutCubic.transform(((t - .25) / .2).clamp(0, 1));
    return ColoredBox(
        key: const ValueKey('modern-startup-intro'),
        color: const Color(0xFF06050B),
        child: Stack(fit: StackFit.expand, children: [
          CustomPaint(painter: _StartupLightPainter(t, _reduced)),
          Center(
              child: Opacity(
                  opacity: _reduced ? 1 : entrance,
                  child: Transform.translate(
                      offset: Offset(0, _reduced ? 0 : 24 * (1 - entrance)),
                      child: Transform.scale(
                          scale: _reduced ? 1 : .9 + .1 * entrance,
                          child:
                              Column(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                                width: 100,
                                height: 100,
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(28),
                                    gradient: const LinearGradient(colors: [
                                      Color(0xFF342A51),
                                      Color(0xFF100D1B)
                                    ]),
                                    border: Border.all(
                                        color: const Color(0xFFBFA3FA)
                                            .withValues(alpha: .55)),
                                    boxShadow: [
                                      BoxShadow(
                                          color: const Color(0xFF9161EF)
                                              .withValues(alpha: .24),
                                          blurRadius: 50,
                                          spreadRadius: 8)
                                    ]),
                                child: Image.asset('assets/IconeAppV1.png')),
                            const SizedBox(height: 28),
                            const Text('V1 LAUNCHER',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                    fontFamily: 'Oxanium',
                                    fontSize: 32,
                                    letterSpacing: 6,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFF1EBFF))),
                            const SizedBox(height: 16),
                            Opacity(
                                opacity: _reduced ? 1 : caption,
                                child: const Text('Seu universo de jogos',
                                    style: TextStyle(
                                        fontSize: 15,
                                        letterSpacing: 2,
                                        color: Color(0xFFC4B6DE)))),
                            const SizedBox(height: 36),
                            SizedBox(
                                width: 160,
                                child: ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                        value: t,
                                        minHeight: 2,
                                        color: const Color(0xFFD2B7FF),
                                        backgroundColor:
                                            const Color(0xFF241C36))))
                          ]))))),
          Positioned(
              bottom: 24,
              left: 0,
              right: 0,
              child: Center(
                  child: TextButton(
                      onPressed: _skip,
                      style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFFB5A7CC)),
                      child: const Text('Pular introdução  ·  A / Enter'))))
        ]));
  }
}

/// Bounded vector effects: no video, shaders, external assets or per-frame blur.
class _StartupLightPainter extends CustomPainter {
  _StartupLightPainter(this.progress, this.reduced);
  final double progress;
  final bool reduced;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final drift = reduced ? 0.0 : math.sin(progress * math.pi) * .08;
    final center = Offset(size.width * (.5 + drift), size.height * .48);
    final glow = Paint()
      ..shader = const RadialGradient(colors: [
        Color(0x553B235F),
        Color(0x15231536),
        Colors.transparent
      ]).createShader(
          Rect.fromCircle(center: center, radius: size.longestSide * .55));
    canvas.drawRect(rect, glow);
    final paint = Paint()..style = PaintingStyle.stroke;
    for (var i = 0; i < 3; i++) {
      final y = size.height * (.72 + i * .055);
      final wave = reduced ? 0.0 : math.sin(progress * math.pi * 2 + i) * 25;
      paint
        ..strokeWidth = 1.2
        ..shader = const LinearGradient(colors: [
          Colors.transparent,
          Color(0x706E4B9C),
          Colors.transparent
        ]).createShader(rect);
      canvas.drawPath(
          Path()
            ..moveTo(0, y)
            ..cubicTo(size.width * .3, y - 80 + wave, size.width * .65,
                y + 80 - wave, size.width, y - 20),
          paint);
    }
    final stars = Paint();
    for (var i = 0; i < 36; i++) {
      final x = ((i * .6180339) % 1) * size.width;
      final y =
          ((i * .381966 + (reduced ? 0 : progress * .035)) % 1) * size.height;
      stars.color = const Color(0xFFD8C4FF).withValues(
          alpha: .08 + .18 * (math.sin(i + progress * math.pi * 2) + 1) / 2);
      canvas.drawCircle(Offset(x, y), i % 4 == 0 ? 1.4 : .8, stars);
    }
  }

  @override
  bool shouldRepaint(_StartupLightPainter oldDelegate) =>
      progress != oldDelegate.progress || reduced != oldDelegate.reduced;
}
