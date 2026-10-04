import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'aria2_engine.dart';
import 'download_record.dart';
import 'download_store.dart';
import 'download_destination.dart';
import 'download_game_launcher.dart';
import 'game_preparation.dart';
import 'installed_game_library.dart';

class DownloadsController extends ChangeNotifier {
  static final instance = DownloadsController();
  final Future<DownloadStore> Function() _openStore;
  final TorrentEngine engine;
  final DateTime Function() _now;
  final GamePreparation _preparation;
  final GamePreparation _silentPreparation;
  final InstalledGameLibrary _library;
  final _preparationTasks = <String, PreparationTask>{};
  final _preparationJobs = <String, Future<String?>>{};
  DownloadStore? _store;
  Future<void>? _initializing;
  Timer? _timer;
  Timer? _watchDebounce;
  StreamSubscription<FileSystemEvent>? _watch;
  bool _polling = false;
  bool _scanning = false;
  bool _closed = false;
  bool loading = false;
  String? error;
  DownloadsController(
      {Future<DownloadStore> Function()? openStore,
      TorrentEngine? engine,
      GamePreparation? preparation,
      GamePreparation? silentPreparation,
      InstalledGameLibrary? library,
      DateTime Function()? now})
      : _openStore = openStore ?? DownloadStore.openDefault,
        _now = now ?? DateTime.now,
        _preparation = preparation ?? GamePreparation(),
        _silentPreparation = silentPreparation ??
            GamePreparation(method: GamePreparationMethod.silent),
        _library = library ?? InstalledGameLibrary(),
        engine = engine ?? Aria2Engine();

  List<DownloadRecord> get items =>
      List.unmodifiable(_store?.records.values ?? <DownloadRecord>[]);
  String get purchaseDirectory => _store?.purchases.path ?? '';

  Future<void> initialize() => _initializing ??= _initialize();
  Future<void> _initialize() async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      final store = await _openStore();
      await store.load();
      _store = store;
      await store.save();
      _watch = store.purchases.watch().listen((event) {
        if (!event.path.toLowerCase().endsWith('.torrent')) return;
        _watchDebounce?.cancel();
        _watchDebounce = Timer(const Duration(seconds: 1), () => refresh());
      }, onError: (Object e) {
        error = 'Não foi possível monitorar a pasta: $e';
        notifyListeners();
      });
      _timer = Timer.periodic(const Duration(seconds: 2), (_) => poll());
    } catch (e) {
      _initializing = null;
      error = 'Não foi possível carregar Downloads: $e';
      rethrow;
    } finally {
      loading = false;
      notifyListeners();
    }
  }

  Future<void> refresh() async {
    try {
      await initialize();
      if (_scanning || _closed) return;
      _scanning = true;
      await _store!.scan();
      await _store!.save();
      error = null;
    } catch (e) {
      error = e.toString();
    } finally {
      _scanning = false;
      if (!_closed) notifyListeners();
    }
  }

  Future<void> registerPurchase(String path,
      {required String sourceName,
      required String edition,
      required String pageUrl,
      required String downloadUrl,
      required Map<String, String> releaseInfo}) async {
    await initialize();
    await _store!.importTorrent(path,
        sourceName: sourceName,
        edition: edition,
        pageUrl: pageUrl,
        downloadUrl: downloadUrl,
        releaseInfo: releaseInfo);
    await _store!.save();
    notifyListeners();
  }

  Future<void> setDownloadDrive(DownloadRecord record, String drive) async {
    await initialize();
    if (!items.contains(record) ||
        record.busy ||
        record.running ||
        record.startedAt != null ||
        record.downloadedBytes > 0 ||
        record.state == DownloadState.completed) {
      throw StateError('Escolha o disco antes de iniciar o download.');
    }
    final destination = gameDownloadDirectory(drive, record.name, record.id);
    if (!await Directory(drive).exists()) {
      throw StateError('Este disco não está disponível. Escolha outro disco.');
    }
    await Directory(destination).create(recursive: true);
    final previous = record.destination;
    final chosen = record.destinationChosen;
    record.destination = destination;
    record.destinationChosen = true;
    try {
      await _store!.save();
    } catch (_) {
      record.destination = previous;
      record.destinationChosen = chosen;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> setLaunchPath(DownloadRecord record, String path) async {
    await initialize();
    if (!items.contains(record) || record.state != DownloadState.completed) {
      throw StateError('O download precisa estar concluído para jogar.');
    }
    if (!await File(path).exists()) {
      throw StateError('Executável não encontrado.');
    }
    if (!isGameExecutable(path)) {
      throw StateError('Selecione o executável .exe do jogo.');
    }
    final previous = record.launchPath;
    record.launchPath = path;
    try {
      await _store?.save();
    } catch (_) {
      record.launchPath = previous;
      rethrow;
    }
    notifyListeners();
  }

  Future<void> registerInstalledGame(DownloadRecord record, String path) async {
    final previous = record.launchPath;
    await setLaunchPath(record, path);
    await _library.register(record.name, path, previousExecutable: previous);
    record.installationState = 'ready';
    record.installationStatus =
        'Pronto para jogar · cadastrado no início da biblioteca';
    record.installationError = null;
    await _store?.save();
    if (!_closed) notifyListeners();
  }

  Future<String?> prepareForPlay(DownloadRecord record) {
    return _startPreparation(record, silent: false);
  }

  Future<String?> installSilently(DownloadRecord record) {
    return _startPreparation(record, silent: true);
  }

  Future<String?> _startPreparation(DownloadRecord record,
      {required bool silent}) {
    final existing = _preparationJobs[record.id];
    if (existing != null) return existing;
    if (_closed ||
        record.busy ||
        record.state != DownloadState.completed ||
        record.sourceType != ReleaseSource.fitGirl) {
      return Future.error(StateError(
          'O download precisa estar concluído, disponível e usar o protocolo FitGirl.'));
    }
    final task = PreparationTask();
    _preparationTasks[record.id] = task;
    final job = _prepareForPlay(record, task, silent: silent);
    _preparationJobs[record.id] = job;
    return job;
  }

  Future<String?> _prepareForPlay(DownloadRecord record, PreparationTask task,
      {required bool silent}) async {
    final previous = DownloadRecord.fromJson(record.toJson());
    try {
      if (_closed || record.busy || record.state != DownloadState.completed) {
        throw StateError('O download precisa estar concluído e disponível.');
      }
      if (record.sourceType != ReleaseSource.fitGirl) {
        throw StateError('Este release ainda não tem protocolo automático.');
      }
      final retry = record.installationState == 'failed';
      record.busy = true;
      record.installationState = 'extracting';
      record.installationError = null;
      record.installationStatus = 'Analisando os arquivos do jogo…';
      record.installationProgress = null;
      if (!_closed) notifyListeners();
      await _store?.save();
      final path = await (silent ? _silentPreparation : _preparation)
          .prepare(record, task, (message, progress) {
        record.installationStatus = message;
        record.installationProgress = progress;
        if (!_closed) notifyListeners();
      }, allowExisting: !retry && !silent);
      task.check();
      if (path != null) {
        record.installationStatus = 'Cadastrando o jogo na biblioteca…';
        if (!_closed) notifyListeners();
        await registerInstalledGame(record, path);
      } else {
        record.installationState = 'chooseExecutable';
        record.installationStatus = 'Selecione o executável do jogo';
      }
      return path;
    } catch (error) {
      record.installationState = 'failed';
      record.installationError =
          error is StateError ? error.message.toString() : error.toString();
      record.installationStatus =
          task.canceled ? 'Preparação cancelada' : 'Instalação não concluída';
      if (silent && previous.installationState == 'ready') {
        record.launchPath = previous.launchPath;
        record.installationState = previous.installationState;
        record.installationProtocol = previous.installationProtocol;
        record.installationDirectory = previous.installationDirectory;
        record.installationMetrics = previous.installationMetrics;
        record.installationStatus =
            'Instalação atual preservada · teste silent não concluído';
      }
      rethrow;
    } finally {
      record.busy = false;
      record.installationProgress = null;
      _preparationTasks.remove(record.id);
      _preparationJobs.remove(record.id);
      await _store?.save();
      if (!_closed) notifyListeners();
    }
  }

  void cancelInstallation(DownloadRecord record) =>
      _preparationTasks[record.id]?.cancel();

  Future<void> _action(
      DownloadRecord record, Future<void> Function() action) async {
    if (record.busy) return;
    record.busy = true;
    record.error = null;
    notifyListeners();
    try {
      await action();
    } catch (e) {
      record.error = e.toString();
      // Falha ao pausar/cancelar não deve fingir que o download parou.
      if (record.state == DownloadState.preparing) {
        record.state = DownloadState.error;
      }
    } finally {
      record.busy = false;
      try {
        await _store!.save();
      } catch (e) {
        error = 'Falha ao salvar o estado: $e';
      }
      if (!_closed) notifyListeners();
    }
  }

  Future<void> start(DownloadRecord record) => _action(record, () async {
        if (record.running || record.state == DownloadState.completed) return;
        if (record.state != DownloadState.paused) {
          record.analysisElapsed = Duration.zero;
        }
        record.analysisUpdatedAt = _now();
        record.receivedData = record.downloadedBytes > 0;
        if (record.gid != null && record.state == DownloadState.paused) {
          await engine.resume(record.gid!);
        } else {
          if (record.gid != null) {
            await engine.cancel(record.gid!);
            record.gid = null;
          }
          record.state = DownloadState.preparing;
          notifyListeners();
          final path = record.torrentFiles.firstWhere(
              (path) => File(path).existsSync(),
              orElse: () =>
                  throw StateError('Arquivo .torrent não encontrado.'));
          record.gid = await engine.start(path, record.destination);
          record.startedAt ??= DateTime.now();
        }
        record.state = DownloadState.downloading;
      });

  Future<void> pause(DownloadRecord record) => _action(record, () async {
        if (record.gid == null || !record.running) return;
        await engine.pause(record.gid!);
        record.state = DownloadState.paused;
        record.analysisUpdatedAt = null;
        record.speedBytes = 0;
      });

  Future<void> cancel(DownloadRecord record) => _action(record, () async {
        if (record.gid != null && record.state != DownloadState.completed) {
          await engine.cancel(record.gid!);
        }
        record.gid = null;
        record.state = DownloadState.canceled;
        record.analysisUpdatedAt = null;
        record.speedBytes = 0;
        record.peers = 0;
      });

  Future<void> delete(DownloadRecord record, {bool deletePayload = false}) =>
      _action(record, () async {
        if (record.gid != null && record.state != DownloadState.completed) {
          await engine.cancel(record.gid!);
        }
        record.gid = null;
        record.state = DownloadState.canceled;
        record.analysisUpdatedAt = null;
        record.speedBytes = 0;
        record.peers = 0;
        await _store!.delete(record, deletePayload: deletePayload);
      });

  Future<void> poll() async {
    if (_polling || _store == null || _closed) return;
    if (!items.any((r) => r.gid != null && !r.busy)) return;
    _polling = true;
    try {
      await Future.wait(
          items.where((r) => r.gid != null && !r.busy).map((record) async {
        final gid = record.gid!;
        try {
          final status = await engine.status(gid);
          if (record.busy ||
              record.gid != gid ||
              !_store!.records.containsKey(record.id)) {
            return;
          }
          int number(String key) => int.tryParse('${status[key] ?? 0}') ?? 0;
          record.totalBytes = number('totalLength');
          record.downloadedBytes = number('completedLength');
          record.speedBytes = number('downloadSpeed');
          record.peers = number('connections');
          if (record.downloadedBytes > 0 || record.speedBytes > 0) {
            record.receivedData = true;
            record.analysisUpdatedAt = null;
          }
          switch (status['status']) {
            case 'active':
              record.state = DownloadState.downloading;
              break;
            case 'waiting':
              record.state = DownloadState.queued;
              break;
            case 'paused':
              record.state = DownloadState.paused;
              record.speedBytes = 0;
              break;
            case 'complete':
              record.state = DownloadState.completed;
              record.downloadedBytes = record.totalBytes;
              record.completedAt ??= DateTime.now();
              record.speedBytes = 0;
              record.gid = null;
              break;
            case 'removed':
              record.state = DownloadState.canceled;
              record.gid = null;
              break;
            case 'error':
              record.state = DownloadState.error;
              record.error =
                  status['errorMessage'] as String? ?? 'Falha no download.';
              record.speedBytes = 0;
              break;
          }
          if (status['status'] == 'active' && record.waitingForData) {
            final now = _now();
            final previous = record.analysisUpdatedAt;
            if (previous != null && now.isAfter(previous)) {
              record.analysisElapsed += now.difference(previous);
            }
            record.analysisUpdatedAt = now;
            if (record.analysisElapsed >=
                DownloadRecord.analysisDuration +
                    DownloadRecord.finalCheckDuration) {
              await _action(record, () async {
                await engine.cancel(gid);
                record.gid = null;
                record.analysisUpdatedAt = null;
                record.state = DownloadState.error;
                record.speedBytes = 0;
                record.peers = 0;
                record.error = 'Nenhum dado recebido após 5 minutos de análise '
                    'e 3 minutos de verificação final. Tente iniciar novamente.';
              });
            }
          } else if (status['status'] != 'active') {
            record.analysisUpdatedAt = null;
          }
        } catch (e) {
          if (!record.busy &&
              record.gid == gid &&
              _store!.records.containsKey(record.id)) {
            record.error = 'Não foi possível consultar o download: $e';
          }
        }
      }));
      await _store!.save();
    } catch (e) {
      error = 'Falha ao salvar Downloads: $e';
    } finally {
      _polling = false;
      if (!_closed) notifyListeners();
    }
  }

  Future<void> shutdown() async {
    _closed = true;
    _timer?.cancel();
    _watchDebounce?.cancel();
    await _watch?.cancel();
    for (final task in _preparationTasks.values.toList()) {
      task.cancel();
    }
    for (final job in _preparationJobs.values.toList()) {
      try {
        await job;
      } catch (_) {}
    }
    // Finaliza consultas/gravações já iniciadas antes do último salvamento.
    while (_polling || _scanning) {
      await Future<void>.delayed(const Duration(milliseconds: 10));
    }
    for (final record in items.where((r) => r.running)) {
      if (record.gid != null) {
        try {
          await engine.pause(record.gid!);
        } catch (_) {}
      }
      record.state = DownloadState.paused;
      record.speedBytes = 0;
    }
    try {
      await _store?.save();
    } finally {
      await engine.close();
    }
  }
}
