import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:v1_game/Interface/launcher_pad_scope.dart';
import 'package:v1_game/Interface/futuristic_card_effect.dart';
import 'package:v1_game/Widgets/Pops/pop_mais.dart';
import 'package:v1_game/Modelos/configs_sistema.dart';
import 'package:v1_game/Tela/Tela%20Principal/Widgets/body_futurista.dart';

void main() {
  testWidgets('Prévia visual do modo Futurista', (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.runAsync(() async {
      await LiquidGlassShaders.ensureLoaded(false);
      final loader = FontLoader('Preview');
      loader.addFont(Future.value(ByteData.sublistView(
          await File(r'C:\Windows\Fonts\segoeui.ttf').readAsBytes())));
      await loader.load();
      final menuFont = FontLoader('Roboto');
      menuFont.addFont(Future.value(ByteData.sublistView(
          await File(r'C:\Windows\Fonts\segoeui.ttf').readAsBytes())));
      await menuFont.load();
      final gamerFont = FontLoader('Oxanium');
      gamerFont.addFont(rootBundle.load('assets/Futurista/Oxanium.ttf'));
      await gamerFont.load();
      final icons = FontLoader('MaterialIcons');
      icons.addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'));
      await icons.load();
    });
    final nodes = List.generate(8, (_) => FocusNode());
    final tabs = List.generate(4, (_) => FocusNode());
    final scope = FocusScopeNode();
    final tabScope = FocusScopeNode();
    const boundaryKey = ValueKey('futuristic-preview');
    await tester.pumpWidget(MaterialApp(
        theme: ThemeData(fontFamily: 'Preview'),
        home: Scaffold(
            body: RepaintBoundary(
                key: boundaryKey,
                child: FuturisticHome(
                    category: 0,
                    selected: 0,
                    items: List.generate(
                        8,
                        (i) => FuturisticItem(
                            [
                              'Sua biblioteca',
                              'Cinema',
                              'Música',
                              'Loja Interna'
                            ][i % 4],
                            '',
                            Icons.sports_esports_rounded)),
                    itemNodes: nodes,
                    categoryNodes: tabs,
                    itemScope: scope,
                    categoryScope: tabScope,
                    onSelect: (_) {},
                    onCategory: (_) {},
                    onOpen: () {},
                    onMenu: () {})))));
    await tester.runAsync(() async {
      final context = tester.element(find.byType(FuturisticHome));
      await precacheImage(
          const AssetImage('assets/Futurista/aurora_lake.png'), context);
      await precacheImage(const AssetImage('assets/IconeAppV1.png'), context);
    });
    nodes.first.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    final boundary =
        tester.renderObject<RenderRepaintBoundary>(find.byKey(boundaryKey));
    await tester.runAsync(() async {
      final image = await boundary.toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final output = File(Platform.environment['FUTURISTIC_PREVIEW_PATH'] ??
          'build/futuristic-preview.png');
      await output.parent.create(recursive: true);
      await output.writeAsBytes(png!.buffer.asUint8List());
      image.dispose();
    });
    expect(tester.takeException(), isNull);
    final menuResult =
        PopMais.mais(tester.element(find.byType(FuturisticHome)));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() async {
      await Future<void>.delayed(Duration.zero);
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.runAsync(() async {
      final menuBoundary = tester.renderObject<RenderRepaintBoundary>(find
          .ancestor(
              of: find.text('Mais'), matching: find.byType(RepaintBoundary))
          .first);
      final image = await menuBoundary.toImage();
      final png = await image.toByteData(format: ui.ImageByteFormat.png);
      final base = Platform.environment['FUTURISTIC_PREVIEW_PATH'] ??
          'build/futuristic-preview.png';
      await File(base.replaceAll('.png', '-menu.png'))
          .writeAsBytes(png!.buffer.asUint8List());
      image.dispose();
    });
    Navigator.of(tester.element(find.text('Mais'))).pop('');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump();
    expect(await menuResult, '');
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    for (final node in [...nodes, ...tabs]) {
      node.dispose();
    }
    scope.dispose();
    tabScope.dispose();
  }, skip: Platform.environment['GENERATE_FUTURISTIC_PREVIEW'] != '1');
  test('Futurista preserva a escolha ao serializar configurações', () {
    final config = ConfigSistema.defaults()..viewType = 'futurista';
    expect(ConfigSistema.fromJson(config.toJson()).viewType, 'futurista');
  });

  testWidgets('Destaque desliza e redireciona ao trocar rapidamente as abas',
      (tester) async {
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final tabs = List.generate(4, (_) => FocusNode());
    final scope = FocusScopeNode(), tabScope = FocusScopeNode();
    var category = 0;
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: StatefulBuilder(
                builder: (_, update) => FuturisticHome(
                    category: category,
                    selected: 0,
                    items: const [],
                    itemNodes: const [],
                    categoryNodes: tabs,
                    itemScope: scope,
                    categoryScope: tabScope,
                    onSelect: (_) {},
                    onCategory: (value) => update(() => category = value),
                    onOpen: () {},
                    onMenu: () {})))));
    tabs.first.requestFocus();
    await tester.pump();
    final indicator = find.byKey(const ValueKey('futuristic-tab-indicator'));
    final origin = tester.getRect(indicator).left;
    final width = tester.getRect(indicator).width;
    tabs[1].requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.getRect(indicator).left,
        inExclusiveRange(origin, origin + width));
    tabs[3].requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 360));
    expect(tester.getRect(indicator).left, closeTo(origin + width * 3, .01));
    tabs[0].requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 360));
    expect(tester.getRect(indicator).left, closeTo(origin, .01));
    await tester.pumpWidget(const SizedBox());
    for (final node in tabs) {
      node.dispose();
    }
    scope.dispose();
    tabScope.dispose();
    expect(tester.takeException(), isNull);
  });

  testWidgets('Brilho aparece após parar e é cancelado ao trocar a seleção',
      (tester) async {
    var selected = true;
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
                  selected: selected,
                  focused: selected,
                  settledRevision: revision,
                  child: const ColoredBox(color: Colors.black))));
    })));
    final shine = find.descendant(
        of: find.byType(FuturisticCardEffect),
        matching: find.byType(CustomPaint));
    expect(shine, findsNothing);
    update(() => revision++);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(shine, findsOneWidget);
    update(() => selected = false);
    await tester.pump();
    expect(shine, findsNothing);
    update(() {
      selected = true;
      revision++;
    });
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });

  testWidgets('A interface cede o Pad aos menus antigos e retoma ao fechar',
      (tester) async {
    final pad = Paad(escutar: false, janelaCtrl: JanelaCtrl());
    late BuildContext pageContext;
    var commands = 0;
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: pad,
        child: MaterialApp(home: Builder(builder: (context) {
          pageContext = context;
          return LauncherPadScope(
              onCommand: (_) {
                commands++;
                return true;
              },
              child: const SizedBox());
        }))));
    expect(pad.interfaceRouter.dispatch('DIREITA'), isTrue);
    showDialog<void>(
        context: pageContext,
        builder: (_) => const AlertDialog(content: Text('Menu antigo')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(pad.interfaceRouter.dispatch('DIREITA'), isFalse);
    expect(commands, 1);
    Navigator.of(pageContext).pop();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    expect(pad.interfaceRouter.dispatch('DIREITA'), isTrue);
    expect(commands, 2);
    await tester.pumpWidget(const SizedBox());
    pad.dispose();
  });

  testWidgets('Pad e setas mantêm foco, revelam cartões e desmontam sem erro',
      (tester) async {
    tester.view.reset();
    tester.view.physicalSize = const Size(1280, 720);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final pad = Paad(escutar: false, janelaCtrl: JanelaCtrl());
    final nodes = List.generate(18, (_) => FocusNode());
    final tabs = List.generate(4, (_) => FocusNode());
    final itemScope = FocusScopeNode();
    final tabScope = FocusScopeNode();
    var selected = 0;
    var category = 0;
    var opened = 0;
    late StateSetter update;
    final items = List.generate(
        18, (i) => FuturisticItem('Jogo $i', '', Icons.sports_esports));
    await tester.pumpWidget(ChangeNotifierProvider.value(
        value: pad,
        child: MaterialApp(
            home: Scaffold(body: StatefulBuilder(builder: (context, setState) {
          update = setState;
          return LauncherPadScope(
              revealFocus: false,
              menu: false,
              onCommand: (command) {
                if (command == 'DIREITA' || command == 'ESQUERDA') {
                  update(() => selected =
                      (selected + (command == 'DIREITA' ? 1 : -1))
                          .clamp(0, 17));
                  nodes[selected].requestFocus();
                }
                if (command == '2') opened++;
                return true;
              },
              child: FuturisticHome(
                  category: category,
                  selected: selected,
                  items: items,
                  itemNodes: nodes,
                  categoryNodes: tabs,
                  itemScope: itemScope,
                  categoryScope: tabScope,
                  onSelect: (i) {
                    if (selected != i) update(() => selected = i);
                  },
                  onCategory: (i) {
                    if (category != i) {
                      update(() {
                        category = i;
                        selected = 0;
                      });
                    }
                  },
                  onOpen: () => opened++,
                  onMenu: () {}));
        })))));
    nodes.first.requestFocus();
    await tester.pump();
    expect(nodes.first.hasFocus, isTrue);
    final slot = find.byKey(const ValueKey('futuristic-fixed-slot'));
    final anchor = tester.getRect(slot);
    expect(anchor.width, closeTo(anchor.height, .01));
    for (var i = 0; i < 10; i++) {
      expect(pad.interfaceRouter.dispatch('DIREITA'), isTrue);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump();
    }
    expect(selected, 10);
    expect(nodes[10].hasFocus, isTrue);
    final scroll =
        tester.state<ScrollableState>(find.byType(Scrollable).first).position;
    expect(scroll.pixels, greaterThan(900));
    expect(tester.getRect(slot), anchor);
    final other = find
        .byWidgetPredicate(
            (widget) => widget is FuturisticCardEffect && !widget.selected)
        .first;
    final selectedCard = find.byWidgetPredicate(
        (widget) => widget is FuturisticCardEffect && widget.selected);
    expect(tester.getRect(selectedCard).width / tester.getRect(other).width,
        closeTo(1.25, .001));
    expect(tester.getRect(find.byType(ListView).first).right,
        tester.view.physicalSize.width / tester.view.devicePixelRatio);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 500));
    expect(selected, 9);
    final beforeBurst = tester
        .widgetList<FuturisticCardEffect>(find.byType(FuturisticCardEffect))
        .first
        .settledRevision;
    // A burst of pad input must cancel earlier targets and stop exactly once.
    for (var i = 0; i < 4; i++) {
      pad.interfaceRouter.dispatch('DIREITA');
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 16));
      await tester.pump(const Duration(milliseconds: 90));
    }
    expect(selected, 13);
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    final settled = tester
        .widgetList<FuturisticCardEffect>(find.byType(FuturisticCardEffect))
        .singleWhere((effect) => effect.selected && effect.focused);
    expect(settled.settledRevision, greaterThan(beforeBurst));
    expect(scroll.isScrollingNotifier.value, isFalse);
    final exactOffset = scroll.pixels;
    await tester.pump(const Duration(milliseconds: 700));
    expect(scroll.pixels, exactOffset);
    // Even the last item must occupy the exact same highlighted square.
    update(() => selected = 17);
    nodes.last.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(seconds: 2));
    await tester.pump();
    final last = find.byWidgetPredicate(
        (widget) => widget is FuturisticCardEffect && widget.selected);
    expect(tester.getRect(last).left, closeTo(anchor.left, .2));
    expect(
        tester.getRect(last).width, closeTo(tester.getRect(last).height, .01));
    expect(tester.getRect(slot), anchor);
    expect(find.textContaining('LB / RB'), findsNothing);
    pad.interfaceRouter.dispatch('2');
    expect(opened, 1);
    tabs[3].requestFocus();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 500));
    expect(category, 3);
    expect(
        tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position
            .pixels,
        0);
    expect(tester.takeException(), isNull);
    // Simulate another interface taking the same focus nodes during motion.
    update(() => selected = 6);
    await tester.pump();
    await tester.pumpWidget(MaterialApp(
        home: Focus(
            focusNode: nodes.first, child: const Text('Interface anterior'))));
    nodes.first.requestFocus();
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    expect(nodes.first.hasFocus, isTrue);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
    for (final node in [...nodes, ...tabs]) {
      node.dispose();
    }
    itemScope.dispose();
    tabScope.dispose();
    pad.dispose();
  });

  testWidgets('Layout de vidro cabe em janela compacta e biblioteca vazia',
      (tester) async {
    tester.view.physicalSize = const Size(640, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final tabs = List.generate(4, (_) => FocusNode());
    final itemScope = FocusScopeNode();
    final tabScope = FocusScopeNode();
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            body: FuturisticHome(
                category: 0,
                selected: 0,
                items: const [],
                itemNodes: const [],
                categoryNodes: tabs,
                itemScope: itemScope,
                categoryScope: tabScope,
                onSelect: (_) {},
                onCategory: (_) {},
                onOpen: () {},
                onMenu: () {}))));
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Sua próxima descoberta'), findsOneWidget);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox());
    for (final node in tabs) {
      node.dispose();
    }
    itemScope.dispose();
    tabScope.dispose();
  });
}
