import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart' as win;

class WindowsInstalledProgram {
  const WindowsInstalledProgram(this.name, this.installDirectory, this.icon);
  final String name;
  final String installDirectory;
  final String icon;
}

String expandWindowsEnvironment(String value) =>
    value.replaceAllMapped(RegExp(r'%([^%]+)%'), (match) {
      for (final entry in Platform.environment.entries) {
        if (entry.key.toLowerCase() == match[1]!.toLowerCase()) {
          return entry.value;
        }
      }
      return match[0]!;
    });

/// Leitura local: não abre shells, instaladores, jogos ou ferramentas de rede.
Future<List<WindowsInstalledProgram>> readWindowsInstalledPrograms() async {
  if (!Platform.isWindows) return [];
  return Isolate.run(_readInstalledPrograms);
}

List<WindowsInstalledProgram> _readInstalledPrograms() {
  final result = <WindowsInstalledProgram>[];
  const uninstall = r'SOFTWARE\Microsoft\Windows\CurrentVersion\Uninstall';
  for (final hive in [win.HKEY_LOCAL_MACHINE, win.HKEY_CURRENT_USER]) {
    for (final view in [
      win.REG_SAM_FLAGS.KEY_WOW64_64KEY,
      win.REG_SAM_FLAGS.KEY_WOW64_32KEY
    ]) {
      final key = calloc<IntPtr>();
      final keyPath = uninstall.toNativeUtf16();
      final nameBuffer = calloc<Uint16>(256).cast<Utf16>();
      final nameLength = calloc<Uint32>();
      try {
        if (win.RegOpenKeyEx(
                hive, keyPath, 0, win.REG_SAM_FLAGS.KEY_READ | view, key) !=
            0) {
          continue;
        }
        for (var index = 0; index < 10000; index++) {
          nameLength.value = 256;
          final status = win.RegEnumKeyEx(key.value, index, nameBuffer,
              nameLength, nullptr, nullptr, nullptr, nullptr);
          if (status == win.WIN32_ERROR.ERROR_NO_MORE_ITEMS) break;
          if (status != 0) continue;
          final subkey = calloc<IntPtr>();
          try {
            if (win.RegOpenKeyEx(key.value, nameBuffer, 0,
                    win.REG_SAM_FLAGS.KEY_READ | view, subkey) !=
                0) {
              continue;
            }
            final name = _readString(subkey.value, 'DisplayName');
            final install = _readString(subkey.value, 'InstallLocation');
            final icon = _readString(subkey.value, 'DisplayIcon');
            if (name.isNotEmpty && (install.isNotEmpty || icon.isNotEmpty)) {
              result.add(WindowsInstalledProgram(name, install, icon));
            }
          } finally {
            if (subkey.value != 0) win.RegCloseKey(subkey.value);
            calloc.free(subkey);
          }
        }
      } finally {
        if (key.value != 0) win.RegCloseKey(key.value);
        calloc.free(key);
        calloc.free(keyPath);
        calloc.free(nameBuffer);
        calloc.free(nameLength);
      }
    }
  }
  return result;
}

String _readString(int key, String name) {
  final valueName = name.toNativeUtf16();
  final type = calloc<Uint32>();
  final size = calloc<Uint32>();
  Pointer<Uint8>? data;
  try {
    if (win.RegQueryValueEx(key, valueName, nullptr, type, nullptr, size) !=
            0 ||
        ![win.REG_VALUE_TYPE.REG_SZ, win.REG_VALUE_TYPE.REG_EXPAND_SZ]
            .contains(type.value) ||
        size.value < 2 ||
        size.value.isOdd ||
        size.value > 1024 * 1024) {
      return '';
    }
    // Uma unidade extra garante terminação mesmo para registros malformados.
    data = calloc<Uint8>(size.value + 2);
    if (win.RegQueryValueEx(key, valueName, nullptr, type, data, size) != 0) {
      return '';
    }
    return expandWindowsEnvironment(data.cast<Utf16>().toDartString()).trim();
  } finally {
    if (data != null) calloc.free(data);
    calloc.free(valueName);
    calloc.free(type);
    calloc.free(size);
  }
}

/// Obtém somente o destino bruto do .lnk. Não chama Resolve ou ShellExecute.
Future<String?> readWindowsShortcutTarget(String file) async {
  if (!Platform.isWindows) return null;
  return Isolate.run(() => _readShortcut(file));
}

String? _readShortcut(String file) {
  final initialized =
      win.CoInitializeEx(nullptr, win.COINIT.COINIT_APARTMENTTHREADED);
  if (win.FAILED(initialized) && initialized != win.RPC_E_CHANGED_MODE) {
    return null;
  }
  win.IShellLink? link;
  win.IPersistFile? persisted;
  final filename = file.toNativeUtf16();
  final target = calloc<Uint16>(32768).cast<Utf16>();
  final info = calloc<win.WIN32_FIND_DATA>();
  try {
    link = win.ShellLink.createInstance();
    persisted = win.IPersistFile.from(link);
    if (win.FAILED(persisted.load(filename, win.STGM.STGM_READ))) return null;
    const rawPath =
        0x4; // SLGP_RAWPATH, ShObjIdl_core.h (ausente no win32 5.5.4).
    if (win.FAILED(link.getPath(target, 32768, info, rawPath))) {
      return null;
    }
    final path = expandWindowsEnvironment(target.toDartString()).trim();
    return path.isEmpty ? null : path;
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
    calloc.free(filename);
    calloc.free(target);
    calloc.free(info);
    if (!win.FAILED(initialized)) win.CoUninitialize();
  }
}
