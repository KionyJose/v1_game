import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import '../Bando de Dados/db.dart';
import '../Modelos/IconeInicial.dart';
import '../Global.dart';

/// Ícone que o cadastro grava enquanto o jogador não escolhe uma capa.
const defaultCoverFile = 'BGICOdefault.png';

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
            'img: ${existing?.imgStr ?? p.join(assetsPath, defaultCoverFile)}',
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

  /// A entrada já tem capa escolhida? Enquanto guardar o ícone padrão, o jogo
  /// aparece no início sem identidade, e é esse o caso que o Jogar resolve
  /// antes de abrir o jogo. Entra na fila de escritas para não ler o catálogo
  /// no meio de um cadastro.
  Future<bool> hasCover(String executable) => _writes.then((_) async {
        final db = DB();
        if (file != null) db.dbPath = file!.path;
        final key = p.normalize(p.absolute(executable)).toLowerCase();
        for (final entry in await db.leituraDeDados()) {
          if (p.normalize(p.absolute(entry.local)).toLowerCase() != key) {
            continue;
          }
          final image = entry.imgStr.trim();
          return image.isNotEmpty &&
              p.basename(image).toLowerCase() != defaultCoverFile.toLowerCase();
        }
        return false;
      });

  /// Troca só a capa da entrada do jogo, preservando o resto do catálogo.
  /// Entra na mesma fila de escritas de [register] para não perder o cadastro
  /// feito instantes antes.
  Future<bool> setCover(String executable, String image) {
    final result = _writes.then((_) async {
      final db = DB();
      if (file != null) db.dbPath = file!.path;
      final entries = List<IconInicial>.from(await db.leituraDeDados());
      final key = p.normalize(p.absolute(executable)).toLowerCase();
      final index = entries.indexWhere(
          (entry) => p.normalize(p.absolute(entry.local)).toLowerCase() == key);
      if (index < 0) return false;
      entries[index].imgStr = image;
      final target = File(db.dbPath);
      await target.parent.create(recursive: true);
      final temp = File('${target.path}.cover.tmp');
      await temp.writeAsString(db.codificaLista(entries), flush: true);
      await temp.rename(target.path);
      changes.value++;
      return true;
    });
    _writes = result.catchError((_) => false);
    return result;
  }
}
