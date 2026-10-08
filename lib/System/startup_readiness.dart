import 'dart:convert';
import 'dart:io';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:path/path.dart' as p;
import 'app_storage.dart';

class StartupReadiness {
  const StartupReadiness({required this.storageReady, required this.issues});
  final bool storageReady;
  final List<String> issues;

  static Future<StartupReadiness> check() async {
    final issues = <String>[];
    var storageReady = false;
    try {
      await ensureWritableDirectory(AppStorage.root);
      for (final name in const [
        'testeDBLocal.txt',
        'v1_config.txt',
        'v1_game_config.json',
        'v1_game_slim.txt',
        'v1_media_cards.json',
      ]) {
        final file = AppStorage.dataFile(name);
        if (await file.exists()) {
          // Abrir para escrita testa também a ACL do arquivo já existente,
          // sem truncar nem modificar o conteúdo da biblioteca/configuração.
          final handle = await file.open(mode: FileMode.append);
          await handle.close();
        }
      }
      storageReady = true;
    } catch (error) {
      issues.add('Biblioteca e configurações: $error');
    }
    if (Platform.isWindows) {
      final executableDirectory = p.dirname(Platform.resolvedExecutable);
      if (!await File(p.join(executableDirectory, 'aria2c.exe')).exists()) {
        issues.add('O Release está sem aria2c.exe ao lado de v1_game.exe. '
            'Reinstale o pacote completo para habilitar os downloads.');
      }
      try {
        final version = await WebViewEnvironment.getAvailableVersion()
            .timeout(const Duration(seconds: 5));
        if (version == null || version.trim().isEmpty) {
          issues.add('Microsoft Edge WebView2 Runtime ausente. '
              'Execute Install-Prerequisites.ps1, na pasta prerequisites '
              'do aplicativo, para habilitar o navegador de downloads.');
        }
      } catch (error) {
        issues.add('Não foi possível verificar o WebView2 Runtime: $error. '
            'O restante do launcher pode continuar funcionando.');
      }
    }
    final report = StartupReadiness(storageReady: storageReady, issues: issues);
    if (storageReady) {
      try {
        await File(p.join(AppStorage.root.path, 'startup-check.json'))
            .writeAsString(
                const JsonEncoder.withIndent('  ').convert({
                  'checkedAt': DateTime.now().toIso8601String(),
                  'storageReady': storageReady,
                  'issues': issues,
                }),
                flush: true);
      } catch (_) {/* Um relatório opcional não impede abrir o launcher. */}
    }
    return report;
  }
}
