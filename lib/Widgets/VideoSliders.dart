// ignore_for_file: file_names, must_be_immutable

import 'package:flutter/material.dart';

class VideoSliders extends StatefulWidget {
  VideoSliders({required this.child, super.key});
  Widget child;

  @override
  State<VideoSliders> createState() => _VideoSlidersState();
}

class _VideoSlidersState extends State<VideoSliders> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _animation;

  // Simulando o controle e dados
  final List<String> videosYT = ["Video 1", "Video 2"]; // Exemplo de lista de vídeos
  final bool telaIniciada = true; // Exemplo de condição

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );

    _animation = Tween<Offset>(
      begin: const Offset(0, 1), // Começa fora da tela (abaixo)
      end: Offset.zero,          // Termina na posição original
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOut, // Desaceleração suave
      ),
    );

    // Inicia a animação se as condições forem atendidas
    if (videosYT.isNotEmpty && telaIniciada) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget listVideos() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      color: Colors.blueAccent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: videosYT
            .map((video) => Text(
                  video,
                  style: const TextStyle(color: Colors.white),
                ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.bottomCenter,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          return SlideTransition(
            position: _animation,
            child: widget.child,
          );
        },
      ),            
    );
  }
}
