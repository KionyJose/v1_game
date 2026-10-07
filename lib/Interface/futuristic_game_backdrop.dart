import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter/scheduler.dart';
import 'futuristic_landscape.dart';

/// A second spring follows the actual rail, so backdrop and cards share direction
/// and distance while the artwork arrives later. At most two images are painted.
class FuturisticGameBackdrop extends StatefulWidget {
  const FuturisticGameBackdrop(
      {super.key,
      required this.category,
      required this.selected,
      required this.image,
      required this.position});
  final int category, selected;
  final String image;
  final ValueListenable<double> position;
  @override
  State<FuturisticGameBackdrop> createState() => _FuturisticGameBackdropState();
}

class _FuturisticGameBackdropState extends State<FuturisticGameBackdrop>
    with TickerProviderStateMixin {
  late final AnimationController _follow, _fade;
  late final Ticker _followTicker;
  Duration? _lastTick;
  double _target = 0, _velocity = 0;
  Timer? _delay;
  String? _previousImage;
  int _previousIndex = 0;

  @override
  void initState() {
    super.initState();
    _follow = AnimationController.unbounded(
        vsync: this, value: widget.position.value);
    _target = widget.position.value;
    _followTicker = createTicker(_advanceFollow);
    _fade = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1300), value: 1)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed &&
            mounted &&
            _previousImage != null) {
          setState(() => _previousImage = null);
        }
      });
    widget.position.addListener(_followRail);
  }

  bool get _reduce => MediaQuery.disableAnimationsOf(context);

  void _followRail() {
    if (!mounted || _delay != null) return;
    _target = widget.position.value;
    if (_reduce) {
      _resetFollow(_target);
      return;
    }
    if ((_target - _follow.value).abs() < .00005 && _velocity.abs() < .0004) {
      return;
    }
    if (!_followTicker.isActive) {
      _lastTick = null;
      _followTicker.start();
    }
  }

  // Keep one running clock: updating the rail's target must never restart the
  // spring at elapsed time zero on every display frame.
  void _advanceFollow(Duration elapsed) {
    final previous = _lastTick;
    _lastTick = elapsed;
    if (previous == null) return;
    final seconds = (elapsed - previous).inMicroseconds / 1000000;
    if (seconds <= 0) return;
    final spring = SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 28, damping: 12),
        _follow.value,
        _target,
        _velocity);
    _velocity = spring.dx(seconds);
    _follow.value = spring.x(seconds);
    if ((_target - _follow.value).abs() < .00005 && _velocity.abs() < .0004) {
      _resetFollow(_target);
    }
  }

  void _resetFollow(double value) {
    _followTicker.stop();
    _lastTick = null;
    _velocity = 0;
    _target = value;
    _follow.value = value;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_reduce) {
      _delay?.cancel();
      _delay = null;
      _resetFollow(widget.position.value);
      _fade.value = 1;
      _previousImage = null;
    }
  }

  @override
  void didUpdateWidget(FuturisticGameBackdrop oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.position != widget.position) {
      oldWidget.position.removeListener(_followRail);
      widget.position.addListener(_followRail);
    }
    if (oldWidget.selected == widget.selected &&
        oldWidget.image == widget.image &&
        oldWidget.category == widget.category) {
      return;
    }
    _delay?.cancel();
    _delay = null;
    if (_reduce) {
      _previousImage = null;
      _resetFollow(widget.position.value);
      _fade.value = 1;
      return;
    }
    // Preserve the visually dominant artwork during rapid navigation.
    if (_previousImage == null || _fade.value >= .5) {
      _previousImage = oldWidget.image;
      _previousIndex = oldWidget.selected;
    }
    if (oldWidget.category != widget.category) {
      _resetFollow(widget.selected.toDouble());
      _previousIndex = widget.selected;
    }
    _fade.stop();
    _fade.value = 0;
    _delay = Timer(const Duration(milliseconds: 90), () {
      if (!mounted) return;
      _delay = null;
      _followRail();
      _fade.forward();
    });
  }

  @override
  void dispose() {
    widget.position.removeListener(_followRail);
    _delay?.cancel();
    _followTicker.dispose();
    _follow.dispose();
    _fade.dispose();
    super.dispose();
  }

  Widget _artwork(String image) {
    final fallback = FuturisticLandscape(category: widget.category);
    if (image.isEmpty) return fallback;
    final Widget picture;
    if (image.startsWith('assets/')) {
      picture = Image.asset(image,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => fallback);
    } else if (image.startsWith('http')) {
      picture = Image.network(image,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => fallback);
    } else {
      picture = Image.file(File(image),
          fit: BoxFit.cover,
          filterQuality: FilterQuality.medium,
          errorBuilder: (_, __, ___) => fallback);
    }
    return RepaintBoundary(child: picture);
  }

  @override
  Widget build(BuildContext context) =>
      ClipRect(child: LayoutBuilder(builder: (_, constraints) {
        final span = constraints.maxWidth * .14;
        final current = _artwork(widget.image);
        final previous =
            _previousImage == null ? null : _artwork(_previousImage!);
        Widget layer(Widget child, int index, String key) =>
            Transform.translate(
                key: ValueKey(key),
                offset: Offset(
                    ((index - _follow.value) * span)
                        .clamp(-span * 1.3, span * 1.3),
                    0),
                child: Transform.scale(scale: 1.4, child: child));
        return AnimatedBuilder(
            animation: Listenable.merge([_follow, _fade]),
            builder: (_, __) {
              final opacity = Curves.easeInOutCubic.transform(_fade.value);
              return Stack(fit: StackFit.expand, children: [
                const ColoredBox(color: Color(0xFF080D1B)),
                if (previous != null)
                  layer(previous, _previousIndex, 'game-backdrop-previous'),
                Opacity(
                    opacity: previous == null ? 1 : opacity,
                    child: layer(
                        current, widget.selected, 'game-backdrop-current')),
                const DecoratedBox(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                      Color(0x66060B18),
                      Color(0x330A1024),
                      Color(0xC0040712)
                    ],
                            stops: [
                      0,
                      .48,
                      1
                    ]))),
              ]);
            });
      }));
}
