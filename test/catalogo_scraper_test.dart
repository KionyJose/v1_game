import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/catalogo_scraper.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/gamestorrents_scraper.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/catalogo_controller.dart';

void main() {
  test('HTML real: capas originais, nomes, gêneros e próxima página', () {
    final scraper = GamesTorrentsScraper();
    addTearDown(scraper.dispose);
    final pagina = scraper.interpretar(
        File('test/fixtures/gamestorrents_catalogo.html').readAsStringSync(),
        scraper.catalogo);
    expect(pagina.jogos.length, 24);
    expect(pagina.jogos.first.nome, 'Lawn Mowing Simulator 2');
    expect(pagina.jogos.first.generos, ['Simulação', 'Estratégia']);
    expect(pagina.jogos.first.imagem!.path, startsWith('/media/'));
    expect(pagina.proxima!.queryParameters['page'], '2');
    expect(pagina.generos['Adventure'], 'Aventura');
    expect(pagina.jogos.every((jogo) => !jogo.nome.contains('Crítica IGDB')),
        isTrue);
  });

  test('Ignora página anterior, duplicatas e texto acessível adicional', () {
    final scraper = GamesTorrentsScraper();
    addTearDown(scraper.dispose);
    const card =
        '<article class="game-card"><h3><a href="/pt-br/jogos-pc/jogo/">'
        'Jogo<span class="sr-only">. Crítica IGDB</span></a></h3></article>';
    final pagina = scraper.interpretar(
        '$card$card<nav class="pagination">'
        '<a href="?page=1">Anterior</a><a href="?page=3">Próxima</a></nav>',
        scraper.catalogo.replace(queryParameters: {'page': '2'}));
    expect(pagina.jogos.single.nome, 'Jogo');
    expect(pagina.jogos.single.imagem, isNull);
    expect(pagina.jogos.single.genero, 'Gênero não informado');
    expect(pagina.proxima!.queryParameters['page'], '3');
    expect(
        () => scraper.interpretar('<html>Bloqueado</html>', scraper.catalogo),
        throwsA(isA<ErroCatalogo>()));
  });

  test('HTTP indisponível gera erro descritivo', () async {
    final scraper = GamesTorrentsScraper(
        client: MockClient((_) async => http.Response('', 503)));
    addTearDown(scraper.dispose);
    await expectLater(
        scraper.carregar(scraper.catalogo), throwsA(isA<ErroCatalogo>()));
  });

  test('Nova tentativa repete filtro que falhou e preserva jogos anteriores',
      () async {
    var falhar = false;
    final urls = <Uri>[];
    final scraper = GamesTorrentsScraper(client: MockClient((request) async {
      urls.add(request.url);
      return falhar
          ? http.Response('', 503)
          : http.Response(
              '<article class="game-card"><h3><a href="/pt-br/jogos-pc/teste/">Teste</a></h3></article>',
              200);
    }));
    final controller = CatalogoController(scraper);
    addTearDown(controller.dispose);
    await controller.atualizar();
    falhar = true;
    await controller.atualizar(filtroGenero: 'Adventure');
    expect(controller.jogos.length, 1);
    expect(controller.erro, isNotNull);
    falhar = false;
    await controller.tentarNovamente();
    expect(urls.last.queryParameters['genre'], 'Adventure');
    expect(controller.erro, isNull);
    expect(controller.carregando, isFalse);
  });
}
