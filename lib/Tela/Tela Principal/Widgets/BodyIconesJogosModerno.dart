// ignore_for_file: file_names

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart' as mkv;
import 'package:v1_game/Class/WebScrap.dart';
import 'package:v1_game/Modelos/NoticiaGame.dart';
import 'package:v1_game/Tela/Tela Principal/PrincipalCtrl.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';

// ── Paleta azul-violeta ────────────────────────────────────────────────────────
const _corP = Color(0xFF3B2BDB);
const _corA = Color(0xFF7B5EA7);
const _corGlass = Color(0x14FFFFFF);
const _corBorda = Color(0x30FFFFFF);
const _bgEscuro = Color(0xFF06040F);

class BodyIconesJogosModerno extends StatefulWidget {
  final PrincipalCtrl ctrl;
  final double tamanhoBloco;
  //   final Widget Function(PrincipalCtrl ctrl, int index, double tamanho)
  //       cardAnimado;
  // final Widget Function(PrincipalCtrl ctrl, int index) cardAnimadoAdd;

  const BodyIconesJogosModerno({
    super.key,
    required this.ctrl,
    required this.tamanhoBloco,
  });

  @override
  State<BodyIconesJogosModerno> createState() =>
      _BodyIconesJogosModernoState();
}

class _BodyIconesJogosModernoState extends State<BodyIconesJogosModerno> {
  String _lastGame = '';
  String _lastGameHero = '';
  final _newsScroll = ScrollController();

  // ── Hero background video ───────────────────────────────────────────────────
  late final Player _heroPlayer;
  late final mkv.VideoController _heroController;
  bool _heroVideoAtivo = false;

  PrincipalCtrl get ctrl => widget.ctrl;

  @override
  void initState() {
    super.initState();
    _heroPlayer = Player();
    _heroController = mkv.VideoController(_heroPlayer);
    ctrl.abrirNoticiaCallback = (n) => _abrirNoticia(n);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadNoticias();
      // Inicia o video hero imediatamente ao montar o widget
      final nome = _nomeAtual;
      if (nome.isNotEmpty) {
        _lastGameHero = nome;
        _reiniciarHeroVideo(nome);
      }
    });
  }

  @override
  void didUpdateWidget(BodyIconesJogosModerno old) {
    super.didUpdateWidget(old);
    _loadNoticias();
    // Inicia o video hero sempre que o game atual mudar (não só ao focar no card)
    final nome = _nomeAtual;
    if (nome != _lastGameHero && nome.isNotEmpty) {
      _lastGameHero = nome;
      _reiniciarHeroVideo(nome);
    }
    // Para o video quando sai do modo moderno
    if (ctrl.focusScope != ctrl.focusScopeCardInf && _heroVideoAtivo && ctrl.focusScope == ctrl.focusScopeNoticias) {
      // mantém tocando — pausa só se o widget for descartado
    }
  }

  Future<void> _reiniciarHeroVideo(String nomeGame) async {
    await _pararHeroVideoAsync();
    // Busca vídeo diretamente com tag aleatória — não depende de videosYT já carregado
    try {
      final tags = ctrl.tagVideo;
      final tag = tags[Random().nextInt(tags.length)];
      final query = '$nomeGame $tag';
      final yt = YoutubeExplode();
      final results = await yt.search.search(query);
      if (results.isEmpty) { yt.close(); return; }
      final video = results[Random().nextInt(results.length.clamp(1, 5))];
      final manifest = await yt.videos.streamsClient.getManifest(video.id);
      final stream = manifest.muxed.bestQuality;
      await _heroPlayer.open(Media(stream.url.toString()));
      _heroPlayer.setVolume(0);
      yt.close();
      if (mounted) setState(() { _heroVideoAtivo = true; });
    } catch (e) {
      debugPrint('ERRO reiniciarHeroVideo: $e');
    }
  }

  Future<void> _pararHeroVideoAsync() async {
    try { await _heroPlayer.stop(); } catch (_) {}
    if (mounted) setState(() => _heroVideoAtivo = false);
  }

  String get _nomeAtual => ctrl.listIconsInicial.isEmpty
      ? ''
      : ctrl.listIconsInicial[ctrl.selectedIndexIcone].nome;

  Future<void> _loadNoticias() async {
    final nome = _nomeAtual;
    if (nome == _lastGame || nome.isEmpty) return;
    _lastGame = nome;

    if (mounted) setState(() { ctrl.loadingNoticias = true; });

    try {
      final result = await WebScrap.buscaNoticiasGame(nome)
          .timeout(const Duration(seconds: 15), onTimeout: () => []);

      for (final f in ctrl.focusNodeNoticias) {
        try { f.dispose(); } catch (_) {}
      }
      ctrl.focusNodeNoticias = List.generate(result.length, (_) => FocusNode());

      if (mounted) {
        setState(() {
          ctrl.noticias = result;
          ctrl.loadingNoticias = false;
          ctrl.selectedIndexNoticia = 0;
        });
      }
    } catch (e) {
      debugPrint('_loadNoticias erro: $e');
      if (mounted) setState(() { ctrl.loadingNoticias = false; });
    }
  }

  @override
  void dispose() {
    ctrl.abrirNoticiaCallback = null;
    _newsScroll.dispose();
    try { _heroPlayer.dispose(); } catch (_) {}
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Container(
      color: _bgEscuro,
      child: Column(
        children: [
          _buildTop(size),
          _buildMid(size),
          Expanded(child: _buildBottom(size)),
        ],
      ),
    );
  }

  // ════════════════════════════════════════════════════════════════════════════
  // SEÇÃO 1 — HERO / TOPO
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildTop(Size size) {
    final item = ctrl.listIconsInicial.isEmpty ? null : ctrl.listIconsInicial[ctrl.selectedIndexIcone];
    final h = size.height * 0.50;

    return SizedBox(
      width: size.width,
      height: h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          _heroBg(item),
          _gradientOverlay(),
          // Label "Jogos" acima da strip
          Positioned(
            bottom: 90,
            left: 0,
            child: _secaoLabel('Jogos', _corP,
                emFoco: ctrl.focusScope == ctrl.focusScopeIcones),
          ),
          // Strip de miniaturas na base — ocupa só a esquerda
          _jogosStrip(size),
          // Card glass no canto INFERIOR DIREITO — proporcional
          Positioned(
            right: 32,
            bottom: 70,
            child: _glassInfoCard(item, size),
          ),
        ],
      ),
    );
  }

  Widget _heroBg(item) {
    final imgPath = item?.imgStr ?? '';
    if (imgPath.isNotEmpty && File(imgPath).existsSync()) {
      return AnimatedSwitcher(
        duration: const Duration(milliseconds: 600),
        child: Image.file(
          File(imgPath),
          key: ValueKey(imgPath),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
        ),
      );
    }
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1A0A3B), Color(0xFF0D1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
    );
  }

  Widget _gradientOverlay() => Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.black.withValues(alpha: 0.08),
              Colors.black.withValues(alpha: 0.88),
            ],
          ),
        ),
      );

  //identificar click para baixo para mudar o foco de jogos noticas e videos
  indentificarFocoJogosNoticiasVideos() {
    // Verificar se a tecla pressionada é a seta para baixo
    // Se for, mudar o foco para a próxima seção (jogos -> notícias -> vídeos)
    // Isso pode ser feito usando um FocusScope para cada seção e chamando requestFocus no próximo FocusNode
    // ctrl.clicouParaBaixo();
  }

  // Strip horizontal de miniaturas — apenas lado ESQUERDO, sem cobrir o card
  Widget _jogosStrip(Size size) => Positioned(
        bottom: 0,
        left: 0,
        // reserva espaço do card (≈380px) + margem
        right: 420,
        child: SizedBox(
          height: 82,
          child: FocusScope(
            node: ctrl.focusScopeIcones,
            child: ListView.builder(
              controller: ctrl.scrolListIcones,
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.only(left: 20),
              itemCount: ctrl.listIconsInicial.length,
              itemBuilder: (_, i) {
                final item = ctrl.listIconsInicial[i];
                final foco = ctrl.selectedIndexIcone == i;
                return Focus(
                  focusNode: ctrl.focusNodeIcones.length > i
                      ? ctrl.focusNodeIcones[i]
                      : FocusNode(),
                  onFocusChange: (h) {
                    if (h) ctrl.focusScope = ctrl.focusScopeIcones;
                    ctrl.onFocusChangeIcones(h, i, tamanho: 90);
                  },
                  child: GestureDetector(
                    onTap: () => ctrl.focusNodeIcones[i].requestFocus(),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      margin: const EdgeInsets.only(right: 10, bottom: 6, top: 6),
                      width: foco ? 130 : 84,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: foco ? _corP : Colors.white24,
                          width: foco ? 2.5 : 1,
                        ),
                        boxShadow: foco
                            ? [
                                BoxShadow(
                                    color: _corP.withValues(alpha: 0.6),
                                    blurRadius: 16)
                              ]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: item.imgStr.isNotEmpty &&
                                File(item.imgStr).existsSync()
                            ? Image.file(File(item.imgStr), fit: BoxFit.cover)
                            : Container(color: Colors.white10),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      );

  Widget _glassInfoCard(item, Size size) {
    final nome = item?.nome ?? 'Selecione um jogo';
    final emFocoCard = ctrl.focusScope == ctrl.focusScopeCardInf;
    final cardW = (size.width * 0.22).clamp(260.0, 360.0);
    final videoH = cardW * 9.0 / 16.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            width: cardW,
            decoration: BoxDecoration(
              color: emFocoCard ? _corP.withValues(alpha: 0.22) : _corGlass,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: emFocoCard ? _corP : _corBorda,
                width: emFocoCard ? 2 : 1.5,
              ),
              boxShadow: [
                BoxShadow(
                    color: _corP.withValues(alpha: emFocoCard ? 0.55 : 0.25),
                    blurRadius: 50,
                    spreadRadius: emFocoCard ? 6 : 2),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── Video 16:9 no topo — largura total do card ──
                SizedBox(
                  width: cardW,
                  height: videoH,
                  child: _heroVideoAtivo
                      ? mkv.Video(
                          controller: _heroController,
                          controls: mkv.NoVideoControls,
                        )
                      : Container(
                          color: const Color(0xFF0A081A),
                          child: const Center(
                            child: Icon(
                              Icons.videogame_asset_rounded,
                              color: Colors.white12,
                              size: 38,
                            ),
                          ),
                        ),
                ),
                // ── Título e botões ──
                Padding(
                  padding: const EdgeInsets.fromLTRB(22, 16, 22, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        nome,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.4,
                          shadows: [Shadow(color: Colors.black54, blurRadius: 8)],
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: cardW - 44,
                        child: FocusScope(
                          node: ctrl.focusScopeCardInf,
                          child: Row(
                            children: [
                              Expanded(
                                child: _btnAcao(
                                  foco: ctrl.selectedIndexCardInfo == 0 && emFocoCard,
                                  fn: ctrl.focusNodeCardInf[0],
                                  label: 'JOGAR',
                                  icone: Icons.play_arrow_rounded,
                                  cor: _corP,
                                  onFocus: (h) {
                                    if (h) ctrl.focusScope = ctrl.focusScopeCardInf;
                                    ctrl.onFocusChangeCardInf(h, 0);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _btnAcao(
                                  foco: ctrl.selectedIndexCardInfo == 1 && emFocoCard,
                                  fn: ctrl.focusNodeCardInf[1],
                                  label: 'MAIS INFO',
                                  icone: Icons.info_outline_rounded,
                                  cor: Colors.white24,
                                  onFocus: (h) {
                                    if (h) ctrl.focusScope = ctrl.focusScopeCardInf;
                                    ctrl.onFocusChangeCardInf(h, 1);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _btnAcao({
    required bool foco,
    required FocusNode fn,
    required String label,
    required IconData icone,
    required Color cor,
    required void Function(bool) onFocus,
  }) =>
      Focus(
        focusNode: fn,
        onFocusChange: onFocus,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            color: foco ? cor : cor.withValues(alpha: 0.45),
            borderRadius: BorderRadius.circular(50),
            border: Border.all(
              color: foco ? Colors.white : Colors.white30,
              width: foco ? 1.8 : 1,
            ),
            boxShadow: foco
                ? [BoxShadow(color: cor.withValues(alpha: 0.7), blurRadius: 22, spreadRadius: 2)]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icone, color: Colors.white, size: 17),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 12),
                ),
              ),
            ],
          ),
        ),
      );

  // ════════════════════════════════════════════════════════════════════════════
  // SEÇÃO 2 — NOTÍCIAS
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildMid(Size size) => SizedBox(
        height: size.height * 0.28,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _secaoLabel('Notícias', _corP,
                carregando: ctrl.loadingNoticias,
                emFoco: ctrl.focusScope == ctrl.focusScopeNoticias),
            Expanded(
              child: Align(
                alignment: Alignment.topLeft,
                child: SizedBox(
                  height: (size.height * 0.21).clamp(140.0, 200.0),
                  child: ctrl.noticias.isEmpty && !ctrl.loadingNoticias
                      ? FocusScope(
                          node: ctrl.focusScopeNoticias,
                          child: ListView(
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 44),
                            children: [_cardNoticiaVazio()],
                          ),
                        )
                      : FocusScope(
                          node: ctrl.focusScopeNoticias,
                          child: ListView.builder(
                            controller: _newsScroll,
                            scrollDirection: Axis.horizontal,
                            padding: const EdgeInsets.symmetric(horizontal: 44),
                            itemCount: ctrl.noticias.length,
                            itemBuilder: (_, i) => _cardNoticia(i),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _cardNoticiaVazio() => Container(
        width: 230,
        margin: const EdgeInsets.only(right: 14, bottom: 8, top: 4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white10),
        ),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.newspaper_rounded, color: Colors.white12, size: 32),
              SizedBox(height: 8),
              Text('Sem notícias',
                  style: TextStyle(color: Colors.white24, fontSize: 12)),
            ],
          ),
        ),
      );

  Widget _cardNoticia(int i) {
    final n = ctrl.noticias[i];
    final foco = ctrl.selectedIndexNoticia == i;
    final temImg = n.imgUrl.startsWith('http');
    final emoji = !temImg && n.imgUrl.isNotEmpty ? n.imgUrl : null;

    return Focus(
      focusNode: ctrl.focusNodeNoticias.length > i ? ctrl.focusNodeNoticias[i] : FocusNode(),
      onFocusChange: (has) {
        if (!has) return;
        ctrl.focusScope = ctrl.focusScopeNoticias;
        ctrl.selectedIndexNoticia = i;
        ctrl.attTela();
        try {
          _newsScroll.animateTo(i * 254.0,
              duration: const Duration(milliseconds: 400),
              curve: Curves.decelerate);
        } catch (_) {}
      },
      child: GestureDetector(
        onTap: () => _abrirNoticia(n),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: foco ? 250 : 230,
          margin: const EdgeInsets.only(right: 14, bottom: 8, top: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: foco ? _corP : Colors.white12,
              width: foco ? 2 : 1,
            ),
            boxShadow: foco
                ? [
                    BoxShadow(color: _corP.withValues(alpha: 0.5), blurRadius: 28, spreadRadius: 2),
                  ]
                : [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8)],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(17),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Fundo: imagem HTTP, emoji grande ou escuro sólido
                if (temImg)
                  Image.network(
                    n.imgUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(color: const Color(0xFF0E0B24)),
                  )
                else if (emoji != null)
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          _corP.withValues(alpha: 0.30),
                          const Color(0xFF06040F),
                        ],
                      ),
                    ),
                    child: Align(
                      alignment: Alignment.topCenter,
                      child: Text(
                        emoji,
                        style: const TextStyle(fontSize: 60),
                      ),
                    ),
                  )
                else
                  Container(color: const Color(0xFF0E0B24)),
                // Gradiente escuro sobre a imagem para legibilidade
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: temImg
                          ? [
                              Colors.black.withValues(alpha: 0.05),
                              Colors.black.withValues(alpha: 0.72),
                              Colors.black.withValues(alpha: 0.92),
                            ]
                          : [Colors.transparent, Colors.transparent],
                      stops: temImg ? const [0.0, 0.45, 1.0] : const [0.0, 1.0],
                    ),
                  ),
                ),
                // Conteúdo textual na parte inferior
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 14,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (n.veiculo.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(bottom: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                          decoration: BoxDecoration(
                            color: foco ? _corP.withValues(alpha: 0.8) : Colors.black38,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            n.veiculo.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                      Text(
                        n.titulo,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: foco ? 13 : 12,
                          fontWeight: FontWeight.w700,
                          height: 1.3,
                          shadows: const [Shadow(color: Colors.black, blurRadius: 8)],
                        ),
                      ),
                      if (!temImg && n.descricao.isNotEmpty) ...[
                        const SizedBox(height: 5),
                        Text(
                          n.descricao,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white54, fontSize: 10, height: 1.4),
                        ),
                      ],
                    ],
                  ),
                ),
                // Ícone "ler mais" no canto superior direito quando focado
                if (foco)
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: _corP.withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        boxShadow: const [BoxShadow(color: _corP, blurRadius: 12)],
                      ),
                      child: const Icon(Icons.open_in_new_rounded, color: Colors.white, size: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _abrirNoticia(NoticiaGame n) => showDialog(
        context: context,
        barrierColor: Colors.black87,
        builder: (_) => _PopupNoticia(noticia: n, ctrl: ctrl),
      );

  // ════════════════════════════════════════════════════════════════════════════
  // SEÇÃO 3 — VÍDEOS
  // ════════════════════════════════════════════════════════════════════════════
  Widget _buildBottom(Size size) {
    // if (!ctrl.exibirVideos) return const SizedBox.shrink();
    final videos = ctrl.videosYT;
    return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _secaoLabel('Vídeos', _corA,
              emFoco: ctrl.focusScope == ctrl.focusScopeVideos),
          Expanded(
            child: FocusScope(
              node: ctrl.focusScopeVideos,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 44),
                itemCount: videos.length,
                itemBuilder: (_, i) {
                  final v = videos[i];
                  final foco = ctrl.selectedIndexVideo == i;
                  return Focus(
                    focusNode: ctrl.focusNodeVideos.length > i
                        ? ctrl.focusNodeVideos[i]
                        : FocusNode(),
                    onFocusChange: (h) {
                        if (!h) return;
                        ctrl.selectedIndexVideo = i;
                        ctrl.focusScope = ctrl.focusScopeVideos;
                        ctrl.attTela();
                      },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 160),
                      width: foco ? 260 : 190,
                      margin: const EdgeInsets.only(right: 14, bottom: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: foco ? _corA : Colors.transparent,
                          width: 2,
                        ),
                        boxShadow: foco
                            ? [BoxShadow(
                                color: _corA.withValues(alpha: 0.55),
                                blurRadius: 24)]
                            : null,
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(13),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(v.capaM,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    Container(color: Colors.white10)),
                            if (foco)
                              Container(color: Colors.black45),
                            // Ícone de play centralizado
                            Center(
                              child: AnimatedOpacity(
                                opacity: foco ? 1.0 : 0.0,
                                duration: const Duration(milliseconds: 160),
                                child: Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _corA.withValues(alpha: 0.9),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: _corA, blurRadius: 24)
                                    ],
                                  ),
                                  child: const Icon(
                                      Icons.play_arrow_rounded,
                                      color: Colors.white,
                                      size: 30),
                                ),
                              ),
                            ),
                            // Gradiente + título
                            Align(
                              alignment: Alignment.bottomLeft,
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(9),
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.bottomCenter,
                                    end: Alignment.topCenter,
                                    colors: [Colors.black87, Colors.transparent],
                                  ),
                                ),
                                child: Text(
                                  v.titulo,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500),
                                ),
                              ),
                            ),
                            // Badge canal
                            Positioned(
                              top: 7,
                              right: 7,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 7, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.black54,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  v.canal,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  Widget _secaoLabel(String titulo, Color cor,
      {bool carregando = false, bool emFoco = false}) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: EdgeInsets.fromLTRB(44, emFoco ? 10 : 14, 44, emFoco ? 6 : 10),
      padding: emFoco
          ? const EdgeInsets.symmetric(horizontal: 14, vertical: 7)
          : EdgeInsets.zero,
      decoration: emFoco
          ? BoxDecoration(
              color: cor.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: cor.withValues(alpha: 0.7), width: 1.5),
              boxShadow: [
                BoxShadow(
                    color: cor.withValues(alpha: 0.45),
                    blurRadius: 18,
                    spreadRadius: 1),
              ],
            )
          : null,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: emFoco ? 6 : 4,
            height: emFoco ? 22 : 18,
            decoration: BoxDecoration(
              color: cor,
              borderRadius: BorderRadius.circular(3),
              boxShadow: [
                BoxShadow(
                    color: cor.withValues(alpha: emFoco ? 1.0 : 0.6),
                    blurRadius: emFoco ? 16 : 8),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            titulo,
            style: TextStyle(
              color: emFoco ? Colors.white : Colors.white70,
              fontSize: emFoco ? 17 : 15,
              fontWeight: emFoco ? FontWeight.w800 : FontWeight.w600,
              letterSpacing: emFoco ? 1.4 : 0.8,
            ),
          ),
          if (emFoco) ...[
            const SizedBox(width: 8),
            Icon(Icons.keyboard_arrow_right_rounded, color: cor, size: 18),
          ],
          if (carregando) ...[
            const SizedBox(width: 12),
            SizedBox(
              width: 13,
              height: 13,
              child: CircularProgressIndicator(strokeWidth: 2, color: cor),
            ),
          ],
        ],
      ),
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// POPUP DE NOTÍCIA — glass style com foco e atalhos de gamepad/teclado
// ══════════════════════════════════════════════════════════════════════════════
class _PopupNoticia extends StatefulWidget {
  final NoticiaGame noticia;
  final PrincipalCtrl ctrl;
  const _PopupNoticia({required this.noticia, required this.ctrl});

  @override
  State<_PopupNoticia> createState() => _PopupNoticiaState();
}

class _PopupNoticiaState extends State<_PopupNoticia> {
  final FocusNode _focusNode = FocusNode();
  String? _imgBuscada;      // imagem buscada via Bing ao abrir
  bool _loadingImg = true;

  @override
  void initState() {
    super.initState();
    widget.ctrl.noticiaPopupAberta = widget.noticia;
    widget.ctrl.fecharNoticiaPopup = _fechar;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();
      _buscarImagem();
    });
  }

  Future<void> _buscarImagem() async {
    // Usa imagem já disponível se for HTTP
    if (widget.noticia.imgUrl.startsWith('http')) {
      if (mounted) setState(() { _imgBuscada = widget.noticia.imgUrl; _loadingImg = false; });
      return;
    }
    // Busca via Bing com o título da notícia
    final url = await WebScrap.buscaImagemGoogle(widget.noticia.titulo);
    if (mounted) setState(() { _imgBuscada = url.isNotEmpty ? url : null; _loadingImg = false; });
  }

  @override
  void dispose() {
    // Limpa registro ao fechar
    widget.ctrl.noticiaPopupAberta = null;
    widget.ctrl.fecharNoticiaPopup = null;
    _focusNode.dispose();
    super.dispose();
  }

  void _acessar() {
    if (widget.noticia.url.isNotEmpty) {
      Navigator.of(context).pop();
      // Usa o mesmo fluxo de filmes/músicas: libera mouse + loading
      widget.ctrl.sairDaTelaMedia(widget.noticia.url, 'Lendo notícia.');
    }
  }

  void _fechar() => Navigator.of(context).pop();

  KeyEventResult _onKey(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent && event is! KeyRepeatEvent) return KeyEventResult.ignored;
    final key = event.logicalKey;
    // A / Enter / Space → acessar
    if (key == LogicalKeyboardKey.enter ||
        key == LogicalKeyboardKey.space ||
        key == LogicalKeyboardKey.gameButtonA) {
      _acessar();
      return KeyEventResult.handled;
    }
    // B / Escape → fechar
    if (key == LogicalKeyboardKey.escape ||
        key == LogicalKeyboardKey.backspace ||
        key == LogicalKeyboardKey.gameButtonB) {
      _fechar();
      return KeyEventResult.handled;
    }
    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) => Focus(
        focusNode: _focusNode,
        onKeyEvent: _onKey,
        child: Dialog(
          backgroundColor: Colors.transparent,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
              child: Container(
                width: 620,
                constraints: const BoxConstraints(maxHeight: 560),
                decoration: BoxDecoration(
                  color: const Color(0xD00C0920),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: _corBorda, width: 1.5),
                  boxShadow: [
                    BoxShadow(
                        color: _corP.withValues(alpha: 0.45),
                        blurRadius: 70,
                        spreadRadius: 8),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _imgCapaOuLoader(),
                    Flexible(child: _corpo()),
                    _rodape(),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _imgCapaOuLoader() {
    if (_loadingImg) {
      return const SizedBox(
        height: 190,
        width: double.infinity,
        child: Center(
          child: SizedBox(
            width: 28,
            height: 28,
            child: CircularProgressIndicator(strokeWidth: 2, color: _corP),
          ),
        ),
      );
    }
    if (_imgBuscada == null) {
      // Sem imagem: mostra emoji centralizado na área da capa
      final emoji = widget.noticia.imgUrl.isNotEmpty &&
              !widget.noticia.imgUrl.startsWith('http')
          ? widget.noticia.imgUrl
          : '🎮';
      return SizedBox(
        height: 190,
        width: double.infinity,
        child: Center(
          child: Text(emoji, style: const TextStyle(fontSize: 80)),
        ),
      );
    }
    return _imgCapa(_imgBuscada!);
  }

  Widget _imgCapa(String url) => ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: SizedBox(
          height: 190,
          width: double.infinity,
          child: Image.network(
            url,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      );

  Widget _corpo() => SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(30, 26, 30, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.noticia.veiculo.isNotEmpty)
              Text(
                widget.noticia.veiculo.toUpperCase(),
                style: const TextStyle(
                    color: _corA,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 2.5),
              ),
            const SizedBox(height: 10),
            Text(
              widget.noticia.titulo,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  height: 1.35),
            ),
            if (widget.noticia.dataStr.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(widget.noticia.dataStr,
                    style:
                        const TextStyle(color: Colors.white30, fontSize: 11)),
              ),
            const SizedBox(height: 16),
            if (widget.noticia.descricao.isNotEmpty)
              Text(
                widget.noticia.descricao,
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14, height: 1.65),
              ),
          ],
        ),
      );

  Widget _rodape() => Padding(
        padding: const EdgeInsets.fromLTRB(26, 8, 26, 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            // Dica de controles
            const Expanded(
              child: Text(
                'A = Acessar   B = Fechar',
                style: TextStyle(color: Colors.white24, fontSize: 11),
              ),
            ),
            // Botão Fechar
            TextButton(
              onPressed: _fechar,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white60,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
                side: const BorderSide(color: Colors.white12),
              ),
              child: const Text('Fechar'),
            ),
            const SizedBox(width: 10),
            // Botão Acessar
            TextButton(
              onPressed: widget.noticia.url.isNotEmpty ? _acessar : null,
              style: TextButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _corP.withValues(alpha: 0.7),
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(50)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.open_in_new_rounded, size: 14),
                  SizedBox(width: 6),
                  Text('Acessar'),
                ],
              ),
            ),
          ],
        ),
      );
}
