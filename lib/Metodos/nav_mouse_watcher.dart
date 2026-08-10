import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;

class NavMouseWatcher {
  static const String _stateFileName = 'nav_flutuante_mouse_state.json';
  static bool isNavMouseActive = false;
  static Timer? _timer;
  static File? _stateFile;

  static void start() {
    final tempDir = Directory.systemTemp.path;
    final filePath = path.join(tempDir, _stateFileName);
    _stateFile = File(filePath);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      await _checkState();
    });
    
    debugPrint('📡 [NAV_WATCHER] Iniciado: buscando em $filePath');
  }

  static Future<void> _checkState() async {
    try {
      if (await _stateFile!.exists()) {
        final content = await _stateFile!.readAsString();
        final data = jsonDecode(content);
        final bool newValue = data['isMouseMode'] ?? false;
        
        if (isNavMouseActive != newValue) {
          isNavMouseActive = newValue;
          debugPrint('📡 [NAV_WATCHER] Mudança detectada: isNavMouseActive = $isNavMouseActive');
        }
      }
    } catch (e) {
      // Silencioso para não poluir o log se houver erro de leitura concorrente
    }
  }

  static Future<bool> refresh() async {
    await _checkState();
    return isNavMouseActive;
  }

  static void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
