import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:v1_game/Interface/futuristic_game_feed.dart';
import 'package:v1_game/Interface/pad_playback_hints.dart';
import 'package:v1_game/Modelos/videoYT.dart';
import 'package:v1_game/Tela/Tela loja/componentes/trailer_player.dart';
import 'package:v1_game/Tela/Tela loja/scraps/jogo_detalhes.dart';

VideoYT item(String id) => VideoYT()..videoID = id;

void main() {
  test('Alterna as tags e prioriza videos novos sem repetir a busca em cache',
      () async {
    final queries = <String>[];
    var newsCalls = 0;
    final feed = PersonalizedGameFeed(
        random: Random(7),
        newsSearch: (_) async {
          newsCalls++;
          return [];
        },
        videoSearch: (query, _) async {
          queries.add(Uri.decodeQueryComponent(query));
          return [
            item('common'),
            for (var i = 0; i < 12; i++) item('query-${queries.length}-$i')
          ];
        });
    final first = await feed.load('Game', tags: ['montage', 'funny', 'review']);
    final second =
        await feed.load('Game', tags: ['montage', 'funny', 'review']);
    expect(queries.length, 2);
    expect(queries[0], isNot(queries[1]));
    expect(queries.every((query) => query.startsWith('Game ')), isTrue);
    final old = first.videos.map((video) => video.videoID).toSet();
    expect(
        second.videos.where((video) => old.contains(video.videoID)), isEmpty);
    expect(newsCalls, 1);
  });

  test('Consultas simultaneas compartilham apenas a requisicao em andamento',
      () async {
    final pending = Completer<List<VideoYT>>();
    var calls = 0;
    final feed = PersonalizedGameFeed(
        newsSearch: (_) async => [],
        videoSearch: (_, __) {
          calls++;
          return pending.future;
        });
    final first = feed.load('Game');
    final second = feed.load('Game');
    expect(identical(first, second), isTrue);
    pending.complete([item('first')]);
    await first;
    await feed.load('Game');
    expect(calls, 2);
  });

  testWidgets('Instrucoes somem com fade e o movimento renova o prazo',
      (tester) async {
    final key = GlobalKey<PadPlaybackHintsState>();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: PadPlaybackHints(key: key, text: 'Comandos'))));
    await tester.pump(const Duration(seconds: 2));
    expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0);
    await tester.pump(const Duration(milliseconds: 300));
    key.currentState!.show();
    await tester.pump();
    expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1);
    await tester.pump(const Duration(milliseconds: 1500));
    key.currentState!.show();
    await tester.pump(const Duration(milliseconds: 1500));
    expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        1);
    await tester.pump(const Duration(milliseconds: 500));
    expect(tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity,
        0);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('R3 expande e B retorna mantendo a mesma instancia do player',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pad = Paad(escutar: false, janelaCtrl: JanelaCtrl());
    final key = GlobalKey<TrailerPlayerState>();
    await tester.pumpWidget(ChangeNotifierProvider<Paad>.value(
        value: pad,
        child: MaterialApp(
            home: Scaffold(
                body: Center(
                    child: SizedBox(
                        width: 340,
                        height: 200,
                        child: TrailerPlayer(
                            key: key,
                            inline: true,
                            trailer: const TrailerJogo(
                                titulo: 'Teste', youtubeId: 'bad'))))))));
    await tester.pumpAndSettle();
    final original = key.currentState!;
    expect(original.command('R3'), isTrue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 210));
    final fullscreen = find.byKey(const ValueKey('trailer-fullscreen'));
    expect(tester.getRect(fullscreen).width, inExclusiveRange(340, 1280));
    await tester.pumpAndSettle();
    expect(tester.getRect(fullscreen).size, const Size(1280, 720));
    pad.interfaceRouter.dispatch('DIREITA');
    await tester.pump();
    pad.interfaceRouter.dispatch('3');
    await tester.pumpAndSettle();
    expect(fullscreen, findsNothing);
    expect(identical(key.currentState, original), isTrue);
    original.command('R3');
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('R3');
    await tester.pumpAndSettle();
    expect(fullscreen, findsNothing);
    await tester.pumpWidget(const SizedBox());
    pad.dispose();
    expect(tester.takeException(), isNull);
  });
}
