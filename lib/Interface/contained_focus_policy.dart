import 'package:flutter/material.dart';

/// Revela o item dentro da sua lista sem deslocar a página da aba.
class ContainedFocusPolicy extends ReadingOrderTraversalPolicy {
  ContainedFocusPolicy() : super(requestFocusCallback: _requestFocus);

  static void _requestFocus(
    FocusNode node, {
    ScrollPositionAlignmentPolicy? alignmentPolicy,
    double? alignment,
    Duration? duration,
    Curve? curve,
  }) {
    node.requestFocus();
    final context = node.context;
    if (context == null || !context.mounted) return;
    final scrollable = Scrollable.maybeOf(context);
    final target = context.findRenderObject();
    if (scrollable == null ||
        target == null ||
        !target.attached ||
        scrollable.position is PageMetrics) {
      return;
    }
    scrollable.position.ensureVisible(
      target,
      alignment: alignment ?? 1,
      alignmentPolicy:
          alignmentPolicy ?? ScrollPositionAlignmentPolicy.explicit,
      duration: duration ?? const Duration(milliseconds: 400),
      curve: curve ?? Curves.decelerate,
    );
  }
}
