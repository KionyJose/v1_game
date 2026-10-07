import 'package:flutter/material.dart';

/// Mantém a seção visível, em vez de revelar apenas um botão dentro dela.
class PadScrollTarget extends InheritedWidget {
  final Duration settleDelay;

  /// Reveals the beginning of the scroll view for top-level hero actions.
  final bool scrollToStart;
  const PadScrollTarget(
      {super.key,
      required super.child,
      this.settleDelay = Duration.zero,
      this.scrollToStart = false});

  @override
  bool updateShouldNotify(PadScrollTarget oldWidget) => false;
}
