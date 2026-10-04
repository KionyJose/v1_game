import 'dart:async';
import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Video;
import '../scraps/jogo_detalhes.dart';

/// Player criado apenas quando o usuário escolhe um trailer.
class TrailerPlayer extends StatefulWidget {
  final TrailerJogo trailer;
  const TrailerPlayer({super.key, required this.trailer});
  @override
  State<TrailerPlayer> createState() => _TrailerPlayerState();
}

class _TrailerPlayerState extends State<TrailerPlayer> {
  final _youtube = YoutubeExplode();
  Player? _player;
  VideoController? _video;
  StreamSubscription<String>? _erros;
  bool _carregando = true;
  String? _erro;

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
          setState(
              () => _erro = 'Não foi possível reproduzir este trailer no app.');
        }
      });
      await player
          .open(Media(manifest.muxed.bestQuality.url.toString()))
          .timeout(const Duration(seconds: 20));
      if (mounted) setState(() => _carregando = false);
    } catch (_) {
      if (mounted) {
        setState(() {
          _carregando = false;
          _erro = 'Não foi possível reproduzir este trailer no app.';
        });
      }
    }
  }

  @override
  void dispose() {
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
      setState(
          () => _erro = 'Não foi possível abrir o YouTube. Tente novamente.');
    }
  }

  @override
  Widget build(BuildContext context) => Dialog(
      backgroundColor: const Color(0xFF10121B),
      insetPadding: const EdgeInsets.all(16),
      child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1000),
          child: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            ListTile(
                title: Text(widget.trailer.titulo),
                trailing: IconButton(
                    tooltip: 'Fechar trailer',
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
                        ? const Center(child: CircularProgressIndicator())
                        : Video(controller: _video!)),
            Padding(
                padding: const EdgeInsets.all(12),
                child: TextButton.icon(
                    onPressed: _abrirYouTube,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Abrir no YouTube'))),
          ]))));
}
