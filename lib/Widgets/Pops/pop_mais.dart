import 'package:flutter/material.dart';
import '../../Interface/futuristic_material.dart';
import '../../Interface/launcher_more_grid.dart';

class PopMais {
  static Future<String> mais(BuildContext context) async {
    final scene = await GlassScene.capture();
    if (!context.mounted) {
      scene?.dispose();
      return '';
    }
    try {
      final route = DialogRoute<String>(
          context: context,
          barrierColor: const Color(0x800B0915),
          builder: (_) => LauncherMoreGrid(scene: scene));
      final result =
          await Navigator.of(context, rootNavigator: true).push(route);
      // RawImage remains mounted during the route's exit animation.
      await route.completed;
      return result ?? '';
    } finally {
      scene?.dispose();
    }
  }
}
