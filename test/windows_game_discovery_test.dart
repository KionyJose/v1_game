import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:win32/win32.dart' as win;
import 'package:v1_game/System/windows_game_discovery.dart';

void main() {
  test('leitura nativa do atalho não executa seu programa nem argumentos',
      () async {
    final directory = await Directory.systemTemp.createTemp('v1-shortcut-');
    final marker = File(p.join(directory.path, 'executed.txt'));
    final shortcut = p.join(directory.path, "ExitLag teste ação ' &.lnk");
    final executable =
        p.join(Platform.environment['SystemRoot']!, 'System32', 'cmd.exe');
    final initialized =
        win.CoInitializeEx(nullptr, win.COINIT.COINIT_APARTMENTTHREADED);
    win.IShellLink? link;
    win.IPersistFile? persisted;
    final target = executable.toNativeUtf16();
    final arguments = '/c echo EXECUTED > "${marker.path}"'.toNativeUtf16();
    final filename = shortcut.toNativeUtf16();
    try {
      expect(win.FAILED(initialized) && initialized != win.RPC_E_CHANGED_MODE,
          isFalse);
      link = win.ShellLink.createInstance();
      expect(win.FAILED(link.setPath(target)), isFalse);
      expect(win.FAILED(link.setArguments(arguments)), isFalse);
      persisted = win.IPersistFile.from(link);
      expect(win.FAILED(persisted.save(filename, 1)), isFalse);
      final before = await File(shortcut).readAsBytes();
      for (var attempt = 0; attempt < 4; attempt++) {
        final found = await readWindowsShortcutTarget(shortcut);
        expect(p.windows.equals(found!, executable), isTrue);
      }
      expect(await marker.exists(), isFalse);
      expect(await File(shortcut).readAsBytes(), before);
      expect(
          await readWindowsShortcutTarget(
              p.join(directory.path, 'missing.lnk')),
          isNull);
    } finally {
      if (persisted != null) {
        persisted.detach();
        persisted.release();
        calloc.free(persisted.ptr);
      }
      if (link != null) {
        link.detach();
        link.release();
        calloc.free(link.ptr);
      }
      calloc.free(target);
      calloc.free(arguments);
      calloc.free(filename);
      if (!win.FAILED(initialized)) win.CoUninitialize();
      await directory.delete(recursive: true);
    }
  }, skip: !Platform.isWindows);

  test(
      'enumera programas locais preservando Unicode, tabulação e vírgula no caminho',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('v1-registry-scan-');
    final keyPath = 'SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall\\'
        'V1ScanTest-${p.basename(directory.path)}';
    final keyName = keyPath.toNativeUtf16();
    final key = calloc<IntPtr>();
    final installedName = "Teste V1 ação\t'$pid";
    final install = p.join(directory.path, 'Game, edição especial');
    final icon = '"${p.join(install, 'game.exe')}",-1';
    try {
      expect(
          win.RegCreateKeyEx(
              win.HKEY_CURRENT_USER,
              keyName,
              0,
              nullptr,
              0,
              win.REG_SAM_FLAGS.KEY_READ | win.REG_SAM_FLAGS.KEY_WRITE,
              nullptr,
              key,
              nullptr),
          0);
      void set(String name, String value) {
        final nativeName = name.toNativeUtf16();
        final nativeValue = value.toNativeUtf16();
        try {
          expect(
              win.RegSetValueEx(
                  key.value,
                  nativeName,
                  0,
                  win.REG_VALUE_TYPE.REG_SZ,
                  nativeValue.cast(),
                  (value.length + 1) * 2),
              0);
        } finally {
          calloc.free(nativeName);
          calloc.free(nativeValue);
        }
      }

      set('DisplayName', installedName);
      set('InstallLocation', install);
      set('DisplayIcon', icon);
      final programs = await readWindowsInstalledPrograms();
      final matches =
          programs.where((entry) => entry.name == installedName).toList();
      expect(matches, isNotEmpty);
      for (final entry in matches) {
        expect(entry.installDirectory, install);
        expect(entry.icon, icon);
      }
    } finally {
      if (key.value != 0) {
        win.RegCloseKey(key.value);
        expect(win.RegDeleteKey(win.HKEY_CURRENT_USER, keyName), 0);
      }
      calloc.free(key);
      calloc.free(keyName);
      await directory.delete(recursive: true);
    }
  }, skip: !Platform.isWindows);
}
