// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:y_player/y_player.dart';

class YoutubeTela extends StatelessWidget {
  const YoutubeTela({ this.func, this.progress,  this.status, required this.url, super.key});
  final  Function(YPlayerController)? func;
  final  Function(YPlayerStatus )? status;
  final  Function(Duration, Duration)? progress;
  final String url;

  @override
  Widget build(BuildContext context) {
    return  YPlayer(
        // onProgressChanged: (position, duration) {
        //   // print('Progress: ${position.inSeconds}/${duration.inSeconds}');
        // },
      onProgressChanged: progress,
      seekBarMargin: const EdgeInsets.symmetric(horizontal: 10),
      onStateChanged: status,
      onControllerReady: func,
      placeholder: const Icon(Icons.play_arrow),
      color: Colors.red,
      // aspectRatio: 200,
      errorWidget: const Center(child: Text("Errinho bobo"),),
      loadingWidget: const Align(
        alignment: Alignment.bottomCenter,
        child: LinearProgressIndicator(
          backgroundColor: Colors.transparent,
          minHeight: double.infinity,
          color: Colors.white54,
        ),
      ),// Icon(Icons.more_horiz),
      youtubeUrl: url,
      autoPlay: true,
    );
  }
}