import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:v1_game/Global.dart';
import 'package:v1_game/Modelos/configs_sistema.dart';
import 'package:v1_game/Widgets/Pops/pop_config.dart';
import 'package:v1_game/Widgets/Pops/pop_tutorial_tmdb.dart';

class JanelaTutorialTeste extends JanelaCtrl {
  JanelaTutorialTeste(this.eventos);
  final List<String> eventos;

  @override
  void telaPresaReverse({bool usarEstado = false, bool estado = false}) {
    telaPresa = usarEstado ? estado : !telaPresa;
    eventos.add(telaPresa ? 'travar' : 'destravar');
  }
}

class PadTutorialTeste extends Paad {
  PadTutorialTeste(this.eventos)
      : super(escutar: false, janelaCtrl: JanelaTutorialTeste(eventos));
  final List<String> eventos;

  @override
  Future<void> ativaMouse(
      {bool usarEstado = false, bool estado = false}) async {
    isMouse = usarEstado ? estado : !isMouse;
    eventos.add(isMouse ? 'mouse livre' : 'mouse preso');
  }
}

void _simularNavegador(WidgetTester tester, List<String> eventos) {
  const canal = MethodChannel('plugins.flutter.io/url_launcher');
  tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(canal,
      (chamada) async {
    if (chamada.method == 'launch') {
      eventos.add('site:${(chamada.arguments as Map)['url']}');
    }
    return true;
  });
  addTearDown(() => tester.binding.defaultBinaryMessenger
      .setMockMethodCallHandler(canal, null));
}

/// Acha o `Focus` mais próximo de um texto da tela de Configurações e dá
/// foco a ele — o mesmo que o direcional faria, sem depender de um campo
/// público exposto só para o teste.
Future<void> _focar(WidgetTester tester, String texto) async {
  final foco =
      find.ancestor(of: find.text(texto), matching: find.byType(Focus)).first;
  tester.widget<Focus>(foco).focusNode!.requestFocus();
  await tester.pumpAndSettle();
}

void main() {
  for (final mouseInicial in [false, true]) {
    testWidgets('fechar configurações preserva mouse $mouseInicial',
        (tester) async {
      tester.view.physicalSize = const Size(1920, 1080);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final eventos = <String>[];
      final pad = PadTutorialTeste(eventos)..isMouse = mouseInicial;
      addTearDown(pad.dispose);
      await tester.pumpWidget(ChangeNotifierProvider<Paad>.value(
        value: pad,
        child: MaterialApp(
            home: Builder(
                builder: (context) => Scaffold(
                      body: TextButton(
                          onPressed: () => PopConfig.config(context),
                          child: const Text('Configurações')),
                    ))),
      ));
      await tester.tap(find.text('Configurações'));
      await tester.pumpAndSettle();
      pad.click = '3';
      pad.attTela();
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(pad.isMouse, mouseInicial);
      expect(pad.janelaCtrl.telaPresa, isTrue);
      expect(eventos, isEmpty);
      await tester.pumpWidget(const SizedBox.shrink());
    });
  }

  testWidgets('clique no site libera janela e mouse antes de abrir o navegador',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final eventos = <String>[];
    final pad = PadTutorialTeste(eventos);
    addTearDown(pad.dispose);
    _simularNavegador(tester, eventos);
    await tester.pumpWidget(ChangeNotifierProvider<Paad>.value(
      value: pad,
      child: MaterialApp(
          home: Builder(
              builder: (context) => Scaffold(
                    body: TextButton(
                        onPressed: () => PopTutorialTmdb.abrir(context),
                        child: const Text('Tutorial')),
                  ))),
    ));
    await tester.tap(find.text('Tutorial'));
    await tester.pumpAndSettle();
    expect(eventos, isEmpty);
    await tester.tap(find.text('Acessar o site'));
    await tester.pumpAndSettle();
    expect(
        eventos, ['destravar', 'mouse livre', 'site:${PopTutorialTmdb.site}']);
    await tester.tap(find.text('Fechar'));
    await tester.pumpAndSettle();
    expect(pad.isMouse, isTrue);
    expect(pad.janelaCtrl.telaPresa, isFalse);
    expect(pad.interfaceRouter.dispatch('2'), isFalse,
        reason: 'o tutorial fechado não pode continuar recebendo comandos');
    await tester.pumpWidget(const SizedBox.shrink());
  });

  testWidgets(
      'A chave do TMDB abre o teclado e o tutorial pelo Pad sem derrubar a tela',
      (tester) async {
    tester.view.physicalSize = const Size(1920, 1080);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final eventos = <String>[];
    final pad = PadTutorialTeste(eventos);
    _simularNavegador(tester, eventos);
    final original = configSistema;
    configSistema = ConfigSistema.defaults().copyWith(cinemaCatalogo: true);
    addTearDown(() {
      configSistema = original;
      pad.dispose();
    });

    await tester.pumpWidget(ChangeNotifierProvider<Paad>.value(
        value: pad,
        child: MaterialApp(home: Builder(builder: (context) {
          return Scaffold(
              body: TextButton(
                  onPressed: () => PopConfig.config(context),
                  child: const Text('Abrir configurações')));
        }))));
    await tester.tap(find.text('Abrir configurações'));
    await tester.pumpAndSettle();

    // O interruptor do catálogo já nasce ligado: os dois itens do TMDB
    // aparecem sem precisar mexer em nada.
    expect(find.text('Chave da API do TMDB'), findsOneWidget);
    expect(find.text('Como conseguir a chave'), findsOneWidget);

    // Botão "Como conseguir a chave" pelo Pad: antes desta correção, abrir
    // um diálogo de dentro do `escutaPad` — que roda no meio do build do
    // Consumer<Paad> — derrubava a tela com "setState() called during
    // build" e travava o Navigator em seguida. `pumpAndSettle` sozinho não
    // bastava: o diálogo só abre um quadro depois, no post-frame callback.
    await _focar(tester, 'Como conseguir a chave');
    pad.click = '2';
    pad.attTela();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Como conseguir a chave do TMDB'), findsOneWidget,
        reason: 'o tutorial deveria estar na tela');
    expect(eventos, isEmpty,
        reason: 'o A usado nas configurações não abre o site');
    pad.attTela();
    await tester.pumpAndSettle();
    expect(eventos, isEmpty, reason: 'rebuild não repete comando do Pad');

    // B fecha o tutorial e devolve as Configurações.
    pad.click = '3';
    pad.attTela();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Como conseguir a chave do TMDB'), findsNothing);
    expect(find.text('Chave da API do TMDB'), findsOneWidget,
        reason: 'fechar o tutorial não pode fechar as Configurações junto');

    // Botão "Acessar o site" dentro do tutorial também é alcançável pelo
    // Pad e não deve derrubar a tela — ele só chama o navegador externo.
    await _focar(tester, 'Como conseguir a chave');
    pad.click = '2';
    pad.attTela();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(eventos, isEmpty);
    // Aguarda a proteção contra a repetição do botão que abriu o tutorial.
    await tester.pump(const Duration(milliseconds: 300));
    pad.click = '2'; // escolha padrão: "Acessar o site"
    pad.attTela();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(
        eventos, ['destravar', 'mouse livre', 'site:${PopTutorialTmdb.site}']);
    expect(pad.isMouse, isTrue);
    expect(pad.janelaCtrl.telaPresa, isFalse);
    pad.attTela();
    await tester.pumpAndSettle();
    expect(eventos, hasLength(3),
        reason: 'a abertura explícita acontece uma vez');
    pad.click = '3';
    pad.attTela();
    await tester.pump();
    await tester.pumpAndSettle();

    // Campo da chave pelo Pad: o mesmo adiamento vale para o teclado do
    // controle.
    await _focar(tester, 'Chave da API do TMDB');
    pad.click = '2';
    pad.attTela();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);

    pad.click = '3'; // fecha o teclado sem digitar
    pad.attTela();
    await tester.pump();
    await tester.pumpAndSettle();
    expect(find.text('Chave da API do TMDB'), findsOneWidget);

    pad.click = '3'; // fecha as Configurações
    pad.attTela();
    for (var i = 0; i < 5; i++) {
      await tester.pump(const Duration(seconds: 2));
    }
    await tester.pumpWidget(const SizedBox());
    expect(eventos, hasLength(3),
        reason: 'fechar Configurações não mexe no mouse');
    expect(tester.takeException(), isNull);
  });
}
