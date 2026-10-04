import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:v1_game/Tela/Tela%20loja/downloads/arquivo_torrent.dart';
import 'package:v1_game/Tela/Tela%20loja/downloads/cdp_connection.dart';
import 'package:v1_game/Tela/Tela%20loja/downloads/edge_torrent_downloader.dart';
import 'package:v1_game/Tela/Tela%20loja/downloads/torrent_download.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/jogo_detalhes.dart';

const torrentValido =
    'd4:infod6:lengthi1e4:name4:test12:piece lengthi16384e6:pieces20:12345678901234567890ee';

void main() {
  late Directory dir;
  setUp(() async {
    dir = await Directory('test').createTemp('torrent-test-');
  });
  tearDown(() async {
    if (await dir.exists()) await dir.delete(recursive: true);
  });

  test('Confirma torrent e preserva arquivo existente com mesmo nome',
      () async {
    final anterior = File(p.join(dir.path, 'jogo.torrent'));
    await anterior.writeAsString(torrentValido);
    await File(p.join(dir.path, 'guid-123')).writeAsString(torrentValido);
    final salvo =
        await ArquivoTorrent.confirmar(dir, 'guid-123', 'jogo.torrent');
    expect(p.basename(salvo), 'jogo (1).torrent');
    expect(await anterior.readAsString(), torrentValido);
    expect(await File(salvo).exists(), isTrue);
  });
  test('Arquivo parcial ou HTML recebido não produz confirmação de torrent',
      () async {
    await File(p.join(dir.path, 'guid-parcial.crdownload'))
        .writeAsString(torrentValido);
    await expectLater(
        ArquivoTorrent.confirmar(dir, 'guid-parcial', 'jogo.torrent'),
        throwsStateError);
    await File(p.join(dir.path, 'guid-html'))
        .writeAsString('<html>Erro no site</html>');
    await expectLater(
        ArquivoTorrent.confirmar(dir, 'guid-html', 'jogo.torrent'),
        throwsStateError);
    expect(await File(p.join(dir.path, 'jogo.torrent')).exists(), isFalse);
  });
  test('Nome e identificador não permitem escapar da pasta de destino',
      () async {
    expect(ArquivoTorrent.nomeSeguro('../../jogo'), '.._.._jogo.torrent');
    expect(ArquivoTorrent.nomeSeguro('CON.torrent'), '_CON.torrent');
    await expectLater(ArquivoTorrent.confirmar(dir, '../outro', 'jogo.torrent'),
        throwsStateError);
  });

  test(
      'Fluxo do navegador define destino, dispara submit e espera conclusão antes de confirmar',
      () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    final sockets = <WebSocket>[];
    final chamadas = <String>[];
    String? destino;
    final endpoint = server.listen((request) async {
      final ws = await WebSocketTransformer.upgrade(request);
      sockets.add(ws);
      ws.listen((raw) async {
        final pedido = jsonDecode(raw as String) as Map<String, dynamic>;
        final metodo = pedido['method'] as String;
        chamadas.add(metodo);
        var result = <String, dynamic>{};
        if (metodo == 'Browser.setDownloadBehavior') {
          destino = pedido['params']['downloadPath'] as String;
          expect(pedido['params']['behavior'], 'allowAndName');
          expect(pedido['params']['eventsEnabled'], isTrue);
        } else if (metodo == 'Target.getTargets') {
          result = {
            'targetInfos': [
              {'type': 'page', 'targetId': 'teste'}
            ]
          };
        } else if (metodo == 'Target.attachToTarget') {
          result = {'sessionId': 'sessao-teste'};
        } else if (metodo == 'Runtime.evaluate') {
          result = {
            'result': {
              'type': 'object',
              'value': {'estado': 'pronta'}
            }
          };
        }
        ws.add(jsonEncode({'id': pedido['id'], 'result': result}));
        if (metodo == 'Runtime.evaluate' &&
            (pedido['params']['expression'] as String)
                .contains('requestSubmit()')) {
          ws.add(jsonEncode({
            'method': 'Browser.downloadWillBegin',
            'params': {
              'guid': 'outra-compra',
              'suggestedFilename': 'outro.torrent',
              'url': 'blob:https://www.gamestorrents.app/outro'
            }
          }));
          ws.add(jsonEncode({
            'method': 'Browser.downloadWillBegin',
            'params': {
              'guid': 'guid-confirmado',
              'suggestedFilename': 'jogo.torrent',
              'url': 'blob:https://www.gamestorrents.app/arquivo'
            }
          }));
          await File(p.join(destino!, 'guid-confirmado.crdownload'))
              .writeAsString(torrentValido);
          ws.add(jsonEncode({
            'method': 'Browser.downloadProgress',
            'params': {
              'guid': 'guid-confirmado',
              'state': 'inProgress',
              'receivedBytes': 10,
              'totalBytes': torrentValido.length
            }
          }));
          await Future<void>.delayed(const Duration(milliseconds: 100));
          expect(
              await File(p.join(destino!, 'jogo.torrent')).exists(), isFalse);
          await File(p.join(destino!, 'guid-confirmado.crdownload'))
              .rename(p.join(destino!, 'guid-confirmado'));
          ws.add(jsonEncode({
            'method': 'Browser.downloadProgress',
            'params': {
              'guid': 'guid-confirmado',
              'state': 'completed',
              'receivedBytes': torrentValido.length,
              'totalBytes': torrentValido.length
            }
          }));
        }
      });
    });
    addTearDown(() async {
      for (final socket in sockets) {
        await socket.close();
      }
      await endpoint.cancel();
      await server.close(force: true);
    });
    final downloader = EdgeTorrentDownloader(
        localizarDownloads: () async => dir,
        conectarNavegador: () =>
            CdpConnection.conectar(Uri.parse('ws://127.0.0.1:${server.port}')));
    final mensagens = <ProgressoTorrent>[];
    final salvo = await downloader.baixar(
        EtapaDownload(
            pagina: Uri.parse(
                'https://www.gamestorrents.app/pt-br/download/${'a' * 32}/'),
            nomeArquivo: 'jogo.torrent',
            tamanhoArquivo: '',
            instrucao: '',
            exigeJavaScript: true,
            podeExigirCaptcha: true),
        mensagens.add);
    expect(p.dirname(salvo), p.join(dir.path, 'games torrent compra'));
    expect(await File(salvo).exists(), isTrue);
    expect(chamadas, contains('Browser.cancelDownload'));
    expect(chamadas, contains('Browser.close'));
    expect(mensagens.any((m) => m.fracao != null), isTrue);
  }, skip: !Platform.isWindows);
}
