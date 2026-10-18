import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Bounded particle pool, normalized coordinates and time-based damping.
/// Paint notifications never rebuild the launcher's widget or focus trees.
class FuturisticParticleMotion extends ChangeNotifier {
  FuturisticParticleMotion() {
    final random = math.Random(41);
    for (var i = 0; i < 44; i++) {
      particles.add((
        x: random.nextDouble(),
        y: random.nextDouble(),
        depth: .3 + random.nextDouble() * .7,
        phase: random.nextDouble() * math.pi * 2
      ));
    }
  }
  final particles = <({double x, double y, double depth, double phase})>[];
  double gust = 0, time = 0, drift = 0;
  void impulse(double distance) {
    gust = (gust + distance * 2.4).clamp(-1.2, 1.2);
  }

  void advance(double seconds) {
    if (seconds <= 0) return;
    // Keep particles gently drifting at rest, then let navigation impulses
    // speed that drift up and decay smoothly back to the idle pace.
    final activity = gust.abs().clamp(0.0, 1.0);
    time += seconds * (.32 + .68 * activity);
    final decay = math.exp(-5 * seconds);
    // Integrate the navigation impulse analytically and stop at its final pose.
    drift += gust * (1 - decay) / 5;
    gust *= decay;
    notifyListeners();
  }
}

class FuturisticParticles extends StatefulWidget {
  const FuturisticParticles({
    super.key,
    required this.position,
    this.ambientMotion = false,
  });
  final ValueListenable<double> position;
  final bool ambientMotion;
  @override
  State<FuturisticParticles> createState() => _FuturisticParticlesState();
}

class _FuturisticParticlesState extends State<FuturisticParticles>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  final _motion = FuturisticParticleMotion();
  late final Ticker _ticker;
  Duration? _lastTick;
  late double _lastPosition;
  bool _animate = false, _resumed = true;
  @override
  void initState() {
    super.initState();
    _lastPosition = widget.position.value;
    widget.position.addListener(_onNavigation);
    _ticker = createTicker((elapsed) {
      final previous = _lastTick;
      _lastTick = elapsed;
      if (previous != null) {
        _motion.advance(
            ((elapsed - previous).inMicroseconds / 1000000).clamp(0, .067));
        if (_motion.gust.abs() < .002) {
          _motion.gust = 0;
          if (!widget.ambientMotion) {
            _ticker.stop();
            _lastTick = null;
          }
        }
      }
    });
    WidgetsBinding.instance.addObserver(this);
  }

  void _onNavigation() {
    final position = widget.position.value;
    if (_animate && _resumed) {
      _motion.impulse(position - _lastPosition);
      _syncTicker();
    }
    _lastPosition = position;
  }

  void _syncTicker() {
    if (_animate &&
        _resumed &&
        (widget.ambientMotion || _motion.gust.abs() >= .002)) {
      if (!_ticker.isActive) {
        _lastTick = null;
        _ticker.start();
      }
    } else {
      _ticker.stop();
      _lastTick = null;
      _motion.gust = 0;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    _syncTicker();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _resumed = state == AppLifecycleState.resumed;
    _syncTicker();
  }

  @override
  void didUpdateWidget(FuturisticParticles oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) {
      oldWidget.position.removeListener(_onNavigation);
      _lastPosition = widget.position.value;
      widget.position.addListener(_onNavigation);
    }
    if (oldWidget.ambientMotion != widget.ambientMotion) _syncTicker();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    widget.position.removeListener(_onNavigation);
    _ticker.dispose();
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => IgnorePointer(
      child: ExcludeSemantics(
          child: RepaintBoundary(
              child: CustomPaint(painter: _ParticlePainter(_motion)))));
}

class _ParticlePainter extends CustomPainter {
  _ParticlePainter(this.motion) : super(repaint: motion);
  final FuturisticParticleMotion motion;
  final _paint = Paint()..strokeCap = StrokeCap.round;
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    for (final particle in motion.particles) {
      final x = (particle.x +
              motion.drift * particle.depth +
              motion.time * .006 * particle.depth +
              math.sin(motion.time * .22 + particle.phase) *
                  .006 *
                  particle.depth) %
          1 *
          size.width;
      final y =
          (particle.y + math.sin(motion.time * .35 + particle.phase) * .012) *
              size.height;
      final radius = .7 + particle.depth * 1.5;
      _paint.color =
          const Color(0xFFD9F8F5).withValues(alpha: .12 + particle.depth * .28);
      canvas.drawCircle(Offset(x, y), radius, _paint);
      if (motion.gust.abs() > .08) {
        _paint.strokeWidth = radius * .6;
        canvas.drawLine(Offset(x, y),
            Offset(x - motion.gust * particle.depth * 9, y), _paint);
      }
    }
  }

  @override
  bool shouldRepaint(_ParticlePainter oldDelegate) =>
      oldDelegate.motion != motion;
}
