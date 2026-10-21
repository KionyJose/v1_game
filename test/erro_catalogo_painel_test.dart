import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:v1_game/Tela/Tela%20loja/scrap_loja.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/diagnostico_catalogo.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/gamestorrents_scraper.dart';

void main() {
  testWidgets('403 na loja mostra causa, código e detalhe copiável',
      (tester) async {
    final scraper = GamesTorrentsScraper(
        client: MockClient((_) async => http.Response('', 403)));
    addTearDown(scraper.dispose);

    await tester.pumpWidget(MaterialApp(home: ScrapLoja(scraper: scraper)));
    await tester.pumpAndSettle();

    expect(find.text('O catálogo não carregou'), findsOneWidget);
    // A causa certa, não "verifique sua conexão".
    expect(find.textContaining('Cloudflare'), findsOneWidget);
    expect(find.text('LOJA-ACESSORECUSADO'), findsOneWidget);
    expect(find.text('HTTP 403'), findsOneWidget);
    expect(find.text('Tentar novamente'), findsOneWidget);
    expect(tester.takeException(), isNull);

    // O detalhe técnico fica recolhido até o suporte precisar dele.
    expect(find.textContaining('Detalhe:'), findsNothing);
    await tester.tap(find.text('Detalhes técnicos'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Detalhe:'), findsOneWidget);
    expect(find.textContaining('gamestorrents.app'), findsWidgets);
  });

  testWidgets('Copiar detalhes põe o relatório na área de transferência',
      (tester) async {
    String? copiado;
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform, (call) async {
      if (call.method == 'Clipboard.setData') {
        copiado = (call.arguments as Map)['text'] as String;
      }
      return null;
    });
    addTearDown(() => tester.binding.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null));

    final scraper = GamesTorrentsScraper(
        client: MockClient((_) async => http.Response('', 503)));
    addTearDown(scraper.dispose);
    await tester.pumpWidget(MaterialApp(home: ScrapLoja(scraper: scraper)));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Copiar detalhes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Copiar detalhes'));
    await tester.pumpAndSettle();

    expect(copiado, isNotNull);
    expect(copiado, contains('Código: LOJA-SITEINDISPONIVEL'));
    expect(copiado, contains('HTTP: 503'));
    expect(copiado, contains('Quando: '));
    expect(find.text('Detalhes copiados. Envie para o suporte.'),
        findsOneWidget);
  });

  testWidgets('DNS bloqueado explica que o contorno também falhou',
      (tester) async {
    final scraper = GamesTorrentsScraper(client: MockClient((_) async =>
        throw http.ClientException(
            'Failed host lookup: www.gamestorrents.app')));
    addTearDown(scraper.dispose);

    await tester.pumpWidget(MaterialApp(home: ScrapLoja(scraper: scraper)));
    await tester.pumpAndSettle();

    expect(find.text('LOJA-DNSBLOQUEADO'), findsOneWidget);
    expect(find.textContaining('rota alternativa'), findsOneWidget);
    expect(find.textContaining('Verifique sua conexão'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Tentar novamente recarrega e some com o painel', (tester) async {
    var falhar = true;
    final scraper = GamesTorrentsScraper(client: MockClient((_) async => falhar
        ? http.Response('', 500)
        : http.Response(
            '<div class="catalog-controls"></div>'
            '<article class="game-card"><h3>'
            '<a href="/pt-br/jogos-pc/jogo/">Jogo recuperado</a></h3></article>',
            200,
            headers: const {'content-type': 'text/html; charset=utf-8'})));
    addTearDown(scraper.dispose);

    await tester.pumpWidget(MaterialApp(home: ScrapLoja(scraper: scraper)));
    await tester.pumpAndSettle();
    expect(find.text('O catálogo não carregou'), findsOneWidget);

    falhar = false;
    await tester.ensureVisible(find.text('Tentar novamente'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Tentar novamente'));
    await tester.pumpAndSettle();

    expect(find.text('O catálogo não carregou'), findsNothing);
    expect(find.text('Jogo recuperado'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('O painel cabe na largura de um monitor pequeno', (tester) async {
    await tester.binding.setSurfaceSize(const Size(640, 480));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final scraper = GamesTorrentsScraper(
        client: MockClient((_) async => http.Response('', 403)));
    addTearDown(scraper.dispose);

    await tester.pumpWidget(MaterialApp(home: ScrapLoja(scraper: scraper)));
    await tester.pumpAndSettle();
    expect(find.text('LOJA-ACESSORECUSADO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  test('o log fica na pasta de dados do aplicativo, não ao lado do .exe', () {
    final caminho = DiagnosticoCatalogo.arquivoDeLog.path;
    expect(caminho, endsWith('loja-erros.log'));
    expect(caminho, contains('V1 Launcher'));
  });
}
