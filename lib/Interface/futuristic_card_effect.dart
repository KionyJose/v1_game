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
      vsync: this, duration: const Duration(milliseconds: 620));
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
    final center = size.width * (-.4 + progress * 1.8);
    final band = Rect.fromLTWH(
        center - size.width * .2, 0, size.width * .4, size.height);
    canvas.drawRect(
        Offset.zero & size,
        Paint()
          ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
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
  }

  @override
  bool shouldRepaint(_Shine oldDelegate) => progress != oldDelegate.progress;
}
