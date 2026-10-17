import 'package:flutter/material.dart';
import '../../Interface/futuristic_material.dart';
import '../../Interface/launcher_more_grid.dart';

class PopMais {
  static Future<String> mais(BuildContext context,
      {bool futuristic = false}) async {
    final scene = futuristic ? await GlassScene.capture() : null;
    if (!context.mounted) {
      scene?.dispose();
      return '';
    }
    try {
      final route = DialogRoute<String>(
        context: context,
        barrierColor:
            futuristic ? const Color(0x800B0915) : Colors.black54,
        builder: (_) => LauncherMoreGrid(
          scene: scene,
          futuristic: futuristic,
        ),
      );
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
