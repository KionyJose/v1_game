// ignore_for_file: file_names
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:v1_game/Global.dart';

class SonsSistema {
  static void _playSound(String assetPath) {
    try {
      final audioPlayer = AudioPlayer();
      audioPlayer.setPlayerMode(PlayerMode.lowLatency);
      audioPlayer.setReleaseMode(ReleaseMode.stop);
      audioPlayer.setVolume(configSistema.volume);
      
      // Configura dispose automático após conclusão
      audioPlayer.onPlayerComplete.listen((_) {
        audioPlayer.dispose();
      });
      
      audioPlayer.play(AssetSource(assetPath));
    } catch (erro) {
      debugPrint(erro.toString());
    }
  }

  static void direction() => _playSound('Sons/SomMovimento.mp3');
  static void directionRL() => _playSound('Sons/SomMovimentoBaixo.mp3');
  static void cheat() => _playSound('Sons/SomCheat.mp3');
  static void pim() => _playSound('Sons/SomCheat2.mp3');
  static void click() => _playSound('Sons/SomClick.mp3');
  static void intro() => _playSound('Sons/Intro.mp3');
}