import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:v1_game/Downloads/download_game_launcher.dart';
import 'package:v1_game/Downloads/download_record.dart';
import 'package:v1_game/Downloads/game_preparation.dart';
import 'package:v1_game/Downloads/installed_game_library.dart';
import 'package:v1_game/Bando de Dados/db.dart';
import 'package:v1_game/Downloads/repack_manifest.dart';

void main() {
  late Directory root;
  setUp(() async {
    root = await Directory('test').createTemp('game-preparation-');
  });
  tearDown(() async {
    await root.delete(recursive: true);
  });

  test('Cadastro coloca o jogo em primeiro, limpa o nome e não duplica',
      () async {
    final file = File(p.join(root.path, 'library.txt'));
    final library = InstalledGameLibrary(file: file);
    await library.register('Outro jogo', p.join(root.path, 'Other.exe'));
    await library.register(
        'FACEMINER [FitGirl Repack]', p.join(root.path, 'FACEMINER.exe'));
    await library.register(
        'FACEMINER [FitGirl Repack]', p.join(root.path, 'FACEMINER.exe'));
    final db = DB()..dbPath = file.path;
    final entries = await db.leituraDeDados();
    expect(entries.length, 2);
    expect(entries.first.nome, 'FACEMINER');
    expect(entries.first.local, p.join(root.path, 'FACEMINER.exe'));
    expect(entries.map((e) => e.lugar), [1, 2]);
    expect(entries.last.nome, 'Outro jogo');
  });

  test('Preparação ignora QuickSFV salvo e identifica o executável real',
      () async {
    final md5 = await Directory(p.join(root.path, 'MD5')).create();
    final checker =
        await File(p.join(md5.path, 'QuickSFV.exe')).writeAsString('fixture');
    final game =
        await File(p.join(root.path, 'FACEMINER.exe')).writeAsString('fixture');
    await File(p.join(root.path, 'setup.exe')).writeAsString('fixture');
    final record = DownloadRecord(
        id: '1' * 40,
        name: 'FACEMINER',
        torrentFiles: [],
        destination: root.path,
        acquiredAt: DateTime(2026),
        sourceName: 'FitGirl Repacks',
        state: DownloadState.completed,
        launchPath: checker.path);
    expect(await findDownloadedGames(root.path), [game.path]);
    expect(
        await GamePreparation().prepare(record, PreparationTask(), (_, __) {}),
        game.path);
  });

  test(
      'Preparação interrompida é recuperada como falha, sem concluir instalação',
      () {
    final record = DownloadRecord(
        id: '1' * 40,
        name: 'Teste',
        torrentFiles: [],
        destination: root.path,
        acquiredAt: DateTime(2026),
        state: DownloadState.completed)
      ..installationState = 'extracting'
      ..installationProtocol = 'fitgirl-inno-freearc-v1';
    final recovered = DownloadRecord.fromJson(record.toJson());
    expect(recovered.installationState, 'failed');
    expect(recovered.installationError, contains('interrompida'));
    expect(recovered.state, DownloadState.completed);
    expect(recovered.installationProtocol, 'fitgirl-inno-freearc-v1');
  });

  test('Manifesto rejeita instalação parcial mesmo com executável presente',
      () async {
    await File(p.join(root.path, 'Game.exe')).writeAsString('game');
    final file = await File(p.join(root.path, 'fitgirl.md5'))
        .writeAsString('c8d46d341bea4fd5bff866a65ff8aea9 *../Game.exe\n'
            'd41d8cd98f00b204e9800998ecf8427e *../assets.pak\n');
    final manifest = await RepackManifest.read(file);
    expect(
        await manifest
            .matches(root.path, () {}, (_, __) {}, only: ['Game.exe']),
        isTrue);
    expect(await manifest.matches(root.path, () {}, (_, __) {}), isFalse);
    await File(p.join(root.path, 'assets.pak')).writeAsString('');
    expect(await manifest.matches(root.path, () {}, (_, __) {}), isTrue);
  });

  test('Seleciona launcher raiz em vez de binário da engine e utilitários', () {
    final rootGame = p.join(root.path, 'Dungeons.exe');
    expect(
        chooseInstalledExecutable([
          rootGame,
          p.join(root.path, 'Dungeons', 'Dungeons-WinGDK-Shipping.exe'),
          p.join(root.path, 'gamelaunchhelper.exe'),
          p.join(root.path, 'GamingRepair.exe'),
        ], root.path),
        rootGame);
    expect(isGameExecutable('gamelaunchhelper.exe'), isFalse);
    expect(isGameExecutable('GamingRepair.exe'), isFalse);
  });

  test('Manifesto não permite sair da pasta de instalação', () async {
    final file = await File(p.join(root.path, 'bad.md5'))
        .writeAsString('d41d8cd98f00b204e9800998ecf8427e *../../outside.exe');
    expect(() => RepackManifest.read(file), throwsStateError);
  });

  test('Reinstalação atualiza caminho e preserva os outros jogos', () async {
    final file = File(p.join(root.path, 'library.txt'));
    final library = InstalledGameLibrary(file: file);
    final old = p.join(root.path, 'Jogo', 'Game.exe');
    final replacement = p.join(root.path, 'Jogo-Silent', 'Game.exe');
    await library.register('Outro', p.join(root.path, 'Other.exe'));
    await library.register('Game', old);
    await library.register('Game', replacement, previousExecutable: old);
    final db = DB()..dbPath = file.path;
    final entries = await db.leituraDeDados();
    expect(entries.length, 2);
    expect(entries.first.local, replacement);
    expect(entries.last.nome, 'Outro');
  });
}
