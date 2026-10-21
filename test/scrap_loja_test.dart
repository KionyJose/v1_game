import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v1_game/Tela/Tela%20loja/scrap_loja.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/catalogo_scraper.dart';

class FonteTeste implements CatalogoScraper {
  /// Endereços pedidos, na ordem: é assim que o teste enxerga se a tela
  /// perguntou ao site ou só filtrou o que já tinha.
  final pedidos = <Uri>[];
  @override
  String get nome => 'Fonte de teste';
  @override
  Uri get catalogo => Uri.parse('https://example.com/jogos/');
  @override
  Uri busca(String termo) =>
      Uri.https('example.com', '/buscar/', {'q': termo.trim()});
  @override
  Uri catalogoPorGenero(String genero) => genero.isEmpty
      ? catalogo
      : catalogo.replace(queryParameters: {'genre': genero});
  @override
  void dispose() {}
  @override
  Future<PaginaCatalogo> carregar(Uri pagina) async {
    pedidos.add(pagina);
    return PaginaCatalogo(
      jogos: [
        JogoCatalogo(
            nome: pagina.queryParameters['q'] == null
                ? 'Jogo de aventura'
                : 'Resultado do site',
            pagina: catalogo.resolve(pagina.queryParameters['q'] ?? 'jogo'),
            imagem: null,
            generos: const ['Aventura'])
      ],
      generos: const {'': 'Todos os gêneros', 'Adventure': 'Aventura'},
    );
  }
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
    expect(find.text('Ver detalhes'), findsNothing);
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

  testWidgets('Confirmar a busca pergunta ao site, não filtra o que já veio',
      (tester) async {
    final fonte = FonteTeste();
    await tester.pumpWidget(MaterialApp(home: ScrapLoja(scraper: fonte)));
    await tester.pumpAndSettle();
    expect(fonte.pedidos.single.path, '/jogos/');
    // Digitar só filtra: nada é pedido ao site enquanto se escreve.
    await tester.enterText(find.byType(TextField), 'stickman');
    await tester.pumpAndSettle();
    expect(fonte.pedidos.length, 1);
    // Confirmar vai ao site, e o resultado substitui o catálogo na tela.
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(fonte.pedidos.last,
        Uri.parse('https://example.com/buscar/?q=stickman'));
    expect(find.text('Resultado do site'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Busca vazia volta ao catálogo', (tester) async {
    final fonte = FonteTeste();
    await tester.pumpWidget(MaterialApp(home: ScrapLoja(scraper: fonte)));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'stickman');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(find.text('Resultado do site'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '   ');
    await tester.testTextInput.receiveAction(TextInputAction.done);
    await tester.pumpAndSettle();
    expect(fonte.pedidos.last.path, '/jogos/');
    expect(find.text('Jogo de aventura'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
