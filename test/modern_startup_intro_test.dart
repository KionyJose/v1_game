import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:v1_game/Interface/modern_startup_intro.dart';

void main() {
  late Paad pad;
  setUp(() => pad = Paad(escutar: false, janelaCtrl: JanelaCtrl()));
  tearDown(() => pad.dispose());

  Widget app({bool enabled = true, bool reduced = false, VoidCallback? done}) =>
      ChangeNotifierProvider<Paad>.value(
          value: pad,
          child: MaterialApp(
              builder: (_, child) => MediaQuery(
                  data: MediaQueryData(disableAnimations: reduced),
                  child: child!),
              home: ModernStartupIntro(
                  enabled: enabled,
                  onFinished: done,
                  child: const Scaffold(body: Text('Dashboard')))));
  final intro = find.byKey(const ValueKey('modern-startup-intro'));

  testWidgets('Revela a dashboard em dez segundos e nao repete ao reconstruir',
      (tester) async {
    var finished = 0;
    await tester.pumpWidget(app(done: () => finished++));
    final dashboardElement = tester.element(find.text('Dashboard'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 9));
    expect(
        tester
            .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator))
            .value,
        closeTo(.9, .01));
    expect(intro, findsOneWidget);
    expect(finished, 0);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump();
    expect(intro, findsNothing);
    expect(finished, 1);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(identical(tester.element(find.text('Dashboard')), dashboardElement),
        isTrue);
    await tester.pumpWidget(app(done: () => finished++));
    await tester.pump(const Duration(seconds: 12));
    expect(intro, findsNothing);
    expect(finished, 1);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pad absorve direcoes e permite pular uma unica vez',
      (tester) async {
    var finished = 0;
    await tester.pumpWidget(app(done: () => finished++));
    expect(pad.interfaceRouter.dispatch('DIREITA'), isTrue);
    await tester.pump(const Duration(seconds: 2));
    expect(intro, findsOneWidget);
    pad.interfaceRouter.dispatch('2');
    pad.interfaceRouter.dispatch('2');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(intro, findsNothing);
    expect(finished, 1);
    expect(pad.interfaceRouter.dispatch('DIREITA'), isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Enter pula com transicao e desmonta sem callbacks pendentes',
      (tester) async {
    await tester.pumpWidget(app());
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pump();
    expect(intro, findsOneWidget);
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(intro, findsNothing);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 12));
    expect(tester.takeException(), isNull);
  });

  testWidgets('Outros modos nao exibem introducao', (tester) async {
    await tester.pumpWidget(app(enabled: false));
    expect(intro, findsNothing);
    expect(find.text('Dashboard'), findsOneWidget);
    expect(pad.interfaceRouter.dispatch('2'), isFalse);
  });

  testWidgets('Preferencia por movimento reduzido encurta a abertura',
      (tester) async {
    await tester.pumpWidget(app(reduced: true));
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();
    expect(intro, findsNothing);
    expect(tester.takeException(), isNull);
  });
}
