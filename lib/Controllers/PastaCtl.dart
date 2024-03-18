// ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:v1_game/Bando%20de%20Dados/db.dart';
import 'package:v1_game/Tela/NavegadorPasta.dart';
import 'package:v1_game/Widgets/Pops.dart';

import '../Modelos/IconeInicial.dart';

class PastaCtrl{
  DB db = DB();

  navPasta(BuildContext context, String caminho, String tarefa, List<IconInicial> listiconIni, int index) async {
    
    await showDialog(
      context: context,
      builder: (context) => Pops().popScren(const NavPasta())).then((value) async {
        if (value == null) return;
        if (value[0] == "caminho") {
          if(tarefa == "Caminho do game"){
            listiconIni[index].local = value[1];
            await db.attDados(listiconIni);
          }
          if(tarefa == "Imagem de capa"){
            listiconIni[index].imgStr = value[1];
            await db.attDados(listiconIni);
          }
        }
        if (value[0] == "alterado") {
          // saveObgrigatorio = true;
        } else {
          // saveObgrigatorio = false;
        }
    });
  }
}