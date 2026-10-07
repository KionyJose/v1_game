import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:v1_game/Interface/futuristic_card_effect.dart';

void main() {
  testWidgets('Brilho percorre o card e sai antes de encerrar a animação',
      (tester) async {
    var revision = 0;
    late StateSetter update;
    await tester
        .pumpWidget(MaterialApp(home: StatefulBuilder(builder: (_, state) {
      update = state;
      return Center(
          child: SizedBox(
              width: 180,
              height: 220,
              child: FuturisticCardEffect(
                  selected: true,
                  focused: true,
                  settledRevision: revision,
                  child: const ColoredBox(color: Colors.black))));
    })));
    final shine = find.descendant(
        of: find.byType(FuturisticCardEffect),
        matching: find.byType(CustomPaint));
    Future<bool> hasVisiblePixels() async {
      final painter = tester.widget<CustomPaint>(shine).painter!;
      return (await tester.runAsync(() async {
        final recorder = ui.PictureRecorder();
        painter.paint(Canvas(recorder), const Size(180, 220));
        final picture = recorder.endRecording();
        final image = await picture.toImage(180, 220);
        final bytes = await image.toByteData();
        image.dispose();
        picture.dispose();
        for (var i = 3; i < bytes!.lengthInBytes; i += 4) {
          if (bytes.getUint8(i) != 0) return true;
        }
        return false;
      }))!;
    }

    update(() => revision++);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 525));
    expect(await hasVisiblePixels(), isTrue);
    await tester.pump(const Duration(milliseconds: 515));
    expect(shine, findsOneWidget);
    expect(await hasVisiblePixels(), isFalse);
    await tester.pump(const Duration(milliseconds: 20));
    expect(shine, findsNothing);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });
}
