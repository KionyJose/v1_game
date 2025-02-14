
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:y_player/y_player.dart';

import '../Widgets/YouTubeTela.dart';


class Yotubesss extends StatefulWidget {
  const Yotubesss({Key? key}) : super(key: key);

  @override
  State<Yotubesss> createState() => _YotubesssState();
}

class _YotubesssState extends State<Yotubesss> {
  // late VideoPlayerController controller;

  verificaLinkLive(String link){

    delInicio(String str){
      debugPrint(str);
      str = str.replaceAll("https://", "");
      str = str.replaceAll("www.youtube.com/", ""); 
      str = str.replaceAll("youtube.com/", "");
      str = str.replaceAll("youtu.be/", "");
      str = str.replaceAll("live/", "");
      str = str.replaceAll("watch?v=", "");
      return str;      
    }      
    List<String> list = delInicio(link).split('?');
    link = list[0].split('&')[0];

    return link;
  }// ignore_for_file: file_names
 @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('YPlayer Example'),
        ),
        body:  Column(
          children: [
            Container(
              height: 400,
              width: 700,
              padding:const EdgeInsets.all(8.0),
              child: const YoutubeTela(url:  "https://www.youtube.com/watch?v=YMx8Bbev6T4&t=14s&ab_channel=FlutterUIDev"), //"https://www.youtube.com/watch?v=pvpHTLCaOcg&ab_channel=PMBMusic"),
            ),
          ],
        ),
      ),
    );
  }
}
