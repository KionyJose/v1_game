import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v1_game/Interface/futuristic_particles.dart';

void main() {
  test('Partículas reagem na direção da navegação e a agitação se dissipa', () {
    final motion = FuturisticParticleMotion();
    motion.impulse(.5);
    final start = motion.gust;
    motion.advance(.1);
    expect(motion.drift, greaterThan(0));
    expect(motion.gust, inExclusiveRange(0, start));
    motion.impulse(-1);
    expect(motion.gust, lessThan(0));
    final before = motion.drift;
    motion.advance(.1);
    expect(motion.drift, lessThan(before));
    motion.advance(3);
    expect(motion.gust.abs(), lessThan(.001));
    expect(motion.particles.length, 44);
    motion.dispose();
  });
  test('Desaceleração mantém a mesma trajetória em 30, 60 e 120 Hz', () {
    final results = <double>[];
    for (final hz in [30, 60, 120]) {
      final motion = FuturisticParticleMotion()..impulse(.5);
      for (var frame = 0; frame < hz * 2; frame++) {
        motion.advance(1 / hz);
      }
      results.add(motion.drift);
      expect(motion.particles.length, 44);
      motion.dispose();
    }
    expect(results[0], closeTo(results[1], .000001));
    expect(results[1], closeTo(results[2], .000001));
  });
  testWidgets('Camada pausa fora da tela e libera o ticker e o listener',
      (tester) async {
    final position = ValueNotifier<double>(0);
    Widget scene({bool active = true, bool reduce = false}) => MaterialApp(
        home: MediaQuery(
            data: MediaQueryData(disableAnimations: reduce),
            child: TickerMode(
                enabled: active,
                child: FuturisticParticles(position: position))));
    await tester.pumpWidget(scene());
    await tester.pump(const Duration(milliseconds: 16));
    position.value = 1;
    await tester.pump(const Duration(milliseconds: 16));
    expect(tester.binding.transientCallbackCount, greaterThan(0));
    await tester.pumpWidget(scene(active: false));
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(scene(reduce: true));
    position.value = 0;
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    await tester.pumpWidget(scene());
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pumpWidget(const SizedBox());
    position.value = 1;
    await tester.pump();
    expect(tester.binding.transientCallbackCount, 0);
    expect(tester.takeException(), isNull);
    position.dispose();
  });
}
