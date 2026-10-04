import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:v1_game/Downloads/aria2_engine.dart';

void main() {
  final skipNative = !Platform.isWindows ||
      Platform.environment['RUN_ARIA2_NATIVE_TEST'] != '1';
  test('aria2 instalado inicia e controla dois torrents por RPC autenticado',
      () async {
    final root = await Directory('test').createTemp('aria2-native-');
    final engine = Aria2Engine();
    addTearDown(() async {
      await engine.close();
      await root.delete(recursive: true);
    });
    Future<String> add(String name) async {
      final file = File(p.join(root.path, '$name.torrent'));
      await file.writeAsString('d4:infod6:lengthi1e4:name4:$name'
          '12:piece lengthi16384e6:pieces20:12345678901234567890ee');
      return engine.start(file.path, p.join(root.path, name));
    }

    final gids = await Future.wait([add('test'), add('next')]);
    expect(gids.toSet().length, 2);
    await engine.pause(gids.first);
    for (var attempt = 0; attempt < 30; attempt++) {
      if ((await engine.status(gids.first))['status'] == 'paused') break;
      await Future<void>.delayed(const Duration(milliseconds: 100));
    }
    expect((await engine.status(gids.first))['status'], 'paused');
    await engine.resume(gids.first);
    await engine.cancel(gids.first);
    expect((await engine.status(gids.last))['gid'], gids.last);
    await engine.cancel(gids.last);
  }, skip: skipNative);

  test('aria2 baixa conteúdo real de um webseed local até concluir', () async {
    final root = await Directory('test').createTemp('aria2-payload-');
    final seed = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final subscription = seed.listen((request) async {
      request.response.contentLength = 1;
      request.response.add([120]); // Conteúdo x.
      await request.response.close();
    });
    final engine = Aria2Engine();
    addTearDown(() async {
      await engine.close();
      await subscription.cancel();
      await seed.close(force: true);
      await root.delete(recursive: true);
    });
    final url = 'http://127.0.0.1:${seed.port}/';
    // SHA-1 de x, para que o aria2 valide efetivamente a peça recebida.
    const hash = '11f6ad8ec52a2984abaafd7c3b516503785c2072';
    final torrent = File(p.join(root.path, 'local.torrent'));
    await torrent.writeAsBytes([
      ...utf8.encode(
          'd4:infod6:lengthi1e4:name4:test12:piece lengthi16384e6:pieces20:'),
      for (var i = 0; i < hash.length; i += 2)
        int.parse(hash.substring(i, i + 2), radix: 16),
      ...utf8.encode('e8:url-list${url.length}:${url}e'),
    ]);
    final destination = p.join(root.path, 'payload');
    final gid = await engine.start(torrent.path, destination);
    Map<String, dynamic>? status;
    for (var attempt = 0; attempt < 100; attempt++) {
      status = await engine.status(gid);
      if (['complete', 'error'].contains(status['status'])) break;
      await Future<void>.delayed(const Duration(milliseconds: 150));
    }
    expect(status!['status'], 'complete', reason: '$status');
    expect(status['completedLength'], '1');
    expect(await File(p.join(destination, 'test')).readAsString(), 'x');
  }, skip: skipNative);
}
