import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

class FuturisticPalette {
  static const accent = Color(0xFFC9B9FF);
  static const pearl = Color(0xFFF4F0FF);
  static const water = Color(0xFFA9EEE4);
}

/// Shares one backdrop capture per display frame for desktop Skia refraction.
class GlassBackdrop extends StatelessWidget {
  const GlassBackdrop(
      {super.key,
      required this.background,
      required this.child,
      this.animated = true});
  final Widget background, child;
  final bool animated;
  @override
  Widget build(BuildContext context) => LiquidGlassView(
      backgroundWidget: background,
      pixelRatio: .75,
      useImpellerBackdrop: ui.ImageFilter.isShaderFilterSupported,
      realTimeCapture: animated && !MediaQuery.disableAnimationsOf(context),
      // Capture during paint so each lens sees the current, sharper backdrop.
      // 0.75 improves refraction detail without a full-size 4K readback.
      regionCapture: false,
      refreshRate: LiquidGlassRefreshRate.deviceRefreshRate,
      child: child);
}

/// A menu can refract a cached view of the launcher without recapturing frames.
class GlassScene extends StatefulWidget {
  const GlassScene({super.key, required this.child});
  final Widget child;
  static _GlassSceneState? _active;
  static Future<ui.Image?> capture() async {
    if (_active == null) return null;
    // Capture after paint even when a water animation has scheduled a frame.
    await WidgetsBinding.instance.endOfFrame;
    return _active?.capture();
  }

  @override
  State<GlassScene> createState() => _GlassSceneState();
}

class _GlassSceneState extends State<GlassScene> {
  final _boundary = GlobalKey();
  @override
  void initState() {
    super.initState();
    GlassScene._active = this;
  }

  ui.Image? capture() {
    if (!mounted) return null;
    final boundary = _boundary.currentContext?.findRenderObject();
    if (boundary is! RenderRepaintBoundary || !boundary.hasSize) return null;
    var ready = true;
    assert(() {
      ready = !boundary.debugNeedsPaint;
      return true;
    }());
    if (!ready) return null;
    try {
      final pixelRatio =
          MediaQuery.devicePixelRatioOf(context).clamp(1.0, 1.5).toDouble();
      return boundary.toImageSync(pixelRatio: pixelRatio);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    if (identical(GlassScene._active, this)) GlassScene._active = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      RepaintBoundary(key: _boundary, child: widget.child);
}

class GlassPanel extends StatelessWidget {
  const GlassPanel(
      {super.key,
      required this.child,
      this.radius = 24,
      this.focused = false,
      this.borderWidth,
      this.refractionWidth = 24,
      this.appearanceColor});
  final Widget child;
  final double radius;
  final bool focused;
  final double? borderWidth;
  final double refractionWidth;
  final Color? appearanceColor;
  @override
  Widget build(BuildContext context) => LiquidGlassLens(
      useImpellerBackdrop: ui.ImageFilter.isShaderFilterSupported,
      style: LiquidGlassStyle(
          shape: LiquidGlassShape.continuousRoundedRectangle(
              cornerRadius: radius,
              borderWidth: borderWidth ?? (focused ? 1.8 : 1.2),
              lightIntensity: focused ? 2.6 : 1.8,
              lightDirection: 125,
              lightColor: FuturisticPalette.pearl,
              borderType: const OpticalBorder(
                  ambientIntensity: 1.8,
                  borderSaturation: 1.3,
                  borderSolidity: .15)),
          appearance: LiquidGlassAppearance(
              color: appearanceColor ??
                  (focused
                      ? const Color(0x448F70D8)
                      : const Color(0x20877AAE)),
              saturation: 1.2,
              blur: const LiquidGlassBlur(sigmaX: 5, sigmaY: 5),
              shadow: const LiquidGlassShadow(
                  blur: 10, opacity: .3, offset: Offset(0, 7))),
          refraction: LiquidGlassRefraction(
              distortion: .16,
              distortionWidth: refractionWidth,
              magnification: 1.04,
              chromaticAberration: .004)),
      child: DecoratedBox(
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0x38FFFFFF),
                    Color(0x088F81B8),
                    Color(0x1076EADB)
                  ],
                  stops: [
                    0,
                    .48,
                    1
                  ])),
          child: child));
}

/// Lightweight vector landscape: slow waves without a network image or video.
class WaterLandscape extends StatefulWidget {
  const WaterLandscape({super.key});
  @override
  State<WaterLandscape> createState() => _WaterLandscapeState();
}

class _WaterLandscapeState extends State<WaterLandscape>
    with SingleTickerProviderStateMixin {
  late final AnimationController _water =
      AnimationController(vsync: this, duration: const Duration(seconds: 24));
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (MediaQuery.disableAnimationsOf(context)) {
      _water.stop();
    } else {
      _water.repeat();
    }
  }

  @override
  void dispose() {
    _water.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      CustomPaint(painter: _LandscapePainter(_water));
}

class _LandscapePainter extends CustomPainter {
  _LandscapePainter(this.water) : super(repaint: water);
  final Animation<double> water;
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0xFF25223E),
                Color(0xFF9A90BB),
                Color(0xFF3B737D),
                Color(0xFF101A30)
              ],
              stops: [
                0,
                .42,
                .58,
                1
              ]).createShader(rect));
    final glow = Rect.fromCircle(
        center: Offset(size.width * .72, size.height * .22),
        radius: size.width * .28);
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const RadialGradient(
                  colors: [Color(0x88D4BFFF), Colors.transparent])
              .createShader(glow));
    for (var layer = 0; layer < 3; layer++) {
      final mountain = Path()..moveTo(0, size.height * .48);
      for (var x = 0.0; x <= size.width; x += 10) {
        final y = .4 +
            layer * .035 -
            .07 * math.sin(x / size.width * 9 + layer * 2) -
            .035 * math.cos(x / size.width * 17 + layer);
        mountain.lineTo(x, size.height * y);
      }
      mountain
        ..lineTo(size.width, size.height * .54)
        ..lineTo(0, size.height * .54)
        ..close();
      canvas.drawPath(
          mountain,
          Paint()
            ..color = [
              const Color(0xFF747494),
              const Color(0xFF555E7A),
              const Color(0xFF354759)
            ][layer]);
    }
    for (var line = 0; line < 30; line++) {
      final path = Path();
      final baseline = size.height * (.53 + line * .016);
      for (var x = 0.0; x <= size.width; x += 14) {
        final y = baseline +
            math.sin(x / size.width * 11 +
                    water.value * math.pi * 2 +
                    line * .5) *
                (2 + line * .18);
        if (x == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFFB5E9DE)
                .withValues(alpha: .025 + (line % 3) * .012)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1 + line * .035);
    }
    canvas.drawRect(
        rect,
        Paint()
          ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0x55001018),
                Color(0x00000000),
                Color(0xAA000F1A)
              ]).createShader(rect));
  }

  @override
  bool shouldRepaint(_LandscapePainter oldDelegate) =>
      oldDelegate.water != water;
}
