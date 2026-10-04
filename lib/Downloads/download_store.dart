import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:dtorrent_parser/dtorrent_parser.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../Tela/Tela loja/downloads/arquivo_torrent.dart';
import 'download_record.dart';

class DownloadStore {
  final Directory purchases;
  final Directory payloads;
  final File indexFile;
  final Map<String, DownloadRecord> records = {};
  Future<void> _writes = Future.value();
  Future<void> _operations = Future.value();

  Future<T> _serialize<T>(Future<T> Function() operation) {
    final result = Completer<T>();
    _operations = _operations.then((_) async {
      try {
        result.complete(await operation());
      } catch (error, stack) {
        result.completeError(error, stack);
      }
    });
    return result.future;
  }

  DownloadStore(
      {required this.purchases,
      required this.payloads,
      required this.indexFile});

  static Future<DownloadStore> openDefault() async {
    final downloads = await getDownloadsDirectory();
    if (downloads == null) throw StateError('Pasta Downloads não encontrada.');
    final app = await getApplicationSupportDirectory();
    return DownloadStore(
        purchases: Directory(p.join(downloads.path, ArquivoTorrent.pasta)),
        payloads: Directory(p.join(downloads.path, 'games torrent downloads')),
        indexFile: File(p.join(app.path, 'downloads', 'downloads.json')));
  }

  Future<void> load() async {
    await purchases.create(recursive: true);
    await payloads.create(recursive: true);
    if (await indexFile.exists()) {
      // Não sobrescrever silenciosamente um índice danificado.
      final json =
          jsonDecode(await indexFile.readAsString()) as Map<String, dynamic>;
      for (final item in json['downloads'] as List) {
        final record =
            DownloadRecord.fromJson((item as Map).cast<String, dynamic>());
        record.destination = p.join(payloads.path, record.id);
        if (record.running) record.state = DownloadState.paused;
        records[record.id] = record;
      }
    }
    await scan();
  }

  Future<void> scan() async {
    await for (final file in purchases.list(followLinks: false)) {
      if (file is! File || p.extension(file.path).toLowerCase() != '.torrent') {
        continue;
      }
      try {
        await importTorrent(file.path);
      } catch (_) {
        // Arquivo ainda incompleto ou inválido não vira um download pronto.
      }
    }
  }

  Future<DownloadRecord> importTorrent(String path,
          {String? sourceName,
          String? edition,
          String? pageUrl,
          String? downloadUrl,
          Map<String, String>? releaseInfo}) =>
      _serialize(() => _importTorrent(path,
          sourceName: sourceName,
          edition: edition,
          pageUrl: pageUrl,
          downloadUrl: downloadUrl,
          releaseInfo: releaseInfo));

  Future<DownloadRecord> _importTorrent(String path,
      {String? sourceName,
      String? edition,
      String? pageUrl,
      String? downloadUrl,
      Map<String, String>? releaseInfo}) async {
    final absolute = p.normalize(p.absolute(path));
    if (!p.isWithin(p.absolute(purchases.path), absolute)) {
      throw StateError('O torrent deve estar na pasta de compras.');
    }
    final parsed = await Torrent.parseFromFile(absolute);
    final id = parsed.infoHash.toLowerCase();
    DownloadRecord? record = records[id];
    if (record == null) {
      final sidecar = File('$absolute.json');
      if (await sidecar.exists()) {
        try {
          final saved = DownloadRecord.fromJson(
              jsonDecode(await sidecar.readAsString()) as Map<String, dynamic>);
          if (saved.id == id) {
            saved.destination = p.join(payloads.path, id);
            if (saved.running) saved.state = DownloadState.paused;
            record = saved;
          }
        } catch (_) {
          /* Metadados antigos não impedem importação do torrent válido. */
        }
      }
      record ??= DownloadRecord(
          id: id,
          name: parsed.name,
          torrentFiles: [],
          destination: p.join(payloads.path, id),
          acquiredAt: DateTime.now(),
          totalBytes: parsed.length);
      records[id] = record;
    }
    if (!record.torrentFiles.contains(absolute)) {
      record.torrentFiles.add(absolute);
    }
    if (sourceName != null) record.sourceName = sourceName;
    if (edition != null) record.edition = edition;
    if (pageUrl != null) record.pageUrl = pageUrl;
    if (downloadUrl != null) record.downloadUrl = downloadUrl;
    if (releaseInfo != null) record.releaseInfo = Map.of(releaseInfo);
    return record;
  }

  Future<void> _queueWrite(Future<void> Function() operation) {
    final previous = _writes;
    _writes = () async {
      try {
        await previous;
      } catch (_) {/* Uma falha anterior pode ser tentada novamente. */}
      await operation();
    }();
    return _writes;
  }

  Future<void> save() => _queueWrite(_persist);

  Future<void> _persist() async {
    final snapshots = records.values.map((r) => r.toJson()).toList();
    await _writeJson(indexFile, {'schemaVersion': 1, 'downloads': snapshots});
    for (final record in snapshots) {
      for (final path in (record['torrentFiles'] as List).cast<String>()) {
        if (p.isWithin(p.absolute(purchases.path), p.absolute(path)) &&
            await File(path).exists()) {
          await _writeJson(File('$path.json'), record);
        }
      }
    }
  }

  Future<void> _writeJson(File file, Object json) async {
    await file.parent.create(recursive: true);
    final temporary = File('${file.path}.tmp');
    await temporary.writeAsString(
        const JsonEncoder.withIndent('  ').convert(json),
        flush: true);
    await temporary.rename(file.path);
  }

  Future<void> delete(DownloadRecord record, {bool deletePayload = false}) =>
      _serialize(() =>
          _queueWrite(() => _delete(record, deletePayload: deletePayload)));

  Future<void> _delete(DownloadRecord record,
      {bool deletePayload = false}) async {
    // Destino calculado pelo sistema; nunca excluir recursivamente um caminho vindo do JSON/RPC.
    final directory = Directory(p.join(payloads.path, record.id));
    if (deletePayload && await directory.exists()) {
      final root = await payloads.resolveSymbolicLinks();
      final resolved = await directory.resolveSymbolicLinks();
      if (!p.isWithin(root, resolved)) {
        throw StateError('O destino aponta para fora da pasta gerenciada.');
      }
      await directory.delete(recursive: true);
    }
    for (final path in record.torrentFiles) {
      if (!p.isWithin(p.absolute(purchases.path), p.absolute(path))) continue;
      for (final file in [File(path), File('$path.json')]) {
        if (await file.exists()) await file.delete();
      }
    }
    records.remove(record.id);
    await _persist();
  }
}
