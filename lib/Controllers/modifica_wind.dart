import 'dart:io';
import 'package:flutter/material.dart';
import '../Global.dart';
import 'package:path/path.dart' as p;

class ModificaWind {
  /// Executa script para desabilitar Xbox Game Bar e Steam ao iniciar o sistema
  static Future<void> desabilitarXboxESteam() async {
    if (!Platform.isWindows) return;
    final scriptPath = p.join(assetsPath, 'Scripts', 'disable_xbox_steam.ps1');
    if (!await File(scriptPath).exists()) {
      debugPrint('Script de configuração do Guide ausente: $scriptPath');
      return;
    }
    try {
      final result = await Process.run('powershell', [
        '-NoProfile',
        '-NonInteractive',
        '-ExecutionPolicy',
        'Bypass',
        '-File',
        scriptPath
      ]);
      if (result.exitCode != 0) {
        debugPrint('Windows não permitiu configurar o Guide: ${result.stderr}');
      }
    } catch (e) {
      // Trate o erro conforme necessário
      debugPrint('Erro ao executar script: $e');
    }
  }
}
