import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'futuristic_material.dart';

/// A page transition with one live focus tree and a non-interactive old frame.
class FuturisticViewBox extends StatefulWidget {
  const FuturisticViewBox(
      {super.key, required this.page, required this.child, this.glass = true});
  final bool glass;
  final int page;
  final Widget child;
  @override
  State<FuturisticViewBox> createState() => _FuturisticViewBoxState();
}

class _FuturisticViewBoxState extends State<FuturisticViewBox>
    with SingleTickerProviderStateMixin {
  final _boundary = GlobalKey();
  late final AnimationController _transition;
  ui.Image? _previous;
  double _direction = 1;

  @override
  void initState() {
    super.initState();
    _transition = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 580), value: 1)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          final old = _previous;
          setState(() => _previous = null);
          _release(old);
        }
      });
  }

  void _release(ui.Image? image) {
    if (image == null) return;
    // Wait until RawImage has been removed from the render tree.
    WidgetsBinding.instance.addPostFrameCallback((_) => image.dispose());
  }

  @override
  void didUpdateWidget(FuturisticViewBox oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.page == widget.page) return;
    _direction = widget.page > oldWidget.page ? 1 : -1;
    _release(_previous);
    _previous = null;
    if (MediaQuery.disableAnimationsOf(context)) {
      _transition.value = 1;
      return;
    }
    final boundary = _boundary.currentContext?.findRenderObject();
    if (boundary is RenderRepaintBoundary && boundary.hasSize) {
      var painted = true;
      assert(() {
        painted = !boundary.debugNeedsPaint;
        return true;
      }());
      if (painted) {
        try {
          final pixelRatio =
              MediaQuery.devicePixelRatioOf(context).clamp(1.0, 1.5).toDouble();
          _previous = boundary.toImageSync(pixelRatio: pixelRatio);
        } catch (_) {}
      }
    }
    _transition.forward(from: 0);
  }

  @override
  void dispose() {
    _transition.dispose();
    _release(_previous);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
        builder: (_, constraints) => AnimatedBuilder(
              animation: _transition,
              child: RepaintBoundary(key: _boundary, child: widget.child),
              builder: (_, child) {
                final t = Curves.easeOutQuint.transform(_transition.value);
                return Stack(fit: StackFit.passthrough, children: [
                  if (_previous != null)
                    Positioned.fill(
                        child: IgnorePointer(
                            child: Opacity(
                                opacity: 1 - t,
                                child: Transform.translate(
                                    offset: Offset(
                                        -_direction *
                                            constraints.maxWidth *
                                            .06 *
                                            t,
                                        0),
                                    child: RawImage(
                                        image: _previous, fit: BoxFit.fill))))),
                  Transform.translate(
                      offset: Offset(
                          _direction * constraints.maxWidth * .1 * (1 - t), 0),
                      child: Opacity(opacity: t, child: child)),
                ]);
              },
            ));
    return widget.glass
        ? GlassPanel(
            radius: 32,
            child: ClipRRect(
                borderRadius: BorderRadius.circular(32), child: content))
        : ClipRect(child: content);
  }
}
