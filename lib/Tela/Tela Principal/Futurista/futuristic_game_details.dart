import 'dart:ui' as ui;
import '../../../Class/game_video_tags.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../Interface/futuristic_action_tile.dart';
import '../../../Interface/futuristic_content_skeleton.dart';
import '../../../Interface/futuristic_topic_label.dart';
import '../../../Interface/futuristic_card_effect.dart';
import '../../../Interface/futuristic_window_controls.dart';
import '../../../Interface/launcher_menu.dart';
import '../../../Interface/futuristic_artwork.dart';
import '../../../Interface/futuristic_game_feed.dart';
import '../../../Interface/futuristic_material.dart';
import '../../../Interface/futuristic_particles.dart';
import '../../../Interface/noticia_game_artwork.dart';
import '../../../Interface/launcher_pad_scope.dart';
import '../../../Interface/pad_scroll_target.dart';
import '../../../Modelos/NoticiaGame.dart';
import '../../../Modelos/videoYT.dart';
import '../../Tela loja/componentes/trailer_player.dart';
import '../../Tela loja/scraps/jogo_detalhes.dart';

class FuturisticGameDetails extends StatefulWidget {
  const FuturisticGameDetails(
      {super.key,
      required this.name,
      required this.image,
      this.loadContent,
      this.videoTags = GameVideoTags.values,
      this.trailerBuilder});
  final Widget Function(TrailerJogo)? trailerBuilder;
  final String name, image;
  final Future<FuturisticGameContent> Function(String)? loadContent;
  final List<String> videoTags;
  @override
  State<FuturisticGameDetails> createState() => _FuturisticGameDetailsState();
}

class _FuturisticGameDetailsState extends State<FuturisticGameDetails> {
  final _play = FocusNode(),
      _videosHeading = FocusNode(),
      _newsHeading = FocusNode(),
      _viewer = FocusNode(),
      _retry = FocusNode();
  final _scroll = ScrollController();
  final _position = ValueNotifier<double>(0);
  var _player = GlobalKey<TrailerPlayerState>();
  List<FocusNode> _videoNodes = [], _newsNodes = [];
  FuturisticGameContent _content = const FuturisticGameContent();
  bool _loading = true, _busy = false;
  bool _loadStarted = false, _leaving = false;
  Animation<double>? _routeAnimation;
  int _selectedVideo = 0, _playShineRevision = 0;
  VideoYT? _playing;
  @override
  void initState() {
    super.initState();
    _play.addListener(_playFocusChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _play.requestFocus();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final animation = ModalRoute.of(context)?.animation;
    if (animation != _routeAnimation) {
      _routeAnimation?.removeStatusListener(_routeStatusChanged);
      _routeAnimation = animation;
      animation?.addStatusListener(_routeStatusChanged);
    }
    if (animation == null || animation.status == AnimationStatus.completed) {
      _startContentLoad();
    }
  }

  void _routeStatusChanged(AnimationStatus status) {
    if (status == AnimationStatus.reverse) _leaving = true;
    if (status == AnimationStatus.completed) _startContentLoad();
  }

  void _startContentLoad() {
    if (_loadStarted || _busy || _leaving) return;
    // Render the entrance first; a quick Play must not start a content search.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // ModalRoute temporarily exposes a completed animation while measuring
      // its offstage page. Recheck after that first frame before starting work.
      if (!mounted || _loadStarted || _busy || _leaving) return;
      if (_routeAnimation != null &&
          _routeAnimation!.status != AnimationStatus.completed) {
        return;
      }
      _loadStarted = true;
      _load();
    });
  }

  void _playFocusChanged() {
    if (!mounted) return;
    setState(() {
      if (_play.hasFocus) {
        _playShineRevision++;
      }
    });
  }

  Future<void> _load() async {
    if (!mounted || _busy || _leaving) return;
    try {
      final content = await (widget.loadContent?.call(widget.name) ??
          FuturisticGameFeed.load(widget.name, tags: widget.videoTags));
      if (!mounted || _busy || _leaving) return;
      final oldNodes = [..._videoNodes, ..._newsNodes];
      setState(() {
        _content = content;
        _selectedVideo = 0;
        _playing = null;
        _player = GlobalKey<TrailerPlayerState>();
        _videoNodes = List.generate(content.videos.length, (_) => FocusNode());
        _newsNodes = List.generate(content.news.length, (_) => FocusNode());
        _loading = false;
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        for (final node in oldNodes) {
          node.dispose();
        }
      });
    } catch (_) {
      if (mounted && !_busy && !_leaving) {
        setState(() => _loading = false);
      }
    }
  }

  void _retryLoad() {
    if (_loading || _busy || _leaving) return;
    FuturisticGameFeed.invalidate(widget.name);
    _play.requestFocus();
    setState(() => _loading = true);
    _load();
  }

  void _launch() {
    if (_busy) return;
    setState(() => _busy = true);
    _player.currentState?.command('START');
    Navigator.of(context).pop(true);
  }

  void _activateVideo(int index) {
    if (_busy || index >= _content.videos.length) return;
    if (_playing == _content.videos[index]) {
      _player.currentState?.togglePlayback();
    } else {
      setState(() {
        _selectedVideo = index;
        _playing = _content.videos[index];
        _player = GlobalKey<TrailerPlayerState>();
      });
    }
    _viewer.requestFocus();
  }

  bool _command(String command) {
    if (_busy) return true;
    if (command == 'START') _player.currentState?.command(command);
    if (command == 'R3' &&
        _viewer.hasFocus &&
        _playing == null &&
        _content.videos.isNotEmpty) {
      _activateVideo(_selectedVideo);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _player.currentState?.command('R3');
      });
      return true;
    }
    if (_viewer.hasFocus && _playing != null) {
      if (command == '2') {
        _player.currentState?.togglePlayback();
        return true;
      }
      if (_player.currentState?.command(command) ?? false) return true;
    }
    if (['CIMA', 'BAIXO', 'ESQUERDA', 'DIREITA'].contains(command)) {
      return _move(command);
    }
    return false;
  }

  bool _move(String direction) {
    final video = _videoNodes.indexWhere((node) => node.hasFocus);
    final news = _newsNodes.indexWhere((node) => node.hasFocus);
    FocusNode? target;
    if (_play.hasFocus) {
      target = switch (direction) {
        'BAIXO' => _videosHeading,
        'DIREITA' => _viewer,
        _ => null,
      };
    } else if (_viewer.hasFocus) {
      target = switch (direction) {
        'BAIXO' => _newsHeading,
        'ESQUERDA' => _play,
        _ => null,
      };
    } else if (_videosHeading.hasFocus) {
      target = switch (direction) {
        'CIMA' => _play,
        'DIREITA' => _newsHeading,
        'BAIXO' => _loading ? null : _videoNodes.firstOrNull,
        _ => null,
      };
    } else if (_newsHeading.hasFocus) {
      target = switch (direction) {
        'CIMA' => _viewer,
        'ESQUERDA' => _videosHeading,
        'BAIXO' => _loading ? null : _newsNodes.firstOrNull,
        _ => null,
      };
    } else if (video >= 0) {
      target = switch (direction) {
        'CIMA' => _videosHeading,
        'ESQUERDA' => _videoNodes[(video - 1).clamp(0, _videoNodes.length - 1)],
        'DIREITA' => video == _videoNodes.length - 1
            ? _newsHeading
            : _videoNodes[video + 1],
        _ => null,
      };
    } else if (news >= 0) {
      target = switch (direction) {
        'CIMA' => news == 0 ? _newsHeading : _newsNodes[news - 1],
        'BAIXO' => _newsNodes[(news + 1).clamp(0, _newsNodes.length - 1)],
        'ESQUERDA' => _videosHeading,
        _ => null,
      };
    } else if (_retry.hasFocus) {
      target = direction == 'CIMA' ? _newsHeading : _play;
    }
    target?.requestFocus();
    return true;
  }

  Future<void> _news(NoticiaGame news) async {
    _player.currentState?.command('START');
    await showDialog<void>(
        context: context, builder: (_) => _NewsDialog(news: news));
  }

  @override
  void dispose() {
    _routeAnimation?.removeStatusListener(_routeStatusChanged);
    _play.removeListener(_playFocusChanged);
    for (final node in [
      _play,
      _videosHeading,
      _newsHeading,
      _viewer,
      _retry,
      ..._videoNodes,
      ..._newsNodes
    ]) {
      node.dispose();
    }
    _scroll.dispose();
    _position.dispose();
    super.dispose();
  }

  Text _label(String text) => Text(text,
      style: const TextStyle(
          color: FuturisticPalette.water,
          fontFamily: 'Oxanium',
          letterSpacing: 3,
          fontSize: 13));
  Widget _topic(String text, FocusNode node, FocusNode? first, String key) =>
      FuturisticTopicLabel(
          key: ValueKey(key),
          text: text,
          node: node,
          onActivate: () => first?.requestFocus());

  Widget _playingVideo() {
    final trailer =
        TrailerJogo(titulo: _playing!.titulo, youtubeId: _playing!.videoID);
    return widget.trailerBuilder?.call(trailer) ??
        TrailerPlayer(key: _player, trailer: trailer, inline: true);
  }

  Widget _videoStation() => PadScrollTarget(
      scrollToStart: true,
      child: GlassPanel(
          radius: 28,
          child: Padding(
              padding: const EdgeInsets.all(6),
              child: FuturisticActionTile(
                  node: _viewer,
                  onActivate: () {
                    if (_content.videos.isNotEmpty) {
                      _activateVideo(_selectedVideo);
                    }
                  },
                  child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: AspectRatio(
                          aspectRatio: 16 / 9,
                          child: _loading
                              ? const FuturisticContentSkeleton(
                                  section: FuturisticSkeletonSection.viewer)
                              : _playing != null
                                  ? _playingVideo()
                                  : Stack(fit: StackFit.expand, children: [
                                      FuturisticArtwork(
                                          image: _content.videos.isEmpty
                                              ? widget.image
                                              : _content.videos[_selectedVideo]
                                                  .capaG),
                                      const ColoredBox(
                                          color: Color(0x35000000)),
                                      if (_content.videos.isNotEmpty)
                                        const Center(
                                            child: Icon(
                                                Icons.play_circle_fill_rounded,
                                                color: Colors.white,
                                                size: 70)),
                                    ])))))));
  Widget _hero(bool narrow) {
    final title =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _label('SUA PRÓXIMA SESSÃO'),
      const SizedBox(height: 18),
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        SizedBox(
            key: const ValueKey('futuristic-game-cover'),
            width: narrow ? 104 : 124,
            height: narrow ? 104 : 124,
            child: GlassPanel(
                radius: 22,
                child: Padding(
                    padding: const EdgeInsets.all(6),
                    child: ClipRRect(
                        borderRadius: BorderRadius.circular(17),
                        child: FuturisticArtwork(image: widget.image))))),
        const SizedBox(width: 20),
        Expanded(
            child: Text(widget.name,
                style: TextStyle(
                    color: Colors.white,
                    fontFamily: 'Oxanium',
                    fontSize: narrow ? 30 : 38,
                    height: 1.15,
                    fontWeight: FontWeight.w600))),
      ]),
      const SizedBox(height: 14),
      const Text('Seu jogo. Um novo universo.',
          style: TextStyle(color: Colors.white70, fontSize: 16)),
      const SizedBox(height: 28),
      SizedBox(
          width: 360,
          child: FuturisticCardEffect(
              selected: true,
              focused: _play.hasFocus,
              settledRevision: _playShineRevision,
              child: FuturisticActionTile(
                  key: const ValueKey('futuristic-play'),
                  node: _play,
                  prominent: true,
                  onActivate: _launch,
                  child: const Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 26, vertical: 24),
                      child: Row(children: [
                        Icon(Icons.play_arrow_rounded,
                            color: Colors.white, size: 38),
                        SizedBox(width: 16),
                        Text('Jogar',
                            style: TextStyle(
                                fontFamily: 'Oxanium',
                                color: Colors.white,
                                fontSize: 28)),
                        Spacer(),
                        Icon(Icons.arrow_forward_rounded,
                            color: FuturisticPalette.water)
                      ]))))),
    ]);
    return narrow
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [title, const SizedBox(height: 28), _videoStation()])
        : Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
            Expanded(flex: 5, child: title),
            const SizedBox(width: 40),
            Expanded(flex: 6, child: _videoStation())
          ]);
  }

  Widget _videos() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _topic(
            'VÍDEOS',
            _videosHeading,
            _loading ? null : _videoNodes.firstOrNull,
            'futuristic-videos-heading'),
        const SizedBox(height: 18),
        if (_loading)
          const FuturisticContentSkeleton(
              section: FuturisticSkeletonSection.videos)
        else if (_content.videos.isEmpty)
          const Text('Nenhum vídeo disponível agora.',
              style: TextStyle(color: Colors.white60))
        else
          SizedBox(
              height: 180,
              child: Stack(children: [
                Positioned.fill(
                    child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                            children:
                                List.generate(_content.videos.length, (index) {
                          final video = _content.videos[index];
                          return Padding(
                              padding: EdgeInsets.only(
                                  right: index == _content.videos.length - 1
                                      ? 0
                                      : 14),
                              child: SizedBox(
                                  width: 220,
                                  child: FuturisticActionTile(
                                      node: _videoNodes[index],
                                      onActivate: () => _activateVideo(index),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            ClipRRect(
                                                borderRadius: const BorderRadius
                                                    .vertical(
                                                    top: Radius.circular(23)),
                                                child: SizedBox(
                                                    height: 118,
                                                    width: double.infinity,
                                                    child: FuturisticArtwork(
                                                        image: video.capaM))),
                                            Expanded(
                                                child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            10),
                                                    child: Text(video.titulo,
                                                        maxLines: 2,
                                                        overflow: TextOverflow
                                                            .ellipsis,
                                                        style: const TextStyle(
                                                            color: Colors.white,
                                                            fontSize: 13,
                                                            height: 1.25)))),
                                          ]))));
                        })))),
                const Positioned(
                    key: ValueKey('futuristic-video-edge-glow'),
                    top: 0,
                    bottom: 0,
                    right: 0,
                    width: 64,
                    child: IgnorePointer(
                        child: DecoratedBox(
                            decoration: BoxDecoration(
                                gradient: LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        Colors.transparent,
                        Color(0x183FBDBB),
                        Color(0x387DE2D8)
                      ],
                    ))))),
              ])),
      ]);
  Widget _newsList() =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        _topic(
            'NOTÍCIAS',
            _newsHeading,
            _loading ? null : _newsNodes.firstOrNull,
            'futuristic-news-heading'),
        const SizedBox(height: 18),
        if (_loading)
          const FuturisticContentSkeleton(
              section: FuturisticSkeletonSection.news)
        else if (_content.news.isEmpty)
          const Text('Nenhuma notícia disponível agora.',
              style: TextStyle(color: Colors.white60)),
        for (var index = 0; !_loading && index < _content.news.length; index++)
          Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FuturisticActionTile(
                  node: _newsNodes[index],
                  onActivate: () => _news(_content.news[index]),
                  child: Padding(
                      padding: const EdgeInsets.all(18),
                      child: Row(children: [
                        _newsImage(_content.news[index], 124, 76),
                        const SizedBox(width: 16),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text(_content.news[index].titulo,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white, fontSize: 16)),
                              const SizedBox(height: 6),
                              Text(_content.news[index].veiculo,
                                  style: const TextStyle(
                                      color: FuturisticPalette.accent,
                                      fontSize: 12)),
                            ])),
                        const SizedBox(width: 12),
                        const Icon(Icons.arrow_outward_rounded,
                            color: Colors.white54, size: 18),
                      ])))),
      ]);

  Widget _newsImage(NoticiaGame news, double width, double height) =>
      SizedBox(
          width: width,
          height: height,
          child: NoticiaGameArtwork(
              news: news,
              accentColor: FuturisticPalette.water,
              placeholderIconSize: 28,
              borderRadius: BorderRadius.circular(12)));

  @override
  Widget build(BuildContext context) => LauncherPadScope(
      revealInitialFocus: false,
      onCommand: _command,
      child: Scaffold(
          backgroundColor: Colors.black,
          body: LayoutBuilder(builder: (_, constraints) {
            final narrow = constraints.maxWidth < 900;
            return GlassBackdrop(
                background: RepaintBoundary(
                    child: Stack(fit: StackFit.expand, children: [
                  ImageFiltered(
                      key: const ValueKey('futuristic-details-background-blur'),
                      imageFilter: ui.ImageFilter.blur(
                          sigmaX: 28, sigmaY: 28, tileMode: ui.TileMode.mirror),
                      child: FuturisticArtwork(image: widget.image)),
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
                child: Stack(children: [
                  Positioned.fill(
                      child: FuturisticParticles(position: _position)),
                  SafeArea(
                      child: AnimatedScale(
                          scale: _busy ? .96 : 1,
                          duration: const Duration(milliseconds: 450),
                          curve: Curves.easeInOutCubic,
                          child: AnimatedSlide(
                              offset:
                                  _busy ? const Offset(0, .04) : Offset.zero,
                              duration: const Duration(milliseconds: 450),
                              curve: Curves.easeInOutCubic,
                              child: Padding(
                                  padding: const EdgeInsets.only(top: 88),
                                  child: SingleChildScrollView(
                                      controller: _scroll,
                                      padding: EdgeInsets.all(narrow ? 24 : 48),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            PadScrollTarget(
                                                scrollToStart: true,
                                                child: _hero(narrow)),
                                            const SizedBox(height: 44),
                                            if (_loading)
                                              const LinearProgressIndicator(
                                                  color:
                                                      FuturisticPalette.water,
                                                  backgroundColor:
                                                      Colors.white12),
                                            const SizedBox(height: 18),
                                            if (narrow) ...[
                                              _videos(),
                                              const SizedBox(height: 32),
                                              _newsList()
                                            ] else
                                              Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Expanded(
                                                        flex: 5,
                                                        child: _videos()),
                                                    const SizedBox(width: 40),
                                                    Expanded(
                                                        flex: 6,
                                                        child: _newsList())
                                                  ]),
                                            const SizedBox(height: 24),
                                            if (!_loading &&
                                                (_content.news.isEmpty ||
                                                    _content.videos.isEmpty))
                                              FuturisticActionTile(
                                                  node: _retry,
                                                  onActivate: _retryLoad,
                                                  child: const Padding(
                                                      padding:
                                                          EdgeInsets.all(16),
                                                      child: Text(
                                                          'Atualizar conteúdo',
                                                          style: TextStyle(
                                                              color: Colors
                                                                  .white)))),
                                          ])))))),
                  Positioned(
                      top: 0,
                      left: 0,
                      right: 0,
                      child: SafeArea(
                          bottom: false,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: narrow ? 24 : 48, vertical: 20),
                            child: Row(children: [
                              _label('V1 / GAME HUB'),
                              const Spacer(),
                              FuturisticHeaderControls(onMenu: () {
                                _player.currentState?.command('START');
                                mostrarMenuLauncher(context);
                              })
                            ]),
                          ))),
                ]));
          })));
}

class _NewsDialog extends StatelessWidget {
  const _NewsDialog({required this.news});
  final NoticiaGame news;
  @override
  Widget build(BuildContext context) => LauncherPadScope(
      child: Dialog(
          backgroundColor: const Color(0xFF101022),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
              side: const BorderSide(color: FuturisticPalette.accent)),
          child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 820),
              child: SingleChildScrollView(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: AspectRatio(
                                aspectRatio: 16 / 9,
                                child: NoticiaGameArtwork(
                                    news: news,
                                    accentColor: FuturisticPalette.water,
                                    placeholderIconSize: 48,
                                    borderRadius: BorderRadius.circular(12)))),
                        Text(news.veiculo.toUpperCase(),
                            style: const TextStyle(
                                color: FuturisticPalette.water,
                                letterSpacing: 3)),
                        const SizedBox(height: 16),
                        Text(news.titulo,
                            style: const TextStyle(
                                color: Colors.white,
                                fontFamily: 'Oxanium',
                                fontSize: 28)),
                        const SizedBox(height: 20),
                        Text(
                            news.descricao.isEmpty
                                ? 'Leia a notícia completa na fonte.'
                                : news.descricao,
                            style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 21,
                                height: 1.55)),
                        const SizedBox(height: 28),
                        Wrap(spacing: 16, runSpacing: 12, children: [
                          FilledButton.icon(
                              autofocus: true,
                              onPressed: () async {
                                final uri = Uri.tryParse(news.url);
                                if (uri == null ||
                                    !['https', 'http'].contains(uri.scheme)) {
                                  return;
                                }
                                try {
                                  await launchUrl(uri,
                                      mode: LaunchMode.externalApplication);
                                } catch (_) {}
                              },
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Ler na fonte')),
                          OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              child: const Text('Fechar')),
                        ]),
                      ])))));

}

