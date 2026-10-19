import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:path/path.dart' as p;
import 'download_game_launcher.dart';
import 'download_record.dart';
import 'repack_decoder_channel.dart';
import 'repack_decoder_tuning.dart';
import 'repack_manifest.dart';
import '../System/app_storage.dart';

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
    await ensureWritableDirectory(Directory(record.destination));
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
    await ensureWritableDirectory(output);
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
      await config.writeAsString(tuneDecoderConfig(text, output.path));
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
      final channel = DecoderChannel.pin();
      try {
        final sizes = <int>[];
        for (final archive in archives) {
          var size = 0;
          await _run(
              helper.path, [dll.path, archive.path, output.path, 'l'], task,
              (line) {
            final parts = line.split('\t');
            if (parts.length >= 4 && parts[1] == 'origsize') {
              size = _bytes(parts);
            }
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
        await _restoreRecompressedAudio(
            output, runtime, dll.path, helper.path, task, status);
      } finally {
        channel?.release();
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

  /// Parte dos repacks entrega o áudio recomprimido: o arquivo final sai como
  /// Ogg Vorbis cru e vem acompanhado de um patch `.x5` (HDiffPatch) que o
  /// devolve ao formato do jogo. Sem aplicar esse patch o jogo instala
  /// completo, roda e fica mudo — e o manifesto acusa justamente esse arquivo.
  ///
  /// O patch aparece em duas formas, e as duas são tratadas aqui:
  ///
  /// - ao lado do próprio alvo, como `Master Bank.bank.x5`, quando o Ogg já
  ///   está gravado no lugar do arquivo final;
  /// - sozinho, como `inner.fgpack.x5`, quando o alvo ainda precisa ser
  ///   montado a partir dos segmentos `NN.fgpack`.
  Future<void> _restoreRecompressedAudio(
      Directory output,
      Directory runtime,
      String dll,
      String helper,
      PreparationTask task,
      PreparationStatus status) async {
    final patches = <File>[];
    await for (final entry in output.list(recursive: true, followLinks: false)) {
      if (entry is File && p.extension(entry.path).toLowerCase() == '.x5') {
        patches.add(entry);
      }
    }
    if (patches.isEmpty) return;
    final patcher = File(p.join(runtime.path, 'x5.exe'));
    if (!await patcher.exists()) {
      throw StateError(
          'O repack não trouxe o reconstrutor de áudio (x5.exe) que seus arquivos pedem.');
    }
    patches.sort((a, b) => a.path.compareTo(b.path));
    for (var i = 0; i < patches.length; i++) {
      task.check();
      final patch = patches[i];
      final alvo = File(p.withoutExtension(patch.path));
      status(
          'Restaurando o áudio do jogo (${i + 1}/${patches.length})…',
          i / patches.length);
      final origem = await alvo.exists()
          ? alvo
          : await _montarAlvoDoPatch(alvo, runtime, task);
      final refeito = File('${alvo.path}.v1refeito');
      await _run(patcher.path, [origem.path, patch.path, refeito.path], task,
          (_) {},
          growthProbe: refeito);
      task.check();
      // Um FreeArc no lugar do alvo significa que o áudio vem dentro dele, e
      // não no próprio arquivo: é o caso dos repacks que juntam todas as
      // trilhas num pacote só.
      if (await _ehFreeArc(refeito)) {
        status('Gravando o áudio na pasta do jogo…', null);
        await _run(helper, [dll, refeito.path, output.path, 'x'], task, (_) {});
        await _apagar([refeito, alvo]);
      } else {
        await _apagar([alvo]);
        await refeito.rename(alvo.path);
      }
      await _apagar([patch]);
    }
    // Os segmentos só servem para montar o alvo; depois disso são peso morto.
    await for (final entry in output.list(recursive: true, followLinks: false)) {
      final nome = p.basename(entry.path).toLowerCase();
      if (entry is File &&
          (nome.endsWith('.fgpack') ||
              nome.endsWith('.fgpack.x2') ||
              nome.endsWith('.fgpack.fsb'))) {
        await _apagar([entry]);
      }
    }
  }

  /// Monta o arquivo que o patch espera encontrar: cada segmento `NN.fgpack` é
  /// cortado no tamanho real gravado em `NN.fgpack.x2`, convertido de Ogg
  /// Vorbis para FSB5 pelo `fsb.exe` e concatenado na ordem dos nomes.
  /// Converter o conjunto já concatenado não serve — o resultado perde os
  /// cabeçalhos intermediários e o patch recusa o tamanho.
  Future<File> _montarAlvoDoPatch(
      File alvo, Directory runtime, PreparationTask task) async {
    final segmentos = <File>[];
    await for (final entry in alvo.parent.list(followLinks: false)) {
      if (entry is File &&
          entry.path != alvo.path &&
          p.basename(entry.path).toLowerCase().endsWith('.fgpack')) {
        segmentos.add(entry);
      }
    }
    if (segmentos.isEmpty) {
      throw StateError(
          'O patch de áudio aponta para ${p.basename(alvo.path)}, que não veio no repack.');
    }
    final conversor = File(p.join(runtime.path, 'fsb.exe'));
    if (!await conversor.exists()) {
      throw StateError(
          'O repack não trouxe o conversor de áudio (fsb.exe) que seus segmentos pedem.');
    }
    segmentos.sort((a, b) => a.path.compareTo(b.path));
    final bancos = <File>[];
    for (final segmento in segmentos) {
      task.check();
      final medida = File('${segmento.path}.x2');
      if (await medida.exists()) {
        final marca = await medida.readAsBytes();
        if (marca.length < 8) {
          throw StateError(
              'O repack não informou o tamanho de ${p.basename(segmento.path)}.');
        }
        final real = ByteData.sublistView(marca).getUint64(0, Endian.little);
        if (real <= 0 || real > await segmento.length()) {
          throw StateError(
              'O tamanho declarado de ${p.basename(segmento.path)} não confere.');
        }
        final handle = await segmento.open(mode: FileMode.append);
        try {
          await handle.truncate(real);
        } finally {
          await handle.close();
        }
      }
      final banco = File('${segmento.path}.fsb');
      await _run(conversor.path, [segmento.path, banco.path], task, (_) {},
          growthProbe: banco);
      bancos.add(banco);
    }
    final destino = alvo.openWrite();
    try {
      for (final banco in bancos) {
        task.check();
        await destino.addStream(banco.openRead());
      }
    } finally {
      await destino.close();
    }
    return alvo;
  }

  /// Assinatura `ArC` no começo do arquivo.
  Future<bool> _ehFreeArc(File arquivo) async {
    final handle = await arquivo.open();
    try {
      final cabecalho = await handle.read(4);
      return cabecalho.length == 4 &&
          cabecalho[0] == 65 &&
          cabecalho[1] == 114 &&
          cabecalho[2] == 67 &&
          cabecalho[3] == 1;
    } finally {
      await handle.close();
    }
  }

  Future<void> _apagar(Iterable<File> arquivos) async {
    for (final arquivo in arquivos) {
      try {
        if (await arquivo.exists()) await arquivo.delete();
      } on FileSystemException {
        // Restos não invalidam uma instalação já verificada.
      }
    }
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

  /// [growthProbe] mantém vivas as ferramentas que trabalham caladas: o avanço
  /// é medido pelo arquivo que elas gravam, não pelas linhas que imprimem.
  Future<void> _run(String executable, List<String> args, PreparationTask task,
      void Function(String) onLine,
      {Set<int> canceledExitCodes = const {}, File? growthProbe}) async {
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
    var probed = -1;
    var probing = false;
    final timer = Timer.periodic(const Duration(seconds: 2), (_) async {
      if (growthProbe != null && !probing) {
        probing = true;
        try {
          final size = await growthProbe.length();
          if (size != probed) {
            probed = size;
            lastData = DateTime.now();
          }
        } on FileSystemException {
          // O arquivo só aparece quando a ferramenta começa a gravar.
        } finally {
          probing = false;
        }
      }
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
