import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:win32/win32.dart';

const _megabyte = 1048576;

typedef PhysicalMemory = ({int total, int available});

/// Memória física da máquina, ou nulo quando o Windows não informa.
PhysicalMemory? physicalMemory() {
  if (!Platform.isWindows) return null;
  final status = calloc<MEMORYSTATUSEX>();
  try {
    status.ref.dwLength = sizeOf<MEMORYSTATUSEX>();
    if (GlobalMemoryStatusEx(status) == 0) return null;
    return (total: status.ref.ullTotalPhys, available: status.ref.ullAvailPhys);
  } finally {
    calloc.free(status);
  }
}

/// Teto de memória para os decodificadores, sempre acima de um mínimo viável.
int decoderMemoryBudget(int availableBytes) {
  final budget = availableBytes * 7 ~/ 10;
  return budget < 256 * _megabyte ? 256 * _megabyte : budget;
}

int _scale(int value, String? unit) => switch (unit?.toLowerCase()) {
      'k' => value * 1024,
      'g' => value * 1073741824,
      _ => value * _megabyte,
    };

/// O CLS aceita `60%-2048m`, `75%-10m`, `1024m` e `128` (megabytes).
int? _resolveBudget(String value, int totalBytes) {
  final text = value.replaceAll(' ', '');
  final share = RegExp(r'^(\d+)%(?:-(\d+)([kmg])?)?$', caseSensitive: false)
      .firstMatch(text);
  if (share != null) {
    final offset = share[2] == null ? 0 : _scale(int.parse(share[2]!), share[3]);
    return totalBytes * int.parse(share[1]!) ~/ 100 - offset;
  }
  final absolute =
      RegExp(r'^(\d+)([kmg])?$', caseSensitive: false).firstMatch(text);
  return absolute == null ? null : _scale(int.parse(absolute[1]!), absolute[2]);
}

final _budgetKey = RegExp(
    r'^(\s*)(MaxMemoryUsage|ldmfMaxMemoryUsage|Memory)(\s*=\s*)(\S+)(\s*)$',
    caseSensitive: false);

/// O CLS.ini do repack pede porcentagens da memória *total* da máquina. Com
/// pouca RAM livre o worker x64 do codec morre no meio da extração e o unarc
/// acusa "broken compressed data", então cada orçamento é reduzido ao que a
/// máquina tem de fato. Limites de thread e caminhos de temporários ficam como
/// o repack definiu.
String tuneDecoderConfig(String text, String appPath,
    {PhysicalMemory? memory}) {
  final resolved = memory ?? physicalMemory();
  final replaced = text.replaceAll('{app}', appPath);
  if (resolved == null || resolved.total <= 0) return replaced;
  final budget = decoderMemoryBudget(resolved.available);
  final lines = replaced.split('\n');
  for (var i = 0; i < lines.length; i++) {
    final match = _budgetKey.firstMatch(lines[i]);
    if (match == null) continue;
    final current = _resolveBudget(match[4]!, resolved.total);
    if (current == null || current <= budget) continue;
    lines[i] =
        '${match[1]}${match[2]}${match[3]}${budget ~/ _megabyte}m${match[5]}';
  }
  return lines.join('\n');
}
