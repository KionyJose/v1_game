import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/catalogo_scraper.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/steam_scraper.dart';

String _fixture(String nome) =>
    File('test/fixtures/$nome').readAsStringSync(encoding: utf8);

void main() {
  group('catálogo da Steam', () {
    test('JSON real: nomes, appid, capa, legenda, filtros e próxima página',
        () {
      final scraper = SteamScraper();
      addTearDown(scraper.dispose);
      final pagina = scraper.interpretar(
          _fixture('steam_busca.json'), scraper.catalogo);

      expect(pagina.jogos.length, 25);
      final primeiro = pagina.jogos.first;
      expect(primeiro.nome, 'Dota 2');
      // A ficha é montada do appid, sem o `?snr=` de rastreamento do href.
      expect(primeiro.pagina, Uri.https(SteamScraper.host, '/app/570/'));
      expect(primeiro.pagina.hasQuery, isFalse);
      expect(primeiro.imagem!.scheme, 'https');
      // A Steam não dá gênero na linha de busca; a legenda leva data e preço.
      expect(primeiro.genero, contains('2013'));
      expect(primeiro.genero, contains('Grátis'));
      expect(pagina.total, '297929 jogos');
      expect(pagina.generos['19'], 'Ação');
      expect(pagina.generos.length, SteamScraper.generosSteam.length);
      expect(pagina.proxima!.queryParameters['start'], '50');
    });

    test('paginação avança a partir do start e do count da própria URL', () {
      final scraper = SteamScraper();
      addTearDown(scraper.dispose);
      final pagina = scraper.interpretar(
          _fixture('steam_busca.json'),
          scraper.catalogo.replace(queryParameters: {
            ...scraper.catalogo.queryParameters,
            'start': '50',
            'count': '25',
          }));
      expect(pagina.proxima!.queryParameters['start'], '75');
      expect(pagina.proxima!.queryParameters['count'], '25');
    });

    test('fim do catálogo não oferece próxima página', () {
      final scraper = SteamScraper();
      addTearDown(scraper.dispose);
      final pagina = scraper.interpretar(
          jsonEncode({'total_count': 10, 'results_html': ''}),
          scraper.catalogo);
      expect(pagina.jogos, isEmpty);
      expect(pagina.proxima, isNull);
    });

    test('mudança de estrutura não é confundida com catálogo vazio', () {
      final scraper = SteamScraper();
      addTearDown(scraper.dispose);
      expect(
          () => scraper.interpretar(
              jsonEncode({
                'total_count': 500,
                'results_html': '<div class="outra_coisa">Dota 2</div>'
              }),
              scraper.catalogo),
          throwsA(isA<ErroCatalogo>()));
    });

    test('resposta que não é JSON vira erro de catálogo', () {
      final scraper = SteamScraper();
      addTearDown(scraper.dispose);
      expect(() => scraper.interpretar('<html>bloqueado</html>', scraper.catalogo),
          throwsA(isA<ErroCatalogo>()));
    });

    test('endereço fora da busca da Steam é recusado antes da rede', () async {
      final scraper = SteamScraper(
          client: MockClient((_) async => throw StateError('não deve pedir')));
      addTearDown(scraper.dispose);
      await expectLater(scraper.carregar(Uri.parse('https://exemplo.com/x')),
          throwsA(isA<ErroCatalogo>()));
    });

    test('HTTP diferente de 200 informa o código', () async {
      final scraper = SteamScraper(
          client: MockClient((_) async => http.Response('', 429)));
      addTearDown(scraper.dispose);
      await expectLater(
          scraper.carregar(scraper.catalogo),
          throwsA(isA<ErroCatalogo>().having(
              (e) => e.mensagem, 'mensagem', contains('429'))));
    });

    test('a busca manda o termo e mantém moeda e idioma', () {
      final scraper = SteamScraper();
      addTearDown(scraper.dispose);
      final uri = scraper.busca('  elden ring  ');
      expect(uri.queryParameters['term'], 'elden ring');
      expect(uri.queryParameters['cc'], 'br');
      expect(uri.queryParameters['l'], 'portuguese');
      expect(uri.queryParameters['start'], '0');
    });

    test('envia User-Agent de navegador, não o do Dart', () async {
      Map<String, String>? enviados;
      final scraper = SteamScraper(client: MockClient((request) async {
        enviados = request.headers;
        return http.Response(
            jsonEncode({'total_count': 0, 'results_html': ''}), 200);
      }));
      addTearDown(scraper.dispose);
      await scraper.carregar(scraper.catalogo);
      expect(enviados!['User-Agent'], contains('Mozilla/5.0'));
      expect(enviados!['User-Agent'], isNot(contains('Dart')));
    });
  });

  group('ficha da Steam', () {
    test('JSON real: nome, gêneros, capturas, preço e endereço da loja', () {
      final scraper = SteamDetalhesScraper();
      addTearDown(scraper.dispose);
      final pagina = Uri.https(SteamScraper.host, '/app/570/');
      final ficha =
          scraper.interpretar(_fixture('steam_appdetails.json'), pagina, '570');

      expect(ficha.nome, 'Dota 2');
      expect(ficha.generos, contains('Ação'));
      expect(ficha.imagens.length, 4);
      expect(ficha.imagens.every((e) => e.scheme == 'https'), isTrue);
      expect(ficha.capa!.path, contains('header.jpg'));
      expect(ficha.descricao, isNotEmpty);
      // Jogo gratuito: o preço não vem em price_overview.
      expect(ficha.preco, 'Grátis');
      expect(ficha.urlLoja, pagina);
      // Loja oficial não entrega torrent, e o player só toca YouTube.
      expect(ficha.versoes, isEmpty);
      expect(ficha.trailers, isEmpty);
    });

    test('jogo pago usa o preço formatado da própria Steam', () {
      final scraper = SteamDetalhesScraper();
      addTearDown(scraper.dispose);
      final ficha = scraper.interpretar(
          jsonEncode({
            '1245620': {
              'success': true,
              'data': {
                'name': 'ELDEN RING',
                'is_free': false,
                'price_overview': {'final_formatted': 'R\$ 274,50'},
              }
            }
          }),
          Uri.https(SteamScraper.host, '/app/1245620/'),
          '1245620');
      expect(ficha.preco, 'R\$ 274,50');
      expect(ficha.imagens, isEmpty);
    });

    test('descrição chega sem marcação HTML', () {
      final scraper = SteamDetalhesScraper();
      addTearDown(scraper.dispose);
      final ficha = scraper.interpretar(
          jsonEncode({
            '1': {
              'success': true,
              'data': {
                'name': 'Jogo',
                'short_description': 'Linha um<br>e <strong>dois</strong>',
              }
            }
          }),
          Uri.https(SteamScraper.host, '/app/1/'),
          '1');
      expect(ficha.descricao, 'Linha ume dois');
      expect(ficha.descricao, isNot(contains('<')));
    });

    test('appid sem ficha pública vira erro legível', () {
      final scraper = SteamDetalhesScraper();
      addTearDown(scraper.dispose);
      expect(
          () => scraper.interpretar(jsonEncode({'9': {'success': false}}),
              Uri.https(SteamScraper.host, '/app/9/'), '9'),
          throwsA(isA<ErroCatalogo>()));
    });

    test('endereço que não é ficha da Steam é recusado antes da rede',
        () async {
      final scraper = SteamDetalhesScraper(
          client: MockClient((_) async => throw StateError('não deve pedir')));
      addTearDown(scraper.dispose);
      for (final endereco in [
        'https://store.steampowered.com/app/abc/',
        'https://store.steampowered.com/search/results/',
        'http://store.steampowered.com/app/570/',
        'https://exemplo.com/app/570/',
      ]) {
        await expectLater(scraper.carregar(Uri.parse(endereco)),
            throwsA(isA<ErroCatalogo>()),
            reason: endereco);
      }
    });
  });

  group('filtro de gênero', () {
    test('manda tags e preserva os campos obrigatórios da busca', () {
      final scraper = SteamScraper();
      addTearDown(scraper.dispose);
      final uri = scraper.catalogoPorGenero('19');
      expect(uri.queryParameters['tags'], '19');
      expect(uri.queryParameters.containsKey('genre'), isFalse);
      // Sem infinite=1 a Steam responde HTML em vez de JSON.
      expect(uri.queryParameters['infinite'], '1');
      expect(uri.queryParameters['cc'], 'br');
      expect(uri.queryParameters['l'], 'portuguese');
    });

    test('sem gênero devolve o catálogo base inteiro', () {
      final scraper = SteamScraper();
      addTearDown(scraper.dispose);
      final uri = scraper.catalogoPorGenero('');
      expect(uri.queryParameters.containsKey('tags'), isFalse);
      expect(uri.queryParameters['infinite'], '1');
    });
  });
}
