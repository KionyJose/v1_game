import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:v1_game/System/app_storage.dart';

void main() {
  late Directory root;
  setUp(
      () async => root = await Directory.systemTemp.createTemp('v1-storage-'));
  tearDown(() async => root.delete(recursive: true));

  test('migra os dados sem apagar a origem ou substituir dados atuais',
      () async {
    final old = File(p.join(root.path, 'old', 'library.txt'));
    await old.parent.create();
    await old.writeAsString('biblioteca original');
    final target = File(p.join(root.path, 'private', 'library.txt'));
    AppStorage.migrateFile(target, old);
    expect(await target.readAsString(), 'biblioteca original');
    expect(await old.readAsString(), 'biblioteca original');
    await target.writeAsString('biblioteca atual');
    AppStorage.migrateFile(target, old);
    expect(await target.readAsString(), 'biblioteca atual');
    expect(await target.parent.list().length, 1);
  });

  test('verifica escrita sem deixar arquivos e sem alterar outros dados',
      () async {
    final directory = Directory(p.join(root.path, 'games'));
    await ensureWritableDirectory(directory);
    expect(await directory.list().isEmpty, isTrue);
    final existing = File(p.join(directory.path, 'game.bin'));
    await existing.writeAsString('dados');
    await Future.wait(
        List.generate(8, (_) => ensureWritableDirectory(directory)));
    expect(await existing.readAsString(), 'dados');
    expect(await directory.list().length, 1);
  });

  test('falha de acesso informa a pasta e preserva o arquivo bloqueador',
      () async {
    final blocker = File(p.join(root.path, 'blocked'));
    await blocker.writeAsString('preservar');
    await expectLater(
        ensureWritableDirectory(Directory(p.join(blocker.path, 'child'))),
        throwsA(isA<FolderAccessException>().having((error) => error.toString(),
            'orientação', contains('Escolha outra'))));
    expect(await blocker.readAsString(), 'preservar');
  });
}
