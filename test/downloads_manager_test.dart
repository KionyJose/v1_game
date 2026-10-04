import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:v1_game/Downloads/aria2_engine.dart';
import 'package:v1_game/Downloads/download_record.dart';
import 'package:v1_game/Downloads/download_store.dart';
import 'package:v1_game/Downloads/downloads_controller.dart';

const smallTorrent =
    'd4:infod6:lengthi1e4:name4:test12:piece lengthi16384e6:pieces20:12345678901234567890ee';

class FakeEngine implements TorrentEngine {
  final states = <String, Map<String, dynamic>>{};
  final destinations = <String>[];
  final removed = <String>[];
  bool failPause = false;
  @override
  Future<String> start(String torrentPath, String destination) async {
    final gid = 'gid-${states.length}';
    destinations.add(destination);
    states[gid] = {
      'status': 'active',
      'totalLength': '100',
      'completedLength': '25',
      'downloadSpeed': '512',
      'connections': '3'
    };
    return gid;
  }

  @override
  Future<void> pause(String gid) async {
    if (failPause) throw StateError('Falha RPC');
    states[gid]!['status'] = 'paused';
  }

  @override
  Future<void> resume(String gid) async {
    states[gid]!['status'] = 'active';
  }

  @override
  Future<void> cancel(String gid) async {
    removed.add(gid);
    states[gid]!['status'] = 'removed';
  }

  @override
  Future<Map<String, dynamic>> status(String gid) async => states[gid]!;
  @override
  Future<void> close() async {}
}

void main() {
  late Directory root;
  late DownloadStore store;
  late FakeEngine engine;
  late DownloadsController controller;
  setUp(() async {
    root = await Directory('test').createTemp('downloads-manager-');
    store = DownloadStore(
        purchases: Directory(p.join(root.path, 'purchases')),
        payloads: Directory(p.join(root.path, 'payloads')),
        indexFile: File(p.join(root.path, 'app', 'downloads.json')));
    engine = FakeEngine();
    controller =
        DownloadsController(openStore: () async => store, engine: engine);
    await controller.initialize();
  });
  tearDown(() async {
    await controller.shutdown();
    controller.dispose();
    await root.delete(recursive: true);
  });

  Future<DownloadRecord> add(String name,
      {String source = 'FitGirl Repacks'}) async {
    final path = p.join(store.purchases.path, '$name.torrent');
    await File(path)
        .writeAsString(smallTorrent.replaceFirst('4:test', '4:$name'));
    await controller.registerPurchase(path,
        sourceName: source,
        edition: 'Build 123',
        pageUrl: 'https://example.com/jogo',
        downloadUrl: 'https://example.com/download',
        releaseInfo: {'Build': '123'});
    return controller.items.last;
  }

  test(
      'Source tipado e dados persistidos ao receber torrent; duplicatas usam infoHash',
      () async {
    final item = await add('test');
    final json =
        jsonDecode(await File('${item.torrentFiles.first}.json').readAsString())
            as Map;
    expect(
        json['releaseSource'], {'type': 'fitGirl', 'name': 'FitGirl Repacks'});
    expect(json['edition'], 'Build 123');
    expect(json['download']['state'], 'ready');
    await File(p.join(store.purchases.path, 'duplicado.torrent'))
        .writeAsString(smallTorrent);
    await controller.refresh();
    expect(controller.items.length, 1);
    expect(item.torrentFiles.length, 2);
    expect(classifyReleaseSource('DODI Repacks'), ReleaseSource.dodi);
    expect(classifyReleaseSource('ElAmigos'), ReleaseSource.elAmigos);
    expect(classifyReleaseSource('Fonte nova'), ReleaseSource.other);
  });

  test('Dois downloads simultâneos têm ações e progresso independentes',
      () async {
    final first = await add('test');
    final second = await add('next');
    await Future.wait([controller.start(first), controller.start(second)]);
    expect(first.gid, isNot(second.gid));
    expect(engine.destinations.toSet().length, 2);
    await controller.poll();
    expect(first.downloadedBytes, 25);
    expect(second.peers, 3);
    await controller.pause(first);
    expect(first.state, DownloadState.paused);
    expect(second.state, DownloadState.downloading);
    await controller.start(first);
    expect(engine.destinations.length, 2);
    await controller.cancel(first);
    expect(first.state, DownloadState.canceled);
    expect(second.state, DownloadState.downloading);
    engine.states[second.gid]!['status'] = 'complete';
    await controller.poll();
    expect(second.state, DownloadState.completed);
    expect(second.completedAt, isNotNull);
  });

  test(
      'Falha ao pausar preserva estado real e restauração mantém progresso/fonte',
      () async {
    final item = await add('test');
    await controller.start(item);
    await controller.poll();
    engine.failPause = true;
    await controller.pause(item);
    expect(item.state, DownloadState.downloading);
    expect(item.error, contains('Falha RPC'));
    await store.save();
    final restored = DownloadStore(
        purchases: store.purchases,
        payloads: store.payloads,
        indexFile: store.indexFile);
    await restored.load();
    expect(restored.records[item.id]!.state, DownloadState.paused);
    expect(restored.records[item.id]!.downloadedBytes, 25);
    expect(restored.records[item.id]!.sourceType, ReleaseSource.fitGirl);
    expect(restored.records[item.id]!.gid, isNull);
  });

  test('Reiniciar erro remove o GID antigo sem afetar outra transferência',
      () async {
    final first = await add('test');
    final second = await add('next');
    await controller.start(first);
    await controller.start(second);
    final previous = first.gid!;
    engine.states[previous]!['status'] = 'error';
    engine.states[previous]!['errorMessage'] = 'Falha de conexão';
    await controller.poll();
    expect(first.state, DownloadState.error);
    await controller.start(first);
    expect(first.state, DownloadState.downloading);
    expect(first.gid, isNot(previous));
    expect(engine.removed, [previous]);
    expect(second.state, DownloadState.downloading);
  });

  test('Importações concorrentes preservam fonte e não duplicam o registro',
      () async {
    final path = p.join(store.purchases.path, 'test.torrent');
    await File(path).writeAsString(smallTorrent);
    await Future.wait([
      store.importTorrent(path),
      store.importTorrent(path, sourceName: 'DODI Repacks'),
      store.importTorrent(path),
    ]);
    expect(store.records.length, 1);
    expect(store.records.values.single.sourceType, ReleaseSource.dodi);
    await store.save();
    expect(
        jsonDecode(await File('$path.json').readAsString())['releaseSource']
            ['type'],
        'dodi');
  });

  test(
      'Excluir pode preservar conteúdo; exclusão completa fica restrita à pasta do item',
      () async {
    final first = await add('test');
    final second = await add('next');
    await Directory(first.destination).create();
    final content = File(p.join(first.destination, 'jogo.bin'));
    await content.writeAsString('dados');
    await controller.delete(first);
    expect(await content.exists(), isTrue);
    expect(controller.items.length, 1);
    await Directory(second.destination).create();
    await File(p.join(second.destination, 'jogo.bin')).writeAsString('dados');
    await controller.delete(second, deletePayload: true);
    expect(await Directory(second.destination).exists(), isFalse);
    expect(await content.exists(), isTrue);
    await controller.refresh();
    expect(controller.items, isEmpty);
  });

  test('RPC real usa GIDs distintos e opções de destino independentes',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final calls = <Map>[];
    final requestLengths = <int>[];
    final subscription = server.listen((request) async {
      requestLengths.add(request.contentLength);
      final json = jsonDecode(
              await request.cast<List<int>>().transform(utf8.decoder).join())
          as Map;
      calls.add(json);
      request.response.headers.contentType = ContentType.json;
      request.response.write(jsonEncode({
        'jsonrpc': '2.0',
        'id': json['id'],
        'result': 'gid-${calls.length}'
      }));
      await request.response.close();
    });
    final rpc = Aria2Engine(
        rpcUri: Uri.parse('http://127.0.0.1:${server.port}/jsonrpc'));
    addTearDown(() async {
      await rpc.close();
      await subscription.cancel();
      await server.close(force: true);
    });
    final item = await add('test');
    final gids = await Future.wait([
      rpc.start(item.torrentFiles.first, p.join(root.path, 'first')),
      rpc.start(item.torrentFiles.first, p.join(root.path, 'second'))
    ]);
    expect(gids.toSet().length, 2);
    expect(calls.every((call) => call['method'] == 'aria2.addTorrent'), isTrue);
    expect(requestLengths.every((length) => length > 0), isTrue,
        reason:
            'O aria2 precisa de Content-Length; envio chunked impede o RPC.');
    expect(calls.map((call) => call['params'][2]['dir']).toSet().length, 2);
  });
}
