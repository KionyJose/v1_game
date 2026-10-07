import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v1_game/Interface/futuristic_view_box.dart';

void main() {
  testWidgets('Parallax mantém um único foco e aceita inversão rápida de abas',
      (tester) async {
    final node = FocusNode();
    var page = 0;
    late StateSetter update;
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: StatefulBuilder(builder: (_, state) {
      update = state;
      return FuturisticViewBox(
          page: page,
          child: SizedBox(
              height: 200,
              child: Focus(focusNode: node, child: Text('Página $page'))));
    }))));
    node.requestFocus();
    await tester.pump();
    for (final next in [1, 2, 0, 3, 1]) {
      update(() => page = next);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 80));
      expect(
          find.byWidgetPredicate(
              (widget) => widget is Focus && widget.focusNode == node),
          findsOneWidget);
      expect(node.hasFocus, isTrue);
      expect(find.text('Página $next'), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
    await tester.pump(const Duration(milliseconds: 700));
    await tester.pump();
    expect(find.byType(RawImage), findsNothing);
    update(() => page = 0);
    await tester.pump();
    await tester.pumpWidget(MaterialApp(
        home: Focus(focusNode: node, child: const Text('Outro modo'))));
    node.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(node.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    node.dispose();
  });

  testWidgets('Reduzir animações elimina o deslocamento da troca de abas',
      (tester) async {
    var page = 0;
    late StateSetter update;
    await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
      data: const MediaQueryData(disableAnimations: true),
      child: Scaffold(body: StatefulBuilder(builder: (_, state) {
        update = state;
        return FuturisticViewBox(
            page: page,
            child: SizedBox(height: 200, child: Text('Página $page')));
      })),
    )));
    update(() => page = 1);
    await tester.pump();
    expect(find.text('Página 1'), findsOneWidget);
    expect(tester.widget<Opacity>(find.byType(Opacity)).opacity, 1);
    expect(find.byType(RawImage), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
