import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'torrent_model.dart';

void _log(String message) {
  final time = DateTime.now().toIso8601String().substring(11, 19);
  debugPrint('[Torrent $time] $message');
}

class TorrentDownloadManager {
  Process? _aria2Process;
  String? _aria2Path;
  String? _gid;
  String? _saveDirectory;
  Uri? _rpcUri;
  final StringBuffer _aria2Log = StringBuffer();

  Timer? _statsTimer;

  DateTime? _downloadStartedAt;
  DateTime? _integrityCheckDeadline;
  static const _stallTimeout = Duration(minutes: 10);
  static const _integrityCheckGracePeriod = Duration(minutes: 5);

  TorrentModel _currentState = TorrentModel.initial();

  final _controller = StreamController<TorrentModel>.broadcast();
  Stream<TorrentModel> get onProgressChanged => _controller.stream;

  TorrentModel get currentState => _currentState;

  Future<void> initTask(String torrentFilePath) async {
    _log('Clique: selecionar arquivo .torrent -> $torrentFilePath');
    try {
      await _resetCurrentDownload();

      _updateState(_currentState.copyWith(
        name: p.basename(torrentFilePath),
        status: TorrentStatus.parsing,
        downloadedBytes: 0,
        totalBytes: 0,
        progress: 0.0,
        downloadSpeed: 0.0,
        peersCount: 0,
        clearErrorMessage: true,
      ));

      _log('Preparando aria2c...');
      await _ensureReady();

      _log('Lendo arquivo .torrent do disco...');
      final torrentBytes = await File(torrentFilePath).readAsBytes();
      final torrentBase64 = base64Encode(torrentBytes);

      _log('Enviando .torrent para aria2c (aria2.addTorrent)...');
      _gid = await _addTorrent(torrentBase64);
      _log('Torrent adicionado com sucesso. gid=$_gid');
      _downloadStartedAt = DateTime.now();
      _integrityCheckDeadline = null;
      _startStatsTimer();

      _updateState(_currentState.copyWith(
        saveDirectory: _saveDirectory,
        status: TorrentStatus.downloading,
        clearErrorMessage: true,
      ));
    } catch (e, stack) {
      _log('ERRO ao iniciar download do .torrent: $e');
      _log('Stack: $stack');
      _updateState(_currentState.copyWith(
        status: TorrentStatus.error,
        downloadSpeed: 0.0,
        peersCount: 0,
        errorMessage: '$e',
      ));
    }
  }

  Future<void> initMagnet(String magnetUri) async {
    _log('Clique: baixar magnet -> $magnetUri');
    try {
      await _resetCurrentDownload();

      _updateState(_currentState.copyWith(
        name: 'Magnet link',
        status: TorrentStatus.parsing,
        downloadedBytes: 0,
        totalBytes: 0,
        progress: 0.0,
        downloadSpeed: 0.0,
        peersCount: 0,
        clearErrorMessage: true,
      ));

      _log('Preparando aria2c...');
      await _ensureReady();

      _log('Enviando magnet para aria2c (aria2.addUri)...');
      _gid = await _addMagnet(magnetUri);
      _log('Magnet adicionado com sucesso. gid=$_gid');
      _downloadStartedAt = DateTime.now();
      _integrityCheckDeadline = null;
      _startStatsTimer();

      _updateState(_currentState.copyWith(
        saveDirectory: _saveDirectory,
        status: TorrentStatus.downloading,
        clearErrorMessage: true,
      ));
    } catch (e, stack) {
      _log('ERRO ao iniciar download do magnet: $e');
      _log('Stack: $stack');
      _updateState(_currentState.copyWith(
        status: TorrentStatus.error,
        downloadSpeed: 0.0,
        peersCount: 0,
        errorMessage: '$e',
      ));
    }
  }

  Future<void> start() async {
    _log('Clique: Iniciar (gid=$_gid)');
    if (_gid == null) {
      _log('Iniciar ignorado: nenhum gid ativo.');
      return;
    }

    try {
      await _unpauseWithRetry(_gid!);
      _log('Download retomado com sucesso.');
      _startStatsTimer();
      _updateState(_currentState.copyWith(
        status: TorrentStatus.downloading,
        clearErrorMessage: true,
      ));
    } catch (e, stack) {
      _log('ERRO ao iniciar/retomar download: $e');
      _log('Stack: $stack');
      _updateState(_currentState.copyWith(
        status: TorrentStatus.error,
        errorMessage: '$e',
      ));
    }
  }

  Future<void> _unpauseWithRetry(String gid) async {
    const maxAttempts = 10;
    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        await _rpc('aria2.unpause', [gid]);
        return;
      } catch (e) {
        final isTransientPause = '$e'.contains('cannot be unpaused now');
        if (!isTransientPause || attempt == maxAttempts) rethrow;
        _log('aria2 ainda finalizando o pause, tentando novamente ($attempt/$maxAttempts)...');
        await Future<void>.delayed(const Duration(milliseconds: 400));
      }
    }
  }

  Future<void> pause() async {
    _log('Clique: Pausar (gid=$_gid)');
    if (_gid == null) {
      _log('Pausar ignorado: nenhum gid ativo.');
      return;
    }

    try {
      await _rpc('aria2.pause', [_gid]);
      _log('Download pausado com sucesso.');
    } catch (e, stack) {
      _log('ERRO ao pausar download: $e');
      _log('Stack: $stack');
    }

    _stopStatsTimer();
    _updateState(_currentState.copyWith(
      status: TorrentStatus.paused,
      downloadSpeed: 0.0,
    ));
  }

  Future<void> stop() async {
    _log('Clique: Parar (gid=$_gid)');
    if (_gid != null) {
      try {
        await _rpc('aria2.forceRemove', [_gid]);
        _log('Download removido do aria2c com sucesso.');
      } catch (e, stack) {
        _log('ERRO ao remover download do aria2c: $e');
        _log('Stack: $stack');
      }
    }

    _gid = null;
    _downloadStartedAt = null;
    _integrityCheckDeadline = null;
    _stopStatsTimer();
    _updateState(_currentState.copyWith(
      status: TorrentStatus.paused,
      downloadSpeed: 0.0,
      peersCount: 0,
    ));
  }

  Future<void> _ensureReady() async {
    _saveDirectory ??= await _defaultSaveDirectory();
    _log('Pasta de destino: $_saveDirectory');

    _aria2Path ??= await _findAria2Executable();
    if (_aria2Path == null) {
      _log('ERRO: aria2c nao encontrado no sistema.');
      throw 'aria2c nao encontrado. Instale com: winget install aria2.aria2';
    }
    _log('aria2c encontrado em: $_aria2Path');

    if (_aria2Process != null && _rpcUri != null) {
      _log('aria2c ja estava rodando, reaproveitando processo (rpc=$_rpcUri).');
      return;
    }

    final port = await _findOpenPort();
    _rpcUri = Uri.parse('http://127.0.0.1:$port/jsonrpc');
    _log('Iniciando processo aria2c na porta RPC $port...');
    _aria2Log.clear();
    _aria2Process = await Process.start(
      _aria2Path!,
      [
        '--enable-rpc=true',
        '--rpc-listen-all=false',
        '--rpc-listen-port=$port',
        '--dir=$_saveDirectory',
        '--continue=true',
        '--check-integrity=true',
        '--enable-dht=true',
        '--enable-peer-exchange=true',
        '--bt-enable-lpd=true',
        '--bt-save-metadata=true',
        '--seed-time=0',
        '--summary-interval=0',
        '--console-log-level=warn',
      ],
      runInShell: false,
    );

    _log('Processo aria2c iniciado (pid=${_aria2Process!.pid}).');
    _aria2Process!.stdout.drain<void>();
    _aria2Process!.stderr.transform(utf8.decoder).listen(_aria2Log.write);

    _log('Aguardando aria2c responder no RPC...');
    await _waitForRpc();
    _log('aria2c pronto e respondendo no RPC.');
  }

  Future<String> _addTorrent(String torrentBase64) async {
    final result = await _rpc('aria2.addTorrent', [
      torrentBase64,
      <String>[],
      _downloadOptions(),
    ]);
    return result as String;
  }

  Future<String> _addMagnet(String magnetUri) async {
    if (!magnetUri.trim().startsWith('magnet:')) {
      _log('ERRO: texto informado nao e um magnet valido.');
      throw 'Magnet invalido.';
    }

    final result = await _rpc('aria2.addUri', [
      [magnetUri.trim()],
      _downloadOptions(),
    ]);
    return result as String;
  }

  Map<String, String> _downloadOptions() {
    return {
      'dir': _saveDirectory!,
      'continue': 'true',
      'check-integrity': 'true',
      'bt-save-metadata': 'true',
      'seed-time': '0',
    };
  }

  void _startStatsTimer() {
    _stopStatsTimer();
    _statsTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _refreshStatus();
    });
    _refreshStatus();
  }

  Future<void> _refreshStatus() async {
    if (_gid == null) return;

    try {
      final status = await _rpc('aria2.tellStatus', [
        _gid,
        [
          'gid',
          'status',
          'totalLength',
          'completedLength',
          'downloadSpeed',
          'connections',
          'errorMessage',
          'files',
          'bittorrent',
        ],
      ]) as Map;

      final total = int.tryParse('${status['totalLength'] ?? 0}') ?? 0;
      final completed = int.tryParse('${status['completedLength'] ?? 0}') ?? 0;
      final speed = int.tryParse('${status['downloadSpeed'] ?? 0}') ?? 0;
      final peers = int.tryParse('${status['connections'] ?? 0}') ?? 0;
      final progress = total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0;
      final ariaStatus = '${status['status'] ?? ''}';
      final name = _statusName(status) ?? _currentState.name;

      if (ariaStatus == 'complete') {
        _log('Download concluido: $name ($total bytes).');
        _stopStatsTimer();
        _updateState(_currentState.copyWith(
          name: name,
          totalBytes: total,
          downloadedBytes: total,
          progress: 1.0,
          downloadSpeed: 0.0,
          peersCount: 0,
          status: TorrentStatus.completed,
          clearErrorMessage: true,
        ));
        return;
      }

      if (ariaStatus == 'error' || ariaStatus == 'removed') {
        _log('ERRO reportado pelo aria2c: ${status['errorMessage'] ?? 'Download interrompido.'}');
        _stopStatsTimer();
        _updateState(_currentState.copyWith(
          name: name,
          totalBytes: total,
          downloadedBytes: completed,
          progress: progress,
          downloadSpeed: 0.0,
          peersCount: 0,
          status: TorrentStatus.error,
          errorMessage: '${status['errorMessage'] ?? 'Download interrompido.'}',
        ));
        return;
      }

      if (completed == 0 && ariaStatus != 'paused' && _downloadStartedAt != null) {
        final elapsed = DateTime.now().difference(_downloadStartedAt!);

        if (_integrityCheckDeadline == null && elapsed >= _stallTimeout) {
          _integrityCheckDeadline = DateTime.now().add(_integrityCheckGracePeriod);
          _log('Sem progresso apos 10 minutos (ainda em 0%). Verificando integridade do arquivo por mais 5 minutos...');
        } else if (_integrityCheckDeadline != null &&
            DateTime.now().isAfter(_integrityCheckDeadline!)) {
          _log('ERRO: nenhum progresso mesmo apos verificacao de integridade (15min no total). Cancelando download.');
          await _cancelStalledDownload();
          return;
        }
      }

      _updateState(_currentState.copyWith(
        name: name,
        saveDirectory: _saveDirectory,
        totalBytes: total,
        downloadedBytes: completed,
        progress: progress,
        downloadSpeed: speed / 1024.0,
        peersCount: peers,
        status: ariaStatus == 'paused'
            ? TorrentStatus.paused
            : (_integrityCheckDeadline != null
                ? TorrentStatus.checkingIntegrity
                : TorrentStatus.downloading),
        clearErrorMessage: true,
      ));
    } catch (e, stack) {
      _log('ERRO ao consultar status do download: $e');
      _log('Stack: $stack');
      _updateState(_currentState.copyWith(
        status: TorrentStatus.error,
        downloadSpeed: 0.0,
        errorMessage: '$e',
      ));
    }
  }

  Future<void> _cancelStalledDownload() async {
    final gid = _gid;
    if (gid != null) {
      try {
        await _rpc('aria2.forceRemove', [gid]);
      } catch (e) {
        _log('Aviso: falha ao remover gid travado do aria2c: $e');
      }
    }

    _gid = null;
    _downloadStartedAt = null;
    _integrityCheckDeadline = null;
    _stopStatsTimer();
    _updateState(_currentState.copyWith(
      status: TorrentStatus.error,
      downloadSpeed: 0.0,
      peersCount: 0,
      errorMessage:
          'Nenhum progresso apos 15 minutos (10min parado em 0% + 5min de verificacao de integridade). '
          'O arquivo pode nao ter seeds/peers ativos ou estar corrompido.',
    ));
  }

  String? _statusName(Map status) {
    final bittorrent = status['bittorrent'];
    if (bittorrent is Map) {
      final info = bittorrent['info'];
      if (info is Map && info['name'] != null) return '${info['name']}';
    }

    final files = status['files'];
    if (files is List && files.isNotEmpty) {
      final first = files.first;
      if (first is Map && first['path'] != null) {
        final path = '${first['path']}';
        if (path.isNotEmpty) return p.basename(path);
      }
    }

    return null;
  }

  Future<dynamic> _rpc(String method, List<dynamic> params) async {
    if (_rpcUri == null) throw 'RPC do aria2 nao foi inicializado.';

    final body = jsonEncode({
      'jsonrpc': '2.0',
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'method': method,
      'params': params,
    });

    final client = HttpClient();
    try {
      final bodyBytes = utf8.encode(body);
      final request = await client.postUrl(_rpcUri!);
      request.headers.contentType = ContentType.json;
      request.headers.contentLength = bodyBytes.length;
      request.add(bodyBytes);

      final response = await request.close().timeout(const Duration(seconds: 8));
      final responseBody = await response.transform(utf8.decoder).join();
      if (responseBody.trim().isEmpty) {
        _log('ERRO RPC ($method): resposta vazia do aria2c.');
        throw 'aria2 respondeu vazio para $method. ${_aria2LogText()}';
      }

      late final Map<String, dynamic> decoded;
      try {
        decoded = jsonDecode(responseBody) as Map<String, dynamic>;
      } catch (e) {
        _log('ERRO RPC ($method): falha ao interpretar resposta: $e');
        throw 'Falha ao interpretar resposta do aria2 para $method: $e. Resposta: $responseBody. ${_aria2LogText()}';
      }

      if (decoded['error'] != null) {
        final error = decoded['error'] as Map;
        _log('ERRO RPC ($method): ${error['message'] ?? error}');
        throw 'aria2: ${error['message'] ?? error}';
      }

      return decoded['result'];
    } on TimeoutException {
      _log('ERRO RPC ($method): tempo esgotado aguardando resposta do aria2c.');
      rethrow;
    } finally {
      client.close(force: true);
    }
  }

  Future<void> _waitForRpc() async {
    Object? lastError;
    for (var i = 0; i < 30; i++) {
      try {
        await _rpc('aria2.getVersion', []);
        return;
      } catch (e) {
        lastError = e;
        await Future<void>.delayed(const Duration(milliseconds: 200));
      }
    }

    _log('ERRO: aria2c nao respondeu ao RPC apos 30 tentativas. Ultimo erro: $lastError');
    throw 'Nao foi possivel iniciar o aria2c: $lastError. ${_aria2LogText()}';
  }

  Future<String> _defaultSaveDirectory() async {
    final documents = await getApplicationDocumentsDirectory();
    final directory = Directory(
      p.join(documents.path, 'Meus Downloads de Jogos'),
    );
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return _withTrailingSeparator(directory.path);
  }

  Future<String?> _findAria2Executable() async {
    final executableDir = File(Platform.resolvedExecutable).parent.path;
    final localAppData = Platform.environment['LOCALAPPDATA'];
    final candidates = [
      r'C:\aria2\aria2c.exe',
      r'C:\Tools\aria2\aria2c.exe',
      p.join(Directory.current.path, 'assets', 'Scripts', 'aria2c.exe'),
      p.join(Directory.current.path, 'aria2c.exe'),
      p.join(executableDir, 'aria2c.exe'),
      p.join(executableDir, 'data', 'flutter_assets', 'assets', 'Scripts', 'aria2c.exe'),
      if (localAppData != null)
        p.join(localAppData, 'Microsoft', 'WinGet', 'Links', 'aria2c.exe'),
    ];

    for (final candidate in candidates) {
      final resolved = await _resolveExecutable(candidate);
      if (resolved != null) return resolved;
    }

    if (localAppData != null) {
      final wingetPackages = p.join(localAppData, 'Microsoft', 'WinGet', 'Packages');
      final fromWingetPackages = await _findAria2InDirectory(wingetPackages);
      if (fromWingetPackages != null) return fromWingetPackages;
    }

    try {
      final result = await Process.run(
        'where',
        ['aria2c'],
        runInShell: true,
      );
      if (result.exitCode == 0) {
        final path = '${result.stdout}'.trim().split(RegExp(r'\r?\n')).first;
        if (path.isNotEmpty) return path;
      }
    } catch (_) {}

    return null;
  }

  Future<String?> _resolveExecutable(String candidate) async {
    final file = File(candidate);
    if (!await file.exists()) return null;

    try {
      final resolved = await file.resolveSymbolicLinks();
      if (await File(resolved).exists()) return resolved;
    } catch (_) {}

    return candidate;
  }

  Future<String?> _findAria2InDirectory(String directoryPath) async {
    final directory = Directory(directoryPath);
    if (!await directory.exists()) return null;

    try {
      await for (final entity in directory.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        if (p.basename(entity.path).toLowerCase() != 'aria2c.exe') continue;
        final resolved = await _resolveExecutable(entity.path);
        if (resolved != null) return resolved;
      }
    } catch (_) {}

    return null;
  }

  Future<int> _findOpenPort() async {
    final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
    final port = socket.port;
    await socket.close();
    return port;
  }

  Future<void> _resetCurrentDownload() async {
    await stop();
    _updateState(TorrentModel.initial());
  }

  void _stopStatsTimer() {
    _statsTimer?.cancel();
    _statsTimer = null;
  }

  String _withTrailingSeparator(String directory) {
    if (directory.endsWith(Platform.pathSeparator)) return directory;
    return '$directory${Platform.pathSeparator}';
  }

  String _aria2LogText() {
    final log = _aria2Log.toString().trim();
    if (log.isEmpty) return '';
    return 'Log do aria2: $log';
  }

  void _updateState(TorrentModel newState) {
    _currentState = newState;
    _controller.add(_currentState);
  }

  void dispose() {
    _stopStatsTimer();
    try {
      _aria2Process?.kill();
    } catch (_) {}
    _controller.close();
  }
}
