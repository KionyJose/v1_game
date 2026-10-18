import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v1_game/Interface/futuristic_card_effect.dart';
import 'package:v1_game/Interface/futuristic_warmup.dart';

FuturisticCardEffect efeito(WidgetTester tester) =>
    tester.widget<FuturisticCardEffect>(find.byType(FuturisticCardEffect));

void main() {
  testWidgets('O brilho assenta sozinho, sem esperar um movimento',
      (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FuturisticWarmup())));
    // Antes do primeiro quadro terminar, nada assentou ainda.
    expect(efeito(tester).settledRevision, 0);
    await tester.pump();
    // O efeito é o mesmo do card e recebe seleção, foco e a virada de revisão
    // que dispara o brilho — é ela que compila o pipeline.
    final aquecido = efeito(tester);
    expect(aquecido.selected, isTrue);
    expect(aquecido.focused, isTrue);
    expect(aquecido.settledRevision, 1);
    await tester.pump(const Duration(milliseconds: 120));
    expect(tester.takeException(), isNull);
    await tester.pump(FuturisticWarmup.duracao);
    await tester.pumpAndSettle();
  });

  testWidgets('Sai da árvore sozinho e não intercepta o ponteiro',
      (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FuturisticWarmup())));
    await tester.pump();
    expect(find.byType(FuturisticCardEffect), findsOneWidget);
    // O aquecimento embrulha tudo num IgnorePointer; o próprio efeito do card
    // traz o dele para o brilho, por isso são mais de um.
    expect(
        find.descendant(
            of: find.byType(FuturisticWarmup),
            matching: find.byType(IgnorePointer)),
        findsWidgets);
    await tester.pump(FuturisticWarmup.duracao);
    await tester.pumpAndSettle();
    expect(find.byType(FuturisticCardEffect), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Com animações desligadas não aquece nem deixa timer pendente',
      (tester) async {
    await tester.pumpWidget(const MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: true),
            child: Scaffold(body: FuturisticWarmup()))));
    await tester.pump();
    expect(find.byType(FuturisticCardEffect), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sair da tela durante o aquecimento não deixa timer solto',
      (tester) async {
    await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: FuturisticWarmup())));
    await tester.pump();
    await tester.pumpWidget(const MaterialApp(home: Scaffold(body: SizedBox())));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
}
