import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:v1_game/Modelos/IconeInicial.dart';
import 'package:v1_game/Tela/Tela Principal/PrincipalCtrl.dart';
import 'package:v1_game/Tela/Tela Principal/Widgets/BodySlim.dart';

class CtrlDeTeste extends PrincipalCtrl {
  CtrlDeTeste(super.ctx);

  @override
  Future<void> iniciaTela() async {
    focusNodeIcones = [FocusNode(), FocusNode()];
    focusNodeAbaGuias = List.generate(4, (_) => FocusNode());
    focusNodeCinema = [];
    focusNodeMusica = [];
    focusNodeLoja = [];
    focusNodeVideos = [];
  }
}

Future<CtrlDeTeste> _montar(WidgetTester tester) async {
  CtrlDeTeste? criado;
  final pad = Paad(escutar: false, janelaCtrl: JanelaCtrl());
  addTearDown(pad.dispose);
  await tester.binding.setSurfaceSize(const Size(1280, 300));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(MultiProvider(
    providers: [
      ChangeNotifierProvider<Paad>.value(value: pad),
      ChangeNotifierProvider<JanelaCtrl>(create: (_) => JanelaCtrl()),
    ],
    child: MaterialApp(home: Builder(builder: (context) {
      final ctrl = criado ??= CtrlDeTeste(context)
        ..listIconsInicial = List.generate(
            2,
            (i) => IconInicial([
                  'lugar: ${i + 1}',
                  'nome: Jogo $i',
                  'local: jogo$i.exe',
                  'img: ',
                  'imgAux: ',
                ]))
        ..stateTela = true
        ..telaIniciada = true;
      // Sem escutar o controller, `attTela()` não reconstrói nada e o teste
      // não enxerga a mudança de estado.
      return AnimatedBuilder(
        animation: ctrl,
        builder: (_, __) => Scaffold(body: BodySlim(ctrl: ctrl)),
      );
    })),
  ));
  await tester.pump();
  return criado!;
}

void main() {
  testWidgets('O rodapé não traz mais a legenda de como navegar',
      (tester) async {
    await _montar(tester);

    // Ela repetia a cada quadro algo que se aprende uma vez, e ocupava a
    // largura inteira do rodapé.
    expect(find.textContaining('LB / RB'), findsNothing);
    expect(find.textContaining('Categorias'), findsNothing);
    expect(find.textContaining('Abrir'), findsNothing);
    expect(find.textContaining('Menu'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sobra o indicador de categoria, no canto esquerdo',
      (tester) async {
    final ctrl = await _montar(tester);

    // As quatro categorias continuam lá, como status de onde a tela está.
    // O ícone de jogos aparece mais vezes: é também a reserva dos cartões
    // sem capa, então só os outros três servem de contagem exata.
    expect(find.byIcon(Icons.sports_esports_rounded), findsWidgets);
    for (final icone in [
      Icons.movie_rounded,
      Icons.music_note_rounded,
      Icons.storefront_rounded,
    ]) {
      expect(find.byIcon(icone), findsOneWidget);
    }

    final tela = tester.getRect(find.byType(BodySlim));
    final categorias = tester.getRect(find.byIcon(Icons.storefront_rounded));
    expect(categorias.left - tela.left, lessThan(tela.width * .2),
        reason: 'encostado à esquerda');
    expect(categorias.center.dy, greaterThan(tela.center.dy),
        reason: 'na metade de baixo');
    expect(ctrl.selectedIndexAbaGuias, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Nenhum fundo preto arredondado atrás dos ícones',
      (tester) async {
    await _montar(tester);

    // O contraste vem do gradiente do rodapé; a pílula preta saiu.
    final pretos = tester
        .widgetList<Container>(find.byType(Container))
        .where((c) {
      final decoracao = c.decoration;
      if (decoracao is! BoxDecoration) return false;
      return decoracao.color == Colors.black &&
          decoracao.borderRadius != null;
    });
    expect(pretos, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A base do gradiente é quase preta', (tester) async {
    await _montar(tester);

    final fundo = tester
        .widgetList<DecoratedBox>(find.byType(DecoratedBox))
        .map((d) => d.decoration)
        .whereType<BoxDecoration>()
        .map((d) => d.gradient)
        .whereType<LinearGradient>()
        .where((g) => g.begin == Alignment.bottomCenter)
        .toList();
    expect(fundo, isNotEmpty, reason: 'o rodapé precisa do gradiente');

    // Sem a pílula, é a opacidade da base que sustenta a leitura.
    final base = fundo.first.colors.first;
    expect(base.a, greaterThan(.9),
        reason: 'a parte inicial do gradiente precisa ser bem escura');
    expect(fundo.first.colors.last, Colors.transparent,
        reason: 'o topo continua limpo');
  });

  testWidgets('Cartões 5% menores e 15% mais juntos', (tester) async {
    await _montar(tester);

    // Os dois andam juntos: encolher sem aproximar só aumentaria o vazio.
    expect(BodySlim.escalaDoCartao, .95);
    expect(BodySlim.folgaEntreCartoes, closeTo(16 * .85, .001));

    final cartoes = tester
        .widgetList<AnimatedScale>(find.byType(AnimatedScale))
        .length;
    expect(cartoes, greaterThan(0), reason: 'os cartões continuam na tela');
    expect(tester.takeException(), isNull);
  });

  group('nome do item na barra inferior', () {
    testWidgets('aparece uma vez só, centralizado e maior', (tester) async {
      final ctrl = await _montar(tester);
      ctrl.selectedIndexIcone = 0;

      // Antes era uma legenda de 12 px embaixo de cada cartão, repetida na
      // esteira e apertada na largura do ícone.
      final nome = find.text('Jogo 0');
      expect(nome, findsOneWidget);

      final estilo = tester.widget<Text>(nome).style!;
      expect(estilo.fontSize, greaterThan(12),
          reason: 'um pouco maior que a legenda antiga');
      expect(tester.widget<Text>(nome).textAlign, TextAlign.center);

      final tela = tester.getRect(find.byType(BodySlim));
      final caixa = tester.getRect(nome);
      expect((caixa.center.dx - tela.center.dx).abs(), lessThan(tela.width * .06),
          reason: 'centralizado na largura inteira, não no espaço que sobra');
      expect(caixa.center.dy, greaterThan(tela.center.dy),
          reason: 'na barra inferior');
      expect(tester.takeException(), isNull);
    });

    testWidgets('o nome do vizinho não fica mais sob o cartão', (tester) async {
      await _montar(tester);

      // Dois itens na lista, um nome na tela: o do selecionado.
      expect(find.text('Jogo 1'), findsNothing);
      expect(find.text('Jogo 0'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('sem itens a barra não quebra', (tester) async {
      final ctrl = await _montar(tester);
      ctrl.listIconsInicial = [];
      ctrl.focusNodeIcones = [];
      ctrl.attTela();
      await tester.pump();

      expect(find.text('Nenhum item. Adicione no modo Fat.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
