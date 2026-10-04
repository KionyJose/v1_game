import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'download_game_launcher.dart';
import 'download_record.dart';
import 'repack_manifest.dart';

typedef PreparationStatus = void Function(String message, double? progress);

enum GamePreparationMethod { direct, silent }

class PreparationCanceled implements Exception {
  @override
  String toString() =>
      'Instalação cancelada. Os arquivos recebidos foram mantidos.';
}

class PreparationTask {
  bool canceled = false;
  Process? process;
  void cancel() {
    canceled = true;
    process?.kill();
  }

  void check() {
    if (canceled) throw PreparationCanceled();
  }
}

class GamePreparation {
  final Duration stallTimeout;
  final GamePreparationMethod method;
  final String? outputSubdirectory;
  GamePreparation(
      {this.stallTimeout = const Duration(minutes: 10),
      this.method = GamePreparationMethod.direct,
      this.outputSubdirectory});

  Future<String?> prepare(
      DownloadRecord record, PreparationTask task, PreparationStatus status,
      {bool allowExisting = true}) async {
    if (record.sourceType != ReleaseSource.fitGirl) {
      throw StateError('Este release ainda não tem protocolo automático.');
    }
    status('Localizando o executável do jogo…', null);
    final elapsed = Stopwatch()..start();
    task.check();
    final saved = record.launchPath;
    final managed = p.join(record.destination, 'Jogo');
    if (allowExisting &&
        (record.installationState == 'ready' ||
            record.installationProtocol == 'fitgirl-inno-freearc-v2' ||
            record.installationProtocol == 'fitgirl-inno-silent-v1') &&
        saved != null &&
        isGameExecutable(saved) &&
        await File(saved).exists() &&
        await File(saved).length() > 0) {
      return saved;
    }
    final games = await findDownloadedGames(record.destination);
    if (allowExisting &&
        record.installationProtocol == null &&
        games.length == 1 &&
        !p.isWithin(managed, games.single) &&
        await File(games.single).length() > 0) {
      return games.single;
    }
    final installers = <File>[];
    Future<void> scan(Directory folder, int depth) async {
      task.check();
      if (depth > 3) return;
      await for (final entry in folder.list(followLinks: false)) {
        if (entry is File &&
            p.basename(entry.path).toLowerCase() == 'setup.exe') {
          installers.add(entry);
        }
        if (entry is Directory && !p.basename(entry.path).startsWith('.')) {
          await scan(entry, depth + 1);
        }
      }
    }

    await scan(Directory(record.destination), 0);
    if (installers.isEmpty) return null;
    if (installers.length != 1) {
      throw StateError(
          'Há mais de um instalador. Selecione um executável já instalado.');
    }
    final setup = installers.single;
    final signature =
        latin1.decode(await setup.readAsBytes(), allowInvalid: true);
    if (!signature.contains('Inno Setup Setup Data')) {
      throw StateError(
          'Este pacote FitGirl usa um instalador ainda não compatível com a extração automática.');
    }
    final archives = await setup.parent
        .list(followLinks: false)
        .where((e) =>
            e is File &&
            RegExp(r'^fg-\d+\.bin$', caseSensitive: false)
                .hasMatch(p.basename(e.path)))
        .cast<File>()
        .toList();
    archives.sort((a, b) => a.path.compareTo(b.path));
    if (archives.isEmpty) {
      throw StateError('Os arquivos fg-*.bin do repack não foram encontrados.');
    }
    final tools = Directory(p.join(record.destination, '.v1-tools'));
    if (await FileSystemEntity.isLink(tools.path)) {
      throw StateError('A pasta de instalação não pode ser um link.');
    }
    await tools.create(recursive: true);
    final native = await _asset('V1Unarc.exe', tools);
    Future<String> hashFile(File file) async {
      String? hash;
      await _run(native, ['h', file.path], task, (line) {
        if (line.startsWith('HASH\t')) hash = line.substring(5).trim();
      });
      if (hash == null || !RegExp(r'^[a-f0-9]{32}$').hasMatch(hash!)) {
        throw StateError(
            'Não foi possível verificar a integridade do arquivo.');
      }
      return hash!;
    }

    final binsManifest =
        File(p.join(setup.parent.path, 'MD5', 'fitgirl-bins.md5'));
    if (await binsManifest.exists()) {
      final manifest = await RepackManifest.read(binsManifest);
      if (!await manifest.matches(setup.parent.path, task.check, status,
          only: archives.map((file) => p.basename(file.path)),
          hashFile: hashFile)) {
        throw StateError(
            'Os arquivos do download não passaram na verificação de integridade.');
      }
    }
    for (final archive in archives) {
      final handle = await archive.open();
      try {
        final header = await handle.read(4);
        if (header.length != 4 ||
            header[0] != 65 ||
            header[1] != 114 ||
            header[2] != 67 ||
            header[3] != 1) {
          throw StateError(
              'Compactação não suportada em ${p.basename(archive.path)}.');
        }
      } finally {
        await handle.close();
      }
    }
    record.installationProtocol = method == GamePreparationMethod.silent
        ? 'fitgirl-inno-silent-v1'
        : 'fitgirl-inno-freearc-v2';
    final subdirectory = outputSubdirectory ??
        (method == GamePreparationMethod.silent ? 'Jogo-Silent' : 'Jogo');
    if (p.basename(subdirectory) != subdirectory ||
        subdirectory.startsWith('.')) {
      throw StateError('Pasta de instalação inválida.');
    }
    final output = Directory(p.join(record.destination, subdirectory));
    await tools.create(recursive: true);
    await output.create(recursive: true);
    record.installationDirectory = output.path;
    if (await FileSystemEntity.isLink(tools.path) ||
        await FileSystemEntity.isLink(output.path)) {
      throw StateError('A pasta de instalação não pode ser um link.');
    }
    status('Preparando os decodificadores do repack…', null);
    final inno = await _asset('innoextract.exe', tools);
    await _run(inno, ['--extract', '--output-dir', tools.path, setup.path],
        task, (_) {});
    final runtime = Directory(p.join(tools.path, 'tmp'));
    final dll = File(p.join(runtime.path, 'unarc.dll'));
    if (!await dll.exists()) {
      throw StateError(
          'O repack não contém o decodificador unarc.dll esperado.');
    }
    final helper = await File(native).copy(p.join(runtime.path, 'V1Unarc.exe'));
    final config = File(p.join(runtime.path, 'CLS.ini'));
    if (await config.exists()) {
      final text = await config.readAsString();
      await config.writeAsString(text.replaceAll('{app}', output.path));
    }
    final manifestFile =
        File(p.join(tools.path, 'app', '_Redist', 'fitgirl.md5'));
    final manifest = await manifestFile.exists()
        ? await RepackManifest.read(manifestFile)
        : null;
    if (allowExisting &&
        manifest != null &&
        await manifest.matches(output.path, task.check, status,
            hashFile: hashFile)) {
      return chooseInstalledExecutable(
          await findDownloadedGames(output.path), output.path);
    }
    if (method == GamePreparationMethod.silent) {
      final runner = await _asset('V1SilentInstall.exe', tools);
      final log = File(p.join(tools.path, 'silent-install.log'));
      status(
          'Instalação silenciosa · aguarde a autorização do Windows, se solicitada…',
          null);
      var lastSize = -1;
      var changed = DateTime.now();
      var sampling = false;
      var stalled = false;
      var finished = false;
      final sampler = Timer.periodic(const Duration(seconds: 2), (_) async {
        if (sampling || task.canceled) return;
        sampling = true;
        try {
          var bytes = 0;
          await for (final file
              in output.list(recursive: true, followLinks: false)) {
            if (file is File) bytes += await file.length();
          }
          if (bytes != lastSize) {
            lastSize = bytes;
            changed = DateTime.now();
          }
          if (!finished) {
            status(
                'Instalação silenciosa · ${(bytes / 1073741824).toStringAsFixed(2)} GB gravados…',
                null);
          }
          if (DateTime.now().difference(changed) > stallTimeout) {
            stalled = true;
            task.process?.kill();
          }
        } on FileSystemException {
          /* Files can change during the sample. */
        } finally {
          sampling = false;
        }
      });
      try {
        await _run(runner, [setup.path, output.path, log.path], task, (_) {},
            canceledExitCodes: const {1223});
      } catch (_) {
        if (stalled) {
          throw StateError(
              'O instalador silencioso ficou sem progresso. A instalação atual foi preservada.');
        }
        rethrow;
      } finally {
        finished = true;
        sampler.cancel();
        while (sampling) {
          await Future<void>.delayed(const Duration(milliseconds: 50));
        }
      }
      if (manifest == null) {
        throw StateError(
            'O instalador não forneceu um manifesto para verificar todos os arquivos.');
      }
    } else {
      final sizes = <int>[];
      for (final archive in archives) {
        var size = 0;
        await _run(
            helper.path, [dll.path, archive.path, output.path, 'l'], task,
            (line) {
          final parts = line.split('\t');
          if (parts.length >= 4 && parts[1] == 'origsize') size = _bytes(parts);
        });
        sizes.add(size);
      }
      final total = sizes.fold<int>(0, (a, b) => a + b);
      var extracted = 0;
      for (var i = 0; i < archives.length; i++) {
        task.check();
        final label =
            'Extraindo ${p.basename(archives[i].path)} (${i + 1}/${archives.length})…';
        status(label, null);
        await _run(
            helper.path, [dll.path, archives[i].path, output.path, 'x'], task,
            (line) {
          final parts = line.split('\t');
          if (parts.length >= 4 && parts[1] == 'write') {
            status(
                label,
                total > 0
                    ? ((extracted + _bytes(parts)) / total).clamp(0, 1)
                    : null);
          }
        });
        extracted += sizes[i];
      }
    }
    status('Verificando todos os arquivos instalados…', null);
    if (manifest != null &&
        !await manifest.matches(output.path, task.check, status,
            hashFile: hashFile)) {
      throw StateError(
          'A instalação está incompleta ou contém arquivos inválidos. O jogo não foi cadastrado.');
    }
    final candidates = await findDownloadedGames(output.path);
    record.installationMetrics = {
      'method': method.name,
      'elapsedMs': elapsed.elapsedMilliseconds,
      'verified': manifest != null,
      'manifestFiles': manifest?.files.length,
      if (method == GamePreparationMethod.silent)
        'log': p.join(tools.path, 'silent-install.log'),
    };
    final report = File(p.join(tools.path, '${method.name}-installation.json'));
    await report.writeAsString(
        const JsonEncoder.withIndent('  ').convert({
          'method': method.name,
          'protocol': record.installationProtocol,
          'installer': setup.path,
          'directory': output.path,
          'elapsedMs': elapsed.elapsedMilliseconds,
          'verified': manifest != null,
          'manifestFiles': manifest?.files.length,
          'executables': candidates,
          'selectedExecutable':
              chooseInstalledExecutable(candidates, output.path),
          if (method == GamePreparationMethod.silent)
            'log': p.join(tools.path, 'silent-install.log'),
        }),
        flush: true);
    return chooseInstalledExecutable(candidates, output.path);
  }

  static int _bytes(List<String> parts) =>
      (int.tryParse(parts[2]) ?? 0) * 1048576 +
      ((int.tryParse(parts[3]) ?? 0) & 1048575);

  Future<String> _asset(String name, Directory directory) async {
    final data = await rootBundle.load('assets/Repack/$name');
    final file = File(p.join(directory.path, name));
    await file.writeAsBytes(
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes),
        flush: true);
    return file.path;
  }

  Future<void> _run(String executable, List<String> args, PreparationTask task,
      void Function(String) onLine,
      {Set<int> canceledExitCodes = const {}}) async {
    task.check();
    final process = await Process.start(executable, args,
        workingDirectory: p.dirname(executable));
    task.process = process;
    if (task.canceled) process.kill();
    var lastData = DateTime.now();
    var stalled = false;
    final errors = <String>[];
    final out = process.stdout
        .transform(const Utf8Decoder(allowMalformed: true))
        .transform(const LineSplitter())
        .listen((line) {
      if (line.startsWith('PROGRESS\t') ||
          line.startsWith('RESULT\t') ||
          line.startsWith('HEARTBEAT\t')) {
        lastData = DateTime.now();
      }
      if (line.startsWith('ERROR\t') && errors.length < 10) errors.add(line);
      onLine(line);
    });
    final err = process.stderr
        .transform(const Utf8Decoder(allowMalformed: true))
        .listen((text) {
      if (errors.length < 10) errors.add(text);
    });
    final stdoutDone = out.asFuture<void>();
    final stderrDone = err.asFuture<void>();
    final timer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (DateTime.now().difference(lastData) > stallTimeout) {
        stalled = true;
        process.kill();
      }
    });
    try {
      final code = await process.exitCode;
      await stdoutDone;
      await stderrDone;
      task.check();
      if (canceledExitCodes.contains(code)) throw PreparationCanceled();
      if (stalled) {
        throw StateError(
            'O decodificador ficou sem progresso. A instalação não foi concluída; selecione um executável já instalado ou tente novamente.');
      }
      if (code != 0) {
        throw StateError(
            'Falha ao extrair o repack (código $code). ${errors.join(' ').trim()}');
      }
    } finally {
      timer.cancel();
      await out.cancel();
      await err.cancel();
      task.process = null;
    }
  }
}
