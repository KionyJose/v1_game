// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

class MediaKitVideo extends StatefulWidget {
  const MediaKitVideo({
    super.key,
    required this.url,
    this.onDurationChanged,
    this.onPositionChanged,
    this.onPlayingChanged,
    this.onBufferingChanged,
    this.onError,
  });

  final String url;
  final Function(Duration duration)? onDurationChanged;
  final Function(Duration position)? onPositionChanged;
  final Function(bool playing)? onPlayingChanged;
  final Function(bool buffering)? onBufferingChanged;
  final Function(String error)? onError;

  @override
  State<MediaKitVideo> createState() => _MediaKitVideoState();
}

class _MediaKitVideoState extends State<MediaKitVideo> {
  late final Player player;
  late final VideoController controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      player = Player();
      controller = VideoController(player);

      // Escuta eventos do player
      player.stream.duration.listen((duration) {
        if (widget.onDurationChanged != null) {
          widget.onDurationChanged!(duration);
        }
      });

      player.stream.position.listen((position) {
        if (widget.onPositionChanged != null) {
          widget.onPositionChanged!(position);
        }
      });

      player.stream.playing.listen((playing) {
        if (widget.onPlayingChanged != null) {
          widget.onPlayingChanged!(playing);
        }
      });

      player.stream.buffering.listen((buffering) {
        if (widget.onBufferingChanged != null) {
          widget.onBufferingChanged!(buffering);
        }
      });

      player.stream.error.listen((error) {
        if (widget.onError != null && error.isNotEmpty) {
          widget.onError!(error);
        }
      });

      // Abre o vídeo do YouTube
      await player.open(Media(widget.url));

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      debugPrint('Erro ao inicializar player: $e');
      if (widget.onError != null) {
        widget.onError!(e.toString());
      }
    }
  }

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.red,
        ),
      );
    }

    return Video(
      controller: controller,
      controls: NoVideoControls,
    );
  }
}
