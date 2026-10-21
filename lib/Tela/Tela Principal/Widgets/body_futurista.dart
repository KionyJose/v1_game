import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/physics.dart';
import '../../../Interface/futuristic_card_effect.dart';
import '../../../Interface/futuristic_warmup.dart';
import '../../../Interface/futuristic_card_entrance.dart';
import '../../../Interface/futuristic_details_transition.dart';
import '../../../Interface/futuristic_launch.dart';
import '../../../Interface/futuristic_game_backdrop.dart';
import '../../../Interface/futuristic_card_mirror.dart';
import '../../../Interface/futuristic_card_fold.dart';
import '../Futurista/futuristic_game_details.dart';
import '../../../Interface/futuristic_particles.dart';
import '../../../Interface/futuristic_view_box.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:window_manager/window_manager.dart';
import '../../../Interface/futuristic_window_controls.dart';
import '../../../Interface/futuristic_game_feed.dart';

import '../../../Controllers/SonsSistema.dart';
import '../../../Interface/launcher_pad_scope.dart';
import '../../../Interface/futuristic_material.dart';
import 'package:v1_game/Tela/Tela%20Principal/PrincipalCtrl.dart';

/// Presentation only: the existing launcher owns the library, focus and actions.
class BodyFuturista extends StatefulWidget {
  const BodyFuturista({super.key, required this.ctrl});
  final PrincipalCtrl ctrl;
  @override
  State<BodyFuturista> createState() => _BodyFuturistaState();
}

class _BodyFuturistaState extends State<BodyFuturista> with WindowListener {
  SoundHandle? _ambience;
  Timer? _audioTimer;
  ModalRoute<dynamic>? _route;
  bool _foreground = true;
  bool _openingGame = false, _launchingGame = false;
  late final Future<void> Function() _detailsHandler;

  @override
  void initState() {
    super.initState();
    _detailsHandler = _openGameDetails;
    widget.ctrl.abrirDetalhesFuturista = _detailsHandler;
    final games = widget.ctrl.listIconsInicial;
    unawaited(FuturisticGameFeed.prepareLibrary(
      games.map((game) => game.nome),
      priorityName: games.isEmpty
          ? null
          : games[widget.ctrl.selectedIndexIcone
                  .clamp(0, games.length - 1)]
              .nome,
    ));
    windowManager.addListener(this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _agendarEntrada());
    _startAudio();
  }

  bool _focoInicialFeito = false;
  bool _entradaAgendada = false;
  bool _entradaLiberada = false;
  bool _entradaConcluida = false;
  Timer? _entradaTimer;

  /// Respiro entre a tela ficar pronta e a cascata começar: dá tempo de as
  /// capas aparecerem e dos primeiros quadros pesados passarem.
  static const _respiroEntrada = Duration(milliseconds: 450);

  /// A cascata só começa com o launcher pronto e a tela já desenhada.
  /// Rodando em cima da carga inicial ela saía truncada — o jogador via um
  /// tranco no lugar da entrada.
  void _agendarEntrada() {
    if (_entradaAgendada || !mounted) return;
    final ctrl = widget.ctrl;
    if (!ctrl.telaIniciada || !ctrl.stateTela || ctrl.slimItemNodes.isEmpty) {
      return;
    }
    if (!(_route?.isCurrent ?? true)) return;
    _entradaAgendada = true;
    _entradaTimer = Timer(_respiroEntrada, () {
      if (mounted) setState(() => _entradaLiberada = true);
    });
  }

  /// O foco de entrada é dos cards. `focarCategoriaSlim` cai na barra de abas
  /// quando a lista ainda está vazia — o que acontece se a tela montar antes
  /// de a biblioteca chegar — e nada depois trazia o foco de volta. Por isso o
  /// foco só é pousado quando a cascata de cards termina, e aí já há card.
  void _focoInicial() {
    if (!mounted || _focoInicialFeito || !_entradaConcluida) return;
    final ctrl = widget.ctrl;
    if (!ctrl.telaIniciada || !ctrl.stateTela || ctrl.slimItemNodes.isEmpty) {
      return;
    }
    if (!(_route?.isCurrent ?? true)) return;
    _focoInicialFeito = true;
    ctrl.focarCategoriaSlim();
  }

  /// Fim da cascata: devolve o movimento ao jogador e pousa o foco no card.
  void _entradaTerminou() {
    if (!mounted || _entradaConcluida) return;
    setState(() => _entradaConcluida = true);
    _focoInicial();
  }

  Future<void> _startAudio() async {
    try {
      final handle = await SonsSistema.startWaterAmbience();
      if (!mounted) {
        if (handle != null) await SonsSistema.stopWaterAmbience(handle);
        return;
      }
      _ambience = handle;
      _audioTimer = Timer.periodic(
          const Duration(milliseconds: 350), (_) => _syncAudio());
      _syncAudio();
    } catch (error) {
      debugPrint('Áudio Futurista indisponível: $error');
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _route = ModalRoute.of(context);
  }

  void _syncAudio() {
    final handle = _ambience;
    if (!mounted || handle == null) return;
    SonsSistema.updateWaterAmbience(
        handle,
        _foreground &&
            !_openingGame &&
            !_launchingGame &&
            widget.ctrl.stateTela &&
            (_route?.isCurrent ?? true));
  }

  Future<void> _openGameDetails() async {
    final ctrl = widget.ctrl;
    if (!mounted ||
        _openingGame ||
        _launchingGame ||
        ctrl.listIconsInicial.isEmpty) {
      return;
    }
    final game = ctrl.listIconsInicial[ctrl.selectedIndexIcone];
    setState(() => _openingGame = true);
    _syncAudio();
    try {
      if (!MediaQuery.disableAnimationsOf(context)) {
        await Future<void>.delayed(const Duration(milliseconds: 450));
      }
      if (!mounted) return;
      final reduce = MediaQuery.disableAnimationsOf(context);
      final detailsRoute = PageRouteBuilder<bool>(
        transitionDuration: Duration(milliseconds: reduce ? 0 : 580),
        reverseTransitionDuration: Duration(milliseconds: reduce ? 0 : 380),
        pageBuilder: (_, __, ___) => FuturisticGameDetails(
            name: game.nome, image: game.imgStr, videoTags: ctrl.tagVideo),
        transitionsBuilder: (_, animation, __, child) =>
            FuturisticDetailsTransition(animation: animation, child: child),
      );
      final played = await launchFuturisticGameFromLibrary(context,
          detailsRoute: detailsRoute,
          name: game.nome,
          image: game.imgStr, revealLibrary: () async {
        if (!mounted) return;
        ctrl.stateTela = false;
        setState(() {
          _openingGame = false;
          _launchingGame = true;
        });
        _syncAudio();
      }, start: (presentation) async {
        if (!mounted) throw StateError('A interface foi alterada.');
        final index = ctrl.listIconsInicial
            .indexWhere((item) => item.local == game.local);
        if (index < 0) {
          throw StateError('O jogo n\u00e3o est\u00e1 mais na biblioteca.');
        }
        ctrl.selectedIndexIcone = index;
        ctrl.stateTela = true;
        // Sem `reportErrors`, como no modo principal: o jogo é apenas
        // iniciado. Com ele ligado, uma falha do `Process.start` — o que
        // acontece com todo jogo que exige elevação — subia como erro e a
        // tela desistia, em vez de deixar o `openFile` cair no shell, que é
        // quem sabe pedir a autorização do Windows. A confirmação do UAC é
        // do jogador; o launcher não tem como responder por ele.
        await ctrl.btnEntrar(apresentarInicializacao: presentation);
      });
      if (played == true && mounted) ctrl.selecionarItemSlim(0);
    } catch (error) {
      debugPrint('Falha ao iniciar o jogo: $error');
      if (mounted) {
        ctrl.stateTela = true;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text(
                'N\u00e3o foi poss\u00edvel iniciar o jogo. Confira o caminho do execut\u00e1vel.')));
        final index = ctrl.listIconsInicial
            .indexWhere((item) => item.local == game.local);
        if (index >= 0) ctrl.selecionarItemSlim(index);
      }
    } finally {
      if (mounted) {
        setState(() {
          _openingGame = false;
          _launchingGame = false;
        });
        _syncAudio();
      }
    }
  }

  @override
  void onWindowBlur() {
    _foreground = false;
    _syncAudio();
  }

  @override
  void onWindowFocus() {
    _foreground = true;
    _syncAudio();
  }

  @override
  void dispose() {
    if (widget.ctrl.abrirDetalhesFuturista == _detailsHandler) {
      widget.ctrl.abrirDetalhesFuturista = null;
    }
    _audioTimer?.cancel();
    _entradaTimer?.cancel();
    windowManager.removeListener(this);
    final handle = _ambience;
    if (handle != null) unawaited(SonsSistema.stopWaterAmbience(handle));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    // O launcher pode ficar pronto depois da montagem; quando ficar, a cascata
    // é liberada no quadro seguinte.
    if (!_entradaAgendada) {
      WidgetsBinding.instance.addPostFrameCallback((_) => _agendarEntrada());
    }
    final category = ctrl.selectedIndexAbaGuias;
    final items = List.generate(
        ctrl.slimItemNodes.length,
        (index) => switch (category) {
              1 => FuturisticItem(ctrl.listCinema[index].nome,
                  ctrl.listCinema[index].imgLocal, Icons.movie_rounded),
              2 => FuturisticItem(ctrl.listMusica[index].nome,
                  ctrl.listMusica[index].imgLocal, Icons.music_note_rounded),
              3 => FuturisticItem(ctrl.listLojas[index].nome,
                  ctrl.listLojas[index].logo, ctrl.listLojas[index].icone,
                  logo: true),
              _ => FuturisticItem(
                  ctrl.listIconsInicial[index].nome,
                  ctrl.listIconsInicial[index].imgStr,
                  Icons.sports_esports_rounded),
            });
    return LauncherPadScope(
      // Durante a cascata de entrada o Pad fica quieto: mover um card que
      // ainda está chegando deixaria a esteira e o foco fora de sincronia.
      enabled: !ctrl.mouseBloqueado && !_launchingGame && _entradaConcluida,
      revealInitialFocus: false,
      revealFocus: false,
      onCommand: ctrl.comandoSlim,
      child: Focus(
        skipTraversal: true,
        onKeyEvent: (_, event) {
          if (_launchingGame) return KeyEventResult.handled;
          if (event is! KeyDownEvent && event is! KeyRepeatEvent) {
            return KeyEventResult.ignored;
          }
          final command = {
                LogicalKeyboardKey.keyW: 'CIMA',
                LogicalKeyboardKey.keyS: 'BAIXO',
                LogicalKeyboardKey.keyA: 'ESQUERDA',
                LogicalKeyboardKey.keyD: 'DIREITA',
                LogicalKeyboardKey.keyQ: 'LB',
                LogicalKeyboardKey.keyE: 'RB',
                LogicalKeyboardKey.pageUp: 'LB',
                LogicalKeyboardKey.pageDown: 'RB',
                LogicalKeyboardKey.enter: '2',
                LogicalKeyboardKey.numpadEnter: '2',
                LogicalKeyboardKey.space: '2',
                LogicalKeyboardKey.gameButtonA: '2',
                LogicalKeyboardKey.backspace: '3',
                LogicalKeyboardKey.numpadAdd: 'START',
              }[event.logicalKey] ??
              (event.character == '+' ? 'START' : null);
          if (command == null) return KeyEventResult.ignored;
          if (event is KeyDownEvent || !['2', 'START', '3'].contains(command)) {
            ctrl.comandoSlim(command);
          }
          return KeyEventResult.handled;
        },
        child: FuturisticHome(
          windowControls: const FuturisticWindowControls(),
          category: category,
          selected: ctrl.slimItemIndex,
          gridMode: ctrl.cardGamesGrid,
          items: items,
          itemNodes: ctrl.slimItemNodes,
          categoryNodes: ctrl.focusNodeAbaGuias,
          itemScope: ctrl.slimItemScope,
          categoryScope: ctrl.focusScopeAbaGuias,
          enabled:
              !ctrl.mouseBloqueado && !_launchingGame && _entradaConcluida,
          openingGame: _openingGame,
          startEntrance: _entradaLiberada,
          onEntranceDone: _entradaTerminou,
          onSelect: ctrl.selecionarItemSlim,
          onCategory: (index) =>
              ctrl.selecionarCategoriaSlim(index, barra: true),
          onOpen: () => ctrl.abrirItemSlim(),
          onMenu: ctrl.btnMais,
        ),
      ),
    );
  }
}

class FuturisticItem {
  const FuturisticItem(this.name, this.image, this.icon, {this.logo = false});
  final String name;
  final String image;
  final IconData icon;

  /// Marca de loja em vez de capa de jogo: precisa caber inteira no bloco,
  /// então é desenhada com `contain` e respiro, não recortada por `cover`.
  final bool logo;
}

/// Independently testable glass layout; it never launches processes itself.
class FuturisticHome extends StatefulWidget {
  const FuturisticHome(
      {super.key,
      required this.category,
      required this.selected,
      this.gridMode = false,
      required this.items,
      required this.itemNodes,
      required this.categoryNodes,
      required this.itemScope,
      required this.categoryScope,
      required this.onSelect,
      required this.onCategory,
      required this.onOpen,
      required this.onMenu,
      this.windowControls,
      this.onEntranceDone,
      this.startEntrance = true,
      this.enabled = true,
      this.openingGame = false});
  final bool openingGame, gridMode;
  final Widget? windowControls;
  final int category, selected;
  final List<FuturisticItem> items;
  final List<FocusNode> itemNodes, categoryNodes;
  final FocusScopeNode itemScope, categoryScope;
  final ValueChanged<int> onSelect, onCategory;
  final VoidCallback onOpen, onMenu;

  /// Avisa quando a entrada em cascata terminou e o controle pode ser
  /// devolvido ao jogador.
  final VoidCallback? onEntranceDone;

  /// Libera a cascata. Quem monta a tela segura isso até o launcher estar
  /// pronto e desenhado; usada sozinha, a tela anima na própria montagem.
  final bool startEntrance;
  final bool enabled;
  @override
  State<FuturisticHome> createState() => _FuturisticHomeState();
}

class _FuturisticHomeState extends State<FuturisticHome>
    with TickerProviderStateMixin {
  final _scroll = ScrollController();
  final _settled = ValueNotifier<int>(0);
  late final ValueNotifier<double> _railPosition;
  late final AnimationController _motion;
  double _extent = 200;
  static const _cardGap = 26.4;

  /// Respiro antes do primeiro card, como fração do tamanho do card: o card
  /// que rola para a esquerda tem onde sumir em vez de ser cortado na borda.
  /// Sai proporcional porque o card acompanha a altura da janela — em pixel
  /// fixo ele ficaria largo demais numa tela pequena e apertado numa grande.
  static const _fracaoRespiro = .025;

  /// Cerca de 5 px num card de tamanho usual.
  double _respiroEsquerdo(double cardSize) => cardSize * _fracaoRespiro;
  int _revision = 0;
  Timer? _focusSettle;
  static const labels = ['Jogos', 'Cinema', 'Música', 'Lojas'];
  static const icons = [
    Icons.sports_esports_rounded,
    Icons.movie_rounded,
    Icons.music_note_rounded,
    Icons.storefront_rounded
  ];

  bool get _showGameGrid => widget.gridMode && widget.category == 0;

  void _tick() {
    if (!_scroll.hasClients || _scroll.positions.length != 1) return;
    _scroll.jumpTo(_motion.value.clamp(0.0, _scroll.position.maxScrollExtent));
    _railPosition.value = _indexAtOffset(_scroll.offset);
  }

  double _cardVisualWidth(int index) =>
      (_extent - _cardGap) * (index == widget.selected ? 1 : .8);

  double _itemStride(int index) =>
      _cardVisualWidth(index) + _cardGap;

  double _itemStart(int index) {
    final smallStride = (_extent - _cardGap) * .8 + _cardGap;
    final selectedAdjustment = widget.selected < index
        ? _itemStride(widget.selected) - smallStride
        : 0.0;
    return index * smallStride + selectedAdjustment;
  }

  double _indexAtOffset(double offset) {
    final count = widget.items.length;
    if (count < 2) return 0;
    final selected = widget.selected.clamp(0, count - 1);
    final selectedStart = _itemStart(selected);
    final selectedStride = _itemStride(selected);
    final smallStride = (_extent - _cardGap) * .8 + _cardGap;
    if (offset < selectedStart) {
      return (offset / smallStride).clamp(0.0, selected.toDouble());
    }
    if (offset <= selectedStart + selectedStride) {
      return selected + (offset - selectedStart) / selectedStride;
    }
    return selected + 1 +
        (offset - selectedStart - selectedStride) / smallStride;
  }

  void _reveal({bool categoryChanged = false}) {
    if (_showGameGrid) {
      _motion.stop();
      _railPosition.value = widget.selected.toDouble();
      return;
    }
    final revision = ++_revision;
    _focusSettle?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted ||
          revision != _revision ||
          !_scroll.hasClients ||
          _scroll.positions.length != 1) {
        return;
      }
      final target = _itemStart(widget.selected)
          .clamp(0.0, _scroll.position.maxScrollExtent);
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      final velocity =
          _motion.isAnimating && !categoryChanged ? _motion.velocity : 0.0;
      _motion.stop();
      if (categoryChanged ||
          reduceMotion ||
          (target - _scroll.offset).abs() < .5) {
        _scroll.jumpTo(target);
        _railPosition.value = _indexAtOffset(_scroll.offset);
      } else {
        _motion.value = _scroll.offset;
        try {
          // Near-critical damping: fast departure, no bounce, precise arrival.
          await _motion
              .animateWith(SpringSimulation(
                  const SpringDescription(mass: 1, stiffness: 100, damping: 22),
                  _scroll.offset,
                  target,
                  velocity.clamp(-6000.0, 6000.0),
                  tolerance: const Tolerance(distance: .1, velocity: 1)))
              .orCancel;
        } on TickerCanceled {
          return;
        }
      }
      if (!mounted || revision != _revision || !_scroll.hasClients) return;
      _scroll.jumpTo(target);
      _railPosition.value = _indexAtOffset(_scroll.offset);
      _acknowledge(revision);
    });
  }

  void _acknowledge(int revision) {
    if (!widget.itemScope.hasFocus || widget.itemNodes.isEmpty) return;
    widget.itemNodes[widget.selected.clamp(0, widget.itemNodes.length - 1)]
        .requestFocus();
    _focusSettle = Timer(const Duration(milliseconds: 70), () {
      if (mounted && revision == _revision && widget.itemScope.hasFocus) {
        _settled.value++;
      }
    });
  }

  /// Entrada em cascata: roda uma vez, quando os primeiros cards existem.
  late final AnimationController _entrance = AnimationController(
      vsync: this, duration: FuturisticCardEntrance.duracao);
  bool _entranceStarted = false;

  /// Enquanto a esteira se monta, o movimento fica travado; a liberação vem
  /// junto com o fim da animação, pelo [FuturisticHome.onEntranceDone].
  void _startEntrance() {
    if (_entranceStarted ||
        !mounted ||
        !widget.startEntrance ||
        widget.items.isEmpty) {
      return;
    }
    _entranceStarted = true;
    if (MediaQuery.disableAnimationsOf(context)) {
      _entrance.value = 1;
      widget.onEntranceDone?.call();
      return;
    }
    _entrance.forward(from: 0).whenCompleteOrCancel(() {
      if (mounted) widget.onEntranceDone?.call();
    });
  }

  @override
  void initState() {
    super.initState();
    _railPosition = ValueNotifier(widget.selected.toDouble());
    _motion = AnimationController.unbounded(vsync: this)..addListener(_tick);
    _reveal(categoryChanged: true);
    WidgetsBinding.instance.addPostFrameCallback((_) => _startEntrance());
  }

  @override
  void didUpdateWidget(FuturisticHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_showGameGrid) {
      _motion.stop();
      _railPosition.value = widget.selected.toDouble();
      return;
    }
    if (oldWidget.category != widget.category ||
        oldWidget.gridMode != widget.gridMode) {
      _motion.stop();
    }
    if (oldWidget.selected != widget.selected ||
        oldWidget.category != widget.category ||
        oldWidget.items.length != widget.items.length) {
      _reveal(categoryChanged: oldWidget.category != widget.category);
    }
    // A cascata espera a liberação de quem monta a tela e os primeiros cards.
    if ((!oldWidget.startEntrance && widget.startEntrance) ||
        (oldWidget.items.isEmpty && widget.items.isNotEmpty)) {
      _startEntrance();
    }
  }

  @override
  void dispose() {
    ++_revision;
    _focusSettle?.cancel();
    _motion.dispose();
    _entrance.dispose();
    _railPosition.dispose();
    _scroll.dispose();
    _settled.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      LayoutBuilder(builder: (context, constraints) {
        final compact = constraints.maxWidth < 800;
        final blurBackdrop = _showGameGrid || widget.category == 3;
        final padding = compact ? 24.0 : 56.0;
        final height = constraints.maxHeight;
        final extent =
            (height * (height < 550 ? .23 : .32)).clamp(110.0, 245.0) + 24;
        if (_extent != extent) {
          _extent = extent;
          _reveal();
        }
        final cardHeight = _extent - 24;
        final selected = widget.items.isEmpty
            ? null
            : widget.items[widget.selected.clamp(0, widget.items.length - 1)];
        final duration = MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : const Duration(milliseconds: 220);
        return GlassScene(
            child: GlassBackdrop(
                background: RepaintBoundary(
                    child: Stack(fit: StackFit.expand, children: [
                      ImageFiltered(
                          imageFilter: ui.ImageFilter.blur(
                              sigmaX: blurBackdrop ? 28 : 0,
                              sigmaY: blurBackdrop ? 28 : 0,
                              tileMode: ui.TileMode.mirror),
                          child: FuturisticGameBackdrop(
                              category: widget.category,
                              selected: widget.selected,
                              image: selected?.image ?? '',
                              position: _railPosition)),
                      if (blurBackdrop)
                        const DecoratedBox(
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                              Color(0xE6060710),
                              Color(0xB0080B18),
                              Color(0xF2060710)
                            ]))),
                    ])),
                child: Stack(fit: StackFit.expand, children: [
                  // Compila o brilho do card antes do primeiro movimento.
                  const Positioned(left: 0, top: 0, child: FuturisticWarmup()),
                  FuturisticParticles(
                    position: _railPosition,
                    ambientMotion: widget.category == 0,
                  ),
                  Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: height * .25,
                      child: const IgnorePointer(
                          child: DecoratedBox(
                              decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                      begin: Alignment.bottomCenter,
                                      end: Alignment.topCenter,
                                      colors: [
                            Color(0xD7000000),
                            Colors.transparent,
                          ]))))),
                  SafeArea(
                      child: Padding(
                          padding: EdgeInsets.fromLTRB(padding, 22, 0, 4),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Padding(
                                    padding: EdgeInsets.only(right: padding),
                                    child: Row(children: [
                                      Image.asset('assets/IconeAppV1.png',
                                          width: 34, height: 34),
                                      const SizedBox(width: 12),
                                      const Text('V1',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 22,
                                              fontFamily: 'Oxanium',
                                              fontWeight: FontWeight.w600,
                                              letterSpacing: 4)),
                                      const Spacer(),
                                      if (!compact)
                                        const Text('FUTURISTA',
                                            style: TextStyle(
                                                color: Color(0xFFB6DDDB),
                                                fontSize: 11,
                                                letterSpacing: 3)),
                                      const SizedBox(width: 12),
                                      FuturisticHeaderControls(
                                          onMenu: widget.enabled
                                              ? widget.onMenu
                                              : null,
                                          windowControls:
                                              widget.windowControls),
                                    ])),
                                const SizedBox(height: 22),
                                _categories(compact, duration),
                                if (_showGameGrid) ...[
                                  SizedBox(height: compact ? 16 : 22),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Padding(
                                          padding: EdgeInsets.only(
                                              left: compact ? 14 : 22,
                                              right: compact ? 14 : 56),
                                          child: Row(
                                            children: [
                                              const Text('JOGOS',
                                                  style: TextStyle(
                                                      color:
                                                          Color(0xFFB6DDDB),
                                                      fontSize: 12,
                                                      fontFamily: 'Oxanium',
                                                      letterSpacing: 3)),
                                              const Spacer(),
                                              Text(
                                                  '${widget.items.length} jogos',
                                                  style: const TextStyle(
                                                      color: Colors.white70,
                                                      fontSize: 12,
                                                      fontFamily: 'Oxanium')),
                                            ],
                                          ),
                                        ),
                                        const SizedBox(height: 14),
                                        Expanded(
                                          child: widget.items.isEmpty
                                              ? const Center(
                                                  child: Icon(
                                                      Icons.water_rounded,
                                                      color: Colors.white38,
                                                      size: 52))
                                              : _gamesGrid(compact, duration),
                                        ),
                                      ],
                                    ),
                                  ),
                                ] else ...[
                                  const Spacer(),
                                  FuturisticViewBox(
                                      glass: false,
                                      page: widget.category,
                                      child: Padding(
                                          padding: EdgeInsets.only(
                                              left: compact ? 14 : 22,
                                              top: compact ? 14 : 22),
                                          child: Column(
                                              mainAxisSize: MainAxisSize.min,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    labels[widget.category]
                                                        .toUpperCase(),
                                                    style: const TextStyle(
                                                        color:
                                                            Color(0xFFB6DDDB),
                                                        fontSize: 12,
                                                        fontFamily: 'Oxanium',
                                                        letterSpacing: 3)),
                                                const SizedBox(height: 10),
                                                AnimatedSwitcher(
                                                    duration: duration,
                                                    child: Align(
                                                        key: ValueKey(
                                                            selected?.name),
                                                        alignment: Alignment
                                                            .centerLeft,
                                                        child: Text(
                                                            selected?.name ??
                                                                'Sua próxima descoberta',
                                                            maxLines: 1,
                                                            overflow:
                                                                TextOverflow
                                                                    .ellipsis,
                                                            style: TextStyle(
                                                                color: Colors
                                                                    .white,
                                                                fontSize:
                                                                    compact
                                                                        ? 28
                                                                        : 42,
                                                                fontFamily:
                                                                    'Oxanium',
                                                                fontWeight:
                                                                    FontWeight
                                                                        .w500,
                                                                shadows: const [
                                                                  Shadow(
                                                                      color: Colors
                                                                          .black54,
                                                                      blurRadius:
                                                                          16)
                                                                ])))),
                                                const SizedBox(height: 24),
                                                SizedBox(
                                                    height:
                                                        cardHeight * 1.5 + 22,
                                                    child: FocusScope(
                                                        node:
                                                            widget.itemScope,
                                                        child: widget
                                                                .items.isEmpty
                                                            ? const Center(
                                                                child: Icon(
                                                                    Icons
                                                                        .water_rounded,
                                                                    color: Colors
                                                                        .white38,
                                                                    size: 52))
                                                            : _cardRail(
                                                                duration,
                                                                cardHeight))),
                                              ]))),
                                ],
                              ]))),
                  if (widget.category == 0 &&
                      !widget.gridMode &&
                      widget.items.isNotEmpty)
                    Positioned(
                        left: 0,
                        right: 0,
                        bottom: 4,
                        child: SafeArea(
                            top: false,
                            child: IgnorePointer(
                                child: AnimatedOpacity(
                                    opacity: widget.openingGame ? 0 : 1,
                                    duration: duration,
                                    child: const Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text('Mais detalhes',
                                              style: TextStyle(
                                                  color: Color(0xFFB6DDDB),
                                                  fontFamily: 'Oxanium',
                                                  fontSize: 12,
                                                  letterSpacing: 1.2)),
                                          SizedBox(width: 6),
                                          Icon(
                                              Icons.keyboard_arrow_down_rounded,
                                              color: Color(0xFFB6DDDB),
                                              size: 22),
                                        ]))))),
                ])));
      });

  Widget _gamesGrid(bool compact, Duration duration) => FocusScope(
        node: widget.itemScope,
        child: GridView.builder(
          key: const ValueKey('futuristic-games-grid'),
          padding: EdgeInsets.fromLTRB(
              compact ? 14 : 22, 2, compact ? 14 : 56, 20),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 5,
            crossAxisSpacing: compact ? 8 : 12,
            mainAxisSpacing: compact ? 8 : 12,
            childAspectRatio: 14 / 9,
          ),
          itemCount: widget.items.length,
          itemBuilder: (_, index) => _gridCard(index, duration),
        ),
      );

  Widget _gridCard(int index, Duration duration) {
    final item = widget.items[index];
    final selected = index == widget.selected;
    return Builder(
      builder: (cardContext) => Focus(
        focusNode: widget.itemNodes[index],
        onFocusChange: (focused) {
          if (!focused || !widget.enabled) return;
          widget.onSelect(index);
          unawaited(Scrollable.ensureVisible(
            cardContext,
            alignment: .45,
            duration: duration,
            curve: Curves.easeOutCubic,
          ));
        },
        child: Builder(builder: (context) {
          final focused = Focus.of(context).hasFocus;
          return Semantics(
            label: item.name,
            selected: selected,
            button: true,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: !widget.enabled
                  ? null
                  : () {
                      widget.onSelect(index);
                      widget.onOpen();
                    },
              child: AnimatedContainer(
                duration: duration,
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  boxShadow: focused
                      ? const [
                          BoxShadow(
                              color: Color(0xD9A9EEE4),
                              blurRadius: 34,
                              spreadRadius: 4),
                          BoxShadow(
                              color: Color(0xA08063FF),
                              blurRadius: 18,
                              spreadRadius: 1),
                        ]
                      : null,
                ),
                foregroundDecoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(23),
                  border: Border.all(
                    color: focused
                        ? const Color(0xFFF4FFFE)
                        : Colors.transparent,
                    width: focused ? 2.5 : 0,
                  ),
                ),
                child: GlassPanel(
                  radius: 20,
                  focused: focused,
                  borderWidth: 5,
                  refractionWidth: 28,
                  child: Padding(
                    padding: const EdgeInsets.all(3),
                    child: _cardFace(item, borderRadius: 17),
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _cardRail(Duration duration, double cardSize) =>
      LayoutBuilder(builder: (_, rail) {
        final lastCardWidth = _cardVisualWidth(widget.items.length - 1);
        final respiro = _respiroEsquerdo(cardSize);
        // O espaço à direita encolhe junto com o respiro, para o último card
        // ainda alcançar exatamente a vaga iluminada.
        final trailingSpace =
            (rail.maxWidth - respiro - lastCardWidth - _cardGap)
                .clamp(0.0, double.infinity)
                .toDouble();
        final fadeWidth = ((cardSize * .8 + _cardGap) * 4)
            .clamp(0.0, rail.maxWidth)
            .toDouble();
        final fadeStart = rail.maxWidth <= 0
            ? 1.0
            : (1 - fadeWidth / rail.maxWidth).clamp(0.0, 1.0).toDouble();
        return Stack(children: [
          ShaderMask(
            blendMode: BlendMode.dstIn,
            shaderCallback: (bounds) => LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [Colors.white, Colors.transparent],
              stops: [fadeStart, 1],
            ).createShader(bounds),
            child: ListView.builder(
              key: ValueKey(widget.category),
              controller: _scroll,
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.only(
                  left: respiro, right: trailingSpace),
              itemCount: widget.items.length,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) => _card(index, duration),
            ),
          ),
          Positioned(
            // Acompanha o respiro: a vaga iluminada marca onde o card
            // selecionado para, e ele agora para depois da margem.
            left: respiro,
            top: 8,
            width: cardSize,
            height: cardSize,
            child: IgnorePointer(
              child: AnimatedOpacity(
                opacity: widget.openingGame ? 0 : 1,
                duration: duration,
                child: DecoratedBox(
                  key: const ValueKey('futuristic-fixed-slot'),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(25),
                    border: Border.all(
                        color: FuturisticPalette.pearl, width: 2),
                    boxShadow: const [
                      BoxShadow(
                          color: Color(0x608D70D8), blurRadius: 20)
                    ],
                  ),
                ),
              ),
            ),
          ),
        ]);
      });

  Widget _categories(bool compact, Duration duration) {
    final tabWidth = compact ? 55.0 : 132.0;
    final slideDuration = duration == Duration.zero
        ? Duration.zero
        : const Duration(milliseconds: 360);
    return FocusScope(
        node: widget.categoryScope,
        child: GlassPanel(
            radius: 28,
            child: Padding(
                padding: const EdgeInsets.all(5),
                child: SizedBox(
                    width: tabWidth * 4,
                    height: 46,
                    child: ListenableBuilder(
                        listenable: widget.categoryScope,
                        builder: (_, __) => Stack(children: [
                              AnimatedPositioned(
                                  key: const ValueKey(
                                      'futuristic-tab-indicator'),
                                  duration: slideDuration,
                                  curve: Curves.easeOutQuart,
                                  left: widget.category * tabWidth,
                                  top: 0,
                                  bottom: 0,
                                  width: tabWidth,
                                  child: IgnorePointer(
                                      child: AnimatedContainer(
                                          duration: duration,
                                          decoration: BoxDecoration(
                                              borderRadius:
                                                  BorderRadius.circular(23),
                                              gradient: LinearGradient(colors: [
                                                Colors.white.withValues(
                                                    alpha: widget.categoryScope
                                                            .hasFocus
                                                        ? .28
                                                        : .16),
                                                FuturisticPalette.water
                                                    .withValues(
                                                        alpha: widget
                                                                .categoryScope
                                                                .hasFocus
                                                            ? .18
                                                            : .08),
                                              ]),
                                              border: Border.all(
                                                  color: widget.categoryScope
                                                          .hasFocus
                                                      ? FuturisticPalette.pearl
                                                      : Colors.white24),
                                              boxShadow: widget
                                                      .categoryScope.hasFocus
                                                  ? const [
                                                      BoxShadow(
                                                          color:
                                                              Color(0x303FBDBB),
                                                          blurRadius: 16),
                                                    ]
                                                  : null)))),
                              Row(
                                  children: List.generate(
                                      4,
                                      (index) => SizedBox(
                                          width: tabWidth,
                                          child: Focus(
                                              focusNode:
                                                  widget.categoryNodes[index],
                                              onFocusChange: (focused) {
                                                if (focused && widget.enabled) {
                                                  widget.onCategory(index);
                                                }
                                              },
                                              child: GestureDetector(
                                                  behavior:
                                                      HitTestBehavior.opaque,
                                                  onTap: widget.enabled
                                                      ? () => widget
                                                          .categoryNodes[index]
                                                          .requestFocus()
                                                      : null,
                                                  child: Center(
                                                      child: Row(
                                                          mainAxisSize:
                                                              MainAxisSize.min,
                                                          children: [
                                                        Icon(icons[index],
                                                            size: 19,
                                                            color:
                                                                Colors.white),
                                                        if (!compact) ...[
                                                          const SizedBox(
                                                              width: 8),
                                                          Text(labels[index],
                                                              style: const TextStyle(
                                                                  color: Colors
                                                                      .white,
                                                                  fontFamily:
                                                                      'Oxanium',
                                                                  fontSize:
                                                                      14)),
                                                        ],
                                                      ]))))))),
                            ]))))));
  }

  Widget _card(int index, Duration duration) => FuturisticCardEntrance(
      animation: _entrance, index: index, child: _cardCorpo(index, duration));

  Widget _cardCorpo(int index, Duration duration) {
    final item = widget.items[index];
    final selected = index == widget.selected;
    final cardSize = _extent - _cardGap;
    final cardHeight = cardSize * 1.5 + 22;
    final visualWidth = cardSize * (selected ? 1 : .8);
    return Focus(
        focusNode: widget.itemNodes[index],
        onFocusChange: (focused) {
          if (focused && widget.enabled) {
            widget.onSelect(index);
            if (selected && !_motion.isAnimating) _reveal();
          }
        },
        child: Builder(builder: (context) {
          final focused = Focus.of(context).hasFocus;
          final card = SizedBox(
            width: cardSize,
            height: cardSize,
            child: AnimatedScale(
              scale: selected ? 1 : .8,
              alignment: Alignment.bottomLeft,
              duration: duration,
              curve: Curves.easeOutCubic,
              child: FuturisticCardFold(
                opening: selected && widget.openingGame,
                child: ValueListenableBuilder<int>(
                  valueListenable: _settled,
                  builder: (_, revision, child) => FuturisticCardEffect(
                    selected: selected,
                    focused: focused,
                    settledRevision: revision,
                    child: child!,
                  ),
                  child: GlassPanel(
                    radius: 25,
                    focused: focused,
                    borderWidth: 5,
                    refractionWidth: 28,
                    child: Padding(
                      padding: const EdgeInsets.all(3),
                      child: _cardFace(item, borderRadius: 22),
                    ),
                  ),
                ),
              ),
            ),
          );
          final reflection = AnimatedOpacity(
            opacity: selected && widget.openingGame ? 0 : 1,
            duration: duration,
            child: AnimatedScale(
              scale: selected ? 1 : .8,
              alignment: Alignment.topLeft,
              duration: duration,
              curve: Curves.easeOutCubic,
              child: FuturisticCardMirror(
                size: cardSize,
                focused: focused,
                child: Padding(
                  padding: const EdgeInsets.all(3),
                  child: _cardFace(item, borderRadius: 22),
                ),
              ),
            ),
          );
          return Semantics(
              label: item.name,
              selected: selected,
              button: true,
              child: GestureDetector(
                  onTap: !widget.enabled
                      ? null
                      : () {
                          widget.onSelect(index);
                          widget.onOpen();
                        },
                  child: SizedBox(
                      width: visualWidth + _cardGap,
                      height: cardHeight,
                      child: OverflowBox(
                          alignment: Alignment.topLeft,
                          minWidth: cardSize,
                          maxWidth: cardSize,
                          minHeight: cardHeight,
                          maxHeight: cardHeight,
                          child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    card,
                                    const SizedBox(height: 6),
                                    reflection,
                                  ]))))));
        }));
  }

  Widget _cardFace(FuturisticItem item, {double borderRadius = 20}) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: Stack(fit: StackFit.expand, children: [
          _cover(item),
          const DecoratedBox(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.center,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Color(0xDD051B24)]))),
          Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: Text(item.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Oxanium',
                      fontWeight: FontWeight.w500))),
        ]),
      );

  Widget _cover(FuturisticItem item) {
    final fallback = ColoredBox(
        color: const Color(0xFF35314F),
        child: Center(
            child: Icon(item.icon, size: 52, color: const Color(0xFFB8ECE8))));
    if (item.image.isEmpty) return fallback;
    if (item.image.startsWith('assets/')) {
      final imagem = Image.asset(item.image,
          fit: item.logo ? BoxFit.contain : BoxFit.cover,
          errorBuilder: (_, __, ___) => fallback);
      return item.logo
          ? Padding(padding: const EdgeInsets.all(18), child: imagem)
          : imagem;
    }
    if (item.image.startsWith('http')) {
      return Image.network(item.image,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
    }
    return Image.file(File(item.image),
        fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
  }
}
