import 'package:flutter/material.dart';

/// Mantém a seção visível, em vez de revelar apenas um botão dentro dela.
class PadScrollTarget extends InheritedWidget {
  final Duration settleDelay;
  const PadScrollTarget(
      {super.key, required super.child, this.settleDelay = Duration.zero});

  @override
  bool updateShouldNotify(PadScrollTarget oldWidget) => false;
}
