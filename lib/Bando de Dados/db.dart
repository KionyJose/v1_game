import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:v1_game/Modelos/IconeInicial.dart';

class DB{

  
  // String dbPath = "C:\\Users\\kiony\\OneDrive\\Área de Trabalho\\testeDBLocal.txt"; 
  String dbPath = "C:\\Users\\Public\\Documents\\testeDBLocal.txt"; 

  leiaBanco() async {
    return await leituraDeDados();


  }
  attDados(List<IconInicial> list) async {
    // Solicitar permissão para escrever na área de trabalho
    var status = await Permission.storage.request();
    String  lista =  codificaLista(list);
    if (status.isGranted) {
      // Escrever conteúdo no arquivo
      File file = File(dbPath);
      await file.writeAsString(lista);

    } else {
      // Se a permissão não for concedida, exiba uma mensagem ao usuário ou tome outra ação apropriada
      debugPrint('Permissão para escrever na área de trabalho não concedida');
    }

  }
  addNovoCard(IconInicial ico){

  }

  codificaLista(List<IconInicial> list){
    String listaInLine = "";
    int index = 1;
    for (IconInicial ico in list) { 
      
      listaInLine += "item-${index.toString().padLeft(1,'0')}\n";
      listaInLine += "lugar: ${ico.lugar}\n";
      listaInLine += "nome: ${ico.nome}\n";
      listaInLine += "local: ${ico.local}\n";
      listaInLine += "img: ${ico.imgStr}\n";
      listaInLine += "imgAux: ${ico.imgAuxStr}\n";      

      index++;

    }
    return listaInLine;    
    // item-01
    // lugar: 01
    // nome: Harry Pother
    // local: D:\\GAMES\\HOGWARTS LEGACY\\Hogwarts Legacy\\Phoenix\\Binaries\\Win64\\HogwartsLegacy.exe
    // img: C:\\Users\\kiony\\OneDrive\\Imagens\\Walpappers\\1102284.jpg
    // imgAux: caminho/.png
  }
  

  leituraDeDados() async {
    var file = File(dbPath);
    bool start = false;

    List<String> itemCard = [];
    List<IconInicial> listIconsInicial = [];

    Stream<String> lines = file.openRead()
      .transform(utf8.decoder) // Decode bytes to UTF-8.
      .transform(const LineSplitter()); // Convert stream to individual lines.
    try {
      await for (String line in lines) {

        if(line.contains("item-") && start){

          IconInicial iconIni =  IconInicial(itemCard);
          listIconsInicial.add(iconIni);
          itemCard.clear();

        }
        start =true;
        itemCard.add(line);

      }
      if(itemCard.isNotEmpty){        
        IconInicial iconIni =  IconInicial(itemCard);
        listIconsInicial.add(iconIni);
      }
    } catch (_) {}
    debugPrint(listIconsInicial.length.toString());
    return listIconsInicial;
  }

  openFile(String filePath) async {
    try {

      final process = await Process.start(filePath, ["-h"]);
      await process.stderr.drain();
      debugPrint('Erro ao abrir 1\ncode: ${await process.exitCode}');
      
    } on ProcessException catch (e) {
      debugPrint('Erro ao abrir o arquivo: $e');
      openUrl(filePath);
    } catch (e) {
      debugPrint('Erro 2 desconhecido: $e');
    }
  }

  openUrl(String filePath){
    try{      
      Process.run('explorer', [filePath]);
    } on ProcessException catch (e) {
        debugPrint('Erro ao abrir o URL: $e');
        // openUrl(filePath);
      } catch (e) {
        debugPrint('Erro desconhecido: $e');
      }
  }



}