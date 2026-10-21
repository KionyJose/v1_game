// ignore_for_file: file_names

import 'dart:async';
import 'dart:math' as math;
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:v1_game/Modelos/IconeInicial.dart';
import 'package:v1_game/Tela/Tela%20Principal/PrincipalCtrl.dart';

class BodyTransversal extends StatefulWidget {
  const BodyTransversal({super.key, required this.ctrl});

  final PrincipalCtrl ctrl;

  @override
  State<BodyTransversal> createState() => _BodyTransversalState();
}

class _BodyTransversalState extends State<BodyTransversal>
    with TickerProviderStateMixin {
  static const _accent = Color(0xFF66E8F2);
  late final AnimationController _scrollController;
  late final AnimationController _barsController;
  late Animation<double> _scrollAnimation;
  int _lastFocusedIndex = 0;
  int _lastGameCount = 0;
  double _visualPosition = 0;
  double _targetVisualIndex = 0;
  double _barDirection = 1;

  @override
  void initState() {
    super.initState();
    _lastFocusedIndex = widget.ctrl.selectedIndexIcone;
    _lastGameCount = widget.ctrl.listIconsInicial.length;
    _visualPosition = _lastFocusedIndex.toDouble();
    _targetVisualIndex = _lastFocusedIndex.toDouble();
    widget.ctrl.addListener(_onControllerSelectionChanged);
    _scrollController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 420),
    )..addListener(_onScrollTick);
    _scrollAnimation = AlwaysStoppedAnimation<double>(_visualPosition);
    _barsController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 920),
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && widget.ctrl.listIconsInicial.isNotEmpty) {
        _barsController.forward(from: 0);
      }
    });
  }

  @override
  void didUpdateWidget(covariant BodyTransversal oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.ctrl == widget.ctrl) return;
    oldWidget.ctrl.removeListener(_onControllerSelectionChanged);
    widget.ctrl.addListener(_onControllerSelectionChanged);
    _lastFocusedIndex = widget.ctrl.selectedIndexIcone;
    _lastGameCount = widget.ctrl.listIconsInicial.length;
    _visualPosition = _lastFocusedIndex.toDouble();
    _targetVisualIndex = _lastFocusedIndex.toDouble();
    _scrollController.stop();
    _scrollAnimation = AlwaysStoppedAnimation<double>(_visualPosition);
  }

  void _onScrollTick() {
    _visualPosition = _scrollAnimation.value;
    if (mounted) setState(() {});
  }

  void _animateToTarget() {
    _scrollController.stop();
    final distance = (_targetVisualIndex - _visualPosition).abs();
    if (distance < 0.001) return;
    _scrollController.duration = Duration(
      milliseconds: (distance * 360).round().clamp(220, 720).toInt(),
    );
    _scrollAnimation = Tween<double>(
      begin: _visualPosition,
      end: _targetVisualIndex,
    ).animate(
      CurvedAnimation(parent: _scrollController, curve: Curves.easeInOutCubic),
    );
    _scrollController.forward(from: 0);
  }

  void _onControllerSelectionChanged() {
    final index = widget.ctrl.selectedIndexIcone;
    final gameCount = widget.ctrl.listIconsInicial.length;
    if (gameCount != _lastGameCount) {
      _lastGameCount = gameCount;
      _lastFocusedIndex = index;
      _visualPosition = index.toDouble();
      _targetVisualIndex = index.toDouble();
      _scrollController.stop();
      _scrollAnimation = AlwaysStoppedAnimation<double>(_visualPosition);
      if (mounted) setState(() {});
      return;
    }
    if (index == _lastFocusedIndex) return;
    var delta = index - _lastFocusedIndex;
    if (gameCount >= 4 && _lastFocusedIndex == gameCount - 1 && index == 0) {
      delta = 1;
    } else if (gameCount >= 4 &&
        _lastFocusedIndex == 0 &&
        index == gameCount - 1) {
      delta = -1;
    }
    _barDirection = delta > 0 ? 1 : -1;
    if (delta.abs() == 1) {
      _targetVisualIndex += delta;
    } else {
      _targetVisualIndex = index.toDouble();
    }
    _lastFocusedIndex = index;
    _barsController.forward(from: 0);
    _animateToTarget();
  }

  @override
  void dispose() {
    widget.ctrl.removeListener(_onControllerSelectionChanged);
    _scrollController.dispose();
    _barsController.dispose();
    super.dispose();
  }

  void _onFocusChange(bool hasFocus, int index) {
    if (!hasFocus) return;
    widget.ctrl.onFocusChangeIcones(true, index);
  }

  void _openGame(int index) {
    // `entrandoNoJogo` fecha já no primeiro toque; `mouseBloqueado` só reflete
    // isso no quadro seguinte, e um duplo-clique rápido passava entre os dois.
    if (widget.ctrl.entrandoNoJogo ||
        widget.ctrl.mouseBloqueado ||
        index < 0 ||
        index >= widget.ctrl.listIconsInicial.length) {
      return;
    }
    widget.ctrl.selectedIndexIcone = index;
    widget.ctrl.focusScope = widget.ctrl.focusScopeIcones;
    widget.ctrl.focusNodeIcones[index].requestFocus();
    widget.ctrl.attTela();
    unawaited(widget.ctrl.btnEntrar());
  }

  @override
  Widget build(BuildContext context) {
    final games = widget.ctrl.listIconsInicial;
    final selectedGameIndex = games.isEmpty
        ? 0
        : widget.ctrl.selectedIndexIcone.clamp(0, games.length - 1).toInt();
    final selectedImagePath =
        games.isEmpty ? '' : games[selectedGameIndex].imgStr.trim();
    final selectionFloor = _visualPosition.floor();
    final scrollProgress = _visualPosition - selectionFloor;
    final firstAtStart = _firstRawIndex(selectionFloor);
    final firstAtEnd = _firstRawIndex(selectionFloor + 1);
    final firstRaw = math.min(firstAtStart, firstAtEnd);
    final lastRaw = math.max(firstAtStart, firstAtEnd) + 3;
    final panelRawIndices = games.length < 4
        ? List<int>.generate(4, (index) => index)
        : List<int>.generate(
            lastRaw - firstRaw + 1, (index) => firstRaw + index);
    final paintOrder = panelRawIndices.toList()
      ..sort((a, b) => _barDirection > 0 ? a.compareTo(b) : b.compareTo(a));

    return FocusScope(
      node: widget.ctrl.focusScopeIcones,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;
          final selectionStart = _layoutSelection(selectionFloor, games.length);
          final selectionEnd =
              _layoutSelection(selectionFloor + 1, games.length);

          return SizedBox.expand(
            child: Stack(
              clipBehavior: Clip.hardEdge,
              children: [
                const Positioned.fill(
                  child: ColoredBox(color: Color(0xFF0C1220)),
                ),
                if (selectedImagePath.isNotEmpty)
                  Positioned.fill(
                    child: Opacity(
                      opacity: 0.72,
                      child: Image.file(
                        File(selectedImagePath),
                        fit: BoxFit.cover,
                        filterQuality: FilterQuality.high,
                        errorBuilder: (_, __, ___) => const ColoredBox(
                          color: Color(0xFF0C1220),
                        ),
                      ),
                    ),
                  ),
                for (final rawIndex in paintOrder)
                  _buildPanel(
                    games: games,
                    rawIndex: rawIndex,
                    gameIndex: _gameIndexForRaw(rawIndex, games.length),
                    edges: _PanelEdges.lerp(
                      _edgesForSelection(
                        selectionFloor,
                        rawIndex,
                        selectionStart,
                        width,
                        games.length,
                      ),
                      _edgesForSelection(
                        selectionFloor + 1,
                        rawIndex,
                        selectionEnd,
                        width,
                        games.length,
                      ),
                      scrollProgress,
                    ),
                    emphasis: (1 - (rawIndex - _visualPosition).abs())
                        .clamp(0.0, 1.0)
                        .toDouble(),
                    isFocusedRaw: rawIndex == _targetVisualIndex.round(),
                    height: height,
                  ),
                Positioned(
                  left: 42,
                  right: 42,
                  bottom: 24,
                  child: _controlsHint(),
                ),
                Positioned.fill(
                  child: IgnorePointer(
                    child: AnimatedBuilder(
                      animation: _barsController,
                      builder: (context, _) => CustomPaint(
                        painter: _TransversalBarsPainter(
                          progress: _barsController.value,
                          direction: _barDirection,
                          accent: _accent,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  int _layoutSelection(int selection, int gameCount) {
    if (gameCount == 0) return 0;
    return gameCount < 4 ? selection.clamp(0, gameCount - 1) : selection;
  }

  int _firstRawIndex(int selection) => selection;

  int? _gameIndexForRaw(int rawIndex, int gameCount) {
    if (gameCount == 0) return null;
    if (gameCount < 4) return rawIndex < gameCount ? rawIndex : null;
    return ((rawIndex % gameCount) + gameCount) % gameCount;
  }

  _PanelEdges _edgesForSelection(
    int selection,
    int rawIndex,
    int layoutSelection,
    double width,
    int gameCount,
  ) {
    final firstRaw = _firstRawIndex(layoutSelection);
    final weights = List<double>.generate(4, (slot) {
      final raw = firstRaw + slot;
      if (gameCount < 4 && raw >= gameCount) return 0.72;
      final emphasis = (1 - (raw - selection).abs()).clamp(0.0, 1.0);
      return 0.78 + emphasis * 0.96;
    });
    final totalWeight = weights.fold<double>(0, (sum, value) => sum + value);
    final segmentWidths = weights.map((weight) => width * weight / totalWeight);
    final widths = segmentWidths.toList();
    final skew = math.min(38.0, width * 0.02);
    final topEdges = <double>[0];
    final bottomEdges = <double>[0];
    var edge = 0.0;
    for (var slot = 1; slot < 4; slot++) {
      edge += widths[slot - 1];
      topEdges.add(edge + skew);
      bottomEdges.add(edge - skew);
    }
    topEdges.add(width);
    bottomEdges.add(width);

    final slot = rawIndex - firstRaw;
    if (slot >= 0 && slot < 4) {
      return _PanelEdges(
        topEdges[slot],
        topEdges[slot + 1],
        bottomEdges[slot],
        bottomEdges[slot + 1],
      );
    }
    if (slot < 0) {
      return _PanelEdges(
        -widths.first - skew,
        -skew,
        -widths.first,
        -skew,
      );
    }
    return _PanelEdges(
      width + skew,
      width + widths.last + skew,
      width + skew,
      width + widths.last + skew,
    );
  }

  Widget _buildPanel({
    required List<IconInicial> games,
    required int? gameIndex,
    required int rawIndex,
    required _PanelEdges edges,
    required double emphasis,
    required bool isFocusedRaw,
    required double height,
  }) {
    final left = math.min(edges.topLeft, edges.bottomLeft);
    final right = math.max(edges.topRight, edges.bottomRight);
    final points = <Offset>[
      Offset(edges.topLeft - left, 0),
      Offset(edges.topRight - left, 0),
      Offset(edges.bottomRight - left, height),
      Offset(edges.bottomLeft - left, height),
    ];
    final selected = emphasis > 0.5;

    return Positioned(
      key: ValueKey('transversal-panel-$rawIndex'),
      left: left,
      top: 0,
      width: math.max(1.0, right - left),
      bottom: 0,
      child: ClipPath(
        clipper: _TransversalPanelClipper(points),
        child: gameIndex == null
            ? _emptyPanel(points)
            : Focus(
                focusNode: isFocusedRaw
                    ? widget.ctrl.focusNodeIcones[gameIndex]
                    : null,
                canRequestFocus: isFocusedRaw,
                skipTraversal: !isFocusedRaw,
                onFocusChange: (hasFocus) =>
                    _onFocusChange(hasFocus, gameIndex),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  // Sem toque enquanto um jogo sobe, como nos demais modos.
                  onTap: widget.ctrl.mouseBloqueado
                      ? null
                      : () => _openGame(gameIndex),
                  child: _gamePanel(
                    games[gameIndex],
                    gameIndex,
                    games.length,
                    emphasis,
                    selected,
                    points,
                  ),
                ),
              ),
      ),
    );
  }

  Widget _gamePanel(
    IconInicial game,
    int index,
    int total,
    double emphasis,
    bool selected,
    List<Offset> points,
  ) {
    final panelTextSize = 17 + emphasis * 13;
    final imagePath = game.imgStr.trim();
    final image = imagePath.isEmpty
        ? _missingArtwork(game.nome)
        : Image.file(
            File(imagePath),
            fit: BoxFit.cover,
            filterQuality: FilterQuality.high,
            errorBuilder: (_, __, ___) => _missingArtwork(game.nome),
          );

    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(child: image),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.24 - emphasis * 0.12),
                  const Color(0xFF07111D).withValues(alpha: 0.20),
                  Colors.black.withValues(alpha: 0.90 - emphasis * 0.22),
                ],
              ),
            ),
          ),
        ),
        if (selected)
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _accent.withValues(alpha: 0.13),
                    Colors.transparent,
                    const Color(0xFF6549D8).withValues(alpha: 0.14),
                  ],
                ),
              ),
            ),
          ),
        Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: _TransversalPanelPainter(
                points,
                color: selected ? _accent : Colors.white,
                opacity: selected ? 0.95 : 0.32,
                selected: selected,
              ),
            ),
          ),
        ),
        Positioned(
          top: 60,
          left: 38,
          right: 38,
          child: Row(
            children: [
              Text(
                (index + 1).toString().padLeft(2, '0'),
                style: TextStyle(
                  color: _accent.withValues(alpha: 0.88),
                  fontSize: 13 + emphasis * 4,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 2.5,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.28 + emphasis * 0.35),
                ),
              ),
            ],
          ),
        ),
        Positioned(
          left: 38,
          right: 38,
          bottom: 80,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedContainer(
                duration: const Duration(milliseconds: 240),
                width: 48 + emphasis * 80,
                height: 3,
                decoration: BoxDecoration(
                  color: _accent,
                  borderRadius: BorderRadius.circular(4),
                  boxShadow: [
                    BoxShadow(
                      color: _accent.withValues(alpha: 0.8),
                      blurRadius: 18,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                game.nome,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: panelTextSize,
                  height: 1.05,
                  fontWeight: FontWeight.w800,
                  letterSpacing: emphasis > 0.5 ? 0.8 : 0.2,
                  shadows: const [Shadow(color: Colors.black, blurRadius: 18)],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${(index + 1).toString().padLeft(2, '0')}  /  ${total.toString().padLeft(2, '0')}',
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.62),
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 2.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _missingArtwork(String title) => ColoredBox(
        color: const Color(0xFF11192B),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Text(
              title,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white24,
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
          ),
        ),
      );

  Widget _emptyPanel(List<Offset> points) => Stack(
        fit: StackFit.expand,
        children: [
          const ColoredBox(color: Color(0xFF0C1220)),
          CustomPaint(
            painter: _TransversalPanelPainter(
              points,
              color: _accent,
              opacity: 0.12,
            ),
          ),
          const Center(
            child: Icon(Icons.add_rounded, color: Colors.white12, size: 42),
          ),
        ],
      );

  Widget _controlsHint() => Row(
        children: [
          _hint('A / D'),
          const SizedBox(width: 24),
          _hint('ENTER / A'),
          const SizedBox(width: 24),
          _hint('+ / START'),
          const Spacer(),
          _hint('SELECT'),
        ],
      );

  Widget _hint(String key) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            key,
            style: const TextStyle(
              color: _accent,
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
        ],
      );
}

class _PanelEdges {
  const _PanelEdges(
    this.topLeft,
    this.topRight,
    this.bottomLeft,
    this.bottomRight,
  );

  final double topLeft;
  final double topRight;
  final double bottomLeft;
  final double bottomRight;

  static _PanelEdges lerp(_PanelEdges start, _PanelEdges end, double t) {
    double value(double a, double b) => a + (b - a) * t;
    return _PanelEdges(
      value(start.topLeft, end.topLeft),
      value(start.topRight, end.topRight),
      value(start.bottomLeft, end.bottomLeft),
      value(start.bottomRight, end.bottomRight),
    );
  }
}

class _TransversalPanelClipper extends CustomClipper<Path> {
  const _TransversalPanelClipper(this.points);
  final List<Offset> points;

  @override
  Path getClip(Size size) => _polygon(points);

  @override
  bool shouldReclip(covariant _TransversalPanelClipper oldClipper) =>
      oldClipper.points != points;
}

class _TransversalPanelPainter extends CustomPainter {
  const _TransversalPanelPainter(
    this.points, {
    required this.color,
    required this.opacity,
    this.selected = false,
  });

  final List<Offset> points;
  final Color color;
  final double opacity;
  final bool selected;

  @override
  void paint(Canvas canvas, Size size) {
    final path = _polygon(points);
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selected ? 1.8 : 1
        ..color = color.withValues(alpha: opacity),
    );
  }

  @override
  bool shouldRepaint(covariant _TransversalPanelPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.color != color ||
      oldDelegate.opacity != opacity ||
      oldDelegate.selected != selected;
}

class _TransversalBarsPainter extends CustomPainter {
  const _TransversalBarsPainter({
    required this.progress,
    required this.direction,
    required this.accent,
  });

  final double progress;
  final double direction;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    // A lâmina principal cruza a tela logo após a mudança de foco.
    final primaryProgress = (progress / 0.38).clamp(0.0, 1.0).toDouble();
    if (primaryProgress > 0 && primaryProgress < 1) {
      final eased = Curves.easeOutCubic.transform(primaryProgress);
      final x = _travelX(size.width, eased, overscan: 0.18);
      _drawBar(
        canvas,
        x: x,
        centerY: size.height * 0.48,
        width: size.width * 0.17,
        height: size.height * 0.038,
        alpha: math.sin(primaryProgress * math.pi) * 0.30,
      );
    }

    // A lâmina maior acompanha o movimento com menos brilho e uma saída lenta.
    final secondaryProgress =
        ((progress - 0.045) / 0.955).clamp(0.0, 1.0).toDouble();
    if (secondaryProgress > 0 && secondaryProgress < 1) {
      final eased = Curves.easeInOutCubic.transform(secondaryProgress);
      final x = _travelX(size.width, eased, overscan: 0.34);
      _drawBar(
        canvas,
        x: x,
        centerY: size.height * 0.62,
        width: size.width * 0.29,
        height: size.height * 0.055,
        alpha: math.sin(secondaryProgress * math.pi) * 0.105,
      );
    }
  }

  double _travelX(double width, double progress, {required double overscan}) {
    final from = direction > 0 ? -width * overscan : width * (1 + overscan);
    final to = direction > 0 ? width * (1 + overscan) : -width * overscan;
    return from + (to - from) * progress;
  }

  void _drawBar(
    Canvas canvas, {
    required double x,
    required double centerY,
    required double width,
    required double height,
    required double alpha,
  }) {
    final path = Path()
      ..moveTo(x, centerY)
      ..lineTo(x + width, centerY - height * 0.42)
      ..lineTo(x + width, centerY + height)
      ..lineTo(x, centerY + height * 1.42)
      ..close();
    canvas.drawPath(
      path,
      Paint()
        ..color = accent.withValues(alpha: alpha)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );
  }

  @override
  bool shouldRepaint(covariant _TransversalBarsPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.direction != direction ||
      oldDelegate.accent != accent;
}

Path _polygon(List<Offset> points) {
  final path = Path()..moveTo(points.first.dx, points.first.dy);
  for (final point in points.skip(1)) {
    path.lineTo(point.dx, point.dy);
  }
  return path..close();
}
