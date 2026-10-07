import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v1_game/Interface/futuristic_game_backdrop.dart';

void main() {
  testWidgets('Fundo acompanha um alvo contínuo a 120 Hz sem reiniciar a mola',
      (tester) async {
    final position = ValueNotifier<double>(0);
    await tester.pumpWidget(MaterialApp(
        home: FuturisticGameBackdrop(
            category: 0,
            selected: 0,
            image: 'assets/Futurista/aurora_lake.png',
            position: position)));
    double offset() => tester
        .widget<Transform>(find.byKey(const ValueKey('game-backdrop-current')))
        .transform
        .storage[12];
    for (var frame = 1; frame <= 120; frame++) {
      position.value = frame / 120;
      await tester.pump(const Duration(microseconds: 8333));
    }
    final moving = offset();
    // A continually restarted animation remains near zero until the rail stops.
    expect(moving, lessThan(-40));
    for (var frame = 0; frame < 480; frame++) {
      final before = offset();
      await tester.pump(const Duration(microseconds: 8333));
      expect(offset(), lessThanOrEqualTo(before + .001));
      expect((offset() - before).abs(), lessThan(2));
    }
    expect(offset(), closeTo(-800 * .14, .1));
    await tester.pumpWidget(const SizedBox());
    position.dispose();
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'Fundo segue o carrossel com atraso e desacelera nas duas direções',
      (tester) async {
    final position = ValueNotifier<double>(0);
    var selected = 0;
    late StateSetter update;
    await tester.pumpWidget(
        MaterialApp(home: Scaffold(body: StatefulBuilder(builder: (_, state) {
      update = state;
      return FuturisticGameBackdrop(
          category: 0,
          selected: selected,
          image: 'assets/Futurista/aurora_lake.png',
          position: position);
    }))));
    double offset() => tester
        .widget<Transform>(find.byKey(const ValueKey('game-backdrop-current')))
        .transform
        .storage[12];
    expect(offset(), 0);
    update(() => selected = 1);
    await tester.pump();
    position.value = 1;
    final start = offset();
    expect(start, greaterThan(0));
    await tester.pump(const Duration(milliseconds: 70));
    expect(offset(), start);
    await tester.pump(const Duration(milliseconds: 30));
    await tester.pump(const Duration(milliseconds: 400));
    expect(offset(), inExclusiveRange(0, start));
    final midway = offset();
    await tester.pump(const Duration(milliseconds: 400));
    expect(offset(), lessThan(midway));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(offset(), closeTo(0, .1));
    expect(find.byKey(const ValueKey('game-backdrop-previous')), findsNothing);
    update(() => selected = 0);
    await tester.pump();
    position.value = 0;
    expect(offset(), lessThan(0));
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 400));
    expect(offset(), lessThan(0));
    await tester.pump(const Duration(seconds: 4));
    await tester.pump();
    expect(offset(), closeTo(0, .1));
    // Closing the interface cancels both the delayed start and the springs.
    update(() => selected = 1);
    await tester.pump();
    await tester.pumpWidget(const SizedBox());
    position.value = 1;
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    position.dispose();
  });
}
