import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:v1_game/Modelos/IconeInicial.dart';

import '../Global.dart';

class DB{

  
  // String dbPath = "C:\\Users\\kiony\\OneDrive\\Área de Trabalho\\testeDBLocal.txt"; 
  String dbPath = "C:\\Users\\Public\\Documents\\testeDBLocal.txt"; 
  String dbPathConfigSis = "C:\\Users\\Public\\Documents\\v1_config.txt"; 

  leiaBanco() async =>  await leituraDeDados();
  
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
  verificaDocInicio(){
    // Verifica se o arquivo existe
    File dbFile = File(dbPath);
    if (!dbFile.existsSync()) {
      // Cria o arquivo se ele não existir
      dbFile.createSync(recursive: true); // recursive: true para criar diretórios se necessário
      // dbFile.writeAsStringSync("Arquivo criado com sucesso!"); // Escreve conteúdo inicial, se necessário
      debugPrint("Arquivo criado em: $dbPath");
    } else {
      debugPrint("Arquivo já existe em: $dbPath");
    }
  }

  leituraConfigSis() async {
     // Verifica se o arquivo existe
    File dbFile = File(dbPathConfigSis);
    if (!dbFile.existsSync()) {
      // Cria o arquivo se ele não existir
      String isLine = "";
      
      isLine += "volume=50\n";
      isLine += "tela_inicial_tipo=1\n";
      isLine += "videos_tela_principal=true\n";
      isLine += "videos_card_game=false\n";
      isLine += "intro=true\n";    
      dbFile.createSync(recursive: true); // recursive: true para criar diretórios se necessário
      dbFile.writeAsStringSync(isLine); // Escreve conteúdo inicial, se necessário
      // dbFile.writeAsStringSync("tela_inicial_tipo=1"); // Escreve conteúdo inicial, se necessário
      // dbFile.writeAsStringSync("videos_tela_principal=true"); // Escreve conteúdo inicial, se necessário
      // dbFile.writeAsStringSync("videos_card_game=false"); // Escreve conteúdo inicial, se necessário
      debugPrint("Arquivo criado em: $dbPathConfigSis");
    } else {
      debugPrint("Arquivo já existe em: $dbPathConfigSis");
    }
    var file = File(dbPathConfigSis);
    Stream<String> lines = file.openRead()
      .transform(utf8.decoder) // Decode bytes to UTF-8.
      .transform(const LineSplitter()); // Convert stream to individual lines.

    await for (String line in lines) {
      String value = line.split('=')[1];
      if(line.contains("volume")) configSistema.volume = double.parse(value);      
      if(line.contains("tela_inicial_tipo")) configSistema.telaInicialTipo = int.parse(value);      
      if(line.contains("videos_tela_principal")) configSistema.videosTelaPrincipal = value == "true";
      if(line.contains("videos_card_game")) configSistema.videosCardGame = value == "true";
      
      
    }
  }

  leituraDeDados() async {
    verificaDocInicio();
    var file = File(dbPath);
    bool start = false;

    List<String> itemCard = [];
    List<IconInicial> listIconsInicial = [];

    Stream<String> lines = file.openRead()
      .transform(utf8.decoder) // Decode bytes to UTF-8.
      .transform(const LineSplitter()); // Convert stream to individual lines.
   
      await for (String line in lines) {        
        if(line.contains("item-") && start){
          IconInicial iconIni =  IconInicial(itemCard);
          listIconsInicial.add(iconIni);

          // listIconsInicial.add(iconIni);listIconsInicial.add(iconIni);listIconsInicial.add(iconIni);
          // listIconsInicial.add(iconIni);listIconsInicial.add(iconIni);listIconsInicial.add(iconIni);
          // listIconsInicial.add(iconIni);listIconsInicial.add(iconIni);listIconsInicial.add(iconIni);
          // listIconsInicial.add(iconIni);listIconsInicial.add(iconIni);listIconsInicial.add(iconIni);
          itemCard.clear();
        }
        start =true;
        itemCard.add(line);


      }
      if(itemCard.isNotEmpty){        
        IconInicial iconIni =  IconInicial(itemCard);
        listIconsInicial.add(iconIni);

        // listIconsInicial.add(iconIni);listIconsInicial.add(iconIni);listIconsInicial.add(iconIni);
        // listIconsInicial.add(iconIni);listIconsInicial.add(iconIni);listIconsInicial.add(iconIni);
        // listIconsInicial.add(iconIni);listIconsInicial.add(iconIni);listIconsInicial.add(iconIni);
        // listIconsInicial.add(iconIni);listIconsInicial.add(iconIni);listIconsInicial.add(iconIni);
      }
    debugPrint(listIconsInicial.length.toString());
    return listIconsInicial;
  }

  Process? _process; // Variável para armazenar o processo

  openFile(String filePath) async {
    try {
      // Verifica se o processo já foi iniciado e está em execução
      

      // Se o processo não está em execução, inicia um novo processo
      _process = await Process.start(filePath, ["-h"]);
      await _process!.stderr.drain();
      debugPrint('Arquivo aberto com sucesso');

    } on ProcessException catch (e) {
      debugPrint('Erro ao abrir o arquivo: $e');
      openUrl(filePath);
    } catch (e) {
      debugPrint('Erro d  onhecido: $e');
    }
  }

  openUrl(String filePath){
    String str = filePath.replaceAll(r'\\', r'\');
    try{      
      Process.run('explorer', [str]);
    } on ProcessException catch (e) {
        debugPrint('Erro ao abrir o URL: $e');
        // openUrl(filePath);
      } catch (e) {
        debugPrint('Erro desconhecido: $e');
      }
  }

  void addAppToStartup() {
    String appName, appPath;
    String executablePath = Platform.resolvedExecutable;
    
    appName = executablePath.split('\\').last;
    appPath = executablePath;
    final command = '''
    reg add "HKCU\\Software\\Microsoft\\Windows\\CurrentVersion\\Run" /v "$appName" /t REG_SZ /d "$appPath" /f
    ''';

    try {
      Process.runSync('powershell', ['-Command', command]);
      debugPrint('Aplicativo adicionado ao iniciar com o Windows.');
    } catch (e) {
      debugPrint('Erro ao adicionar ao início: $e');
    }
  }


}