import 'dart:async';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/catalogo_controller.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/catalogo_scraper.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/diagnostico_catalogo.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/gamestorrents_scraper.dart';

/// Faz o scraper real falhar do jeito pedido, sem tocar a rede.
GamesTorrentsScraper _scraperQue(Future<http.Response> Function() resposta) =>
    GamesTorrentsScraper(client: MockClient((_) => resposta()));

Future<DiagnosticoCatalogo> _falhaAoCarregar(
    GamesTorrentsScraper scraper) async {
  try {
    await scraper.carregar(scraper.catalogo);
  } on ErroCatalogo catch (erro) {
    expect(erro.diagnostico, isNotNull,
        reason: 'toda falha precisa de um código para o cliente relatar');
    return erro.diagnostico!;
  }
  fail('esperava uma falha de catálogo');
}

void main() {
  group('classificação das falhas', () {
    test('DNS bloqueado pelo provedor não vira "sem internet"', () async {
      final causa = await _falhaAoCarregar(_scraperQue(() =>
          throw const SocketException(
              'Failed host lookup: www.gamestorrents.app')));
      expect(causa.falha, FalhaCatalogo.dnsBloqueado);
      expect(causa.codigo, 'LOJA-DNSBLOQUEADO');
      // Chegar a esta mensagem significa que o contorno automático também
      // falhou, então ela não manda mais o cliente mexer no DNS da máquina.
      expect(causa.mensagem, contains('rota alternativa'));
      expect(causa.mensagem, contains('4G'));
      expect(causa.mensagem, isNot(contains('1.1.1.1')));
    });

    test('DNS embrulhado em ClientException pelo pacote http', () async {
      final causa = await _falhaAoCarregar(_scraperQue(() =>
          throw http.ClientException(
              'Failed host lookup: www.gamestorrents.app')));
      expect(causa.falha, FalhaCatalogo.dnsBloqueado);
    });

    test('conexão recusada é rede/firewall, não DNS', () async {
      final causa = await _falhaAoCarregar(
          _scraperQue(() => throw const SocketException('Connection refused')));
      expect(causa.falha, FalhaCatalogo.semRede);
      expect(causa.mensagem, contains('firewall'));
    });

    test('TLS recusado aponta antivírus com inspeção de HTTPS', () async {
      final causa = await _falhaAoCarregar(
          _scraperQue(() => throw const HandshakeException('CERTIFICATE')));
      expect(causa.falha, FalhaCatalogo.tlsBloqueado);
      expect(causa.mensagem, contains('antivírus'));
    });

    test('tempo esgotado tem mensagem própria', () async {
      final causa = await _falhaAoCarregar(
          _scraperQue(() => throw TimeoutException('depois de 25s')));
      expect(causa.falha, FalhaCatalogo.tempoEsgotado);
    });

    test('403 é bloqueio por IP/Cloudflare, não falta de conexão', () async {
      final causa = await _falhaAoCarregar(
          _scraperQue(() async => http.Response('', 403)));
      expect(causa.falha, FalhaCatalogo.acessoRecusado);
      expect(causa.status, 403);
      expect(causa.mensagem, contains('Cloudflare'));
      expect(causa.mensagem, contains('VPN'));
    });

    test('429 pede espera; 451 informa bloqueio legal', () async {
      expect((await _falhaAoCarregar(_scraperQue(() async =>
              http.Response('', 429))))
          .falha, FalhaCatalogo.excessoDePedidos);
      expect((await _falhaAoCarregar(_scraperQue(() async =>
              http.Response('', 451))))
          .falha, FalhaCatalogo.bloqueioLegal);
    });

    test('5xx diz que o problema não é do computador do cliente', () async {
      final causa = await _falhaAoCarregar(
          _scraperQue(() async => http.Response('', 503)));
      expect(causa.falha, FalhaCatalogo.siteIndisponivel);
      expect(causa.mensagem, contains('Não é problema do seu computador'));
    });

    test('página irreconhecível guarda o título, que denuncia o bloqueio',
        () async {
      final causa = await _falhaAoCarregar(_scraperQue(() async =>
          http.Response(
              '<html><head><title>Acesso bloqueado pela operadora</title>'
              '</head><body>nada aqui</body></html>',
              200,
              headers: const {'content-type': 'text/html; charset=utf-8'})));
      expect(causa.falha, FalhaCatalogo.estruturaMudou);
      expect(causa.detalhe, contains('Acesso bloqueado pela operadora'));
      expect(causa.detalhe, contains('article.game-card'));
    });

    test('endereço fora da fonte é recusado antes da rede', () async {
      final scraper = GamesTorrentsScraper(
          client: MockClient((_) async => throw StateError('não deve pedir')));
      addTearDown(scraper.dispose);
      try {
        await scraper.carregar(Uri.parse('https://exemplo.com/x/'));
        fail('esperava recusa');
      } on ErroCatalogo catch (erro) {
        expect(erro.diagnostico!.falha, FalhaCatalogo.enderecoInvalido);
      }
    });
  });

  group('relatório para o suporte', () {
    test('traz código, endereço, HTTP e detalhe em linhas separadas', () {
      final causa = DiagnosticoCatalogo.doStatus(403,
          endereco: Uri.parse('https://www.gamestorrents.app/pt-br/jogos-pc/'));
      final linhas = causa.relatorio.split('\n');
      expect(linhas.first, 'Código: LOJA-ACESSORECUSADO');
      expect(causa.relatorio, contains('HTTP: 403'));
      expect(causa.relatorio, contains('gamestorrents.app'));
      expect(causa.relatorio, contains('Detalhe:'));
      expect(causa.relatorio, contains('Quando: '));
    });

    test('toda falha tem código distinto e mensagem não vazia', () {
      final vistos = <String>{};
      for (final falha in FalhaCatalogo.values) {
        final causa = DiagnosticoCatalogo(
            falha: falha, mensagem: 'm', detalhe: 'd');
        expect(vistos.add(causa.codigo), isTrue, reason: falha.name);
      }
      expect(vistos.length, FalhaCatalogo.values.length);
    });
  });

  group('controller', () {
    test('guarda o diagnóstico e o registra uma vez por falha', () async {
      final registrados = <DiagnosticoCatalogo>[];
      final controller = CatalogoController(
          _scraperQue(() async => http.Response('', 403)),
          registrarFalha: (d) async => registrados.add(d));
      addTearDown(controller.dispose);

      await controller.atualizar();
      expect(controller.diagnostico!.falha, FalhaCatalogo.acessoRecusado);
      expect(controller.erro, controller.diagnostico!.mensagem);
      expect(registrados.length, 1);

      await controller.tentarNovamente();
      expect(registrados.length, 2);
    });

    test('uma tentativa bem-sucedida limpa o diagnóstico anterior', () async {
      var falhar = true;
      final controller = CatalogoController(
          _scraperQue(() async => falhar
              ? http.Response('', 500)
              : http.Response(
                  File('test/fixtures/gamestorrents_catalogo.html')
                      .readAsStringSync(),
                  200,
                  headers: const {'content-type': 'text/html; charset=utf-8'})),
          registrarFalha: (_) async {});
      addTearDown(controller.dispose);

      await controller.atualizar();
      expect(controller.diagnostico, isNotNull);

      falhar = false;
      await controller.tentarNovamente();
      expect(controller.diagnostico, isNull);
      expect(controller.erro, isNull);
      expect(controller.jogos, isNotEmpty);
    });

    test('falha fora do contrato ainda recebe código, sem travar a tela',
        () async {
      final registrados = <DiagnosticoCatalogo>[];
      final controller = CatalogoController(
          _scraperQue(() => throw ArgumentError('surpresa')),
          registrarFalha: (d) async => registrados.add(d));
      addTearDown(controller.dispose);

      await controller.atualizar();
      expect(controller.diagnostico, isNotNull);
      expect(controller.erro, isNotNull);
      expect(registrados.single.detalhe, contains('surpresa'));
      expect(controller.carregando, isFalse);
    });

    test('gravar o log não derruba a tela quando o disco recusa', () async {
      final controller = CatalogoController(
          _scraperQue(() async => http.Response('', 500)),
          registrarFalha: (_) async => throw const FileSystemException('cheio'));
      addTearDown(controller.dispose);
      await controller.atualizar();
      expect(controller.erro, isNotNull);
      expect(controller.carregando, isFalse);
    });
  });
}
