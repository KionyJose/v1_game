import 'dart:io';

import 'package:flutter/foundation.dart';

class SlimModeConfigController {
  const SlimModeConfigController();

  static const configPath = 'C:\\Users\\Public\\Documents\\v1_game_slim.txt';
  static final active = ValueNotifier<bool>(false);

  Future<bool> readActive() async {
    final file = File(configPath);

    if (!await file.exists()) return false;

    final content = await file.readAsString();
    return content.trim() == 'ativo == 1';
  }

  Future<void> writeActive(bool enabled) async {
    final file = File(configPath);
    await file.parent.create(recursive: true);
    await file.writeAsString('ativo == ${enabled ? 1 : 0}', flush: true);
    active.value = enabled;
  }

  Future<void> load() async {
    try {
      active.value = await readActive();
    } catch (error) {
      debugPrint('Não foi possível carregar o modo Slim: $error');
      active.value = false;
    }
  }
}
