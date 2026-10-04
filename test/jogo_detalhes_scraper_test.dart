import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/catalogo_scraper.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/gamestorrents_detalhes_scraper.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/gamestorrents_download_scraper.dart';

void main() {
  test('release-source-name prevalece sobre atributo de fonte alternativo', () {
    final scraper = GamesTorrentsDetalhesScraper();
    addTearDown(scraper.dispose);
    final jogo = scraper.interpretar(
        '''<header class="game-heading"><h1>Teste</h1></header>
      <article data-release-entry data-release-source="Alternativa">
      <span class="release-source-name">DODI Repacks</span><div class="release-downloads">
      <a href="/pt-br/download/${'a' * 32}/">Baixar torrent</a></div></article>''',
        Uri.parse('https://www.gamestorrents.app/pt-br/jogos-pc/teste/'));
    expect(jogo.versoes.single.fonte, 'DODI Repacks');
  });
  final pagina = Uri.parse(
      'https://www.gamestorrents.app/pt-br/jogos-pc/little-nightmares-iii-1/');
  final download = Uri.parse(
      'https://www.gamestorrents.app/pt-br/download/750e3a42a06f9eeb1ca7cdf80a8b9a12/');
  test('HTML real extrai galeria, trailers cadastrados e ambas as versões', () {
    final scraper = GamesTorrentsDetalhesScraper();
    addTearDown(scraper.dispose);
    final jogo = scraper.interpretar(
        File('test/fixtures/gamestorrents_detalhes.html').readAsStringSync(),
        pagina);
    expect(jogo.nome, 'Little Nightmares III');
    expect(jogo.generos, ['Aventura', 'Plataforma', 'Quebra-cabeça']);
    expect(jogo.imagens.length, 3);
    expect(
        jogo.imagens.every(
            (i) => i.host == pagina.host && i.path.startsWith('/media/')),
        isTrue);
    expect(jogo.trailers.map((t) => t.youtubeId),
        ['XFHOsobwFrA', 'UjrtoFazU1U', 'miK1hqlEsTE']);
    expect(jogo.versoes.length, 2);
    expect(jogo.versoes.first.torrent, download);
    expect(jogo.versoes.first.informacoes['Tamanho do download'], '10,0 GB');
    expect(jogo.descricao, contains('\n'));
  });
  test(
      'Download real retorna metadados e etapa de verificação, sem inventar URL direta',
      () {
    final scraper = GamesTorrentsDownloadScraper();
    addTearDown(scraper.dispose);
    final etapa = scraper.interpretar(
        File('test/fixtures/gamestorrents_download.html').readAsStringSync(),
        download);
    expect(etapa.nomeArquivo, 'Little Nightmares III [FitGirl Repack].torrent');
    expect(etapa.tamanhoArquivo, '53,5 KiB');
    expect(etapa.exigeJavaScript, isTrue);
    expect(etapa.podeExigirCaptcha, isTrue);
    expect(etapa.pagina, download);
  });
  test('Resposta desconhecida e resposta magnet não viram arquivo torrent', () {
    final detalhes = GamesTorrentsDetalhesScraper();
    final scraper = GamesTorrentsDownloadScraper();
    addTearDown(detalhes.dispose);
    addTearDown(scraper.dispose);
    expect(() => detalhes.interpretar('<html>Indisponível</html>', pagina),
        throwsA(isA<ErroCatalogo>()));
    expect(() => scraper.interpretar('<html>Bloqueado</html>', download),
        throwsA(isA<ErroCatalogo>()));
    expect(
        () => scraper.interpretar(
            '''<div data-download-desk data-download-config='{"kind":"magnet"}'></div>
      <form data-download-form></form>''', download),
        throwsA(isA<ErroCatalogo>()));
  });
  test(
      'Links externos, esquemas inválidos e IDs de trailer inválidos são ignorados',
      () {
    final scraper = GamesTorrentsDetalhesScraper();
    addTearDown(scraper.dispose);
    final jogo = scraper.interpretar(
        '''<header class="game-heading"><h1>Teste</h1></header>
      <div class="gallery-stage"><a class="game-gallery-image" href="javascript:alert(1)"></a>
      <div data-gallery-video="invalid"></div></div>
      <article data-release-entry><div class="release-downloads">
      <a href="https://example.com/pt-br/download/test/">Baixar torrent</a></div></article>''',
        pagina);
    expect(jogo.imagens, isEmpty);
    expect(jogo.trailers, isEmpty);
    expect(jogo.versoes, isEmpty);
  });
  test('Consulta faz somente GET na página de download da versão selecionada',
      () async {
    final pedidos = <http.Request>[];
    final scraper =
        GamesTorrentsDownloadScraper(client: MockClient((request) async {
      pedidos.add(request);
      return http.Response(
          File('test/fixtures/gamestorrents_download.html').readAsStringSync(),
          200,
          headers: {'content-type': 'text/html; charset=utf-8'});
    }));
    addTearDown(scraper.dispose);
    final etapa = await scraper.consultar(download);
    expect(etapa.nomeArquivo, endsWith('.torrent'));
    expect(pedidos.single.method, 'GET');
    expect(pedidos.single.url, download);
    await expectLater(
        scraper.consultar(Uri.parse('https://example.com/download/')),
        throwsA(isA<ErroCatalogo>()));
    expect(pedidos.length, 1);
  });
}
