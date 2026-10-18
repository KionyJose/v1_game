import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:v1_game/Class/WebScrap.dart';

/// Páginas reais do wallpapercave para "Stick It to the Stickman", salvas em
/// 18/10/2026. A busca redireciona para a listagem da coleção.
String fixture(String name) => File('test/fixtures/$name').readAsStringSync();

void main() {
  final busca = Uri.parse(
      'https://wallpapercave.com/stick-it-to-the-stickman-wallpapers');
  final pastaWp = Uri.parse('https://wallpapercave.com/w/wp13320575');
  final pastaUwp = Uri.parse('https://wallpapercave.com/w/uwp5101825');

  test('A listagem traz só wallpapers, com a pasta de cada um', () {
    final lista =
        WebScrap.wallpapersDaPagina(fixture('wallpapercave_busca.html'), busca);
    expect(lista, isNotEmpty);
    // Logo, ícone de menu, avatar e botões de rede social não são wallpapers.
    expect(
        lista.where((i) =>
            i.imageUrl.contains('/logo.png') ||
            i.imageUrl.contains('/img/') ||
            i.imageUrl.contains('/avt/')),
        isEmpty);
    for (final imagem in lista) {
      expect(imagem.imageUrl,
          matches(r'^https://wallpapercave\.com/(?:wp|uwp)/[^/]+$'));
      expect(imagem.folderUrl, startsWith('https://wallpapercave.com/w/'));
    }
  });

  test('Página de um wallpaper oficial abre com imagens, não vazia', () {
    final lista = WebScrap.wallpapersDaPagina(
        fixture('wallpapercave_pasta_wp.html'), pastaWp);
    // O filtro antigo exigia a classe `wimg`, que só existe nas listagens:
    // nestas páginas a imagem principal é `wpimg` e as vizinhas não têm classe.
    expect(lista, isNotEmpty);
    expect(lista.first.imageUrl,
        'https://wallpapercave.com/wp/wp13320575.jpg');
    expect(lista.length, greaterThan(1), reason: 'traz também as vizinhas');
  });

  test('Página de wallpaper de usuário também abre', () {
    final lista = WebScrap.wallpapersDaPagina(
        fixture('wallpapercave_pasta_uwp.html'), pastaUwp);
    expect(lista, isNotEmpty);
    expect(lista.first.imageUrl,
        'https://wallpapercave.com/uwp/uwp5101825.webp');
  });

  test('Miniaturas viram o arquivo em tamanho cheio', () {
    final lista = WebScrap.wallpapersDaPagina(
        fixture('wallpapercave_pasta_wp.html'), pastaWp);
    // Na página as vizinhas chegam como /w400/ e /fuwp/; nenhuma pode ficar.
    expect(lista.where((i) => i.imageUrl.contains('/w400/')), isEmpty);
    expect(lista.where((i) => i.imageUrl.contains('/fuwp/')), isEmpty);
    expect(
        lista.where((i) => i.imageUrl.contains('/wp/wp13320576.')), isNotEmpty,
        reason: '/w400/wp13320576.jpg precisa virar /wp/wp13320576.jpg');
  });

  test('Vídeos e imagens repetidas ficam de fora', () {
    final lista =
        WebScrap.wallpapersDaPagina(fixture('wallpapercave_busca.html'), busca);
    expect(lista.where((i) => i.imageUrl.endsWith('.webm')), isEmpty);
    expect(lista.where((i) => i.imageUrl.endsWith('.mp4')), isEmpty);
    expect(lista.map((i) => i.imageUrl).toSet().length, lista.length);
  });
}
