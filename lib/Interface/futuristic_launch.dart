import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:lottie/lottie.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../Controllers/SonsSistema.dart';
import 'launcher_pad_scope.dart';

typedef FuturisticGameLauncher = Future<void> Function(
    Future<void> Function() presentStarted);

/// Finish leaving details before presenting startup over the game library.
Future<bool> launchFuturisticGameFromLibrary(
  BuildContext context, {
  required TransitionRoute<bool> detailsRoute,
  required String name,
  required String image,
  required Future<void> Function() revealLibrary,
  required FuturisticGameLauncher start,
}) async {
  final play = await Navigator.of(context).push(detailsRoute);
  await detailsRoute.completed;
  if (play != true || !context.mounted) return false;
  await revealLibrary();
  if (!context.mounted) return false;
  await launchFuturisticGame(context, name: name, image: image, start: start);
  return true;
}

/// The existing launcher owns process/mouse/window control. This route replaces
/// only its startup presentation and waits for the same user's return action.
Future<void> launchFuturisticGame(
  BuildContext context, {
  required String name,
  required String image,
  required FuturisticGameLauncher start,
}) async {
  final navigator = Navigator.of(context);
  final ready = ValueNotifier(false);
  final reduce = MediaQuery.disableAnimationsOf(context);
  final route = PageRouteBuilder<void>(
      opaque: false,
      barrierDismissible: false,
      barrierColor: Colors.transparent,
      transitionDuration: Duration(milliseconds: reduce ? 0 : 520),
      reverseTransitionDuration: Duration(milliseconds: reduce ? 0 : 320),
      pageBuilder: (_, __, ___) =>
          FuturisticLaunch(name: name, image: image, ready: ready),
      transitionsBuilder: (_, animation, __, child) {
        final curved = animation.drive(CurveTween(curve: Curves.easeOutCubic));
        return FadeTransition(
            opacity: curved,
            child: ScaleTransition(
                scale: Tween<double>(begin: 1.06, end: 1).animate(curved),
                child: child));
      });
  final completed = navigator.push(route);
  try {
    if (!MediaQuery.disableAnimationsOf(context)) {
      await Future<void>.delayed(const Duration(milliseconds: 750));
    }
    if (!context.mounted || !route.isActive) return;
    await start(() {
      ready.value = true;
      return completed;
    });
  } finally {
    if (route.isCurrent) navigator.pop();
    await route.completed;
    ready.dispose();
  }
}

class FuturisticLaunch extends StatefulWidget {
  const FuturisticLaunch(
      {super.key,
      required this.name,
      required this.image,
      required this.ready});
  final String name, image;
  final ValueListenable<bool> ready;
  @override
  State<FuturisticLaunch> createState() => _FuturisticLaunchState();
}

class _FuturisticLaunchState extends State<FuturisticLaunch>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  late final AnimationController _controller;
  Timer? _intro;
  final _returnFocus = FocusNode();
  bool _canDismiss = false, _closing = false;
  bool _animate = false, _foreground = true;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 3200));
    WidgetsBinding.instance.addObserver(this);
    widget.ready.addListener(_focusReturn);
    _intro = Timer(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() => _canDismiss = true);
        _focusReturn();
      }
    });
    SonsSistema.futuristicLaunch();
  }

  void _focusReturn() {
    if (!_canDismiss || !widget.ready.value) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_closing && widget.ready.value) {
        _returnFocus.requestFocus();
      }
    });
  }

  @override
  void didUpdateWidget(FuturisticLaunch oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ready != widget.ready) {
      oldWidget.ready.removeListener(_focusReturn);
      widget.ready.addListener(_focusReturn);
      _focusReturn();
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _animate = !MediaQuery.disableAnimationsOf(context) &&
        TickerMode.valuesOf(context).enabled;
    _syncAnimation();
  }

  void _syncAnimation() {
    if (!_animate || !_foreground) {
      _controller.stop();
      if (!_animate) _controller.value = .65;
    } else if (!_controller.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _syncAnimation();
  }

  void _close() {
    if (_closing || !_canDismiss || !widget.ready.value) return;
    _closing = true;
    Navigator.of(context).pop();
  }

  @override
  void dispose() {
    widget.ready.removeListener(_focusReturn);
    _returnFocus.dispose();
    WidgetsBinding.instance.removeObserver(this);
    _intro?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<bool>(
      valueListenable: widget.ready,
      builder: (_, ready, __) => PopScope(
          canPop: _canDismiss && ready,
          child: LauncherPadScope(
              menu: false,
              revealFocus: false,
              onCommand: (command) {
                if (command == '2' || command == '3') _close();
                return true;
              },
              child: Scaffold(
                  backgroundColor: Colors.transparent,
                  body: Stack(fit: StackFit.expand, children: [
                    ClipRect(
                        child: BackdropFilter(
                            key: const ValueKey('futuristic-launch-blur'),
                            filter: ui.ImageFilter.blur(sigmaX: 26, sigmaY: 26),
                            child: const ColoredBox(color: Color(0xAA060710)))),
                    SafeArea(child: LayoutBuilder(builder: (_, constraints) {
                      final side = math.min(constraints.maxWidth * .25,
                          constraints.maxHeight * .45);
                      return Center(
                          child: Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    RepaintBoundary(
                                        child: SizedBox(
                                            key: const ValueKey(
                                                'futuristic-launch-lottie'),
                                            width: side,
                                            height: side,
                                            child: Lottie.asset(
                                                'assets/Futurista/game_controller.json',
                                                backgroundLoading: true,
                                                controller: _controller,
                                                frameRate: FrameRate.max,
                                                fit: BoxFit.contain,
                                                onLoaded: (composition) {
                                              if (!mounted) return;
                                              _controller.duration =
                                                  composition.duration;
                                              _syncAnimation();
                                            }))),
                                    const SizedBox(height: 18),
                                    const Text('Iniciando seu jogo',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                            color: Color(0xFFA9EEE4),
                                            fontFamily: 'Oxanium',
                                            fontSize: 22,
                                            letterSpacing: 2)),
                                    const SizedBox(height: 12),
                                    Text(widget.name,
                                        textAlign: TextAlign.center,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontFamily: 'Oxanium',
                                            fontSize: 28,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 14),
                                    Text(
                                        ready
                                            ? 'Sua aventura está pronta.'
                                            : 'Preparando sua sessão…',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                            color: Color(0xFFC9B9FF),
                                            fontSize: 15)),
                                    const SizedBox(height: 24),
                                    FilledButton.icon(
                                        focusNode: _returnFocus,
                                        autofocus: true,
                                        onPressed: ready && _canDismiss
                                            ? _close
                                            : null,
                                        icon: const Icon(
                                            Icons.arrow_back_rounded),
                                        label:
                                            const Text('Voltar ao launcher')),
                                  ])));
                    })),
                  ])))));
}
