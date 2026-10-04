import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v1_game/Tela/Tela%20loja/scrap_loja.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/catalogo_scraper.dart';

class FonteTeste implements CatalogoScraper {
  @override
  String get nome => 'Fonte de teste';
  @override
  Uri get catalogo => Uri.parse('https://example.com/jogos/');
  @override
  void dispose() {}
  @override
  Future<PaginaCatalogo> carregar(Uri pagina) async => PaginaCatalogo(
        jogos: [
          JogoCatalogo(
              nome: 'Jogo de aventura',
              pagina: catalogo.resolve('jogo'),
              imagem: null,
              generos: const ['Aventura'])
        ],
        generos: const {'': 'Todos os gêneros', 'Adventure': 'Aventura'},
      );
}

void main() {
  testWidgets('Catálogo funciona em largura pequena e busca filtra os cards',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester
        .pumpWidget(MaterialApp(home: ScrapLoja(scraper: FonteTeste())));
    await tester.pumpAndSettle();
    expect(find.text('Jogo de aventura'), findsOneWidget);
    expect(find.text('Ver detalhes'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'inexistente');
    await tester.pumpAndSettle();
    expect(find.text('Jogo de aventura'), findsNothing);
    expect(
        find.text(
            'Nenhum jogo encontrado. Ajuste a busca ou carregue mais jogos.'),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
