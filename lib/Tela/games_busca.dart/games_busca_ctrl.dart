import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;

class GameEntry {
  final String name;
  final String exePath;
  final String installDir;
  final String platform;
  final String? thumbnailPath;

  GameEntry({required this.name, required this.exePath, required this.installDir, required this.platform, this.thumbnailPath});
}

class GamesBuscaCtrl with ChangeNotifier {
  String query = '';
  bool loading = false;
  List<GameEntry> allGames = [];
  List<GameEntry> filtered = [];
  // Input debounce (milliseconds) to avoid double clicks — reduzido para 1/3 do valor anterior
  int inputDelayMs = 83;
  int _lastInputAt = 0;

  // Default roots per platform (configurável)
  final Map<String, List<String>> defaultRoots = {
    'Steam': [
      r'C:\Program Files (x86)\Steam\steamapps\common',
      r'C:\Program Files\Steam\steamapps\common',
      r'D:\SteamLibrary\steamapps\common',
      r'E:\SteamLibrary\steamapps\common',
    ],
    'Epic Games': [
      r'C:\Program Files\Epic Games',
      r'C:\Program Files (x86)\Epic Games',
      r'D:\Epic Games',
    ],
    'GOG': [
      r'C:\Program Files (x86)\GOG Galaxy\Games',
      r'D:\GOG Games',
    ],
    'Ubisoft': [
      r'C:\Program Files (x86)\Ubisoft\Ubisoft Game Launcher\games',
      r'C:\Program Files\Ubisoft\Ubisoft Game Launcher\games',
      r'D:\Ubisoft\Games',
    ],
    'EA': [
      r'C:\Program Files\EA Games',
      r'C:\Program Files (x86)\Origin Games',
    ],
    'Outros': [
      r'C:\Games',
      r'D:\Games',
      r'C:\Program Files',
      r'C:\Program Files (x86)',
    ],
  };

  // Platforms found with results (order maintained)
  List<String> platformsFound = [];
  int selectedPlatformIndex = 0;

  // Focused index per platform for pad navigation
  final Map<String, int> focusedIndex = {};

  void setQuery(String q) {
    query = q;
    _applyFilter();
  }

  void clear() {
    query = '';
    _applyFilter();
  }

  void _applyFilter() {
    if (query.isEmpty) {
      filtered = List.from(allGames);
    } else {
      filtered = allGames
          .where((g) => g.name.toLowerCase().contains(query.toLowerCase()))
          .toList();
    }
    _rebuildPlatformsFound();
    notifyListeners();
  }

  void _rebuildPlatformsFound() {
    final set = <String>{};
    for (final g in filtered) {
      set.add(g.platform);
    }
    // keep order of defaultRoots keys but only those present
    platformsFound = defaultRoots.keys.where((k) => set.contains(k)).toList();
    if (platformsFound.isEmpty) platformsFound = ['Todos'];
    if (selectedPlatformIndex >= platformsFound.length) selectedPlatformIndex = 0;
    for (final p in platformsFound) {
      focusedIndex.putIfAbsent(p, () => 0);
    }
  }

  List<GameEntry> get currentList {
    final platform = platformsFound.isNotEmpty ? platformsFound[selectedPlatformIndex] : 'Todos';
    if (platform == 'Todos') return filtered;
    return filtered.where((g) => g.platform == platform).toList();
  }

  String get selectedPlatform => platformsFound.isNotEmpty ? platformsFound[selectedPlatformIndex] : 'Todos';

  void startScan() {
    // Exposed method to start scanning using internal defaultRoots
    scanAll();
  }

  Future<void> scanAll({int limit = 500}) async {
    loading = true;
    allGames.clear();
    filtered.clear();
    platformsFound.clear();
    selectedPlatformIndex = 0;
    notifyListeners();

    final List<GameEntry> found = [];

    for (final entry in defaultRoots.entries) {
      final platform = entry.key;
      for (final root in entry.value) {
        try {
          final dir = Directory(root);
          if (!await dir.exists()) continue;
          await for (final ent in dir.list(followLinks: false)) {
            if (ent is Directory) {
              try {
                final List<FileSystemEntity> exeFiles = [];
                await for (final f in ent.list(recursive: false)) {
                  if (f is File && f.path.toLowerCase().endsWith('.exe')) exeFiles.add(f);
                }
                if (exeFiles.isNotEmpty) {
                  final mainExe = exeFiles.first as File;
                  final gameName = path.basename(ent.path);
                  if (!found.any((e) => e.name.toLowerCase() == gameName.toLowerCase())) {
                    final thumb = await _findThumbnail(ent.path);
                    found.add(GameEntry(
                      name: gameName,
                      exePath: mainExe.path,
                      installDir: ent.path,
                      platform: platform,
                      thumbnailPath: thumb,
                    ));
                  }
                }
              } catch (_) {}
            }
            if (found.length >= limit) break;
          }
        } catch (_) {}
        if (found.length >= limit) break;
      }
      if (found.length >= limit) break;
    }

    found.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    allGames = found;
    _applyFilter();

    loading = false;
    notifyListeners();
  }

  Future<String?> _findThumbnail(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return null;
      final candidates = [
        'icon.png', 'icon.jpg', 'icon.jpeg', 'logo.png', 'logo.jpg', 'cover.png', 'cover.jpg', 'banner.jpg', 'boxart.png', 'boxart.jpg'
      ];
      await for (final f in dir.list(recursive: false)) {
        if (f is File) {
          final name = path.basename(f.path).toLowerCase();
          if (candidates.contains(name)) return f.path;
        }
      }
      // fallback: first image file found
      await for (final f in dir.list(recursive: false)) {
        if (f is File) {
          final ext = path.extension(f.path).toLowerCase();
          if (['.png', '.jpg', '.jpeg', '.webp', '.bmp', '.ico'].contains(ext)) return f.path;
        }
      }
    } catch (_) {}
    return null;
  }

  void setPlatformByIndex(int i) {
    if (platformsFound.isEmpty) return;
    if (i < 0) {
      selectedPlatformIndex = 0;
    } else if (i >= platformsFound.length) {
      selectedPlatformIndex = platformsFound.length - 1;
    } else {
      selectedPlatformIndex = i;
    }
    notifyListeners();
  }

  void nextPlatform() {
    if (platformsFound.isEmpty) return;
    selectedPlatformIndex = (selectedPlatformIndex + 1) % platformsFound.length;
    notifyListeners();
  }

  void prevPlatform() {
    if (platformsFound.isEmpty) return;
    selectedPlatformIndex = (selectedPlatformIndex - 1) < 0 ? platformsFound.length - 1 : selectedPlatformIndex - 1;
    notifyListeners();
  }

  int focusedForCurrent() {
    final p = selectedPlatform;
    return focusedIndex[p] ?? 0;
  }

  void _setFocusedForCurrent(int v) {
    final p = selectedPlatform;
    focusedIndex[p] = v;
    notifyListeners();
  }

  void moveFocus(String dir) {
    final list = currentList;
    if (list.isEmpty) return;
    const cross = 4; // grid columns
    int idx = focusedForCurrent();
    if (dir == 'ESQUERDA') idx = (idx - 1) < 0 ? 0 : idx - 1;
    if (dir == 'DIREITA') idx = (idx + 1) >= list.length ? list.length - 1 : idx + 1;
    if (dir == 'CIMA') idx = (idx - cross) < 0 ? 0 : idx - cross;
    if (dir == 'BAIXO') idx = (idx + cross) >= list.length ? list.length - 1 : idx + cross;
    _setFocusedForCurrent(idx);
  }

  /// Handle pad input events (called by UI Consumer/escuta)
  void handlePad(String? event, BuildContext context) {
    if (event == null || event.isEmpty) return;
    final now = DateTime.now().millisecondsSinceEpoch;
    if (now - _lastInputAt < inputDelayMs) return;
    _lastInputAt = now;
    if (event == 'RB') {
      nextPlatform();
      return;
    }
    if (event == 'LB') {
      prevPlatform();
      return;
    }
    if (event == 'CIMA' || event == 'BAIXO' || event == 'ESQUERDA' || event == 'DIREITA') {
      moveFocus(event);
      return;
    }
    if (event == '2' || event == 'SELECT') {
      // pick focused
      final list = currentList;
      if (list.isEmpty) return;
      final idx = focusedForCurrent();
      if (idx >= 0 && idx < list.length) pickGame(context, list[idx]);
      return;
    }
    if (event == '3' || event == 'START') {
      Navigator.of(context).pop('cancelar');
      return;
    }
  }

  /// Handler when the user selects a game; returns the exePath string via Navigator in UI.
  void pickGame(BuildContext context, GameEntry game) {
    Navigator.of(context).pop(game.exePath);
  }
}
