import 'package:flutter/material.dart';

/// One small acknowledgement after the rail settles; the cover stays cached.
class FuturisticCardEffect extends StatefulWidget {
  const FuturisticCardEffect(
      {super.key,
      required this.selected,
      required this.focused,
      required this.settledRevision,
      required this.child});
  final bool selected, focused;
  final int settledRevision;
  final Widget child;
  @override
  State<FuturisticCardEffect> createState() => _FuturisticCardEffectState();
}

class _FuturisticCardEffectState extends State<FuturisticCardEffect>
    with SingleTickerProviderStateMixin {
  late final _acknowledge = AnimationController(
      vsync: this, duration: const Duration(milliseconds: 1050));
  @override
  void didUpdateWidget(FuturisticCardEffect oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!widget.selected || !widget.focused) {
      _acknowledge.stop();
      _acknowledge.value = 0;
    } else if (widget.settledRevision != oldWidget.settledRevision &&
        !MediaQuery.disableAnimationsOf(context)) {
      _acknowledge.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _acknowledge.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
      animation: _acknowledge,
      child: RepaintBoundary(child: widget.child),
      builder: (_, child) {
        final t = _acknowledge.value;
        return Stack(fit: StackFit.passthrough, children: [
          child!,
          if (_acknowledge.isAnimating && widget.focused && widget.selected)
            Positioned.fill(
                child: IgnorePointer(
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(25),
                        child: CustomPaint(painter: _Shine(t))))),
        ]);
      });
}

class _Shine extends CustomPainter {
  const _Shine(this.progress);
  final double progress;
  @override
  void paint(Canvas canvas, Size size) {
    const tilt = .22;
    final width = size.width * .55;
    final t = Curves.easeInOutSine.transform(progress);
    final start = -width / 2 - 2;
    final end = size.width + tilt * size.height + width / 2 + 2;
    final center = start + (end - start) * t;
    final band = Rect.fromLTWH(center - width / 2, 0, width, size.height);
    // Move the complete slanted band beyond the far edge before removing it.
    // A diagonal full-card shader previously remained visible at completion.
    canvas.save();
    canvas.skew(-tilt, 0);
    canvas.drawRect(
        band,
        Paint()
          ..shader = const LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.transparent,
                Color(0x50DFFFF7),
                Color(0x90FFFFFF),
                Colors.transparent
              ],
              stops: [
                0,
                .45,
                .5,
                1
              ]).createShader(band));
    canvas.restore();
  }

  @override
  bool shouldRepaint(_Shine oldDelegate) => progress != oldDelegate.progress;
}
