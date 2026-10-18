import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:v1_game/Class/WebScrap.dart';

/// Páginas reais do wallpapercave salvas em 18/10/2026. São cinco formatos
/// diferentes, e cada um entrega as imagens de um jeito — foi por isso que
/// filtrar por uma classe ou por uma lista de pastas sempre deixava algum de
/// fora.
String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

void main() {
  // "Stick It to the Stickman" tem coleção própria: a busca redireciona.
  final listagem = Uri.parse(
      'https://wallpapercave.com/stick-it-to-the-stickman-wallpapers');
  // "Hollow Knight Silksong" não redireciona: é uma busca de verdade.
  final busca =
      Uri.parse('https://wallpapercave.com/search?q=Hollow+Knight+Silksong');
  final album =
      Uri.parse('https://wallpapercave.com/hollow-knight-silksong-wallpapers');
  final pastaWp = Uri.parse('https://wallpapercave.com/w/wp13320575');
  final pastaUwp = Uri.parse('https://wallpapercave.com/w/uwp5101825');

  test('A busca entrega as pastas do jogo, não wallpapers soltos', () {
    final lista = WebScrap.wallpapersDaPagina(
        fixture('wallpapercave_busca_real.html'), busca);
    final pastas = lista
        .map((i) => i.folderUrl)
        .where((url) => url.endsWith('-wallpapers'))
        .toList();
    expect(pastas, [
      'https://wallpapercave.com/hollow-knight-silksong-wallpapers',
      'https://wallpapercave.com/hollow-knight-silksong-4k-wallpapers',
      'https://wallpapercave.com/hornet-hollow-knight-silksong-wallpapers',
    ]);
    // As capas de álbum vêm de /wpt/, que a regra antiga descartava inteira.
    expect(lista.first.imageUrl, contains('/wpt/'));
  });

  test('A pasta do jogo abre com todas as imagens dela', () {
    final lista = WebScrap.wallpapersDaPagina(
        fixture('wallpapercave_album.html'), album,
        tamanhoCheio: true);
    expect(lista.length, 60);
    for (final imagem in lista) {
      expect(imagem.imageUrl, startsWith('https://wallpapercave.com/wp/'));
    }
  });

  test('O bloco da comunidade fica de fora de toda página', () {
    // São 28 imagens recentes, iguais em qualquer página e sem relação com a
    // busca: deixá-las entrar enchia a grade e fazia qualquer busca "achar".
    expect(
        WebScrap.wallpapersDaPagina(
                fixture('wallpapercave_busca.html'), listagem)
            .length,
        5);
    expect(
        WebScrap.wallpapersDaPagina(
                fixture('wallpapercave_album.html'), album)
            .length,
        60);
    expect(
        WebScrap.wallpapersDaPagina(
                fixture('wallpapercave_pasta_uwp.html'), pastaUwp)
            .length,
        25);
  });

  test('Página de um wallpaper abre com ele e os relacionados', () {
    // O filtro antigo exigia a classe `wimg`, que só existe nas listagens:
    // aqui a imagem principal é `wpimg` e as vizinhas não têm classe.
    final oficial = WebScrap.wallpapersDaPagina(
        fixture('wallpapercave_pasta_wp.html'), pastaWp,
        tamanhoCheio: true);
    expect(oficial, isNotEmpty);
    expect(oficial.first.imageUrl, 'https://wallpapercave.com/wp/wp13320575.jpg');

    final usuario = WebScrap.wallpapersDaPagina(
        fixture('wallpapercave_pasta_uwp.html'), pastaUwp,
        tamanhoCheio: true);
    expect(usuario, isNotEmpty);
    expect(usuario.first.imageUrl,
        'https://wallpapercave.com/uwp/uwp5101825.webp');
  });

  test('A grade usa a miniatura; só a escolha vai em tamanho cheio', () {
    final grade = WebScrap.wallpapersDaPagina(
        fixture('wallpapercave_pasta_wp.html'), pastaWp);
    expect(grade.where((i) => i.imageUrl.contains('/w400/')), isNotEmpty,
        reason: 'a grade não precisa baixar o arquivo original');
    final cheias = WebScrap.wallpapersDaPagina(
        fixture('wallpapercave_pasta_wp.html'), pastaWp,
        tamanhoCheio: true);
    expect(cheias.where((i) => i.imageUrl.contains('/w400/')), isEmpty);
    expect(cheias.where((i) => i.imageUrl.contains('/wp/wp13320576.')),
        isNotEmpty,
        reason: '/w400/wp13320576.jpg precisa virar /wp/wp13320576.jpg');
  });

  test('A pasta informa quantas imagens guarda; a imagem solta não', () {
    final lista = WebScrap.wallpapersDaPagina(
        fixture('wallpapercave_busca_real.html'), busca);
    final albuns = lista.where((i) => i.fotos > 0).toList();
    expect(albuns.map((i) => i.fotos), [60, 14, 37]);
    // Os wallpapers soltos da mesma busca não viram pasta.
    expect(lista.where((i) => i.folderUrl.contains('/w/')).map((i) => i.fotos),
        everyElement(0));
    expect(
        WebScrap.wallpapersDaPagina(
                fixture('wallpapercave_busca.html'), listagem)
            .map((i) => i.fotos),
        everyElement(0));
  });

  test('A imagem solta mostra a resolução do arquivo, não a de exibição', () {
    // A página desenha o wallpaper em 700x1400 e declara a resolução real em
    // `<p class="resolution">`; usar o atributo do `<img>` mostrava 700x1400.
    final oficial = WebScrap.wallpapersDaPagina(
        fixture('wallpapercave_pasta_wp.html'), pastaWp,
        tamanhoCheio: true);
    expect('${oficial.first.largura}x${oficial.first.altura}', '1080x2160');
    final usuario = WebScrap.wallpapersDaPagina(
        fixture('wallpapercave_pasta_uwp.html'), pastaUwp,
        tamanhoCheio: true);
    expect('${usuario.first.largura}x${usuario.first.altura}', '1600x1064');
    // Miniaturas das vizinhas não dizem nada do arquivo: melhor vazio do que
    // o tamanho da miniatura passando por resolução.
    expect(oficial[1].largura, isEmpty);
    expect(oficial[1].altura, isEmpty);
  });

  test('A listagem traz a resolução real de cada wallpaper', () {
    final lista = WebScrap.wallpapersDaPagina(
        fixture('wallpapercave_busca.html'), listagem);
    expect(lista.map((i) => '${i.largura}x${i.altura}'),
        ['1080x2160', '1920x1080', '2560x1440', '1920x1080', '1280x720']);
  });

  test('Logo, ícones, avatares, vídeos e repetidas ficam de fora', () {
    for (final caso in {
      'wallpapercave_busca.html': listagem,
      'wallpapercave_busca_real.html': busca,
      'wallpapercave_album.html': album,
      'wallpapercave_pasta_wp.html': pastaWp,
      'wallpapercave_pasta_uwp.html': pastaUwp,
    }.entries) {
      final lista = WebScrap.wallpapersDaPagina(fixture(caso.key), caso.value);
      expect(lista, isNotEmpty, reason: caso.key);
      for (final imagem in lista) {
        expect(imagem.imageUrl, matches(r'/(?:u?wp)\d+\.[a-z0-9]+$'),
            reason: caso.key);
        expect(imagem.imageUrl, isNot(endsWith('.webm')));
        expect(imagem.imageUrl, isNot(endsWith('.mp4')));
      }
      expect(lista.map((i) => i.imageUrl).toSet().length, lista.length,
          reason: caso.key);
    }
  });
}
