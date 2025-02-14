// ignore_for_file: file_names

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:v1_game/Bando%20de%20Dados/db.dart';
import 'package:v1_game/Controllers/MovimentoSistema.dart';

class TESTES{
  testes() async {
    debugPrint("==========================================================");
    debugPrint("==========================================================");
    // debugPrint(await teste());
    // asdasd();
    MovimentoSistema.audioMovMent();
    // DB().addAppToStartup("","");
    debugPrint("==========================================================");
    debugPrint("==========================================================");
  }


  Future<String> getDesktopPath() async {
    final directory = await getApplicationDocumentsDirectory();
    final userDir = Directory(directory.parent.path); // Caminho do usuário
    final desktopPath = '${userDir.path}\\Desktop'; // Adiciona 'Desktop'
    return desktopPath;
  }

  teste() async {
    final directory = await getApplicationDocumentsDirectory();
    final userProfile = Directory(directory.parent.path); // Caminho do usuário
    String desktopPaths = "";
    if (userProfile == null) {
      throw Exception('Não foi possível determinar o caminho do perfil do usuário.');
    }

    // Tenta acessar "Desktop" no idioma EUA    
    desktopPaths = '${userProfile.path}\\Desktop'; // Adiciona 'Desktop'
    final desktopPath = Directory(desktopPaths);
    if (desktopPath.existsSync()) {
      return desktopPath.path;
    }

    // Tenta acessar "Desktop" no idioma PT-BR        
    desktopPaths = '${userProfile.path}\\Área de Trabalho'; // Adiciona 'Desktop'
    final areaDeTrabalhoPath = Directory(desktopPaths);
    if (areaDeTrabalhoPath.existsSync()) {
      return areaDeTrabalhoPath.path;
    }

    // throw Exception('Não foi possível localizar a área de trabalho.');
  }
}