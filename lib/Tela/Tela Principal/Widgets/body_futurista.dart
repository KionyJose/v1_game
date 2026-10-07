import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/physics.dart';
import '../../../Interface/futuristic_card_effect.dart';
import '../../../Interface/futuristic_game_backdrop.dart';
import '../../../Interface/futuristic_view_box.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:window_manager/window_manager.dart';
import 'package:provider/provider.dart';
import '../../../Class/Paad.dart';
import '../../../Controllers/JanelaCtrl.dart';
import '../../../Bando de Dados/db.dart';

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

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.ctrl.focarCategoriaSlim();
    });
    _startAudio();
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
    SonsSistema.updateWaterAmbience(handle,
        _foreground && widget.ctrl.stateTela && (_route?.isCurrent ?? true));
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
    _audioTimer?.cancel();
    windowManager.removeListener(this);
    final handle = _ambience;
    if (handle != null) unawaited(SonsSistema.stopWaterAmbience(handle));
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = widget.ctrl;
    final category = ctrl.selectedIndexAbaGuias;
    final items = List.generate(
        ctrl.slimItemNodes.length,
        (index) => switch (category) {
              1 => FuturisticItem(ctrl.listCinema[index].nome,
                  ctrl.listCinema[index].imgLocal, Icons.movie_rounded),
              2 => FuturisticItem(ctrl.listMusica[index].nome,
                  ctrl.listMusica[index].imgLocal, Icons.music_note_rounded),
              3 => FuturisticItem(
                  ctrl.listLojas[index].nome, '', ctrl.listLojas[index].icone),
              _ => FuturisticItem(
                  ctrl.listIconsInicial[index].nome,
                  ctrl.listIconsInicial[index].imgStr,
                  Icons.sports_esports_rounded),
            });
    return LauncherPadScope(
      enabled: !ctrl.mouseBloqueado,
      revealInitialFocus: false,
      revealFocus: false,
      onCommand: ctrl.comandoSlim,
      child: Focus(
        skipTraversal: true,
        onKeyEvent: (_, event) {
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
          windowControls: const _FuturisticWindowControls(),
          category: category,
          selected: ctrl.slimItemIndex,
          items: items,
          itemNodes: ctrl.slimItemNodes,
          categoryNodes: ctrl.focusNodeAbaGuias,
          itemScope: ctrl.slimItemScope,
          categoryScope: ctrl.focusScopeAbaGuias,
          enabled: !ctrl.mouseBloqueado,
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
  const FuturisticItem(this.name, this.image, this.icon);
  final String name;
  final String image;
  final IconData icon;
}

class _FuturisticWindowControls extends StatelessWidget {
  const _FuturisticWindowControls();
  @override
  Widget build(BuildContext context) {
    final window = context.watch<JanelaCtrl?>();
    final pads = context.watch<Paad?>()?.controlesAtivos.length ?? 0;
    return ExcludeFocus(
        child: Row(mainAxisSize: MainAxisSize.min, children: [
      IconButton(
          tooltip: 'Travar tela',
          icon: Icon(
              window?.telaPresa == true
                  ? Icons.lock_outline
                  : Icons.lock_open_rounded,
              color: const Color(0xFFB6DDDB),
              size: 18),
          onPressed: window?.telaPresaReverse),
      Text(window?.telaPresa == true ? 'Fixada' : 'Livre',
          style: const TextStyle(color: FuturisticPalette.pearl, fontSize: 12)),
      const SizedBox(width: 14),
      Tooltip(
          message: '$pads controles conectados',
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.sports_esports_rounded,
                color: FuturisticPalette.water, size: 18),
            const SizedBox(width: 6),
            Text('$pads',
                style: const TextStyle(
                    color: FuturisticPalette.pearl, fontSize: 12)),
          ])),
      IconButton(
          tooltip: 'Fechar aplicativo',
          icon: const Icon(Icons.close_rounded,
              color: Color(0xFFB6DDDB), size: 20),
          onPressed: () {
            DB.closeOpenedFileFast();
            JanelaCtrl.fecharAppForcado(origem: 'modo Futurista');
          }),
    ]));
  }
}

/// Independently testable glass layout; it never launches processes itself.
class FuturisticHome extends StatefulWidget {
  const FuturisticHome(
      {super.key,
      required this.category,
      required this.selected,
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
      this.enabled = true});
  final Widget? windowControls;
  final int category, selected;
  final List<FuturisticItem> items;
  final List<FocusNode> itemNodes, categoryNodes;
  final FocusScopeNode itemScope, categoryScope;
  final ValueChanged<int> onSelect, onCategory;
  final VoidCallback onOpen, onMenu;
  final bool enabled;
  @override
  State<FuturisticHome> createState() => _FuturisticHomeState();
}

class _FuturisticHomeState extends State<FuturisticHome>
    with SingleTickerProviderStateMixin {
  final _scroll = ScrollController();
  final _settled = ValueNotifier<int>(0);
  late final ValueNotifier<double> _railPosition;
  late final AnimationController _motion;
  double _extent = 200;
  int _revision = 0;
  Timer? _focusSettle;
  static const labels = ['Jogos', 'Cinema', 'Música', 'Lojas'];
  static const icons = [
    Icons.sports_esports_rounded,
    Icons.movie_rounded,
    Icons.music_note_rounded,
    Icons.storefront_rounded
  ];

  void _tick() {
    if (!_scroll.hasClients || _scroll.positions.length != 1) return;
    _scroll.jumpTo(_motion.value.clamp(0.0, _scroll.position.maxScrollExtent));
    _railPosition.value = _scroll.offset / _extent;
  }

  void _reveal({bool categoryChanged = false}) {
    final revision = ++_revision;
    _focusSettle?.cancel();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted ||
          revision != _revision ||
          !_scroll.hasClients ||
          _scroll.positions.length != 1) {
        return;
      }
      final target = (widget.selected * _extent)
          .clamp(0.0, _scroll.position.maxScrollExtent);
      final reduceMotion = MediaQuery.disableAnimationsOf(context);
      final velocity =
          _motion.isAnimating && !categoryChanged ? _motion.velocity : 0.0;
      _motion.stop();
      if (categoryChanged ||
          reduceMotion ||
          (target - _scroll.offset).abs() < .5) {
        _scroll.jumpTo(target);
        _railPosition.value = _scroll.offset / _extent;
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
      _railPosition.value = _scroll.offset / _extent;
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

  @override
  void initState() {
    super.initState();
    _railPosition = ValueNotifier(widget.selected.toDouble());
    _motion = AnimationController.unbounded(vsync: this)..addListener(_tick);
    _reveal(categoryChanged: true);
  }

  @override
  void didUpdateWidget(FuturisticHome oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.category != widget.category) _motion.stop();
    if (oldWidget.selected != widget.selected ||
        oldWidget.category != widget.category ||
        oldWidget.items.length != widget.items.length) {
      _reveal(categoryChanged: oldWidget.category != widget.category);
    }
  }

  @override
  void dispose() {
    ++_revision;
    _focusSettle?.cancel();
    _motion.dispose();
    _railPosition.dispose();
    _scroll.dispose();
    _settled.dispose();
    super.dispose();
  }

  @override
  Widget
      build(BuildContext context) =>
          LayoutBuilder(builder: (context, constraints) {
            final compact = constraints.maxWidth < 800;
            final padding = compact ? 24.0 : 56.0;
            final height = constraints.maxHeight;
            final extent =
                (height * (height < 550 ? .26 : .32)).clamp(110.0, 245.0) + 24;
            if (_extent != extent) {
              _extent = extent;
              _reveal();
            }
            final cardHeight = _extent - 24;
            final selected = widget.items.isEmpty
                ? null
                : widget
                    .items[widget.selected.clamp(0, widget.items.length - 1)];
            final duration = MediaQuery.disableAnimationsOf(context)
                ? Duration.zero
                : const Duration(milliseconds: 220);
            return GlassScene(
                child: GlassBackdrop(
                    background: RepaintBoundary(
                        child: FuturisticGameBackdrop(
                            category: widget.category,
                            selected: widget.selected,
                            image: selected?.image ?? '',
                            position: _railPosition)),
                    child: Stack(fit: StackFit.expand, children: [
                      SafeArea(
                          child: Padding(
                              padding:
                                  EdgeInsets.fromLTRB(padding, 22, padding, 18),
                              child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(children: [
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
                                      GlassPanel(
                                          radius: 26,
                                          child: Padding(
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                      horizontal: 8),
                                              child: Row(
                                                  mainAxisSize:
                                                      MainAxisSize.min,
                                                  children: [
                                                    if (widget.windowControls !=
                                                        null)
                                                      widget.windowControls!,
                                                    ExcludeFocus(
                                                        child: IconButton(
                                                            tooltip: 'Menu',
                                                            onPressed: widget
                                                                    .enabled
                                                                ? widget.onMenu
                                                                : null,
                                                            icon: const Icon(
                                                                Icons
                                                                    .more_horiz_rounded,
                                                                color:
                                                                    FuturisticPalette
                                                                        .pearl))),
                                                  ]))),
                                    ]),
                                    const SizedBox(height: 22),
                                    _categories(compact, duration),
                                    const Spacer(),
                                    FuturisticViewBox(
                                        page: widget.category,
                                        child: Padding(
                                            padding: EdgeInsets.all(
                                                compact ? 14 : 22),
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
                                                  const SizedBox(height: 8),
                                                  Text(
                                                      widget.items.isEmpty
                                                          ? 'Adicione seus favoritos pelo menu.'
                                                          : '${widget.items.length} favoritos • Um universo para explorar',
                                                      style: const TextStyle(
                                                          color:
                                                              Color(0xFFB6DDDB),
                                                          fontSize: 13)),
                                                  const SizedBox(height: 24),
                                                  SizedBox(
                                                      height: cardHeight + 16,
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
                                                              : LayoutBuilder(
                                                                  builder: (_,
                                                                          rail) =>
                                                                      Stack(
                                                                          children: [
                                                                            ListView.builder(
                                                                                key: ValueKey(widget.category),
                                                                                controller: _scroll,
                                                                                scrollDirection: Axis.horizontal,
                                                                                padding: EdgeInsets.only(right: (rail.maxWidth - _extent).clamp(0.0, double.infinity)),
                                                                                itemExtent: _extent,
                                                                                itemCount: widget.items.length,
                                                                                physics: const NeverScrollableScrollPhysics(),
                                                                                itemBuilder: (context, index) => _card(index, duration)),
                                                                            Positioned(
                                                                                left: 0,
                                                                                top: 8,
                                                                                width: cardHeight,
                                                                                height: cardHeight,
                                                                                child: IgnorePointer(child: DecoratedBox(key: const ValueKey('futuristic-fixed-slot'), decoration: BoxDecoration(borderRadius: BorderRadius.circular(25), border: Border.all(color: FuturisticPalette.pearl, width: 2), boxShadow: const [BoxShadow(color: Color(0x608D70D8), blurRadius: 20)])))),
                                                                          ])))),
                                                ]))),
                                    const Spacer(),
                                  ]))),
                    ])));
          });

  Widget _categories(bool compact, Duration duration) => FocusScope(
      node: widget.categoryScope,
      child: GlassPanel(
          radius: 28,
          child: Padding(
              padding: const EdgeInsets.all(5),
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                      4,
                      (index) => Focus(
                          focusNode: widget.categoryNodes[index],
                          onFocusChange: (focus) {
                            if (focus && widget.enabled) {
                              widget.onCategory(index);
                            }
                          },
                          child: Builder(builder: (context) {
                            final focused = Focus.of(context).hasFocus;
                            return GestureDetector(
                                onTap: widget.enabled
                                    ? () => widget.categoryNodes[index]
                                        .requestFocus()
                                    : null,
                                child: AnimatedContainer(
                                    duration: duration,
                                    curve: Curves.easeOutCubic,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: compact ? 12 : 22,
                                        vertical: 12),
                                    decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(23),
                                        color: widget.category == index
                                            ? Colors.white.withValues(
                                                alpha: focused ? .25 : .14)
                                            : Colors.transparent,
                                        border: Border.all(
                                            color: focused
                                                ? const Color(0xFFE0FFF8)
                                                : Colors.transparent)),
                                    child: Row(children: [
                                      Icon(icons[index],
                                          size: 19, color: Colors.white),
                                      if (!compact) ...[
                                        const SizedBox(width: 8),
                                        Text(labels[index],
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontFamily: 'Oxanium',
                                                fontSize: 14))
                                      ]
                                    ])));
                          })))))));

  Widget _card(int index, Duration duration) {
    final item = widget.items[index];
    final selected = index == widget.selected;
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
                  child: Padding(
                      padding: const EdgeInsets.fromLTRB(0, 8, 24, 8),
                      child: ValueListenableBuilder<int>(
                          valueListenable: _settled,
                          builder: (_, revision, child) => FuturisticCardEffect(
                              selected: selected,
                              focused: focused,
                              settledRevision: revision,
                              child: child!),
                          child: AnimatedContainer(
                              duration: duration,
                              curve: Curves.easeOutCubic,
                              padding: const EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  color: Colors.white.withValues(alpha: .06),
                                  border: Border.all(
                                      color:
                                          Colors.white.withValues(alpha: .16),
                                      width: 1)),
                              child: ClipRRect(
                                  borderRadius: BorderRadius.circular(20),
                                  child: Stack(fit: StackFit.expand, children: [
                                    _cover(item),
                                    const DecoratedBox(
                                        decoration: BoxDecoration(
                                            gradient: LinearGradient(
                                                begin: Alignment.center,
                                                end: Alignment.bottomCenter,
                                                colors: [
                                          Colors.transparent,
                                          Color(0xDD051B24)
                                        ]))),
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
                                  ])))))));
        }));
  }

  Widget _cover(FuturisticItem item) {
    final fallback = ColoredBox(
        color: const Color(0xFF35314F),
        child: Center(
            child: Icon(item.icon, size: 52, color: const Color(0xFFB8ECE8))));
    if (item.image.isEmpty) return fallback;
    if (item.image.startsWith('assets/')) {
      return Image.asset(item.image,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
    }
    if (item.image.startsWith('http')) {
      return Image.network(item.image,
          fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
    }
    return Image.file(File(item.image),
        fit: BoxFit.cover, errorBuilder: (_, __, ___) => fallback);
  }
}
