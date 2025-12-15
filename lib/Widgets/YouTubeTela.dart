// ignore_for_file: file_names
// ARQUIVO LEGADO - NÃO É MAIS USADO
// Mantido apenas para referência histórica
// A reprodução de vídeo agora usa media_kit diretamente em PrincipalPage.dart

import 'package:flutter/material.dart';

class YoutubeTela extends StatefulWidget {
  const YoutubeTela({ 
    this.func, 
    this.progress,  
    this.status, 
    required this.url, 
    super.key
  });
  
  final Function(dynamic)? func;
  final Function(dynamic)? status;
  final Function(Duration, Duration)? progress;
  final String url;

  @override
  State<YoutubeTela> createState() => _YoutubeTelaState();
}

class _YoutubeTelaState extends State<YoutubeTela> {
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "Este widget não é mais usado. Use Video do media_kit.",
        style: TextStyle(color: Colors.white),
      ),
    );
  }
}