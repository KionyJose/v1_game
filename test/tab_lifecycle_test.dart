import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v1_game/Interface/launcher_horizontal_list.dart';
import 'package:v1_game/Interface/lifecycle_carousel.dart';
import 'package:v1_game/Interface/contained_focus_policy.dart';
import 'card_removal_and_image_search_test.dart' show RemovalController;

void main() {
  testWidgets('Foco nos cards não revela parte da próxima aba', (tester) async {
    for (final contained in [false, true]) {
      final pages = PageController();
      final cards = ScrollController();
      final nodes = List.generate(3, (_) => FocusNode());
      await tester.pumpWidget(MaterialApp(
          home: Center(
              child: SizedBox(
        width: 400,
        height: 180,
        child: FocusTraversalGroup(
          policy: contained
              ? ContainedFocusPolicy()
              : ReadingOrderTraversalPolicy(),
          child: PageView(
              controller: pages,
              physics: const NeverScrollableScrollPhysics(),
              children: [
                Stack(children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    width: 800,
                    height: 120,
                    child: ListView(
                      controller: cards,
                      scrollDirection: Axis.horizontal,
                      children: List.generate(
                          3,
                          (i) => SizedBox(
                              width: 300,
                              child: Focus(
                                  focusNode: nodes[i],
                                  autofocus: i == 0,
                                  child: Text('Card $i')))),
                    ),
                  )
                ]),
                const Text('Próxima aba'),
              ]),
        ),
      ))));
      await tester.pumpAndSettle();
      nodes.first.requestFocus();
      await tester.pumpAndSettle();
      nodes.first.focusInDirection(TraversalDirection.right);
      await tester.pumpAndSettle();
      if (contained) {
        expect(nodes[1].hasFocus, isTrue);
        expect(pages.page, closeTo(0, 0.0001),
            reason: 'Mover o foco do card não pode deslocar a aba.');
      } else {
        expect(pages.page, greaterThan(0),
            reason:
                'Reprodução: o ensureVisible padrão também move a aba externa.');
      }
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      pages.dispose();
      cards.dispose();
      for (final node in nodes) {
        node.dispose();
      }
    }
  });

  testWidgets('Troca de aba desliza e desacelera até o destino do Pad',
      (tester) async {
    late RemovalController ctrl;
    await tester.pumpWidget(MaterialApp(home: Builder(builder: (context) {
      ctrl = RemovalController(context);
      ctrl.focusNodeAbaGuias.first.dispose();
      ctrl.focusNodeAbaGuias = List.generate(4, (_) => FocusNode());
      ctrl.focusNodeIcones = [FocusNode()];
      return Scaffold(
          body: Column(children: [
        Row(
            children: List.generate(
                4,
                (i) => Focus(
                      focusNode: ctrl.focusNodeAbaGuias[i],
                      autofocus: i == 0,
                      onFocusChange: (value) =>
                          ctrl.onFocusChangeAbaGuias(value, i),
                      child: Text('Guia $i'),
                    ))),
        Expanded(
            child: PageView(
          controller: ctrl.bodyCtrl,
          physics: const NeverScrollableScrollPhysics(),
          children: List.generate(4, (i) => Center(child: Text('Conteúdo $i'))),
        )),
      ]));
    })));
    await tester.pumpAndSettle();
    ctrl.movAbaGuias('RB');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(ctrl.bodyCtrl.page, greaterThan(0));
    expect(ctrl.bodyCtrl.page, lessThan(1),
        reason: 'A troca deve deslizar, não saltar.');
    await tester.pumpAndSettle();
    expect(ctrl.bodyCtrl.page, closeTo(1, 0.001));
    ctrl.movAbaGuias('RB');
    await tester.pump(const Duration(milliseconds: 60));
    ctrl.movAbaGuias('LB');
    await tester.pumpAndSettle();
    expect(ctrl.bodyCtrl.page, closeTo(1, 0.001));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    ctrl.dispose();
  });

  testWidgets('Lista reutiliza o controller ao sair e retornar à aba',
      (tester) async {
    final controller = ScrollController();
    Widget app(bool visible) => MaterialApp(
        home: Scaffold(
            body: visible
                ? SizedBox(
                    width: 400,
                    height: 100,
                    child: LauncherHorizontalList(
                        controller: controller,
                        itemCount: 12,
                        itemSize: 80,
                        itemBuilder: (_, i) =>
                            SizedBox(width: 80, child: Text('Card $i'))))
                : const Text('Outra aba')));
    for (var i = 0; i < 6; i++) {
      await tester.pumpWidget(app(true));
      controller.animateTo(100,
          duration: const Duration(milliseconds: 700), curve: Curves.linear);
      await tester.pump(const Duration(milliseconds: 20));
      await tester.pumpWidget(app(false));
      await tester.pump(const Duration(milliseconds: 50));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(app(true));
    expect(
        tester
            .widget<ColoredBox>(find.descendant(
                of: find.byType(LauncherHorizontalList),
                matching: find.byType(ColoredBox)))
            .color,
        Colors.transparent);
    controller.jumpTo(0);
    expect(controller.hasClients, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    controller.dispose();
  });

  testWidgets('Autoplay não consulta contexto após sair da aba',
      (tester) async {
    var changes = 0;
    final controller = CarouselSliderController();
    Widget app() => MaterialApp(
            home: Scaffold(
                body: LifecycleCarousel(
          controller: controller,
          options: CarouselOptions(
              autoPlay: true,
              autoPlayInterval: const Duration(milliseconds: 40),
              autoPlayAnimationDuration: const Duration(milliseconds: 10),
              onPageChanged: (_, reason) => changes++),
          items: const [
            Text('Trailer 1'),
            Text('Trailer 2'),
            Text('Trailer 3')
          ],
        )));
    await tester.pumpWidget(app());
    for (var i = 0; i < 12; i++) {
      await tester.pumpWidget(app());
      await tester.pump(const Duration(milliseconds: 20));
    }
    expect(changes, greaterThan(0),
        reason: 'Rebuilds não podem reiniciar o prazo do autoplay.');
    await tester.pumpWidget(const MaterialApp(home: Text('Outra aba')));
    await tester.pump(const Duration(seconds: 5));
    expect(tester.takeException(), isNull);
    final previous = changes;
    await tester.pump(const Duration(seconds: 5));
    expect(changes, previous);
  });
}
