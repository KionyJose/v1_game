import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../Class/Paad.dart';
import 'launcher_menu.dart';
import 'pad_direction_intent.dart';
import 'pad_scroll_target.dart';

/// Adaptador do Paad existente para foco e Actions do Flutter.
class LauncherPadScope extends StatefulWidget {
  final Widget child;
  final bool enabled;
  final bool menu;
  final bool revealInitialFocus;
  final bool revealFocus;
  final bool Function(String)? onCommand;
  const LauncherPadScope(
      {super.key,
      required this.child,
      this.enabled = true,
      this.menu = true,
      this.revealInitialFocus = true,
      this.revealFocus = true,
      this.onCommand});
  @override
  State<LauncherPadScope> createState() => _LauncherPadScopeState();
}

class _LauncherPadScopeState extends State<LauncherPadScope> {
  Paad? _pad;
  void Function()? _detach;
  bool _menuOpen = false;
  final _focusRoot = FocusNode(skipTraversal: true, canRequestFocus: false);
  Timer? _scrollTimer;
  int _focusRevision = 0;
  bool _receivedContentFocus = false;

  @override
  void initState() {
    super.initState();
    FocusManager.instance.addListener(_revealFocus);
  }

  void _revealFocus() {
    if (!widget.revealFocus) return;
    _scrollTimer?.cancel();
    final revision = ++_focusRevision;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_focusRoot.hasFocus || revision != _focusRevision) {
        return;
      }
      final target = FocusManager.instance.primaryFocus?.context;
      if (target != null) {
        if (!_receivedContentFocus) {
          _receivedContentFocus = true;
          if (!widget.revealInitialFocus) return;
        }
        final section =
            target.getElementForInheritedWidgetOfExactType<PadScrollTarget>();
        void reveal() {
          if (!mounted ||
              !_focusRoot.hasFocus ||
              FocusManager.instance.primaryFocus?.context != target) {
            return;
          }
          Scrollable.ensureVisible(section ?? target,
              alignment: 0.35,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic);
        }

        final delay =
            (section?.widget as PadScrollTarget?)?.settleDelay ?? Duration.zero;
        if (delay == Duration.zero) {
          reveal();
        } else {
          _scrollTimer = Timer(delay, reveal);
        }
      }
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final pad = Provider.of<Paad?>(context, listen: false);
    if (!identical(_pad, pad) || _detach == null) {
      _detach?.call();
      _pad = pad;
      if (widget.enabled) _detach = pad?.interfaceRouter.attach(_command);
    }
  }

  @override
  void didUpdateWidget(LauncherPadScope oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.enabled != widget.enabled) {
      _detach?.call();
      _detach = widget.enabled ? _pad?.interfaceRouter.attach(_command) : null;
    }
  }

  @override
  void dispose() {
    _detach?.call();
    FocusManager.instance.removeListener(_revealFocus);
    _scrollTimer?.cancel();
    _focusRoot.dispose();
    super.dispose();
  }

  void _command(String command) {
    if (!mounted || !widget.enabled || (widget.onCommand?.call(command) ?? false)) return;
    if (command == 'START') {
      if (!widget.menu) {
        Navigator.of(context).maybePop();
      } else if (!_menuOpen) {
        _menuOpen = true;
        mostrarMenuLauncher(context).whenComplete(() => _menuOpen = false);
      }
      return;
    }
    if (command == '3') {
      Navigator.of(context).maybePop();
      return;
    }
    final focus = FocusManager.instance.primaryFocus;
    final focusContext = focus?.context;
    if (focusContext == null) return;
    if (command == '2') {
      Actions.maybeInvoke(focusContext, const ActivateIntent());
      return;
    }
    final direction = const {
      'CIMA': TraversalDirection.up,
      'BAIXO': TraversalDirection.down,
      'ESQUERDA': TraversalDirection.left,
      'DIREITA': TraversalDirection.right,
    }[command];
    if (direction != null) {
      final intent = PadDirectionIntent(direction);
      final action = Actions.maybeFind<PadDirectionIntent>(focusContext);
      if (action == null || Actions.invoke(focusContext, intent) != true) {
        FocusScope.of(focusContext).focusInDirection(direction);
      }
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
        data: ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          scaffoldBackgroundColor: Colors.black,
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFFB6A8FF),
            onPrimary: Colors.black,
            secondary: Color(0xFFB6A8FF),
            surface: Color(0xFF111111),
            surfaceContainerLowest: Colors.black,
            surfaceContainerLow: Color(0xFF111111),
            surfaceContainer: Color(0xFF171717),
            surfaceContainerHigh: Color(0xFF202020),
            surfaceContainerHighest: Color(0xFF282828),
            onSurface: Colors.white,
            outline: Color(0xFF444444),
          ),
          dialogTheme:
              const DialogThemeData(backgroundColor: Color(0xFF151515)),
          cardTheme:
              const CardThemeData(color: Color(0xFF141414), elevation: 0),
          inputDecorationTheme: const InputDecorationTheme(
              filled: true, fillColor: Color(0xFF141414)),
          filledButtonTheme: FilledButtonThemeData(
              style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
            side: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.focused)
                    ? const BorderSide(color: Colors.white, width: 3)
                    : BorderSide.none),
          )),
          outlinedButtonTheme: OutlinedButtonThemeData(
              style: ButtonStyle(
            minimumSize: const WidgetStatePropertyAll(Size(48, 48)),
            backgroundColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.focused)
                    ? const Color(0xFF343039)
                    : Colors.transparent),
            side: WidgetStateProperty.resolveWith((states) => BorderSide(
                color: states.contains(WidgetState.focused)
                    ? Colors.white
                    : const Color(0xFF444444),
                width: states.contains(WidgetState.focused) ? 3 : 1)),
          )),
          textButtonTheme: TextButtonThemeData(
              style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.focused)
                    ? const Color(0xFF343039)
                    : Colors.transparent),
          )),
          iconButtonTheme: IconButtonThemeData(
              style: ButtonStyle(
            backgroundColor: WidgetStateProperty.resolveWith((states) =>
                states.contains(WidgetState.focused)
                    ? const Color(0xFF343039)
                    : Colors.transparent),
          )),
        ),
        child: Focus(
            focusNode: _focusRoot,
            canRequestFocus: false,
            skipTraversal: true,
            onKeyEvent: (_, event) {
              if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
                return KeyEventResult.ignored;
              }
              final direction = {
                LogicalKeyboardKey.arrowUp: 'CIMA',
                LogicalKeyboardKey.arrowDown: 'BAIXO',
                LogicalKeyboardKey.arrowLeft: 'ESQUERDA',
                LogicalKeyboardKey.arrowRight: 'DIREITA',
              }[event.logicalKey];
              if (direction != null) {
                _command(direction);
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.gameButtonStart ||
                  event.logicalKey == LogicalKeyboardKey.f10) {
                _command('START');
                return KeyEventResult.handled;
              }
              if (event.logicalKey == LogicalKeyboardKey.escape ||
                  event.logicalKey == LogicalKeyboardKey.gameButtonB) {
                _command('3');
                return KeyEventResult.handled;
              }
              return KeyEventResult.ignored;
            },
            child: widget.child),
      );
}
