import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../Interface/pad_playback_hints.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Video;
import '../scraps/jogo_detalhes.dart';
import '../../../Interface/launcher_pad_scope.dart';

/// Player criado apenas quando o usuário escolhe um trailer.
class TrailerPlayer extends StatefulWidget {
  final TrailerJogo trailer;
  final bool inline;
  const TrailerPlayer({super.key, required this.trailer, this.inline = false});
  @override
  State<TrailerPlayer> createState() => TrailerPlayerState();
}

class TrailerPlayerState extends State<TrailerPlayer> {
  final _youtube = YoutubeExplode();
  Player? _player;
  VideoController? _video;
  StreamSubscription<String>? _erros;
  bool _carregando = true;
  bool _suspended = false;
  String? _erro;
  DateTime? _lastVolumeChange;
  double _volume = 100;
  bool _fullscreen = false, _disposing = false;
  PageRoute<void>? _fullscreenRoute;
  final _viewRevision = ValueNotifier<int>(0);
  final _viewport = GlobalKey();
  final _inlineHints = GlobalKey<PadPlaybackHintsState>();
  final _fullscreenHints = GlobalKey<PadPlaybackHintsState>();

  void _refresh(VoidCallback update) {
    if (!mounted || _disposing) return;
    setState(update);
    _viewRevision.value++;
  }

  void _showHints() {
    _inlineHints.currentState?.show();
    _fullscreenHints.currentState?.show();
  }

  Future<void> _toggleFullscreen() async {
    if (_fullscreen) {
      if (_fullscreenRoute?.isCurrent ?? false) {
        Navigator.of(context).pop();
      }
      return;
    }
    final box = _viewport.currentContext?.findRenderObject() as RenderBox?;
    final origin =
        box == null ? null : box.localToGlobal(Offset.zero) & box.size;
    final reduce = MediaQuery.disableAnimationsOf(context);
    _refresh(() => _fullscreen = true);
    final route = PageRouteBuilder<void>(
        opaque: false,
        transitionDuration: Duration(milliseconds: reduce ? 0 : 420),
        reverseTransitionDuration: Duration(milliseconds: reduce ? 0 : 320),
        pageBuilder: (_, __, ___) => LauncherPadScope(
            revealFocus: false,
            onCommand: (command) {
              if (command == 'R3' || command == '3') {
                _showHints();
                if (_fullscreenRoute?.isCurrent ?? false) {
                  Navigator.of(context).pop();
                }
                return true;
              }
              final handled = this.command(command);
              return handled ||
                  ['CIMA', 'BAIXO', 'ESQUERDA', 'DIREITA'].contains(command);
            },
            child: Focus(
                autofocus: true,
                onKeyEvent: (_, event) {
                  if (event is! KeyDownEvent) return KeyEventResult.ignored;
                  if (event.logicalKey == LogicalKeyboardKey.enter ||
                      event.logicalKey == LogicalKeyboardKey.space) {
                    togglePlayback();
                    return KeyEventResult.handled;
                  }
                  if (event.logicalKey == LogicalKeyboardKey.f11) {
                    unawaited(_toggleFullscreen());
                    return KeyEventResult.handled;
                  }
                  return KeyEventResult.ignored;
                },
                child: Material(
                    key: const ValueKey('trailer-fullscreen'),
                    color: Colors.black,
                    child: ValueListenableBuilder<int>(
                        valueListenable: _viewRevision,
                        builder: (_, __, ___) =>
                            _inlineVideo(fullscreen: true))))),
        transitionsBuilder: (context, animation, _, child) {
          final screen = Offset.zero & MediaQuery.sizeOf(context);
          return AnimatedBuilder(
              animation: animation,
              child: child,
              builder: (_, video) {
                final progress =
                    Curves.easeInOutCubic.transform(animation.value);
                final rect = Rect.lerp(origin ?? screen, screen, progress)!;
                return Stack(children: [
                  Positioned.fill(
                      child: ColoredBox(
                          color: Colors.black.withValues(alpha: progress))),
                  Positioned.fromRect(rect: rect, child: video!),
                ]);
              });
        });
    _fullscreenRoute = route;
    await Navigator.of(context).push(route);
    await route.completed;
    _fullscreenRoute = null;
    if (mounted) _refresh(() => _fullscreen = false);
  }

  @override
  void initState() {
    super.initState();
    _iniciar();
  }

  Future<void> _iniciar() async {
    try {
      final manifest = await _youtube.videos.streamsClient
          .getManifest(widget.trailer.youtubeId)
          .timeout(const Duration(seconds: 30));
      if (!mounted) return;
      if (manifest.muxed.isEmpty) {
        throw StateError('Trailer sem stream compatível.');
      }
      final player = Player();
      _player = player;
      _video = VideoController(player);
      _erros = player.stream.error.listen((error) {
        if (mounted && error.isNotEmpty) {
          _refresh(
              () => _erro = 'Não foi possível reproduzir este trailer no app.');
        }
      });
      await player
          .open(Media(manifest.muxed.bestQuality.url.toString()),
              play: !_suspended)
          .timeout(const Duration(seconds: 20));
      if (mounted) _refresh(() => _carregando = false);
    } catch (_) {
      if (mounted) {
        _refresh(() {
          _carregando = false;
          _erro = 'Não foi possível reproduzir este trailer no app.';
        });
      }
    }
  }

  @override
  void dispose() {
    _disposing = true;
    _viewRevision.dispose();
    _youtube.close();
    _erros?.cancel();
    _player?.dispose();
    super.dispose();
  }

  Future<void> _abrirYouTube() async {
    try {
      await _player?.pause();
      if (await launchUrl(widget.trailer.url,
          mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {/* O link permanece visível se o navegador falhar. */}
    if (mounted) {
      _refresh(
          () => _erro = 'Não foi possível abrir o YouTube. Tente novamente.');
    }
  }

  void togglePlayback() {
    _showHints();
    _player?.playOrPause();
  }

  bool command(String command) {
    if (command == 'R3') {
      _showHints();
      unawaited(_toggleFullscreen());
      return true;
    }
    if (command == '2') {
      togglePlayback();
      return true;
    }
    if (['CIMA', 'BAIXO', 'ESQUERDA', 'DIREITA', 'LB', 'RB', 'START']
        .contains(command)) {
      _showHints();
    }
    final player = _player;
    final trigger =
        RegExp(r'^(LT|RT)(?:-(\d+(?:\.\d+)?))?$').firstMatch(command);
    if (trigger != null) {
      final pressure = double.tryParse(trigger.group(2) ?? '255') ?? 0;
      if (pressure < 30) return true;
      _showHints();
      final now = DateTime.now();
      if (player != null &&
          (_lastVolumeChange == null ||
              now.difference(_lastVolumeChange!) >=
                  const Duration(milliseconds: 150))) {
        _lastVolumeChange = now;
        _volume =
            (_volume + (trigger.group(1) == 'RT' ? 5 : -5)).clamp(0.0, 100.0);
        player.setVolume(_volume);
        if (mounted) _refresh(() {});
      }
      return true;
    }
    if (command == 'START') {
      _suspended = true;
      player?.pause();
    }
    if (player != null && (command == 'LB' || command == 'RB')) {
      final delta = Duration(seconds: command == 'LB' ? -10 : 10);
      final position = player.state.position + delta;
      player.seek(position.isNegative
          ? Duration.zero
          : position > player.state.duration
              ? player.state.duration
              : position);
      return true;
    }
    return false;
  }

  Widget _inlineVideo({bool fullscreen = false}) => ExcludeFocus(
      child: SizedBox.expand(
          key: fullscreen ? null : _viewport,
          child: !fullscreen && _fullscreen
              ? const ColoredBox(color: Colors.black)
              : Stack(fit: StackFit.expand, children: [
                  if (_erro != null)
                    Center(
                        child: Padding(
                            padding: const EdgeInsets.all(20),
                            child: Text(_erro!, textAlign: TextAlign.center)))
                  else if (_carregando)
                    const Center(child: CircularProgressIndicator())
                  else
                    Video(controller: _video!, controls: NoVideoControls),
                  Positioned(
                      left: 12,
                      right: 12,
                      bottom: 12,
                      child: PadPlaybackHints(
                          key: fullscreen ? _fullscreenHints : _inlineHints,
                          text:
                              'A / Enter: reproduzir ou pausar \u2022 LB / RB: 10s \u2022 LT / RT: volume ${_volume.round()}% \u2022 R3: expandir / voltar')),
                ])));

  @override
  Widget build(BuildContext context) => widget.inline
      ? _inlineVideo()
      : LauncherPadScope(
          onCommand: command,
          child: Dialog(
              backgroundColor: const Color(0xFF000000),
              insetPadding: const EdgeInsets.all(16),
              child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1000),
                  child: SingleChildScrollView(
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                    ListTile(
                        title: Text(widget.trailer.titulo),
                        trailing: IconButton(
                            tooltip: 'Fechar trailer',
                            autofocus: true,
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.close))),
                    AspectRatio(
                        aspectRatio: 16 / 9,
                        child: _erro != null
                            ? Center(
                                child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: Text(_erro!)))
                            : _carregando
                                ? const Center(
                                    child: CircularProgressIndicator())
                                : Video(controller: _video!)),
                    Padding(
                        padding: const EdgeInsets.all(12),
                        child: Wrap(spacing: 12, runSpacing: 8, children: [
                          OutlinedButton.icon(
                              autofocus: true,
                              onPressed: _carregando || _erro != null
                                  ? null
                                  : () => _player?.playOrPause(),
                              icon: const Icon(Icons.play_arrow),
                              label: const Text('Reproduzir / Pausar')),
                          OutlinedButton.icon(
                              onPressed: () => Navigator.pop(context),
                              icon: const Icon(Icons.close),
                              label: const Text('Fechar trailer')),
                        ])),
                    Padding(
                        padding: const EdgeInsets.all(12),
                        child: TextButton.icon(
                            onPressed: _abrirYouTube,
                            icon: const Icon(Icons.open_in_new),
                            label: const Text('Abrir no YouTube'))),
                  ])))));
}
