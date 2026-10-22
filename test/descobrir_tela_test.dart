import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
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

List<String> _nomes(int quantos) =>
    List.generate(quantos, (i) => 'Jogo $i');

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

class _SemImagens implements DetalhesScraper {
  @override
  Future<JogoDetalhes> carregar(Uri pagina) async =>
      JogoDetalhes(pagina: pagina, nome: 'Jogo', urlLoja: pagina);
  @override
  void dispose() {}
}

Future<void> _abrirTela(WidgetTester tester, Widget tela, {Paad? pad}) async {
  await tester.binding.setSurfaceSize(const Size(1280, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  final app = MaterialApp(home: tela);
  await tester.pumpWidget(pad == null
      ? app
      : ChangeNotifierProvider<Paad>.value(value: pad, child: app));
  await tester.pumpAndSettle();
}

/// Aperta o direcional ou A como o Pad faria.
Future<void> _pad(WidgetTester tester, Paad pad, String comando) async {
  pad.interfaceRouter.dispatch(comando);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 350));
}

/// Nome do cartão atualmente selecionado na grade.
String _selecionado(WidgetTester tester) => tester
    .widgetList<DescobrirCard>(find.byType(DescobrirCard))
    .firstWhere((c) => c.selecionado)
    .jogo
    .nome;

Paad _novoPad() => Paad(escutar: false, janelaCtrl: JanelaCtrl());

/// Qual captura está grande na ficha.
///
/// A imagem leva `ValueKey(endereco)`, então a chave identifica a captura sem
/// depender de carregar a rede no teste.
Object? _chaveDaImagemGrande(WidgetTester tester) => tester
    .widget<AnimatedSwitcher>(find.byType(AnimatedSwitcher).first)
    .child
    ?.key;

void main() {
  group('grade', () {
    testWidgets('cinco cartões por linha, em 21:9', (tester) async {
      final scraper = _scraper(_resposta(300, _nomes(12)));
      addTearDown(scraper.dispose);
      await _abrirTela(tester, DescobrirTela(scraper: scraper, sons: false));

      expect(DescobrirTela.colunas, 5);
      final grade = tester.widget<GridView>(find.byType(GridView));
      final delegado =
          grade.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
      expect(delegado.crossAxisCount, 5);
      expect(delegado.childAspectRatio, 21 / 9);
      expect(DescobrirTela.proporcao, 21 / 9);

      // O carrossel saiu: não existe mais PageView nesta tela.
      expect(find.byType(PageView), findsNothing);
      expect(find.byType(DescobrirCard), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    testWidgets('os cinco primeiros dividem a mesma linha', (tester) async {
      final scraper = _scraper(_resposta(300, _nomes(10)));
      addTearDown(scraper.dispose);
      await _abrirTela(tester, DescobrirTela(scraper: scraper, sons: false));

      final cartoes = find.byType(DescobrirCard);
      final primeiro = tester.getRect(cartoes.at(0));
      final quinto = tester.getRect(cartoes.at(4));
      final sexto = tester.getRect(cartoes.at(5));
      expect(quinto.top, closeTo(primeiro.top, 1));
      expect(sexto.top, greaterThan(primeiro.bottom - 1),
          reason: 'o sexto já desce de linha');
      expect(primeiro.width / primeiro.height, closeTo(21 / 9, .05));
    });

    testWidgets('a grade ocupa quase toda a largura', (tester) async {
      final scraper = _scraper(_resposta(300, _nomes(10)));
      addTearDown(scraper.dispose);
      await _abrirTela(tester, DescobrirTela(scraper: scraper, sons: false));

      final tela = tester.getRect(find.byType(Scaffold).first);
      final grade = tester.getRect(find.byType(GridView));
      expect(grade.width, greaterThan(tela.width * .9));
    });
  });

  group('Pad na grade', () {
    testWidgets('anda na linha e pula de linha', (tester) async {
      final pad = _novoPad();
      addTearDown(pad.dispose);
      final scraper = _scraper(_resposta(300, _nomes(12)));
      addTearDown(scraper.dispose);
      await _abrirTela(tester, DescobrirTela(scraper: scraper, sons: false),
          pad: pad);

      expect(_selecionado(tester), 'Jogo 0');
      await _pad(tester, pad, 'DIREITA');
      expect(_selecionado(tester), 'Jogo 1');
      // BAIXO pula a linha inteira, não um cartão.
      await _pad(tester, pad, 'BAIXO');
      expect(_selecionado(tester), 'Jogo 6');
      await _pad(tester, pad, 'ESQUERDA');
      expect(_selecionado(tester), 'Jogo 5');
      await _pad(tester, pad, 'CIMA');
      expect(_selecionado(tester), 'Jogo 0');
      expect(tester.takeException(), isNull);
    });

    testWidgets('não passa do primeiro nem do último', (tester) async {
      final pad = _novoPad();
      addTearDown(pad.dispose);
      final scraper = _scraper(_resposta(7, _nomes(7)));
      addTearDown(scraper.dispose);
      await _abrirTela(tester, DescobrirTela(scraper: scraper, sons: false),
          pad: pad);

      await _pad(tester, pad, 'ESQUERDA');
      expect(_selecionado(tester), 'Jogo 0', reason: 'segura no começo');

      for (var i = 0; i < 12; i++) {
        await _pad(tester, pad, 'DIREITA');
      }
      expect(_selecionado(tester), 'Jogo 6', reason: 'segura no fim');
      expect(tester.takeException(), isNull);
    });

    testWidgets('seleciona categorias e filtra com A', (tester) async {
      final pad = _novoPad();
      addTearDown(pad.dispose);
      final pedidos = <Uri>[];
      final scraper =
          _scraper(_resposta(80, _nomes(6)), pedidos: pedidos);
      addTearDown(scraper.dispose);
      await _abrirTela(tester, DescobrirTela(scraper: scraper, sons: false),
          pad: pad);

      // Da primeira linha, CIMA sobe para a faixa de gêneros.
      await _pad(tester, pad, 'CIMA');
      // "Todos" é o primeiro; um à direita é o primeiro gênero de verdade.
      await _pad(tester, pad, 'DIREITA');
      await _pad(tester, pad, '2');

      expect(pedidos.last.queryParameters['tags'], isNotNull,
          reason: 'confirmar no gênero pede o filtro à Steam');
      expect(pedidos.last.queryParameters['infinite'], '1');
      expect(tester.takeException(), isNull);
    });

    testWidgets('dos gêneros, CIMA chega à busca', (tester) async {
      final pad = _novoPad();
      addTearDown(pad.dispose);
      final scraper = _scraper(_resposta(80, _nomes(6)));
      addTearDown(scraper.dispose);
      await _abrirTela(tester, DescobrirTela(scraper: scraper, sons: false),
          pad: pad);

      await _pad(tester, pad, 'CIMA');
      await _pad(tester, pad, 'CIMA');
      expect(
          FocusScope.of(tester.element(find.byType(TextField)))
              .hasFocus,
          isTrue,
          reason: 'a busca recebe o foco');
      expect(tester.takeException(), isNull);
    });
  });

  group('busca e filtros', () {
    testWidgets('continuam na tela', (tester) async {
      final scraper = _scraper(_resposta(50, _nomes(3)));
      addTearDown(scraper.dispose);
      await _abrirTela(tester, DescobrirTela(scraper: scraper, sons: false));

      expect(find.byType(TextField), findsOneWidget);
      expect(find.textContaining('Buscar na Steam'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
      expect(find.text('Ação'), findsOneWidget);
    });

    testWidgets('a busca pergunta à Steam com o termo digitado',
        (tester) async {
      final pedidos = <Uri>[];
      final scraper = _scraper(_resposta(10, ['Resultado']), pedidos: pedidos);
      addTearDown(scraper.dispose);
      await _abrirTela(tester, DescobrirTela(scraper: scraper, sons: false));

      await tester.enterText(find.byType(TextField), 'elden ring');
      await tester.testTextInput.receiveAction(TextInputAction.search);
      await tester.pumpAndSettle();

      expect(pedidos.last.queryParameters['term'], 'elden ring');
      expect(find.textContaining('Resultado'), findsWidgets);
    });
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

  testWidgets('A grade cabe em monitor pequeno', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final scraper = _scraper(_resposta(30, _nomes(8)));
    addTearDown(scraper.dispose);
    await tester.pumpWidget(
        MaterialApp(home: DescobrirTela(scraper: scraper, sons: false)));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.byType(DescobrirCard), findsWidgets);
  });

  group('ficha do Descobrir', () {
    Widget ficha({DetalhesScraper? scraper}) => DescobrirDetalhes(
          jogo: JogoCatalogo(
              nome: 'Jogo',
              pagina: Uri.https(SteamScraper.host, '/app/570/'),
              imagem: null,
              generos: const []),
          scraper: scraper ?? _FichaFalsa(),
          sons: false,
        );

    testWidgets('mostra preço, gêneros, descrição e abrir na loja',
        (tester) async {
      await _abrirTela(tester, ficha());

      expect(find.text('R\$ 99,00'), findsOneWidget);
      expect(find.text('Visitar site'), findsOneWidget);
      expect(find.text('Uma descrição curta.'), findsOneWidget);
      expect(find.textContaining('Ação'), findsWidgets);
      // Loja oficial não entrega torrent: nada de painel de compra.
      expect(find.text('Comprar'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('a captura ocupa a maior parte da tela', (tester) async {
      await _abrirTela(tester, ficha());

      final tela = tester.getRect(find.byType(Scaffold).first);
      final midia = tester.getRect(find.byType(AnimatedSwitcher).first);
      expect(midia.width, greaterThan(tela.width * .5),
          reason: 'a mídia leva a maior parte da largura');
      expect(midia.height, greaterThan(tela.height * .3));
      expect(tester.takeException(), isNull);
    });

    testWidgets('o botão fica acima da imagem, e CIMA chega nele',
        (tester) async {
      final pad = _novoPad();
      addTearDown(pad.dispose);
      await _abrirTela(tester, ficha(), pad: pad);

      final botao = tester.getRect(find.byType(FilledButton));
      final imagem = tester.getRect(find.byType(AnimatedSwitcher).first);
      expect(botao.bottom, lessThanOrEqualTo(imagem.top + 1),
          reason: 'o botão está acima da imagem grande');

      // Começa na galeria; CIMA sobe direto para a ação.
      await _pad(tester, pad, 'CIMA');
      expect(
          tester
              .widget<FilledButton>(find.byType(FilledButton))
              .focusNode
              ?.hasFocus,
          isTrue);
      expect(tester.takeException(), isNull);
    });

    testWidgets('direita e esquerda passam as imagens', (tester) async {
      final pad = _novoPad();
      addTearDown(pad.dispose);
      await _abrirTela(tester, ficha(), pad: pad);

      // A troca é visível pela chave da imagem grande.
      final antes = _chaveDaImagemGrande(tester);
      await _pad(tester, pad, 'DIREITA');
      final depois = _chaveDaImagemGrande(tester);
      expect(depois, isNot(antes), reason: 'passou para a captura seguinte');

      await _pad(tester, pad, 'ESQUERDA');
      expect(_chaveDaImagemGrande(tester), antes, reason: 'e voltou');
      expect(tester.takeException(), isNull);
    });

    testWidgets('a ordem é nome/ação, imagem, miniaturas, descrição',
        (tester) async {
      await _abrirTela(tester, ficha());

      final botao = tester.getRect(find.byType(FilledButton));
      final imagem = tester.getRect(find.byType(AnimatedSwitcher).first);
      final miniaturas = tester.getRect(find.byType(ListView).first);
      final descricao = tester.getRect(find.text('Uma descrição curta.'));

      expect(botao.center.dy, lessThan(imagem.center.dy));
      expect(imagem.center.dy, lessThan(miniaturas.center.dy));
      expect(miniaturas.center.dy, lessThan(descricao.center.dy));
      expect(tester.takeException(), isNull);
    });

    testWidgets('falha na ficha reaproveita o painel de diagnóstico',
        (tester) async {
      await _abrirTela(
          tester,
          ficha(
              scraper: _FichaFalsa(
                  erro: const ErroCatalogo('A Steam não tem ficha pública.'))));

      expect(find.text('O catálogo não carregou'), findsOneWidget);
      expect(find.text('A Steam não tem ficha pública.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sem capturas o jogo não vira tela quebrada', (tester) async {
      await _abrirTela(tester, ficha(scraper: _SemImagens()));
      expect(find.text('Este jogo não tem capturas publicadas.'),
          findsOneWidget);
      expect(find.text('Visitar site'), findsOneWidget);
      // Sem mídia nenhuma a faixa de miniaturas não é desenhada.
      expect(find.byType(ListView), findsNothing);
      expect(tester.takeException(), isNull);
    });
  });
}
