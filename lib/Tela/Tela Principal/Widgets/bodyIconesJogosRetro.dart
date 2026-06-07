// ignore_for_file: file_names

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import 'package:scroll_snap_list/scroll_snap_list.dart';
import 'package:v1_game/Modelos/IconeInicial.dart';
import 'package:v1_game/Tela/Tela%20Principal/PrincipalCtrl.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// ── Paleta Retro NES ─────────────────────────────────────────────────────────
const _navy    = Color(0xFF08102A);
const _navyMid = Color(0xFF0D1A3D);
const _cyan    = Color(0xFF00E5FF);
const _cyanDim = Color(0x5500E5FF);
const _white70 = Color(0xB3FFFFFF);
const _cardBg  = Color(0xFF111928);
const _barBg   = Color(0xFF04070F);

class BodyIconesJogosRetro extends StatefulWidget {
  final PrincipalCtrl ctrl;
  final double tamanhoBloco;

  const BodyIconesJogosRetro({
    super.key,
    required this.ctrl,
    required this.tamanhoBloco,
  });

  @override
  State<BodyIconesJogosRetro> createState() => _BodyIconesJogosRetroState();
}

class _BodyIconesJogosRetroState extends State<BodyIconesJogosRetro> {
  PrincipalCtrl get ctrl => widget.ctrl;

  final _scrollCtrl  = ScrollController();
  final _thumbScroll = ScrollController();

  late final Player _heroPlayer;
  late final mkv.VideoController _heroCtrl;
  bool _heroAtivo = false;
  String _lastGame = '';

  // ── ciclo de vida ────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _heroPlayer = Player();
    _heroCtrl = mkv.VideoController(_heroPlayer);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final nome = _nomeAtual;
      if (nome.isNotEmpty) { _lastGame = nome; _iniciarVideo(nome); }
    });
  }

  @override
  void didUpdateWidget(BodyIconesJogosRetro old) {
    super.didUpdateWidget(old);
    final nome = _nomeAtual;
    if (nome != _lastGame && nome.isNotEmpty) { _lastGame = nome; _iniciarVideo(nome); }
  }

  @override
  void dispose() {
    _scrollCtrl.dispose();
    _thumbScroll.dispose();
    try { _heroPlayer.dispose(); } catch (_) {}
    super.dispose();
  }

  // ── helpers ──────────────────────────────────────────────────────────────
  String get _nomeAtual => ctrl.listIconsInicial.isEmpty
      ? '' : ctrl.listIconsInicial[ctrl.selectedIndexIcone].nome;

  IconInicial? get _jogo => ctrl.listIconsInicial.isEmpty
      ? null : ctrl.listIconsInicial[ctrl.selectedIndexIcone];

  Future<void> _iniciarVideo(String nome) async {
    try { await _heroPlayer.stop(); } catch (_) {}
    if (mounted) setState(() => _heroAtivo = false);
    try {
      final tags = ctrl.tagVideo;
      final tag  = tags[Random().nextInt(tags.length)];
      final yt   = YoutubeExplode();
      final res  = await yt.search.search('$nome $tag');
      if (res.isEmpty) { yt.close(); return; }
      final vid  = res[Random().nextInt(res.length.clamp(1, 5))];
      final mani = await yt.videos.streamsClient.getManifest(vid.id);
      final str  = mani.muxed.bestQuality;
      await _heroPlayer.open(Media(str.url.toString()));
      _heroPlayer.setVolume(0);
      yt.close();
      if (mounted) setState(() => _heroAtivo = true);
    } catch (_) {}
  }

  void _onFoco(int i) {
    if (!mounted) return;
    try {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(i * widget.tamanhoBloco,
            duration: const Duration(milliseconds: 600), curve: Curves.decelerate);
      }
    } catch (_) {}
    try {
      if (_thumbScroll.hasClients) {
        _thumbScroll.animateTo(i * 64.0,
            duration: const Duration(milliseconds: 400), curve: Curves.ease);
      }
    } catch (_) {}
    ctrl.onFocusChangeIcones(true, i, tamanho: widget.tamanhoBloco);
  }

  // ── build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sz = MediaQuery.of(context).size;
    return Stack(
      children: [
        _fundo(sz),
        _scanlines(sz),
        _topIcons(sz),
        _titleBar(sz),
        _carrossel(sz),
        _setaIndicador(sz),
        _thumbStrip(sz),
        _bottomBar(sz),
      ],
    );
  }

  // ── seções ───────────────────────────────────────────────────────────────

  Widget _fundo(Size sz) {
    final img = _jogo?.imgStr ?? '';
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          Container(color: _navy),
          // Vídeo de fundo com efeito de vidro
          if (_heroAtivo)
            Opacity(
              opacity: 0.25, 
              child: mkv.Video(controller: _heroCtrl, controls: mkv.NoVideoControls)
            ),
          if (!_heroAtivo && img.isNotEmpty)
            Opacity(
              opacity: 0.20,
              child: Image.file(File(img), fit: BoxFit.cover,
                  filterQuality: FilterQuality.low, // Estilo retro
                  errorBuilder: (_, __, ___) => const SizedBox()),
            ),
          
          // Efeito de "Vignette" Retro
          Container(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 1.2,
                colors: [
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.7),
                ],
              ),
            ),
          ),

          // Gradientes de profundidade
          const DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [Color(0xEE08102A), Colors.transparent, Colors.transparent, Color(0xFF08102A)],
                stops: [0.0, 0.2, 0.8, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _scanlines(Size sz) => Positioned.fill(
    child: IgnorePointer(
      child: CustomPaint(painter: _ScanlinesPainter(spacing: 3)),
    ),
  );

  Widget _topIcons(Size sz) => Positioned(
    top: 14, left: 0, right: 0,
    child: Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _retroIcon(Icons.desktop_windows, true),
        _retroIcon(Icons.settings, false),
        _retroIcon(Icons.language, false),
        _retroIcon(Icons.format_list_bulleted, false),
        _retroIcon(Icons.help_outline, false),
      ],
    ),
  );

  Widget _retroIcon(IconData ico, bool sel) => Container(
    margin: const EdgeInsets.symmetric(horizontal: 10),
    padding: const EdgeInsets.all(8),
    decoration: BoxDecoration(
      border: Border.all(color: sel ? Colors.white : Colors.white24, width: sel ? 2 : 1),
      color: sel ? Colors.white12 : Colors.transparent,
    ),
    child: Icon(ico, color: sel ? Colors.white : Colors.white54, size: 20),
  );

  Widget _titleBar(Size sz) => Positioned(
    top: 78, left: 0, right: 0,
    child: Column(
      children: [
        Container(
          width: sz.width * 0.85,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 24),
          decoration: const BoxDecoration(
            color: _navyMid,
            border: Border.symmetric(
              horizontal: BorderSide(color: _cyan, width: 1),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.arrow_right, color: _cyan, size: 24),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _nomeAtual.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 4,
                    shadows: [
                      Shadow(color: _cyan, blurRadius: 10),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_left, color: _cyan, size: 24),
            ],
          ),
        ),
        // Detalhe decorativo abaixo do título
        Container(
          width: sz.width * 0.6,
          height: 2,
          margin: const EdgeInsets.only(top: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.transparent, _cyan.withValues(alpha: 0.5), Colors.transparent],
            ),
          ),
        ),
      ],
    ),
  );

  Widget _carrossel(Size sz) {
    // Cálculo de dimensões responsivas
    final cardWidth = sz.width * 0.28; // Card ocupa 28% da largura da tela
    final cardHeight = sz.height * 0.45;
    
    return Container(
      // color: Colors.red,
      child: Positioned(
        top: sz.height * 0.22,
        left: 0,
        right: 0,
        height: cardHeight * 1.3, // Espaço extra para o efeito de escala
        child: FocusScope(
          node: ctrl.focusScopeIcones,
          child: Container(
            // color: Colors.red,
            child: 
            ScrollSnapList(
              // quero que seja loop infinito


              initialIndex: ctrl.selectedIndexIcone.toDouble(),
              // padding: EdgeInsets.symmetric(horizontal: (sz.width - cardWidth) /6),
              listController: _scrollCtrl,
              itemCount: ctrl.focusNodeIcones.length,
              onItemFocus: (index) {
                // Sincroniza se necessário, mas o foco real vem do Focus widget
              },
              itemSize: cardWidth + 20, // largura do card + margem
              itemBuilder: (_, i) => _card(i, sz, cardWidth, cardHeight),
            ),
          ),
        ),
      ),
    );
  }

  Widget _card(int i, Size sz, double baseWidth, double baseHeight) {
    final focused = ctrl.selectedIndexIcone == i;
    final item = (i < ctrl.listIconsInicial.length) ? ctrl.listIconsInicial[i] : null;
    final img  = item?.imgStr ?? '';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutCubic,
      width: focused ? baseWidth * 1.15 : baseWidth,
      height: focused ? baseHeight * 1.15 : baseHeight,
      margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 20),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: focused ? _cyan : Colors.white.withValues(alpha: 0.1),
          width: focused ? 4 : 2,
        ),
        boxShadow: focused
            ? [
                BoxShadow(color: _cyan.withValues(alpha: 0.5), blurRadius: 30, spreadRadius: 2),
                BoxShadow(color: _cyan.withValues(alpha: 0.2), blurRadius: 60, spreadRadius: 5),
              ]
            : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.5), blurRadius: 10, offset: const Offset(0, 5)),
              ],
      ),
      child: Focus(
        focusNode: ctrl.focusNodeIcones[i],
        onFocusChange: (hasFocus) { 
          if (hasFocus) {
            _onFoco(i); 
          }
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Imagem principal
              if (img.isNotEmpty)
                Image.file(
                  File(img), 
                  fit: BoxFit.cover,
                  filterQuality: FilterQuality.medium,
                  errorBuilder: (_, __, ___) => _semImagem(),
                )
              else
                _semImagem(),

              // Overlay Gradiente para leitura
              if (focused)
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Colors.transparent, Colors.black87],
                      stops: [0.6, 1.0],
                    ),
                  ),
                ),

              // Elementos Decorativos Retro (dentro do card)
              if (focused)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const Text(
                      'HI-RES',
                      style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),

              // Rodapé do card selecionado
              if (focused && (item?.nome.isNotEmpty ?? false))
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item!.nome.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: List.generate(3, (index) => Container(
                                width: 6,
                                height: 6,
                                margin: const EdgeInsets.only(right: 4),
                                decoration: const BoxDecoration(color: _cyan, shape: BoxShape.circle),
                              )),
                            ),
                            const Text(
                              'PRESS START',
                              style: TextStyle(
                                color: _cyan,
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
              // Overlay de scanlines internas (mais sutis)
              Positioned.fill(
                child: IgnorePointer(
                  child: Opacity(
                    opacity: 0.05,
                    child: CustomPaint(painter: _ScanlinesPainter(spacing: 2)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _semImagem() => const Center(
    child: Icon(Icons.videogame_asset, color: Colors.white24, size: 48),
  );

  Widget _setaIndicador(Size sz) => Positioned(
    top: sz.height * 0.62,
    left: 0, right: 0,
    child: const Center(
      child: Icon(Icons.arrow_drop_down, color: _cyan, size: 28),
    ),
  );

  Widget _thumbStrip(Size sz) {
    if (ctrl.listIconsInicial.isEmpty) return const SizedBox();
    return Positioned(
      bottom: 44, left: 0, right: 0, height: 62,
      child: ListView.builder(
        controller: _thumbScroll,
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.symmetric(horizontal: sz.width * 0.08),
        itemCount: ctrl.listIconsInicial.length,
        itemBuilder: (_, i) {
          final focused = ctrl.selectedIndexIcone == i;
          final img = ctrl.listIconsInicial[i].imgStr;
          return GestureDetector(
            onTap: () => _onFoco(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              width: 58, height: 58,
              margin: const EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                border: Border.all(
                  color: focused ? _cyan : Colors.white24,
                  width: focused ? 2 : 1,
                ),
                color: _cardBg,
              ),
              child: img.isNotEmpty
                  ? Image.file(File(img), fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.videogame_asset, color: Colors.white24, size: 18))
                  : const Icon(Icons.videogame_asset, color: Colors.white24, size: 18),
            ),
          );
        },
      ),
    );
  }

  Widget _bottomBar(Size sz) => Positioned(
    bottom: 0, left: 0, right: 0,
    child: Container(
      color: _barBg,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('RETRO', style: TextStyle(
                  color: Colors.red, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1)),
              Text('ENTERTAINMENT SYSTEM', style: TextStyle(
                  color: Colors.red, fontSize: 9, letterSpacing: 1)),
            ],
          ),
          Row(children: [
            _hint('+', 'Menu'),
            const SizedBox(width: 14),
            _hint('SELECT', 'Ordenar'),
            const SizedBox(width: 14),
            _hint('START', 'Iniciar'),
          ]),
        ],
      ),
    ),
  );

  Widget _hint(String btn, String label) => Row(
    children: [
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
        decoration: BoxDecoration(
          color: btn == 'START' ? Colors.red : const Color(0xFF1A2040),
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: Colors.white24),
        ),
        child: Text(btn, style: const TextStyle(
            color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
      const SizedBox(width: 4),
      Text(label, style: const TextStyle(color: _white70, fontSize: 11)),
    ],
  );
}

// ── Scanlines ────────────────────────────────────────────────────────────────
class _ScanlinesPainter extends CustomPainter {
  final double spacing;
  _ScanlinesPainter({this.spacing = 3});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.black.withValues(alpha: 0.12)
      ..strokeWidth = 1;
    for (double y = 0; y < size.height; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
    }
  }

  @override
  bool shouldRepaint(covariant _ScanlinesPainter old) => old.spacing != spacing;
}
