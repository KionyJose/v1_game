import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as path;
import 'package:v1_game/Modelos/JogoBuscado.dart';

class GameEntry {
  final String name;
  final String exePath;
  final String installDir;
  final String platform;
  final String? thumbnailPath;
  final int priority;

  GameEntry({required this.name, required this.exePath, required this.installDir, required this.platform, this.thumbnailPath, this.priority = 100});
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
    'Microsoft Store': [
      r'C:\Program Files\WindowsApps',
      // Atalhos e dados de apps UWP (atalhos .lnk e executáveis podem estar em subpastas)
      r'C:\Users', // Será filtrado para buscar por AppData\Local\Packages
    ],
    'Outros': [
      r'C:\Games',
      r'D:\Games',
      r'C:\Jogos',
      r'D:\Jogos',
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
    platformsFound = [
      if (set.contains('Outros')) 'Outros',
      ...defaultRoots.keys.where((k) => k != 'Outros' && set.contains(k)),
    ];
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
    debugPrint('[GAMES_BUSCA] Iniciando busca de jogos...');

    // 1. Buscar atalhos e executáveis na área de trabalho de todos os usuários
    try {
      final usersDir = Directory(r'C:\Users');
      if (await usersDir.exists()) {
        await for (final user in usersDir.list(followLinks: false)) {
          if (user is Directory) {
            final desktopPath = path.join(user.path, 'Desktop');
            final desktopDir = Directory(desktopPath);
            if (await desktopDir.exists()) {
              await for (final f in desktopDir.list(followLinks: false)) {
                if (f is File) {
                  final ext = path.extension(f.path).toLowerCase();
                  if (ext.isNotEmpty) {
                    final gameName = path.basenameWithoutExtension(f.path);
                    final exePath = ext == '.lnk' ? await _resolverAtalho(f.path) ?? f.path : f.path;
                    if (!_jaExiste(found, gameName, exePath)) {
                      found.add(GameEntry(
                        name: gameName,
                        exePath: exePath,
                        installDir: desktopDir.path,
                        platform: 'Outros',
                        thumbnailPath: null,
                        priority: 0,
                      ));
                    }
                  }
                }
              }
            }
          }
        }
      }
    } catch (_) {}

    await _buscarSteamPorManifests(found, limit);
    await _buscarEpicPorManifests(found, limit);
    await _buscarGogPorManifests(found, limit);
    await _buscarProgramasRecursos(found, limit);
    debugPrint('[GAMES_BUSCA] Apos manifests/programas: ${found.length}');

    // 2. Buscar jogos do Game Pass/Microsoft Store
    // 2.1 Vasculhar C:\Program Files\WindowsApps (pode exigir permissões)
    try {
      final winAppsDir = Directory(r'C:\Program Files\WindowsApps');
      if (await winAppsDir.exists()) {
        await for (final appDir in winAppsDir.list(followLinks: false)) {
          if (appDir is Directory) {
            final List<FileSystemEntity> exeFiles = [];
            await for (final f in appDir.list(recursive: true)) {
              if (f is File && f.path.toLowerCase().endsWith('.exe')) exeFiles.add(f);
            }
            if (exeFiles.isNotEmpty) {
              final mainExe = exeFiles.first as File;
              final gameName = path.basename(appDir.path);
              if (!_jaExiste(found, gameName, mainExe.path)) {
                found.add(GameEntry(
                  name: gameName,
                  exePath: mainExe.path,
                  installDir: appDir.path,
                  platform: 'Microsoft Store',
                  thumbnailPath: null,
                ));
              }
            }
          }
          if (found.length >= limit) break;
        }
      }
    } catch (_) {}

    // 2.2 Vasculhar C:\Users\<User>\AppData\Local\Packages
    try {
      final usersDir = Directory(r'C:\Users');
      if (await usersDir.exists()) {
        await for (final user in usersDir.list(followLinks: false)) {
          if (user is Directory) {
            final packagesPath = path.join(user.path, 'AppData', 'Local', 'Packages');
            final packagesDir = Directory(packagesPath);
            if (await packagesDir.exists()) {
              await for (final pkg in packagesDir.list(followLinks: false)) {
                if (pkg is Directory) {
                  final List<FileSystemEntity> exeFiles = [];
                  await for (final f in pkg.list(recursive: true)) {
                    if (f is File && f.path.toLowerCase().endsWith('.exe')) exeFiles.add(f);
                  }
                  if (exeFiles.isNotEmpty) {
                    final mainExe = exeFiles.first as File;
                    final gameName = path.basename(pkg.path);
                    if (!_jaExiste(found, gameName, mainExe.path)) {
                      found.add(GameEntry(
                        name: gameName,
                        exePath: mainExe.path,
                        installDir: pkg.path,
                        platform: 'Microsoft Store',
                        thumbnailPath: null,
                      ));
                    }
                  }
                }
                if (found.length >= limit) break;
              }
            }
          }
          if (found.length >= limit) break;
        }
      }
    } catch (_) {}

    // 3. Busca padrão dos roots já existentes
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
                final mainExe = await _melhorExecutavel(ent.path, exeFiles);
                if (mainExe != null) {
                  final gameName = path.basename(ent.path);
                  if (!_jaExiste(found, gameName, mainExe.path)) {
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

    found.sort((a, b) {
      final priority = a.priority.compareTo(b.priority);
      if (priority != 0) return priority;
      final platform = _platformPriority(a.platform).compareTo(_platformPriority(b.platform));
      if (platform != 0) return platform;
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });
    allGames = found;
    _applyFilter();

    loading = false;
    debugPrint('[GAMES_BUSCA] Busca finalizada: ${found.length} itens');
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

  int _platformPriority(String platform) {
    const order = ['Outros', 'Steam', 'Epic Games', 'GOG', 'EA', 'Microsoft Store', 'Ubisoft'];
    final i = order.indexOf(platform);
    return i < 0 ? 99 : i;
  }

  bool _jaExiste(List<GameEntry> found, String name, String exePath) {
    final nome = name.toLowerCase();
    final exe = exePath.toLowerCase();
    return found.any((e) => e.exePath.toLowerCase() == exe || e.name.toLowerCase() == nome);
  }

  Future<String?> _resolverAtalho(String lnkPath) async {
    try {
      const script = r'$s=(New-Object -ComObject WScript.Shell).CreateShortcut($args[0]); if($s.TargetPath){$s.TargetPath}else{$args[0]}';
      final result = await Process.run('powershell', ['-NoProfile', '-Command', script, lnkPath]);
      final out = result.stdout.toString().trim();
      if (result.exitCode == 0 && out.isNotEmpty && await File(out).exists()) return out;
    } catch (_) {}
    return null;
  }

  Future<void> _buscarSteamPorManifests(List<GameEntry> found, int limit) async {
    final steamRoots = <String>{};
    for (final root in [r'C:\Program Files (x86)\Steam', r'C:\Program Files\Steam', r'D:\SteamLibrary', r'E:\SteamLibrary']) {
      if (await Directory(root).exists()) steamRoots.add(root);
    }

    for (final root in List<String>.from(steamRoots)) {
      final libraryFile = File(path.join(root, 'steamapps', 'libraryfolders.vdf'));
      if (!await libraryFile.exists()) continue;
      final content = await libraryFile.readAsString();
      for (final match in RegExp(r'"path"\s+"([^"]+)"').allMatches(content)) {
        steamRoots.add(match.group(1)!.replaceAll(r'\\', r'\'));
      }
    }

    for (final root in steamRoots) {
      final steamApps = Directory(path.join(root, 'steamapps'));
      if (!await steamApps.exists()) continue;
      await for (final manifest in steamApps.list(followLinks: false)) {
        if (manifest is! File || !path.basename(manifest.path).startsWith('appmanifest_')) continue;
        final content = await manifest.readAsString();
        final name = RegExp(r'"name"\s+"([^"]+)"').firstMatch(content)?.group(1);
        final installDir = RegExp(r'"installdir"\s+"([^"]+)"').firstMatch(content)?.group(1);
        if (name == null || installDir == null) continue;
        final dir = path.join(steamApps.path, 'common', installDir);
        final exe = await _encontrarExecutavel(dir);
        if (exe != null && !_jaExiste(found, name, exe)) {
          found.add(GameEntry(name: name, exePath: exe, installDir: dir, platform: 'Steam', thumbnailPath: await _findThumbnail(dir)));
        }
        if (found.length >= limit) return;
      }
    }
  }

  Future<void> _buscarEpicPorManifests(List<GameEntry> found, int limit) async {
    final dir = Directory(r'C:\ProgramData\Epic\EpicGamesLauncher\Data\Manifests');
    if (!await dir.exists()) return;
    await for (final file in dir.list(followLinks: false)) {
      if (file is! File || path.extension(file.path).toLowerCase() != '.item') continue;
      try {
        final content = await file.readAsString();
        final name = RegExp(r'"DisplayName"\s*:\s*"([^"]+)"').firstMatch(content)?.group(1);
        final install = RegExp(r'"InstallLocation"\s*:\s*"([^"]+)"').firstMatch(content)?.group(1)?.replaceAll(r'\\', r'\');
        if (name == null || install == null) continue;
        final exe = await _encontrarExecutavel(install);
        if (exe != null && !_jaExiste(found, name, exe)) {
          found.add(GameEntry(name: name, exePath: exe, installDir: install, platform: 'Epic Games', thumbnailPath: await _findThumbnail(install)));
        }
      } catch (_) {}
      if (found.length >= limit) return;
    }
  }

  Future<void> _buscarGogPorManifests(List<GameEntry> found, int limit) async {
    for (final root in [r'C:\Program Files (x86)\GOG Galaxy\Games', r'C:\Program Files\GOG Galaxy\Games', r'D:\GOG Games']) {
      final dir = Directory(root);
      if (!await dir.exists()) continue;
      await for (final ent in dir.list(followLinks: false)) {
        if (ent is! Directory) continue;
        final exe = await _encontrarExecutavel(ent.path);
        final name = path.basename(ent.path);
        if (exe != null && !_jaExiste(found, name, exe)) {
          found.add(GameEntry(name: name, exePath: exe, installDir: ent.path, platform: 'GOG', thumbnailPath: await _findThumbnail(ent.path)));
        }
        if (found.length >= limit) return;
      }
    }
  }

  Future<void> _buscarProgramasRecursos(List<GameEntry> found, int limit) async {
    const script = r'''
$keys = @(
 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*',
 'HKLM:\SOFTWARE\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
 'HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall\*'
)
foreach($k in $keys){
  Get-ItemProperty $k -ErrorAction SilentlyContinue |
    Where-Object { $_.DisplayName -and ($_.InstallLocation -or $_.DisplayIcon) } |
    ForEach-Object {
      $name=$_.DisplayName
      $loc=$_.InstallLocation
      $icon=$_.DisplayIcon
      "$name`t$loc`t$icon"
    }
}
''';
    try {
      final result = await Process.run('powershell', ['-NoProfile', '-Command', script]);
      if (result.exitCode != 0) return;
      final linhas = result.stdout.toString().split(RegExp(r'\r?\n'));
      for (final linha in linhas) {
        if (linha.trim().isEmpty) continue;
        final partes = linha.split('\t');
        if (partes.isEmpty) continue;
        final name = partes[0].trim();
        final install = partes.length > 1 ? partes[1].trim() : '';
        final icon = partes.length > 2 ? partes[2].trim().replaceAll('"', '').split(',').first : '';
        final exe = await _resolverExePrograma(install, icon);
        if (name.isNotEmpty && exe != null && !_jaExiste(found, name, exe)) {
          found.add(GameEntry(name: name, exePath: exe, installDir: install.isNotEmpty ? install : File(exe).parent.path, platform: 'Outros', thumbnailPath: null, priority: 20));
        }
        if (found.length >= limit) return;
      }
    } catch (e) {
      debugPrint('[GAMES_BUSCA] Erro Programas e Recursos: $e');
    }
  }

  Future<String?> _resolverExePrograma(String install, String icon) async {
    if (icon.toLowerCase().endsWith('.exe') && await File(icon).exists()) return icon;
    if (install.isNotEmpty) return _encontrarExecutavel(install);
    return null;
  }

  Future<String?> _encontrarExecutavel(String dirPath) async {
    try {
      final dir = Directory(dirPath);
      if (!await dir.exists()) return null;
      final exeFiles = <FileSystemEntity>[];
      await for (final f in dir.list(recursive: true, followLinks: false)) {
        if (f is File && path.extension(f.path).toLowerCase() == '.exe') exeFiles.add(f);
      }
      return (await _melhorExecutavel(dirPath, exeFiles))?.path;
    } catch (_) {}
    return null;
  }

  Future<File?> _melhorExecutavel(String dirPath, List<FileSystemEntity> exeFiles) async {
    final candidatos = exeFiles.whereType<File>().where((f) => !_ehExecutavelSistema(path.basename(f.path).toLowerCase())).toList();
    if (candidatos.isEmpty) return null;
    final dirName = path.basename(dirPath).toLowerCase();
    candidatos.sort((a, b) {
      int score(File f) {
        final name = path.basenameWithoutExtension(f.path).toLowerCase();
        if (name == dirName) return 0;
        if (name.contains(dirName) || dirName.contains(name)) return 1;
        if (f.path.toLowerCase().contains('${Platform.pathSeparator}binaries${Platform.pathSeparator}')) return 2;
        return 3;
      }
      return score(a).compareTo(score(b));
    });
    return candidatos.first;
  }

  bool _ehExecutavelSistema(String nomeExecutavel) {
    final nome = nomeExecutavel.toLowerCase();
    return ['unins', 'uninst', 'uninstall', 'setup', 'install', 'update', 'updater', 'patch', 'crash', 'redist', 'vcredist', 'directx', 'easyanticheat', 'battleye'].any(nome.contains);
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
    const cross = 6; // grid columns
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

  /// Handler when the user selects a game; returns a `JogoBuscado` model via Navigator.
  void pickGame(BuildContext context, GameEntry game) {
    final j = JogoBuscado(
      name: game.name,
      exePath: game.exePath,
      installDir: game.installDir,
      platform: game.platform,
      thumbnailPath: game.thumbnailPath,
    );
    Navigator.of(context).pop(j);
  }
}
