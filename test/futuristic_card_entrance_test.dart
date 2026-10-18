import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v1_game/Interface/futuristic_card_entrance.dart';
import 'package:v1_game/Tela/Tela%20Principal/Widgets/body_futurista.dart';

/// Opacidade aplicada ao card de [index] no instante [t] da entrada.
double opacidade(WidgetTester tester, int index) {
  final opacity = tester.widget<Opacity>(find.descendant(
      of: find.byKey(ValueKey('card-$index')),
      matching: find.byType(Opacity)));
  return opacity.opacity;
}

Widget cascata(AnimationController controlador, int total) => MaterialApp(
    home: Scaffold(
        body: Row(
            children: List.generate(
                total,
                (i) => FuturisticCardEntrance(
                    key: ValueKey('card-$i'),
                    animation: controlador,
                    index: i,
                    child: const SizedBox(width: 10, height: 10))))));

void main() {
  testWidgets('Os cards chegam um a um, não todos de uma vez', (tester) async {
    final controlador = AnimationController(
        vsync: tester, duration: FuturisticCardEntrance.duracao);
    addTearDown(controlador.dispose);
    await tester.pumpWidget(cascata(controlador, 5));
    // Parado no começo, nenhum card chegou.
    for (var i = 0; i < 5; i++) {
      expect(opacidade(tester, i), lessThan(.05), reason: 'card $i');
    }
    controlador.value = .25;
    await tester.pump();
    // No meio da cascata, os primeiros já estão à frente dos últimos.
    expect(opacidade(tester, 0), greaterThan(opacidade(tester, 2)));
    expect(opacidade(tester, 2), greaterThanOrEqualTo(opacidade(tester, 4)));
    expect(opacidade(tester, 0), greaterThan(.5));
    controlador.value = 1;
    await tester.pump();
    for (var i = 0; i < 5; i++) {
      expect(opacidade(tester, i), 1.0, reason: 'card $i no fim');
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('Cards além da janela visível não atrasam a liberação',
      (tester) async {
    final controlador = AnimationController(
        vsync: tester, duration: FuturisticCardEntrance.duracao);
    addTearDown(controlador.dispose);
    await tester.pumpWidget(
        cascata(controlador, FuturisticCardEntrance.escalonados + 6));
    controlador.value = 1;
    await tester.pump();
    // O último escalonado e os seguintes chegam juntos: uma biblioteca grande
    // não faz a entrada durar mais.
    const ultimo = FuturisticCardEntrance.escalonados - 1;
    expect(opacidade(tester, ultimo), 1.0);
    expect(opacidade(tester, ultimo + 5), 1.0);
    controlador.value = .5;
    await tester.pump();
    expect(opacidade(tester, ultimo + 5), opacidade(tester, ultimo));
    expect(tester.takeException(), isNull);
  });

  test('A cascata é lenta o bastante para se ver card a card', () {
    // ~1,8 s no total, com um intervalo visível entre um card e o próximo.
    expect(FuturisticCardEntrance.duracao.inMilliseconds,
        inInclusiveRange(1600, 2100));
    final passo = FuturisticCardEntrance.duracao.inMilliseconds /
        FuturisticCardEntrance.escalonados;
    expect(passo, greaterThan(150),
        reason: 'abaixo disso os cards chegam quase juntos');
  });

  testWidgets('Segurada, a cascata não roda; liberada, ela acontece',
      (tester) async {
    var liberada = false;
    var concluida = false;
    late StateSetter atualizar;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: StatefulBuilder(builder: (context, setState) {
      atualizar = setState;
      return FuturisticHome(
        category: 0,
        selected: 0,
        items: const [FuturisticItem('Jogo', '', Icons.sports_esports)],
        itemNodes: [FocusNode()],
        categoryNodes: List.generate(4, (_) => FocusNode()),
        itemScope: FocusScopeNode(),
        categoryScope: FocusScopeNode(),
        startEntrance: liberada,
        onEntranceDone: () => concluida = true,
        onSelect: (_) {},
        onCategory: (_) {},
        onOpen: () {},
        onMenu: () {},
      );
    }))));
    await tester.pump();
    await tester.pump(FuturisticCardEntrance.duracao);
    // Enquanto o launcher não libera, nada corre e o controle segue preso.
    expect(concluida, isFalse);
    atualizar(() => liberada = true);
    await tester.pump();
    await tester.pump();
    // Sem pumpAndSettle: as partículas do fundo animam sem parar.
    await tester.pump(FuturisticCardEntrance.duracao);
    await tester.pump(const Duration(milliseconds: 100));
    expect(concluida, isTrue);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Nunca some de todo: a pintura segue acontecendo',
      (tester) async {
    final controlador = AnimationController(
        vsync: tester, duration: FuturisticCardEntrance.duracao);
    addTearDown(controlador.dispose);
    await tester.pumpWidget(cascata(controlador, 3));
    // Em zero o Flutter descartaria a pintura, e o card não aqueceria nada.
    for (var i = 0; i < 3; i++) {
      expect(opacidade(tester, i), greaterThan(0));
    }
    expect(tester.takeException(), isNull);
  });
}
