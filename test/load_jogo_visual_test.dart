import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:v1_game/Widgets/Pops/Pops.dart';

Future<void> _abrirLoad(WidgetTester tester) async {
  final pad = Paad(escutar: false, janelaCtrl: JanelaCtrl());
  addTearDown(pad.dispose);
  late BuildContext ctx;
  await tester.pumpWidget(ChangeNotifierProvider<Paad>.value(
    value: pad,
    child: MaterialApp(
        home: Builder(builder: (c) {
      ctx = c;
      return const Scaffold(
          backgroundColor: Colors.blue, body: Text('arte do jogo'));
    })),
  ));
  Pops().carregandoGames(ctx, 'Entrando no game...');
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 600));
}

/// O gradiente que fica atrás do load.
LinearGradient _gradienteDoLoad(WidgetTester tester) => tester
    .widgetList<Container>(find.byType(Container))
    .map((c) => c.decoration)
    .whereType<BoxDecoration>()
    .map((d) => d.gradient)
    .whereType<LinearGradient>()
    .firstWhere((g) => g.begin == Alignment.bottomCenter);

void main() {
  testWidgets('Atrás do load fica um gradiente preto sumindo para cima',
      (tester) async {
    await _abrirLoad(tester);

    expect(find.text('Entrando no game...'), findsOneWidget);
    final gradiente = _gradienteDoLoad(tester);

    // Forte embaixo...
    expect(gradiente.colors.first, const Color(0xFF000000));
    // ...e sumindo para cima.
    expect(gradiente.colors.last, Colors.transparent);
    expect(gradiente.end, Alignment.topCenter);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Sem caixa arredondada e sem halo colorido', (tester) async {
    await _abrirLoad(tester);

    // A caixa com brilho roxo/azul competia com a arte do jogo entrando.
    final caixas = tester
        .widgetList<Container>(find.byType(Container))
        .map((c) => c.decoration)
        .whereType<BoxDecoration>()
        .where((d) => d.borderRadius != null || d.boxShadow != null);
    expect(caixas, isEmpty);
    expect(tester.takeException(), isNull);
  });

  testWidgets('A arte atrás continua visível, sem véu cinza', (tester) async {
    await _abrirLoad(tester);

    // `barrierColor` transparente: o escurecimento é só o gradiente, que
    // deixa o topo da tela limpo.
    final veu = tester
        .widgetList<ModalBarrier>(find.byType(ModalBarrier))
        .where((b) => b.color != null && b.color != Colors.transparent);
    expect(veu, isEmpty);
    expect(find.text('arte do jogo'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
