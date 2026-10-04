import 'dart:io';
import 'package:crypto/crypto.dart';
import 'package:path/path.dart' as p;

/// The repack manifest is relative to _Redist; archive manifests are relative
/// to MD5. Reject traversal after removing that single conventional prefix.
class RepackManifest {
  final Map<String, String> files;
  RepackManifest._(this.files);

  static Future<RepackManifest> read(File manifest) async {
    final files = <String, String>{};
    for (final line in await manifest.readAsLines()) {
      final match =
          RegExp(r'^([a-fA-F0-9]{32})\s+\*?(.+)$').firstMatch(line.trim());
      if (match == null) continue;
      var name = match[2]!.replaceAll('\\', '/');
      if (name.startsWith('../')) name = name.substring(3);
      if (name.startsWith('/') ||
          name.contains(':') ||
          name.split('/').contains('..')) {
        throw StateError('Caminho inválido no manifesto do repack.');
      }
      files[p.normalize(name)] = match[1]!.toLowerCase();
    }
    if (files.isEmpty) throw StateError('O manifesto do repack está vazio.');
    return RepackManifest._(files);
  }

  Future<bool> matches(
      String root, void Function() check, void Function(String, double?) status,
      {Iterable<String>? only, Future<String> Function(File)? hashFile}) async {
    final selected = only?.toList() ?? files.keys.toList();
    for (var i = 0; i < selected.length; i++) {
      check();
      final name = selected[i];
      final expected = files[name];
      if (expected == null) return false;
      final file = File(p.join(root, name));
      if (!await file.exists()) return false;
      final resolved = await file.resolveSymbolicLinks();
      final base = await Directory(root).resolveSymbolicLinks();
      if (!p.isWithin(base, resolved)) {
        throw StateError('O arquivo de instalação aponta para fora da pasta.');
      }
      status('Verificando ${p.basename(name)}…', i / selected.length);
      // Check cancellation during large game-asset hashes too.
      final String digest;
      if (hashFile != null) {
        digest = await hashFile(file);
      } else {
        digest = (await md5
                .bind(file.openRead().map((chunk) {
                  check();
                  return chunk;
                }))
                .first)
            .toString();
      }
      if (digest != expected) return false;
    }
    return true;
  }
}
