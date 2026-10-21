import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/cliente_loja.dart';

/// Falha como o provedor do cliente: o nome não resolve.
class _DnsBloqueado extends http.BaseClient {
  int tentativas = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    tentativas++;
    throw http.ClientException(
        'Failed host lookup: ${request.url.host}', request.url);
  }
}

/// Qualquer outra falha de rede, que **não** deve acionar o contorno.
class _OutraFalha extends http.BaseClient {
  int tentativas = 0;
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    tentativas++;
    throw const SocketException('Connection refused');
  }
}

class _ContornoFalso extends http.BaseClient {
  final List<http.BaseRequest> recebidos = [];
  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    recebidos.add(request);
    return http.StreamedResponse(
        Stream.value(utf8.encode('veio pelo contorno')), 200,
        request: request);
  }
}

void main() {
  setUp(() => ClienteDaLoja.contornoAtivo.value = false);
  tearDown(() => ClienteDaLoja.contornoAtivo.value = false);

  group('troca automática', () {
    test('DNS bloqueado passa para o contorno sem o cliente fazer nada',
        () async {
      final normal = _DnsBloqueado();
      final contorno = _ContornoFalso();
      final cliente = ClienteDaLoja(direto: normal, contorno: contorno);

      final resposta =
          await cliente.get(Uri.https('www.gamestorrents.app', '/pt-br/'));

      expect(resposta.statusCode, 200);
      expect(resposta.body, 'veio pelo contorno');
      expect(ClienteDaLoja.contornoAtivo.value, isTrue);
      expect(normal.tentativas, 1);
    });

    test('depois da troca ninguém mais bate no caminho bloqueado', () async {
      final normal = _DnsBloqueado();
      final contorno = _ContornoFalso();
      final cliente = ClienteDaLoja(direto: normal, contorno: contorno);

      for (var i = 0; i < 4; i++) {
        await cliente.get(Uri.https('www.gamestorrents.app', '/pagina/$i'));
      }
      // Só a primeira tentativa paga o custo da falha.
      expect(normal.tentativas, 1);
      expect(contorno.recebidos.length, 4);
    });

    test('falha que não é de DNS sobe, em vez de virar contorno', () async {
      final normal = _OutraFalha();
      final contorno = _ContornoFalso();
      final cliente = ClienteDaLoja(direto: normal, contorno: contorno);

      await expectLater(
          cliente.get(Uri.https('www.gamestorrents.app', '/pt-br/')),
          throwsA(isA<SocketException>()));
      expect(ClienteDaLoja.contornoAtivo.value, isFalse);
      expect(contorno.recebidos, isEmpty);
    });

    test('com DNS saudável o caminho normal é mantido', () async {
      final contorno = _ContornoFalso();
      final cliente = ClienteDaLoja(
          direto: MockClient((_) async => http.Response('normal', 200)),
          contorno: contorno);

      final resposta =
          await cliente.get(Uri.https('www.gamestorrents.app', '/pt-br/'));
      expect(resposta.body, 'normal');
      expect(ClienteDaLoja.contornoAtivo.value, isFalse);
      expect(contorno.recebidos, isEmpty);
    });

    test('o pedido reenviado preserva método, cabeçalhos e corpo', () async {
      final contorno = _ContornoFalso();
      final cliente =
          ClienteDaLoja(direto: _DnsBloqueado(), contorno: contorno);

      await cliente.post(Uri.https('www.gamestorrents.app', '/enviar'),
          headers: {'User-Agent': 'Chrome', 'Accept': 'text/html'},
          body: 'a=1');

      final reenviado = contorno.recebidos.single as http.Request;
      expect(reenviado.method, 'POST');
      expect(reenviado.url.path, '/enviar');
      expect(reenviado.headers['User-Agent'], 'Chrome');
      expect(reenviado.headers['Accept'], 'text/html');
      expect(reenviado.body, 'a=1');
    });
  });

  group('resolvedor DNS-over-HTTPS', () {
    test('lê os registros A da resposta JSON', () async {
      final resolvedor = ResolvedorDoH(client: MockClient((pedido) async {
        expect(pedido.url.queryParameters['name'], 'www.gamestorrents.app');
        expect(pedido.url.queryParameters['type'], 'A');
        return http.Response(
            jsonEncode({
              'Status': 0,
              'Answer': [
                {'name': 'www.gamestorrents.app', 'type': 1, 'data': '104.21.63.94'},
                {'name': 'www.gamestorrents.app', 'type': 1, 'data': '172.67.145.29'},
                // CNAME e AAAA não entram na lista de IPv4.
                {'name': 'x', 'type': 5, 'data': 'alvo.exemplo'},
              ]
            }),
            200);
      }));
      addTearDown(resolvedor.close);

      expect(await resolvedor.resolver('www.gamestorrents.app'),
          ['104.21.63.94', '172.67.145.29']);
    });

    test('o segundo resolvedor cobre a falha do primeiro', () async {
      final consultados = <String>[];
      final resolvedor = ResolvedorDoH(client: MockClient((pedido) async {
        consultados.add(pedido.url.host);
        if (pedido.url.host == ResolvedorDoH.servidores.first.host) {
          throw const SocketException('sem resposta');
        }
        return http.Response(
            jsonEncode({
              'Answer': [
                {'type': 1, 'data': '1.2.3.4'}
              ]
            }),
            200);
      }));
      addTearDown(resolvedor.close);

      expect(await resolvedor.resolver('exemplo.com'), ['1.2.3.4']);
      expect(consultados.length, 2);
    });

    test('a resposta fica em cache: uma consulta serve várias páginas',
        () async {
      var consultas = 0;
      final resolvedor = ResolvedorDoH(client: MockClient((_) async {
        consultas++;
        return http.Response(
            jsonEncode({
              'Answer': [
                {'type': 1, 'data': '1.2.3.4'}
              ]
            }),
            200);
      }));
      addTearDown(resolvedor.close);

      for (var i = 0; i < 5; i++) {
        await resolvedor.resolver('exemplo.com');
      }
      expect(consultas, 1);
    });

    test('nenhum resolvedor respondendo vira erro legível', () async {
      final resolvedor = ResolvedorDoH(
          client: MockClient((_) async => http.Response('', 502)));
      addTearDown(resolvedor.close);

      await expectLater(
          resolvedor.resolver('exemplo.com'),
          throwsA(isA<StateError>().having((e) => e.message, 'mensagem',
              contains('DNS-over-HTTPS'))));
    });

    test('nome sem registro A não vira lista vazia silenciosa', () async {
      final resolvedor = ResolvedorDoH(client: MockClient((_) async =>
          http.Response(jsonEncode({'Status': 3, 'Answer': []}), 200)));
      addTearDown(resolvedor.close);

      await expectLater(
          resolvedor.resolver('nao-existe.exemplo'), throwsA(isA<StateError>()));
    });
  });
}
