import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottie/lottie.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:v1_game/Global.dart';
import 'package:v1_game/Interface/futuristic_action_tile.dart';
import 'package:v1_game/Interface/futuristic_content_skeleton.dart';
import 'package:v1_game/Interface/futuristic_topic_label.dart';
import 'package:v1_game/Interface/futuristic_card_fold.dart';
import 'package:v1_game/Interface/futuristic_card_effect.dart';
import 'package:v1_game/Interface/futuristic_window_controls.dart';
import 'package:v1_game/Interface/futuristic_game_feed.dart';
import 'package:v1_game/Interface/futuristic_launch.dart';
import 'package:v1_game/Interface/futuristic_details_transition.dart';
import 'package:v1_game/Modelos/IconeInicial.dart';
import 'package:v1_game/Modelos/NoticiaGame.dart';
import 'package:v1_game/Modelos/videoYT.dart';
import 'package:v1_game/Tela/Tela Principal/PrincipalCtrl.dart';
import 'package:v1_game/Tela/Tela Principal/Futurista/futuristic_game_details.dart';

VideoYT video(int index) => VideoYT()
  ..titulo = 'Vídeo $index'
  ..videoID = 'video$index'
  ..capaM = ''
  ..capaG = ''
  ..capaP = ''
  ..urlVideo = 'https://example.com/video$index'
  ..nomeGame = 'Jogo teste'
  ..descricao = ''
  ..canal = ''
  ..data = '';
FuturisticGameContent content() => FuturisticGameContent(
    videos: List.generate(4, video),
    news: List.generate(
        6,
        (i) => NoticiaGame(
            titulo: 'Notícia $i',
            veiculo: 'Fonte $i',
            descricao: 'Novidades do jogo $i.',
            url: 'https://example.com/$i')));

class DetailsController extends PrincipalCtrl {
  DetailsController(super.ctx);
  int executions = 0;
  @override
  Future<void> iniciaTela() async {
    focusNodeCinema = [];
    focusNodeMusica = [];
    focusNodeLoja = [];
    focusNodeVideos = [];
  }

  @override
  Future<void> btnEntrar(
      {Future<void> Function()? apresentarInicializacao,
      bool reportErrors = false}) async {
    executions++;
  }
}

void main() {
  late Paad pad;
  setUp(() => pad = Paad(escutar: false, janelaCtrl: JanelaCtrl()));
  tearDown(() => pad.dispose());
  Widget app(Widget home, {bool animations = false}) =>
      ChangeNotifierProvider<Paad>.value(
          value: pad,
          child: MaterialApp(
              builder: (_, child) => MediaQuery(
                  data: MediaQueryData(disableAnimations: !animations),
                  child: child!),
              home: home));
  Future<void> size(WidgetTester tester, Size value) async {
    tester.view.physicalSize = value;
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  FuturisticGameDetails details(
          {Future<FuturisticGameContent> Function(String)? load}) =>
      FuturisticGameDetails(
          name: 'Jogo teste',
          image: '',
          loadContent: load ?? (_) async => content(),
          trailerBuilder: (trailer) => ColoredBox(
              color: Colors.black,
              child: Center(child: Text('Reproduzindo ${trailer.youtubeId}'))));

  testWidgets('Pad navega pelos titulos e retorna ao Jogar com brilho',
      (tester) async {
    await size(tester, const Size(1280, 720));
    await tester.pumpWidget(app(details()));
    await tester.pumpAndSettle();
    FuturisticActionTile tile(String key) =>
        tester.widget<FuturisticActionTile>(find.byKey(ValueKey(key)));
    Future<void> move(String direction) async {
      pad.interfaceRouter.dispatch(direction);
      await tester.pumpAndSettle();
    }

    final play = tile('futuristic-play');
    final initialShine = tester
        .widget<FuturisticCardEffect>(find.byType(FuturisticCardEffect))
        .settledRevision;
    await move('BAIXO');
    expect(
        tester
            .widget<FuturisticTopicLabel>(
                find.byKey(const ValueKey('futuristic-videos-heading')))
            .node
            .hasFocus,
        isTrue);
    await move('DIREITA');
    expect(
        tester
            .widget<FuturisticTopicLabel>(
                find.byKey(const ValueKey('futuristic-news-heading')))
            .node
            .hasFocus,
        isTrue);
    await move('CIMA');
    final viewer = tester.widget<FuturisticActionTile>(find.ancestor(
        of: find.byType(AspectRatio),
        matching: find.byType(FuturisticActionTile)));
    expect(viewer.node.hasFocus, isTrue);
    await move('ESQUERDA');
    expect(play.node.hasFocus, isTrue);
    expect(
        tester
            .widget<FuturisticCardEffect>(find.byType(FuturisticCardEffect))
            .settledRevision,
        greaterThan(initialShine));
    await move('DIREITA');
    expect(viewer.node.hasFocus, isTrue);
    await move('BAIXO');
    await move('ESQUERDA');
    await move('BAIXO');
    final videoTile = tester.widget<FuturisticActionTile>(find.ancestor(
        of: find.text('V\u00eddeo 0'),
        matching: find.byType(FuturisticActionTile)));
    expect(videoTile.node.hasFocus, isTrue);
    for (var i = 1; i < 4; i++) {
      await move('DIREITA');
      final next = find.ancestor(
          of: find.text('V\u00eddeo $i'),
          matching: find.byType(FuturisticActionTile));
      expect(tester.widget<FuturisticActionTile>(next).node.hasFocus, isTrue);
      final bounds = tester.getRect(next);
      expect(bounds.right, lessThanOrEqualTo(1280));
      expect(bounds.left, greaterThanOrEqualTo(0));
    }

    await move('CIMA');
    expect(
        tester
            .widget<FuturisticTopicLabel>(
                find.byKey(const ValueKey('futuristic-videos-heading')))
            .node
            .hasFocus,
        isTrue);
    await move('CIMA');
    expect(play.node.hasFocus, isTrue);
    expect(tester.getRect(find.byKey(const ValueKey('futuristic-play'))).top,
        greaterThanOrEqualTo(0));
    expect(find.byType(FuturisticHeaderControls), findsOneWidget);
    final header = find.byType(FuturisticHeaderControls);
    expect(
        find.descendant(
            of: header, matching: find.byIcon(Icons.settings_rounded)),
        findsOneWidget);
    expect(
        find.descendant(
            of: header, matching: find.byIcon(Icons.sports_esports_rounded)),
        findsOneWidget);
    expect(
        find.descendant(of: header, matching: find.byIcon(Icons.close_rounded)),
        findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Pad troca vídeos no box, abre notícia e recupera o foco',
      (tester) async {
    await size(tester, const Size(1280, 720));
    await tester.pumpWidget(app(details()));
    await tester.pumpAndSettle();
    final play = tester.widget<FuturisticActionTile>(
        find.byKey(const ValueKey('futuristic-play')));
    expect(play.node.hasFocus, isTrue);
    final headerRect = tester.getRect(find.byType(FuturisticHeaderControls));
    final cover = find.byKey(const ValueKey('futuristic-game-cover'));
    expect(cover, findsOneWidget);
    final viewer = find.byType(AspectRatio);
    expect(tester.getRect(cover).right, lessThan(tester.getRect(viewer).left));
    expect(find.byKey(const ValueKey('futuristic-details-background-blur')),
        findsOneWidget);

    pad.interfaceRouter.dispatch('BAIXO');
    await tester.pumpAndSettle();
    expect(play.node.hasFocus, isFalse);
    for (final index in [0, 1]) {
      final tile = find.ancestor(
          of: find.text('Vídeo $index'),
          matching: find.byType(FuturisticActionTile));
      tester.widget<FuturisticActionTile>(tile).node.requestFocus();
      await tester.pumpAndSettle();
      pad.interfaceRouter.dispatch('2');
      await tester.pumpAndSettle();
      expect(find.text('Reproduzindo video$index'), findsOneWidget);
    }
    final news = find.ancestor(
        of: find.text('Notícia 5'),
        matching: find.byType(FuturisticActionTile));
    final newsNode = tester.widget<FuturisticActionTile>(news).node;
    newsNode.requestFocus();
    await tester.pumpAndSettle();
    expect(tester.getRect(news).bottom, lessThanOrEqualTo(720));
    expect(tester.getRect(find.byType(FuturisticHeaderControls)), headerRect);

    pad.interfaceRouter.dispatch('2');
    await tester.pumpAndSettle();
    expect(find.text('Ler na fonte'), findsOneWidget);
    pad.interfaceRouter.dispatch('3');
    await tester.pumpAndSettle();
    expect(find.text('Ler na fonte'), findsNothing);
    expect(newsNode.hasFocus, isTrue);
    final scroll = tester
        .widget<SingleChildScrollView>(find.byType(SingleChildScrollView).first)
        .controller!;
    expect(scroll.offset, greaterThan(0));
    play.node.requestFocus();
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byKey(const ValueKey('futuristic-play'))).top,
        greaterThanOrEqualTo(0));
    expect(scroll.offset, closeTo(0, .01));
    newsNode.requestFocus();
    await tester.pumpAndSettle();
    final viewerTile = tester.widget<FuturisticActionTile>(
        find.ancestor(of: viewer, matching: find.byType(FuturisticActionTile)));
    viewerTile.node.requestFocus();
    await tester.pumpAndSettle();
    expect(scroll.offset, closeTo(0, .01));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Card de video nao transborda durante a animacao de foco',
      (tester) async {
    await size(tester, const Size(1280, 720));
    final result = content();
    result.videos.first.titulo =
        'Um titulo de video suficientemente longo para ocupar duas linhas no card';
    await tester.pumpWidget(ChangeNotifierProvider<Paad>.value(
        value: pad,
        child: MaterialApp(
            home: MediaQuery(
                data: const MediaQueryData(textScaler: TextScaler.linear(1.25)),
                child: details(load: (_) async => result)))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));
    final tile = find.ancestor(
        of: find.text(result.videos.first.titulo),
        matching: find.byType(FuturisticActionTile));
    tester.widget<FuturisticActionTile>(tile).node.requestFocus();
    await tester.pump();
    for (var i = 0; i < 12; i++) {
      await tester.pump(const Duration(milliseconds: 16));
      expect(tester.takeException(), isNull);
    }
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  for (final early in [true, false]) {
    testWidgets('Jogar fecha sem esperar dados: entrada interrompida=$early',
        (tester) async {
      await size(tester, const Size(1280, 720));
      final pending = Completer<FuturisticGameContent>();
      var searches = 0;
      late BuildContext root;
      await tester.pumpWidget(app(Builder(builder: (context) {
        root = context;
        return const Scaffold(body: Text('Biblioteca'));
      }), animations: true));
      final route = PageRouteBuilder<bool>(
          transitionDuration: const Duration(milliseconds: 580),
          reverseTransitionDuration: const Duration(milliseconds: 380),
          pageBuilder: (_, __, ___) => details(load: (_) {
                searches++;
                return pending.future;
              }),
          transitionsBuilder: (_, animation, __, child) =>
              FuturisticDetailsTransition(animation: animation, child: child));
      final result = Navigator.of(root).push(route);
      await tester.pump();
      await tester.pump(Duration(milliseconds: early ? 100 : 600));
      await tester.pump();
      expect(searches, early ? 0 : 1);
      pad.interfaceRouter.dispatch('2');
      await tester.pump();
      expect(route.animation!.status, AnimationStatus.reverse);
      pending.complete(content());
      await tester.pump(const Duration(milliseconds: 40));
      expect(find.text('Vídeo 0'), findsNothing);
      await tester.pump(const Duration(milliseconds: 400));
      await tester.pump();
      expect(await result, isTrue);
      expect(find.byType(FuturisticGameDetails), findsNothing);
      expect(find.text('Biblioteca'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('Jogar inicia uma vez e o Pad controla a apresentação de entrada',
      (tester) async {
    await size(tester, const Size(1280, 720));
    final composition = await tester.runAsync(
        () => AssetLottie('assets/Futurista/game_controller.json').load());
    expect(composition!.duration, const Duration(milliseconds: 3200));
    var executions = 0;
    late BuildContext homeContext;
    await tester.pumpWidget(app(Builder(builder: (context) {
      homeContext = context;
      return const Scaffold(body: Text('Biblioteca'));
    })));
    var revealed = false;
    final session = launchFuturisticGameFromLibrary(homeContext,
        detailsRoute: MaterialPageRoute<bool>(builder: (_) => details()),
        name: 'Jogo teste',
        image: '', revealLibrary: () async {
      expectSync(find.byType(FuturisticGameDetails, skipOffstage: false),
          findsNothing);
      revealed = true;
    }, start: (present) async {
      expectSync(revealed, isTrue);
      expectSync(find.byType(FuturisticGameDetails, skipOffstage: false),
          findsNothing);
      executions++;
      await present();
    });
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('2');
    await tester.pump();
    pad.interfaceRouter.dispatch('2');
    await tester.pump(const Duration(milliseconds: 400));
    await tester.pumpAndSettle();
    expect(executions, 1);
    expect(
        find.byType(FuturisticGameDetails, skipOffstage: false), findsNothing);
    expect(find.text('Biblioteca', skipOffstage: false), findsOneWidget);
    expect(find.text('Iniciando seu jogo'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('futuristic-launch-blur')), findsOneWidget);
    final lottieBox =
        tester.getRect(find.byKey(const ValueKey('futuristic-launch-lottie')));
    expect(lottieBox.width, closeTo(1280 * .25, .01));
    expect(lottieBox.center.dx, closeTo(640, .01));

    expect(find.byType(FuturisticLaunch), findsOneWidget);
    pad.interfaceRouter.dispatch('3');
    await tester.pump();
    expect(find.byType(FuturisticLaunch), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
    pad.interfaceRouter.dispatch('3');
    await tester.pumpAndSettle();
    expect(await session, isTrue);
    expect(find.text('Biblioteca'), findsOneWidget);
    expect(find.byType(FuturisticGameDetails), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('Enter fecha a entrada após a confirmação tardia do executável',
      (tester) async {
    await size(tester, const Size(1280, 720));
    final ready = ValueNotifier(false);
    late BuildContext root;
    await tester.pumpWidget(app(Builder(builder: (context) {
      root = context;
      return const Scaffold(body: Text('Biblioteca'));
    })));
    final route = DialogRoute<void>(
        context: root,
        builder: (_) =>
            FuturisticLaunch(name: 'Jogo teste', image: '', ready: ready));
    Navigator.of(root).push(route);
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    ready.value = true;
    await tester.pump(const Duration(milliseconds: 200));
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    expect(find.byType(FuturisticLaunch), findsNothing);
    ready.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Falha ao iniciar permanece na biblioteca, sem reabrir detalhes',
      (tester) async {
    await size(tester, const Size(1280, 720));
    late BuildContext root;
    await tester.pumpWidget(app(Builder(builder: (context) {
      root = context;
      return const Scaffold(body: Text('Biblioteca'));
    })));
    final session = launchFuturisticGameFromLibrary(root,
        detailsRoute: MaterialPageRoute<bool>(builder: (_) => details()),
        name: 'Jogo teste',
        image: '',
        revealLibrary: () async {},
        start: (_) async => throw StateError('Arquivo ausente'));
    final failure = expectLater(session, throwsStateError);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    await failure;
    expect(find.byType(FuturisticLaunch), findsNothing);
    expect(
        find.byType(FuturisticGameDetails, skipOffstage: false), findsNothing);
    expect(find.text('Biblioteca'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Voltar dos detalhes nao inicia o jogo nem exibe o Lottie',
      (tester) async {
    await size(tester, const Size(1280, 720));
    late BuildContext root;
    await tester.pumpWidget(app(Builder(builder: (context) {
      root = context;
      return const Scaffold(body: Text('Biblioteca'));
    })));
    var executions = 0;
    final session = launchFuturisticGameFromLibrary(root,
        detailsRoute: MaterialPageRoute<bool>(builder: (_) => details()),
        name: 'Jogo teste',
        image: '',
        revealLibrary: () async {}, start: (_) async {
      executions++;
    });
    await tester.pumpAndSettle();
    pad.interfaceRouter.dispatch('3');
    await tester.pumpAndSettle();
    expect(await session, isFalse);
    expect(executions, 0);
    expect(find.byType(FuturisticLaunch), findsNothing);
    expect(find.text('Biblioteca'), findsOneWidget);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets(
      'Layout compacto e busca tardia desmontam sem callbacks inválidos',
      (tester) async {
    await size(tester, const Size(640, 480));
    final pending = Completer<FuturisticGameContent>();
    await tester.pumpWidget(app(details(load: (_) => pending.future)));
    await tester.pump(const Duration(milliseconds: 400));
    expect(find.text('Jogar'), findsOneWidget);
    expect(find.byType(FuturisticContentSkeleton), findsNWidgets(3));
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    pending.complete(content());
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'Baixo e Enter abrem detalhes no Futurista, sem iniciar executável',
      (tester) async {
    final original = configSistema;
    configSistema = original.copyWith(viewType: 'futurista');
    late DetailsController ctrl;
    await tester.pumpWidget(app(Builder(builder: (context) {
      ctrl = DetailsController(context);
      ctrl.telaIniciada = true;
      ctrl.stateTela = true;
      ctrl.listIconsInicial = [
        IconInicial([
          'nome: Jogo teste',
          'local: teste.exe',
          'img: ',
          'imgAux: ',
          'lugar: 1'
        ])
      ];
      ctrl.focusNodeIcones = [FocusNode()];
      ctrl.focusNodeAbaGuias = List.generate(4, (_) => FocusNode());
      return Scaffold(
          body: Column(children: [
        FocusScope(
            node: ctrl.focusScopeAbaGuias,
            child: Focus(
                focusNode: ctrl.focusNodeAbaGuias[0],
                child: const Text('Jogos'))),
        FocusScope(
            node: ctrl.focusScopeIcones,
            child: Focus(
                focusNode: ctrl.focusNodeIcones[0], child: const Text('Card'))),
      ]));
    })));
    var opens = 0;
    Completer<void>? close;
    ctrl.abrirDetalhesFuturista = () {
      opens++;
      close = Completer<void>();
      return close!.future;
    };
    ctrl.focusNodeIcones[0].requestFocus();
    await tester.pump();
    ctrl.comandoSlim('BAIXO');
    ctrl.comandoSlim('2');
    expect(opens, 1);
    expect(ctrl.executions, 0);
    close!.complete();
    await tester.pump();
    ctrl.comandoSlim('2');
    expect(opens, 2);
    expect(ctrl.executions, 0);
    close!.complete();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpWidget(const SizedBox());
    ctrl.dispose();
    configSistema = original;
    expect(tester.takeException(), isNull);
  });

  testWidgets('Card gira para baixo e volta suavemente sem substituir o foco',
      (tester) async {
    var opening = false;
    late StateSetter update;
    await tester
        .pumpWidget(MaterialApp(home: StatefulBuilder(builder: (_, state) {
      update = state;
      return Center(
          child: SizedBox(
              width: 220,
              height: 220,
              child: FuturisticCardFold(
                  opening: opening,
                  child: const ColoredBox(color: Colors.white))));
    })));
    update(() => opening = true);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 225));
    final transform = find.descendant(
        of: find.byType(FuturisticCardFold), matching: find.byType(Transform));
    expect(tester.widget<Transform>(transform).transform.storage[5],
        inExclusiveRange(0, 1));
    await tester.pump(const Duration(milliseconds: 225));
    expect(tester.widget<Transform>(transform).transform.storage[5],
        closeTo(0, .001));
    update(() => opening = false);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 450));
    expect(tester.widget<Transform>(transform).transform.storage[5],
        closeTo(1, .001));
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  });

  testWidgets('Prévia visual dos detalhes Futurista', (tester) async {
    await size(tester, const Size(1280, 720));
    await tester.runAsync(() async {
      await LiquidGlassShaders.ensureLoaded(false);
      final font = FontLoader('Preview')
        ..addFont(Future.value(ByteData.sublistView(
            await File(r'C:\Windows\Fonts\segoeui.ttf').readAsBytes())));
      await font.load();
      final gamer = FontLoader('Oxanium')
        ..addFont(rootBundle.load('assets/Futurista/Oxanium.ttf'));
      await gamer.load();
      final bodyFont = FontLoader('Roboto')
        ..addFont(Future.value(ByteData.sublistView(
            await File(r'C:\Windows\Fonts\segoeui.ttf').readAsBytes())));
      await bodyFont.load();
      final icons = FontLoader('MaterialIcons')
        ..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    const key = ValueKey('details-preview');
    await tester.pumpWidget(ChangeNotifierProvider<Paad>.value(
        value: pad,
        child: MaterialApp(
            theme: ThemeData(fontFamily: 'Preview'),
            home: RepaintBoundary(
                key: key,
                child: FuturisticGameDetails(
                    name: 'Seu próximo universo',
                    image: 'assets/Futurista/aurora_lake.png',
                    loadContent: (_) async => content())))));
    await tester.runAsync(() => precacheImage(
        const AssetImage('assets/Futurista/aurora_lake.png'),
        tester.element(find.byType(FuturisticGameDetails))));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 600));
    await tester.runAsync(() async {
      final boundary =
          tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
      final image = await boundary.toImage(pixelRatio: 1);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      await File('build/futuristic-details-preview.png')
          .writeAsBytes(bytes!.buffer.asUint8List());
      image.dispose();
    });
    await tester.pumpWidget(const SizedBox());
    expect(tester.takeException(), isNull);
  }, skip: Platform.environment['GENERATE_FUTURISTIC_PREVIEW'] != '1');
}
