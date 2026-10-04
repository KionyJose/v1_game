import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:v1_game/Downloads/download_record.dart';
import 'package:v1_game/Downloads/game_preparation.dart';
import 'package:v1_game/Downloads/installed_game_library.dart';
import 'package:v1_game/Bando de Dados/db.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final metadata = Platform.environment['V1_REPACK_TEST_METADATA'];
  test('Extração nativa completa e cadastro do executável verificado',
      () async {
    final file = File(metadata!);
    final record = DownloadRecord.fromJson(
        (jsonDecode(await file.readAsString()) as Map).cast<String, dynamic>());
    expect(record.state, DownloadState.completed);
    final output = Platform.environment['V1_REPACK_OUTPUT'];
    if (output != null) {
      record.launchPath = null;
      record.installationState = 'idle';
      record.installationProtocol = null;
    }
    final method = Platform.environment['V1_REPACK_METHOD'] == 'silent'
        ? GamePreparationMethod.silent
        : GamePreparationMethod.direct;
    var lastReport = DateTime(2000);
    final executable =
        await GamePreparation(method: method, outputSubdirectory: output)
            .prepare(record, PreparationTask(), (message, progress) {
      if (DateTime.now().difference(lastReport).inSeconds >= 10) {
        lastReport = DateTime.now();
        // ignore: avoid_print
        print(
            '$message ${progress == null ? "" : "${(progress * 100).toStringAsFixed(1)}%"}');
      }
    }, allowExisting: Platform.environment['V1_REPACK_FORCE'] != '1');
    expect(executable, isNotNull);
    expect(await File(executable!).length(), greaterThan(0));
    final register = Platform.environment['V1_REPACK_REGISTER'] == '1';
    final library = InstalledGameLibrary(
        file: register
            ? null
            : File(p.join('build', 'repack-analysis', 'native-library.txt')));
    if (register) {
      final original = File(DB().dbPath);
      if (await original.exists()) {
        await original.copy('${original.path}.before-native-test');
      }
    }
    await library.register(record.name, executable);
    if (register) {
      record.launchPath = executable;
      record.installationState = 'ready';
      record.installationStatus =
          'Pronto para jogar · cadastrado no início da biblioteca';
      record.installationError = null;
      await file.copy('${file.path}.before-native-test');
      final temp = File('${file.path}.native.tmp');
      await temp.writeAsString(
          const JsonEncoder.withIndent('  ').convert(record.toJson()),
          flush: true);
      await temp.rename(file.path);
      final appData = Platform.environment['APPDATA'];
      if (appData != null) {
        final index = File(p.join(
            appData, 'com.example', 'v1_game', 'downloads', 'downloads.json'));
        if (await index.exists()) {
          final json = (jsonDecode(await index.readAsString()) as Map)
              .cast<String, dynamic>();
          final downloads = json['downloads'] as List;
          final at =
              downloads.indexWhere((item) => (item as Map)['id'] == record.id);
          if (at >= 0) {
            downloads[at] = record.toJson();
            await index.copy('${index.path}.before-native-test');
            final update = File('${index.path}.native.tmp');
            await update.writeAsString(
                const JsonEncoder.withIndent('  ').convert(json),
                flush: true);
            await update.rename(index.path);
          }
        }
      }
    }
    final db = DB();
    if (library.file != null) db.dbPath = library.file!.path;
    final entries = await db.leituraDeDados();
    expect(entries.first.local, executable);
    // ignore: avoid_print
    print('VERIFIED_EXECUTABLE=$executable');
  },
      skip: metadata == null || !Platform.isWindows,
      timeout: const Timeout(Duration(hours: 2)));
}
