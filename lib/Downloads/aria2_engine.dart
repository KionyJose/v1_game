import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as p;

abstract class TorrentEngine {
  Future<String> start(String torrentPath, String destination);
  Future<void> pause(String gid);
  Future<void> resume(String gid);
  Future<void> cancel(String gid);
  Future<Map<String, dynamic>> status(String gid);
  Future<void> close();
}

class Aria2RpcException implements Exception {
  final int? code;
  final String message;
  const Aria2RpcException(this.code, this.message);
  bool get missingGid => RegExp(r'GID[#\s]+.+\s+is not found|No such download',
          caseSensitive: false)
      .hasMatch(message);
  bool get removalPending =>
      message.toLowerCase().contains('cannot be removed');
  @override
  String toString() => 'aria2: $message';
}

/// Um único processo aria2, vários GIDs independentes e RPC restrito a loopback.
class Aria2Engine implements TorrentEngine {
  Process? _process;
  Uri? _uri;
  String? _secret;
  Future<void>? _boot;
  final List<String> _processLog = [];
  final HttpClient _client = HttpClient()
    ..connectionTimeout = const Duration(seconds: 5);
  Aria2Engine({Uri? rpcUri}) : _uri = rpcUri;

  Future<void> _ready() async {
    if (_boot != null) {
      await _boot;
      return;
    }
    if (_uri != null) return;
    await (_boot ??= _launch());
  }

  Future<void> _launch() async {
    Object? lastError;
    int? exitCode;
    try {
      final executable = await _findAria2Executable();
      if (executable == null) {
        throw StateError(
            'aria2c não encontrado. Instale aria2 para iniciar os downloads.');
      }
      final socket = await ServerSocket.bind(InternetAddress.loopbackIPv4, 0);
      final port = socket.port;
      await socket.close();
      _secret = List.generate(
          24,
          (_) => Random.secure()
              .nextInt(256)
              .toRadixString(16)
              .padLeft(2, '0')).join();
      _processLog.clear();
      _process = await Process.start(
          executable,
          [
            '--enable-rpc=true',
            '--rpc-listen-all=false',
            '--rpc-listen-port=$port',
            '--rpc-secret=$_secret',
            '--max-concurrent-downloads=5',
            '--check-integrity=true',
            '--seed-time=0',
            '--enable-dht=true',
            '--summary-interval=0',
            '--console-log-level=error',
          ],
          runInShell: false);
      void capture(String line) {
        // O token RPC não deve aparecer nos diagnósticos.
        _processLog.add(line.replaceAll(_secret!, '[token]'));
        if (_processLog.length > 20) _processLog.removeAt(0);
      }

      _process!.stdout
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(capture);
      _process!.stderr
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(capture);
      final startedProcess = _process!;
      startedProcess.exitCode.then((code) {
        exitCode = code;
        if (identical(_process, startedProcess)) {
          _process = null;
          _uri = null;
          _boot = null;
        }
      });
      _uri = Uri.parse('http://127.0.0.1:$port/jsonrpc');
      for (var attempt = 0; attempt < 40; attempt++) {
        if (exitCode != null) break;
        try {
          await _rpc('aria2.getVersion', []);
          return;
        } catch (error) {
          lastError = error;
          await Future<void>.delayed(const Duration(milliseconds: 150));
        }
      }
      throw StateError('aria2 não respondeu ao iniciar. '
          '${exitCode == null ? '' : 'Processo encerrado com código $exitCode. '}'
          'Último erro RPC: $lastError'
          '${_processLog.isEmpty ? '' : '\nLog aria2: ${_processLog.join('\n')}'}');
    } catch (_) {
      _process?.kill();
      _process = null;
      _uri = null;
      _boot = null;
      rethrow;
    }
  }

  @override
  Future<String> start(String torrentPath, String destination) async {
    await _ready();
    await Directory(destination).create(recursive: true);
    final bytes = await File(torrentPath).readAsBytes();
    return await _rpc('aria2.addTorrent', [
      base64Encode(bytes),
      <String>[],
      {
        'dir': p.absolute(destination),
        'check-integrity': 'true',
        'seed-time': '0',
        'allow-overwrite': 'false',
        'auto-file-renaming': 'false'
      }
    ]) as String;
  }

  @override
  Future<void> pause(String gid) async {
    await _rpc('aria2.pause', [gid]);
  }

  @override
  Future<void> resume(String gid) async {
    for (var i = 0; i < 10; i++) {
      try {
        await _rpc('aria2.unpause', [gid]);
        return;
      } catch (e) {
        if (i == 9 || !e.toString().contains('cannot be unpaused now')) rethrow;
        await Future<void>.delayed(const Duration(milliseconds: 250));
      }
    }
  }

  @override
  Future<void> cancel(String gid) async {
    // Um processo próprio encerrado já não possui transferências ativas.
    if (_uri == null && _process == null && _boot == null) return;
    bool removalRequested = false;
    for (var attempt = 0; attempt < 120; attempt++) {
      try {
        final current = await status(gid);
        if (['removed', 'complete', 'error'].contains(current['status'])) {
          // O estado pode mudar antes de o resultado entrar na lista de parados.
          await _rpc('aria2.removeDownloadResult', [gid]);
          return;
        }
        if (!removalRequested) {
          await _rpc('aria2.forceRemove', [gid]);
          removalRequested = true;
        }
      } on Aria2RpcException catch (error) {
        // Cancelar duas vezes e excluir após cancelar são operações válidas.
        if (error.missingGid) return;
        if (!error.removalPending) rethrow;
      }
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    throw StateError('O motor ainda não confirmou o cancelamento.');
  }

  @override
  Future<Map<String, dynamic>> status(String gid) async =>
      (await _rpc('aria2.tellStatus', [
        gid,
        [
          'gid',
          'status',
          'totalLength',
          'completedLength',
          'downloadSpeed',
          'numSeeders',
          'connections',
          'errorMessage',
          'bittorrent',
          'verifyIntegrityPending'
        ]
      ]) as Map)
          .cast<String, dynamic>();

  Future<dynamic> _rpc(String method, List<dynamic> params) async {
    if (_uri == null) throw StateError('Motor de downloads não inicializado.');
    final request = await _client.postUrl(_uri!);
    request.headers.contentType = ContentType.json;
    final body = utf8.encode(jsonEncode({
      'jsonrpc': '2.0',
      'id': DateTime.now().microsecondsSinceEpoch.toString(),
      'method': method,
      'params': [if (_secret != null) 'token:$_secret', ...params]
    }));
    // O servidor HTTP do aria2 precisa do tamanho explícito, como no modelo anterior.
    request.contentLength = body.length;
    request.add(body);
    final response = await request.close().timeout(const Duration(seconds: 8));
    final responseBody = await response
        .transform(utf8.decoder)
        .join()
        .timeout(const Duration(seconds: 8));
    dynamic data;
    try {
      data = jsonDecode(responseBody);
    } on FormatException {
      // Uma falha HTTP sem envelope RPC continua sendo uma falha de transporte.
    }
    // aria2 também entrega erros JSON-RPC válidos com HTTP 400.
    if (data is Map && data['error'] is Map) {
      final error = data['error'] as Map;
      throw Aria2RpcException(error['code'] as int?, '${error['message']}');
    }
    if (response.statusCode != HttpStatus.ok || data is! Map) {
      throw StateError('RPC $method: HTTP ${response.statusCode}'
          '${responseBody.isEmpty ? ', resposta vazia.' : ': $responseBody'}');
    }
    return data['result'];
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
      p.join(executableDir, 'data', 'flutter_assets', 'assets', 'Scripts',
          'aria2c.exe'),
      if (localAppData != null)
        p.join(localAppData, 'Microsoft', 'WinGet', 'Links', 'aria2c.exe'),
    ];

    for (final candidate in candidates) {
      final resolved = await _resolveExecutable(candidate);
      if (resolved != null) return resolved;
    }

    if (localAppData != null) {
      final wingetPackages =
          p.join(localAppData, 'Microsoft', 'WinGet', 'Packages');
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
      await for (final entity
          in directory.list(recursive: true, followLinks: false)) {
        if (entity is! File) continue;
        if (p.basename(entity.path).toLowerCase() != 'aria2c.exe') continue;
        final resolved = await _resolveExecutable(entity.path);
        if (resolved != null) return resolved;
      }
    } catch (_) {}

    return null;
  }

  @override
  Future<void> close() async {
    if (_process != null) {
      try {
        await _rpc('aria2.shutdown', []);
      } catch (_) {
        _process?.kill();
      }
    }
    _client.close(force: true);
  }
}
