import 'dart:math' as math;
import 'package:flutter/material.dart';

/// O controller pertence à tela; desmontar a lista apenas desconecta o scroll.
class LauncherHorizontalList extends StatelessWidget {
  final ScrollController controller;
  final int itemCount;
  final double itemSize;
  final IndexedWidgetBuilder itemBuilder;
  final Color? background;
  const LauncherHorizontalList(
      {super.key,
      required this.controller,
      required this.itemCount,
      required this.itemSize,
      required this.itemBuilder,
      this.background});

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (_, constraints) {
        final padding = math.max(0.0, (constraints.maxWidth - itemSize) / 2);
        return ColoredBox(
          color: background ?? Colors.transparent,
          child: ListView.builder(
            controller: controller,
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: padding),
            itemCount: itemCount,
            itemBuilder: itemBuilder,
          ),
        );
      });
}
