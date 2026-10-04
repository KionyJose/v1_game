import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../Bando de Dados/db.dart';
import '../Modelos/IconeInicial.dart';
import '../Global.dart';

String installedGameName(String name) => name
    .replaceAll(RegExp(r'\[fitgirl[^\]]*\]', caseSensitive: false), '')
    .replaceAll(RegExp(r'[\r\n]'), ' ')
    .replaceAll(': ', ' - ')
    .trim();

/// Grava no mesmo catálogo usado pelo launcher, preservando os outros jogos.
class InstalledGameLibrary {
  static final changes = ValueNotifier<int>(0);
  static int get revision => changes.value;
  static Future<void> _writes = Future.value();
  final File? file;
  InstalledGameLibrary({this.file});

  Future<void> register(String name, String executable,
      {String? previousExecutable}) {
    final result = _writes.then((_) async {
      final db = DB();
      if (file != null) db.dbPath = file!.path;
      final entries = List<IconInicial>.from(await db.leituraDeDados());
      final key = p.normalize(p.absolute(executable)).toLowerCase();
      final previousKey = previousExecutable == null
          ? null
          : p.normalize(p.absolute(previousExecutable)).toLowerCase();
      IconInicial? existing;
      entries.removeWhere((entry) {
        final entryKey = p.normalize(p.absolute(entry.local)).toLowerCase();
        final same = entryKey == key || entryKey == previousKey;
        if (same) existing = entry;
        return same;
      });
      final title = installedGameName(name);
      entries.insert(
          0,
          IconInicial([
            'lugar: 1',
            'nome: ${title.isEmpty ? p.basenameWithoutExtension(executable) : title}',
            'local: $executable',
            'img: ${existing?.imgStr ?? p.join(assetsPath, 'BGICOdefault.png')}',
            'imgAux: ${existing?.imgAuxStr ?? ''}',
          ]));
      for (var i = 0; i < entries.length; i++) {
        entries[i].lugar = i + 1;
      }
      final target = File(db.dbPath);
      await target.parent.create(recursive: true);
      final temp = File('${target.path}.install.tmp');
      await temp.writeAsString(db.codificaLista(entries), flush: true);
      await temp.rename(target.path);
      changes.value++;
    });
    _writes = result.catchError((_) {});
    return result;
  }
}
