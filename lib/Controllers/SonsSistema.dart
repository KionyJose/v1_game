// ignore_for_file: file_names
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:v1_game/Global.dart';

class SonsSistema {

  static direction() async{
    try{
      final AudioPlayer audioPlayer = AudioPlayer();
      audioPlayer.onPlayerComplete.listen((event) => audioPlayer.dispose());
      audioPlayer.setVolume(configSistema.volume);
      await audioPlayer.play(AssetSource('Sons/SomMovimento.mp3'));
    }catch(erro){
      debugPrint(erro.toString());
    }

  }

  static directionRL() async{
    try{
      final AudioPlayer audioPlayer = AudioPlayer();
      audioPlayer.setVolume(configSistema.volume);
      audioPlayer.onPlayerComplete.listen((event) => audioPlayer.dispose());
      await audioPlayer.play(AssetSource('Sons/SomMovimentoBaixo.mp3'));
    }catch(erro){
      debugPrint(erro.toString());
    }

  }
  static cheat() async{
    try{
      final AudioPlayer audioPlayer = AudioPlayer();
      audioPlayer.setVolume(configSistema.volume);
      audioPlayer.onPlayerComplete.listen((event) => audioPlayer.dispose());
      await audioPlayer.play(AssetSource('Sons/SomCheat.mp3'));
    }catch(erro){
      debugPrint(erro.toString());
    }

  }
  static pim() async{
    try{
      final AudioPlayer audioPlayer = AudioPlayer();
      audioPlayer.setVolume(configSistema.volume);
      audioPlayer.onPlayerComplete.listen((event) => audioPlayer.dispose());
      await audioPlayer.play(AssetSource('Sons/SomCheat2.mp3'));
    }catch(erro){
      debugPrint(erro.toString());
    }

  }
  static click() async{
    try{
      final AudioPlayer audioPlayer = AudioPlayer();
      audioPlayer.setVolume(configSistema.volume);
      audioPlayer.onPlayerComplete.listen((event) => audioPlayer.dispose());
      await audioPlayer.play(AssetSource('Sons/SomClick.mp3'));
    }catch(erro){
      debugPrint(erro.toString());
    }

  }
  static intro() async{
    try{
      final AudioPlayer audioPlayer = AudioPlayer();
      audioPlayer.setVolume(configSistema.volume);
      audioPlayer.onPlayerComplete.listen((event) => audioPlayer.dispose());
      await audioPlayer.play(AssetSource('Sons/Intro.mp3'));      
    }catch(erro){
      debugPrint(erro.toString());
    }

  }
}