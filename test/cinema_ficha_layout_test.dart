import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v1_game/Tela/Cinema/cinema_ficha.dart';
import 'package:v1_game/Tela/Cinema/tmdb_cine.dart';

void main() {
  Widget ficha({bool informacoes = true}) => MaterialApp(
        home: FichaCine(
          titulo: TituloCine(
            id: 42,
            tipo: TipoCine.filme,
            titulo: 'Um filme com título grande',
            sinopse: List.filled(50, 'Descrição do filme.').join(' '),
          ),
          acoes: const [AcaoFicha.fechar],
          acao: AcaoFicha.fechar,
          onAcao: (_) {},
          visivel: true,
          escritasVisiveis: informacoes,
        ),
      );

  for (final tamanho in [
    const Size(1920, 1080),
    const Size(1024, 640),
    const Size(800, 600),
  ]) {
    testWidgets('descrição fica 20% mais larga que a área do título em $tamanho',
        (tester) async {
      tester.view.physicalSize = tamanho;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(ficha());
      final titulo = tester.getRect(find.byKey(const ValueKey('ficha-titulo')));
      final descricao =
          tester.getRect(find.byKey(const ValueKey('ficha-descricao')));
      expect(descricao.width, closeTo(titulo.width * 1.2, .01));
      expect(descricao.left, titulo.left);
      expect(descricao.right, lessThanOrEqualTo(tamanho.width - 48));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('escurecimento desaparece junto com as informações do trailer',
      (tester) async {
    await tester.pumpWidget(ficha());
    final informacoes = find.byKey(const ValueKey('ficha-informacoes'));
    final veus = find.descendant(
      of: informacoes,
      matching: find.byWidgetPredicate((widget) =>
          widget is DecoratedBox &&
          widget.decoration is BoxDecoration &&
          (widget.decoration as BoxDecoration).gradient != null),
    );
    expect(veus, findsNWidgets(2));
    double opacidade() => tester
        .widget<FadeTransition>(find.descendant(
            of: informacoes, matching: find.byType(FadeTransition)))
        .opacity.value;
    expect(opacidade(), 1);
    await tester.pumpWidget(ficha(informacoes: false));
    await tester.pump(const Duration(seconds: 2));
    expect(opacidade(), 0);
    expect(
        tester.widget<IgnorePointer>(find.descendant(
            of: informacoes, matching: find.byType(IgnorePointer)).first).ignoring,
        isTrue);
    await tester.pumpWidget(ficha());
    await tester.pump(const Duration(seconds: 2));
    expect(opacidade(), 1);
    expect(tester.takeException(), isNull);
  });
}
