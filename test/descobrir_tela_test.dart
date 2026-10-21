import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:v1_game/Tela/Descobrir/descobrir_card.dart';
import 'package:v1_game/Tela/Descobrir/descobrir_detalhes.dart';
import 'package:v1_game/Tela/Descobrir/descobrir_tela.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/catalogo_scraper.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/jogo_detalhes.dart';
import 'package:v1_game/Tela/Tela%20loja/scraps/steam_scraper.dart';

String _linha(String appid, String nome) =>
    '<a class="search_result_row" data-ds-appid="$appid" '
    'href="https://store.steampowered.com/app/$appid/x/?snr=1_7">'
    '<div class="search_capsule"><img src="https://cdn.exemplo/$appid.jpg">'
    '</div><span class="title">$nome</span>'
    '<div class="search_released">2024</div>'
    '<div class="discount_final_price">Grátis</div></a>';

String _resposta(int total, List<String> nomes) => jsonEncode({
      'total_count': total,
      'results_html': [
        for (var i = 0; i < nomes.length; i++) _linha('${100 + i}', nomes[i]),
      ].join(),
    });

SteamScraper _scraper(String corpo, {List<Uri>? pedidos}) =>
    SteamScraper(client: MockClient((request) async {
      pedidos?.add(request.url);
      return http.Response(corpo, 200,
          headers: const {'content-type': 'application/json; charset=utf-8'});
    }));

class _FichaFalsa implements DetalhesScraper {
  _FichaFalsa({this.erro});
  final Object? erro;
  bool disposed = false;

  @override
  Future<JogoDetalhes> carregar(Uri pagina) async {
    if (erro != null) throw erro!;
    return JogoDetalhes(
      pagina: pagina,
      nome: 'Jogo da ficha',
      descricao: 'Uma descrição curta.',
      preco: 'R\$ 99,00',
      urlLoja: pagina,
      generos: const ['Ação', 'RPG'],
      imagens: [
        Uri.parse('https://cdn.exemplo/1.jpg'),
        Uri.parse('https://cdn.exemplo/2.jpg'),
      ],
    );
  }

  @override
  void dispose() => disposed = true;
}

Future<void> _abrirTela(WidgetTester tester, Widget tela) async {
  await tester.binding.setSurfaceSize(const Size(1280, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MaterialApp(home: tela));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('O carrossel abre centralizado no primeiro jogo', (tester) async {
    final scraper = _scraper(_resposta(300, ['Alfa', 'Beta', 'Gama']));
    addTearDown(scraper.dispose);
    await _abrirTela(tester, DescobrirTela(scraper: scraper, sons: false));

    expect(find.text('Descobrir'), findsOneWidget);
    expect(find.byType(DescobrirCard), findsWidgets);
    // O rodapé nomeia o jogo em destaque e a posição na esteira.
    expect(find.text('1 de 3'), findsNothing);
    expect(find.textContaining('1 de 3'), findsOneWidget);
    expect(find.textContaining('300 jogos'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A busca e os gêneros continuam na tela', (tester) async {
    final scraper = _scraper(_resposta(50, ['Alfa']));
    addTearDown(scraper.dispose);
    await _abrirTela(tester, DescobrirTela(scraper: scraper, sons: false));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.textContaining('Buscar na Steam'), findsOneWidget);
    expect(find.text('Todos'), findsOneWidget);
    expect(find.text('Ação'), findsOneWidget);
    expect(find.text('Indie'), findsOneWidget);
  });

  testWidgets('Filtrar por gênero pede tags à Steam e volta ao primeiro card',
      (tester) async {
    final pedidos = <Uri>[];
    final scraper =
        _scraper(_resposta(80, ['Alfa', 'Beta']), pedidos: pedidos);
    addTearDown(scraper.dispose);
    await _abrirTela(tester, DescobrirTela(scraper: scraper, sons: false));

    await tester.tap(find.text('Ação'));
    await tester.pumpAndSettle();

    expect(pedidos.last.queryParameters['tags'], '19');
    expect(pedidos.last.queryParameters['infinite'], '1');
    expect(find.textContaining('1 de 2'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A busca pergunta à Steam com o termo digitado', (tester) async {
    final pedidos = <Uri>[];
    final scraper =
        _scraper(_resposta(10, ['Resultado']), pedidos: pedidos);
    addTearDown(scraper.dispose);
    await _abrirTela(tester, DescobrirTela(scraper: scraper, sons: false));

    await tester.enterText(find.byType(TextField), 'elden ring');
    await tester.testTextInput.receiveAction(TextInputAction.search);
    await tester.pumpAndSettle();

    expect(pedidos.last.queryParameters['term'], 'elden ring');
    expect(find.textContaining('Resultado'), findsWidgets);
  });

  testWidgets('Erro de rede mostra o painel de diagnóstico, não tela vazia',
      (tester) async {
    final scraper = SteamScraper(client: MockClient((_) async =>
        throw http.ClientException(
            'Failed host lookup: store.steampowered.com')));
    addTearDown(scraper.dispose);
    await _abrirTela(tester, DescobrirTela(scraper: scraper, sons: false));

    expect(find.text('O catálogo não carregou'), findsOneWidget);
    expect(find.text('LOJA-DNSBLOQUEADO'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A tela cabe em monitor pequeno sem estourar o layout',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final scraper = _scraper(_resposta(30, ['Alfa', 'Beta']));
    addTearDown(scraper.dispose);
    await tester.pumpWidget(
        MaterialApp(home: DescobrirTela(scraper: scraper, sons: false)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DescobrirCard), findsWidgets);
  });

  group('ficha do Descobrir', () {
    testWidgets('mostra preço, gêneros, descrição e abrir na loja',
        (tester) async {
      await _abrirTela(
          tester,
          DescobrirDetalhes(
            jogo: JogoCatalogo(
                nome: 'Jogo da ficha',
                pagina: Uri.https(SteamScraper.host, '/app/570/'),
                imagem: null,
                generos: const []),
            scraper: _FichaFalsa(),
            sons: false,
          ));

      expect(find.text('Nesta loja'), findsOneWidget);
      expect(find.text('R\$ 99,00'), findsOneWidget);
      expect(find.text('Abrir na loja'), findsOneWidget);
      expect(find.text('Sobre'), findsOneWidget);
      expect(find.text('Uma descrição curta.'), findsOneWidget);
      expect(find.text('Ação'), findsOneWidget);
      // Loja oficial não entrega torrent: nada de painel de compra.
      expect(find.text('Comprar'), findsNothing);
      expect(find.text('Versão do jogo'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('falha na ficha reaproveita o painel de diagnóstico',
        (tester) async {
      await _abrirTela(
          tester,
          DescobrirDetalhes(
            jogo: JogoCatalogo(
                nome: 'Jogo',
                pagina: Uri.https(SteamScraper.host, '/app/570/'),
                imagem: null,
                generos: const []),
            scraper: _FichaFalsa(
                erro: const ErroCatalogo('A Steam não tem ficha pública.')),
            sons: false,
          ));

      expect(find.text('O catálogo não carregou'), findsOneWidget);
      expect(find.text('A Steam não tem ficha pública.'), findsOneWidget);
      expect(find.text('Tentar novamente'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sem capturas o jogo não vira tela quebrada', (tester) async {
      await _abrirTela(
          tester,
          DescobrirDetalhes(
            jogo: JogoCatalogo(
                nome: 'Jogo',
                pagina: Uri.https(SteamScraper.host, '/app/570/'),
                imagem: null,
                generos: const []),
            scraper: _SemImagens(),
            sons: false,
          ));
      expect(find.text('Este jogo não tem capturas publicadas.'),
          findsOneWidget);
      expect(find.text('Abrir na loja'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

class _SemImagens implements DetalhesScraper {
  @override
  Future<JogoDetalhes> carregar(Uri pagina) async =>
      JogoDetalhes(pagina: pagina, nome: 'Jogo', urlLoja: pagina);
  @override
  void dispose() {}
}
