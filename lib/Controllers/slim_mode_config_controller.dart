import 'dart:io';

import 'package:flutter/foundation.dart';

class SlimModeConfigController {
  const SlimModeConfigController();

  static const configPath = 'C:\\Users\\Public\\Documents\\v1_game_slim.txt';
  static const fileName = 'v1_slim.exe';
  static const folderName = 'v1_slim';

  Future<bool> readActive() async {
    final file = File(configPath);

    if (!await file.exists()) {
      await writeActive(true);
      return true;
    }

    final content = await file.readAsString();
    return !content.contains('ativo == 0');
  }

  Future<void> writeActive(bool active) async {
    final file = File(configPath);
    await file.parent.create(recursive: true);
    await file.writeAsString('ativo == ${active ? 1 : 0}');
  }

  Future<bool> openSlimApp() async {
    final executable = _findSlimApp();
    if (executable == null) {
      debugPrint('V1 SLIM nao encontrado em v1_slim\\v1_slim.exe');
      return false;
    }

    await Process.start(executable.path, const [], runInShell: true);
    return true;
  }

  Future<bool> closeMainAndOpenSlimIfActive() async {
    if (!await readActive()) {
      return false;
    }

    return openSlimAppAndClose();
  }

  Future<bool> openSlimAppAndClose() async {
    final opened = await openSlimApp();
    if (opened) {
      exit(0);
    }

    return opened;
  }

  File? _findSlimApp() {
    final checked = <String>{};
    final candidates = <Directory>[
      File(Platform.resolvedExecutable).parent,
      Directory.current,
    ];

    for (final start in candidates) {
      final candidate = File('${start.path}\\$folderName\\$fileName');
      if (checked.add(candidate.path) && candidate.existsSync()) {
        return candidate;
      }
    }

    return null;
  }
}
