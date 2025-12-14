// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:y_player/y_player.dart';

class YoutubeTela extends StatefulWidget {
  const YoutubeTela({ 
    this.func, 
    this.progress,  
    this.status, 
    required this.url, 
    super.key
  });
  
  final Function(YPlayerController)? func;
  final Function(YPlayerStatus)? status;
  final Function(Duration, Duration)? progress;
  final String url;

  @override
  State<YoutubeTela> createState() => _YoutubeTelaState();
}

class _YoutubeTelaState extends State<YoutubeTela> {
  bool _isInitialized = false;
  YPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    // Pequeno delay para garantir que o widget esteja totalmente montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  void _onControllerReady(YPlayerController controller) {
    if (mounted) {
      setState(() {
        _controller = controller;
      });
      // Chama a função callback se fornecida
      if (widget.func != null) {
        widget.func!(controller);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // Verifica se a URL é válida
    if (widget.url.isEmpty) {
      return const Center(
        child: Text(
          "URL do vídeo inválida",
          style: TextStyle(color: Colors.white),
        ),
      );
    }

    // Se ainda não foi inicializado, mostra loading
    if (!_isInitialized) {
      return const Center(
        child: CircularProgressIndicator(
          color: Colors.red,
        ),
      );
    }

    return YPlayer(
      key: ValueKey(widget.url), // Força reconstrução quando a URL muda
      onProgressChanged: widget.progress,
      seekBarMargin: const EdgeInsets.symmetric(horizontal: 10),
      onStateChanged: widget.status,
      onControllerReady: _onControllerReady,
      placeholder: const Icon(
        Icons.play_arrow,
        size: 60,
        color: Colors.white70,
      ),
      color: Colors.red,
      errorWidget: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 48,
            ),
            SizedBox(height: 16),
            Text(
              "Erro ao carregar vídeo",
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
      loadingWidget: const Align(
        alignment: Alignment.bottomCenter,
        child: LinearProgressIndicator(
          backgroundColor: Colors.transparent,
          minHeight: double.infinity,
          color: Colors.white54,
        ),
      ),
      youtubeUrl: widget.url,
      autoPlay: true,
    );
  }
}