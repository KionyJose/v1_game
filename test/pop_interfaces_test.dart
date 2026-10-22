import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:v1_game/Controllers/slim_mode_config_controller.dart';
import 'package:v1_game/Global.dart';
import 'package:v1_game/Widgets/Pops/pop_interfaces.dart';

late Paad _pad;
late List<bool> _slimGravado;
late int _gravacoes;

/// Abre o pop e devolve o resultado quando ele fechar.
///
/// A gravação é interceptada: `configSistema` é global e `save()` escreveria
/// por cima da configuração real de quem roda os testes.
Future<String?> _abrir(WidgetTester tester) async {
  String? resultado;
  _pad = Paad(escutar: false, janelaCtrl: JanelaCtrl());
  addTearDown(_pad.dispose);
  _slimGravado = [];
  _gravacoes = 0;
  await tester.binding.setSurfaceSize(const Size(1280, 800));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(ChangeNotifierProvider<Paad>.value(
    value: _pad,
    child: MaterialApp(
        home: Builder(
            builder: (context) => Scaffold(
                  body: Center(
                    child: FilledButton(
                      onPressed: () async {
                        resultado = await PopInterfaces.abrir(
                          context,
                          gravar: () async {
                            _gravacoes++;
                            return true;
                          },
                          definirSlim: (v) async => _slimGravado.add(v),
                        );
                      },
                      child: const Text('abrir'),
                    ),
                  ),
                ))),
  ));
  await tester.tap(find.text('abrir'));
  await tester.pumpAndSettle();
  return resultado;
}

Future<void> _comando(WidgetTester tester, String comando) async {
  _pad.interfaceRouter.dispatch(comando);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 200));
}

void main() {
  late String tipoOriginal;
  late bool videosOriginal;
  late bool noticiasOriginal;
  late double musicaOriginal;

  setUp(() {
    tipoOriginal = configSistema.viewType;
    videosOriginal = configSistema.videosTelaPrincipal;
    noticiasOriginal = configSistema.noticias;
    musicaOriginal = configSistema.volumeMusicaFuturista;
    SlimModeConfigController.active.value = false;
  });

  tearDown(() {
    configSistema.viewType = tipoOriginal;
    configSistema.videosTelaPrincipal = videosOriginal;
    configSistema.noticias = noticiasOriginal;
    configSistema.volumeMusicaFuturista = musicaOriginal;
    SlimModeConfigController.active.value = false;
  });

  testWidgets('Mostra todas as telas numa grade de três colunas',
      (tester) async {
    configSistema.viewType = 'list';
    await _abrir(tester);

    expect(PopInterfaces.colunas, 3);
    final grade = tester.widget<GridView>(find.byType(GridView));
    final delegado =
        grade.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegado.crossAxisCount, 3);

    // O nome da tela apontada também aparece no cabeçalho, então a contagem
    // exata se faz pelo resumo, que é único de cada cartão.
    for (final tela in telasDoLauncher()) {
      expect(find.text(tela.nome), findsWidgets, reason: tela.nome);
      expect(find.text(tela.resumo), findsOneWidget, reason: tela.resumo);
    }
    expect(telasDoLauncher().length, 7);
  });

  testWidgets('Tela sem ajuste próprio diz OK; com ajuste, lista os ajustes',
      (tester) async {
    configSistema.viewType = 'list';
    await _abrir(tester);

    // Retro, Grade, Transversal e Slim não têm ajuste só delas.
    expect(find.text('OK'), findsNWidgets(4));

    // As que têm mostram o ajuste e o valor ali mesmo.
    expect(find.text('Vídeos na tela'), findsOneWidget);
    expect(find.text('Notícias no card'), findsNWidgets(2));
    expect(find.text('Música ambiente'), findsOneWidget);
    expect(find.text('Som ao abrir'), findsOneWidget);
  });

  testWidgets('A tela em uso aparece marcada como Atual', (tester) async {
    configSistema.viewType = 'retro';
    await _abrir(tester);
    expect(find.text('Atual'), findsOneWidget);
  });

  testWidgets('O Pad anda entre telas e entra nos ajustes', (tester) async {
    configSistema.viewType = 'list';
    configSistema.videosTelaPrincipal = true;
    await _abrir(tester);

    // Começa no cartão da Principal; BAIXO entra no primeiro ajuste dela.
    await _comando(tester, 'BAIXO');
    expect(find.textContaining('A liga e desliga'), findsOneWidget,
        reason: 'a dica muda quando o foco está num ajuste');

    // A alterna o valor, ali mesmo.
    await _comando(tester, '2');
    expect(configSistema.videosTelaPrincipal, isFalse);
    expect(find.text('Desligado'), findsWidgets);

    await _comando(tester, '2');
    expect(configSistema.videosTelaPrincipal, isTrue);
  });

  testWidgets('LB e RB movem o volume da tela futurista', (tester) async {
    configSistema.viewType = 'list';
    configSistema.volumeMusicaFuturista = .5;
    await _abrir(tester);

    // Futurista é a sexta tela: desce uma linha e anda duas colunas.
    await _comando(tester, 'BAIXO');
    await _comando(tester, 'BAIXO');
    await _comando(tester, 'BAIXO');
    await _comando(tester, 'DIREITA');
    await _comando(tester, 'DIREITA');
    // Apontar outra tela não muda qual está em uso: a marca segue na
    // Principal até alguém confirmar.
    expect(find.text('Atual'), findsOneWidget);

    // Entra no primeiro ajuste do Futurista e mexe com os ombros.
    await _comando(tester, 'BAIXO');
    await _comando(tester, 'RB');
    expect(configSistema.volumeMusicaFuturista, closeTo(.6, .001));
    await _comando(tester, 'LB');
    await _comando(tester, 'LB');
    expect(configSistema.volumeMusicaFuturista, closeTo(.4, .001));
  });

  testWidgets('O volume não passa de 0 nem de 100%', (tester) async {
    configSistema.viewType = 'list';
    configSistema.volumeMusicaFuturista = .95;
    await _abrir(tester);

    await _comando(tester, 'BAIXO');
    await _comando(tester, 'BAIXO');
    await _comando(tester, 'BAIXO');
    await _comando(tester, 'DIREITA');
    await _comando(tester, 'DIREITA');
    await _comando(tester, 'BAIXO');
    for (var i = 0; i < 4; i++) {
      await _comando(tester, 'RB');
    }
    expect(configSistema.volumeMusicaFuturista, 1.0);
    for (var i = 0; i < 15; i++) {
      await _comando(tester, 'LB');
    }
    expect(configSistema.volumeMusicaFuturista, 0.0);
  });

  testWidgets('A no cartão aplica a tela, grava e devolve salvar',
      (tester) async {
    configSistema.viewType = 'list';
    String? resultado;
    await tester.runAsync(() async {});
    resultado = await _abrir(tester);
    expect(resultado, isNull, reason: 'ainda aberto');

    // Vai até Retro (terceira) e confirma.
    await _comando(tester, 'DIREITA');
    await _comando(tester, 'DIREITA');
    await _comando(tester, '2');
    await tester.pumpAndSettle();

    expect(configSistema.viewType, 'retro');
    expect(_gravacoes, 1, reason: 'grava uma vez, na saída');
    expect(find.byType(GridView), findsNothing, reason: 'o pop fechou');
  });

  testWidgets('Escolher Slim liga o modo de janela', (tester) async {
    configSistema.viewType = 'list';
    await _abrir(tester);

    // Slim fica na coluna da esquerda, duas linhas abaixo: BAIXO desce pelos
    // dois ajustes da Principal, depois Grade, depois Slim.
    for (var i = 0; i < 4; i++) {
      await _comando(tester, 'BAIXO');
    }
    expect(find.textContaining('Slim'), findsWidgets);
    await _comando(tester, '2');
    await tester.pumpAndSettle();

    expect(_slimGravado, [true]);
  });

  testWidgets('Sair sem mexer não grava nem pede para aplicar',
      (tester) async {
    configSistema.viewType = 'list';
    await _abrir(tester);

    await _comando(tester, 'DIREITA');
    await _comando(tester, 'ESQUERDA');
    await _comando(tester, '3');
    await tester.pumpAndSettle();

    expect(_gravacoes, 0);
    expect(configSistema.viewType, 'list');
    expect(find.byType(GridView), findsNothing);
  });

  testWidgets('O direcional não sai da grade pelas pontas', (tester) async {
    configSistema.viewType = 'list';
    await _abrir(tester);

    await _comando(tester, 'ESQUERDA');
    await _comando(tester, 'CIMA');
    // Continua desenhando, sem exceção nem índice fora da lista. O nome sai
    // repetido de propósito: cartão e cabeçalho.
    expect(find.text('Principal'), findsWidgets);

    for (var i = 0; i < 20; i++) {
      await _comando(tester, 'DIREITA');
    }
    for (var i = 0; i < 20; i++) {
      await _comando(tester, 'BAIXO');
    }
    expect(find.text('Slim'), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  group('Pad percorre tudo, inclusive as sub-opções', () {
    testWidgets('a dica diz onde estou e o que os botões fazem ali',
        (tester) async {
      configSistema.viewType = 'list';
      await _abrir(tester);

      // No cartão: nome da tela e quantos ajustes existem abaixo.
      expect(find.text('Principal'), findsWidgets);
      expect(find.textContaining('A usa esta tela'), findsOneWidget);
      expect(find.textContaining('abre os 2 ajustes'), findsOneWidget);

      // Dentro de um ajuste: o caminho e o que A faz aqui.
      await _comando(tester, 'BAIXO');
      expect(find.textContaining('Principal  ›  Vídeos na tela'),
          findsOneWidget);
      expect(find.textContaining('A liga e desliga'), findsOneWidget);
    });

    testWidgets('num volume, a dica troca para os ombros', (tester) async {
      configSistema.viewType = 'list';
      await _abrir(tester);

      await _comando(tester, 'BAIXO');
      await _comando(tester, 'BAIXO');
      await _comando(tester, 'BAIXO');
      await _comando(tester, 'DIREITA');
      await _comando(tester, 'DIREITA');
      await _comando(tester, 'BAIXO');

      expect(find.textContaining('Futurista  ›  Música ambiente'),
          findsOneWidget);
      expect(find.textContaining('LB diminui'), findsOneWidget);
      expect(find.textContaining('RB aumenta'), findsOneWidget);
    });

    testWidgets('tela sem ajuste avisa na própria dica', (tester) async {
      configSistema.viewType = 'list';
      await _abrir(tester);

      // Retro é a terceira e não tem ajuste próprio.
      await _comando(tester, 'DIREITA');
      await _comando(tester, 'DIREITA');
      expect(find.textContaining('não tem ajuste próprio'), findsOneWidget);
    });

    testWidgets('andar de lado preserva a profundidade', (tester) async {
      configSistema.viewType = 'list';
      await _abrir(tester);

      // Segundo ajuste da Principal.
      await _comando(tester, 'BAIXO');
      await _comando(tester, 'BAIXO');
      expect(find.textContaining('Principal  ›  Notícias no card'),
          findsOneWidget);

      // Moderno só tem um ajuste: cai no que existe, sem voltar ao cartão.
      await _comando(tester, 'DIREITA');
      expect(find.textContaining('Moderno  ›  Notícias no card'),
          findsOneWidget);

      // De volta, e a profundidade continua de pé.
      await _comando(tester, 'ESQUERDA');
      expect(find.textContaining('Principal  ›'), findsOneWidget);
    });

    testWidgets('subir entra pelo último ajuste da tela de cima',
        (tester) async {
      configSistema.viewType = 'list';
      await _abrir(tester);

      // Desce para a Grade (quarta tela, logo abaixo da Principal).
      await _comando(tester, 'BAIXO');
      await _comando(tester, 'BAIXO');
      await _comando(tester, 'BAIXO');
      expect(find.textContaining('Grade'), findsWidgets);

      // Subindo, o caminho de volta é o mesmo da ida: o último ajuste.
      await _comando(tester, 'CIMA');
      expect(find.textContaining('Principal  ›  Notícias no card'),
          findsOneWidget);
    });

    testWidgets('dá para alcançar toda tela e todo ajuste', (tester) async {
      configSistema.viewType = 'list';
      await _abrir(tester);

      final vistos = <String>{};
      // Varre coluna por coluna, descendo até o fim e voltando ao topo.
      for (var coluna = 0; coluna < PopInterfaces.colunas; coluna++) {
        for (var i = 0; i < 40; i++) {
          await _comando(tester, 'CIMA');
        }
        for (var c = 0; c < coluna; c++) {
          await _comando(tester, 'DIREITA');
        }
        for (var i = 0; i < 12; i++) {
          vistos.add(_ondeEstou(tester));
          await _comando(tester, 'BAIXO');
        }
        vistos.add(_ondeEstou(tester));
        for (var c = 0; c < coluna; c++) {
          await _comando(tester, 'ESQUERDA');
        }
      }

      // As 7 telas e os 5 ajustes, sem nenhum ponto inalcançável.
      for (final esperado in [
        'Principal',
        'Principal  ›  Vídeos na tela',
        'Principal  ›  Notícias no card',
        'Moderno',
        'Moderno  ›  Notícias no card',
        'Retro',
        'Grade',
        'Transversal',
        'Futurista',
        'Futurista  ›  Música ambiente',
        'Futurista  ›  Som ao abrir',
        'Slim',
      ]) {
        expect(vistos, contains(esperado), reason: esperado);
      }
      expect(tester.takeException(), isNull);
    });
  });
}

/// A linha que diz onde o Pad está, lida da própria tela.
String _ondeEstou(WidgetTester tester) {
  final textos = tester
      .widgetList<Text>(find.byType(Text))
      .map((t) => t.data ?? '')
      .where((t) => t.isNotEmpty);
  // O caminho com "›" ganha do nome solto, quando há um.
  final caminho = textos.where((t) => t.contains('  ›  '));
  if (caminho.isNotEmpty) return caminho.first;
  return textos.firstWhere((t) => telasDoLauncher().any((e) => e.nome == t),
      orElse: () => '');
}
