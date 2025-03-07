// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously, unused_local_variable
import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:v1_game/Bando%20de%20Dados/TESTES.dart';
import 'package:v1_game/Class/MouseCtrl.dart';
import 'package:v1_game/Global.dart';
import 'package:v1_game/Tela/MyApp.dart';
import 'package:window_manager/window_manager.dart';
import 'package:y_player/y_player.dart';

import 'Metodos/leituraArquivo.dart';

WindowOptions windowOptions = const WindowOptions(    
    center: true,
    skipTaskbar: false,
    titleBarStyle: TitleBarStyle.hidden,
  );
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  YPlayerInitializer.ensureInitialized();
  // Must add this line.
  await windowManager.ensureInitialized(); 
  await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
      await windowManager.maximize();
    },
  );
  localizaCaminhos();
  
  MouseCtrl.primeiroMovimento();
  // semBarras();
  await TESTES().testes();
  

  // Solicitar permissão de armazenamento externo
  var status = await Permission.storage.request();  
  if (status.isGranted) runApp(const MyApp());
  // Se a permissão não for concedida, exiba uma mensagem ao usuário ou tome outra ação apropriada
  if (!status.isGranted) debugPrint('Permissão de armazenamento não concedida');
  

}

localizaCaminhos(){
  // Obtém o caminho completo do executável em execução
  String caminhoExecutavel = Platform.resolvedExecutable;
  // Cria um objeto File a partir do caminho do executável
  File arquivoExecutavel = File(caminhoExecutavel);
  // Obtém o diretório onde o executável está localizad
  Directory diretorioAtual = arquivoExecutavel.parent;
  // Obtém o diretório pai do diretório atual
  Directory diretorioPai = diretorioAtual.parent;    
  //C:\_Flutter\Game Interfacie\v1_game\build\windows\x64\runner\Debug\assets\Scripts
  // String? minhaPasta = Platform.environment['SystemRoot'];
  // Caminho do aplicativo que você deseja usar para abrir o arquivo
  localPai = diretorioPai.path;
  localPath = diretorioAtual.path;
  assetsPath = "${diretorioAtual.path}\\data\\flutter_assets\\assets\\";

  criaAtalhoTecladoApp();
}
  
criaAtalhoTecladoApp() async {

  String caminhoDesktop = await LerArquivos().getDesktopPath();
  // Atalho App
  criarAtalho(
    origem:"$localPath\\v1_game.exe", 
    destino:"$caminhoDesktop\\V1 Launcher.lnk",
  );
  // Atalho Teclado
  criarAtalho(
    origem:'$localPai\\TecladoVirtual\\teclado_virtual.exe', 
    destino: '$localPai\\teclado_virtual.lnk',
  );
  
}
void criarAtalho({required String origem, required String destino}) {
 final script = '''
  \$WshShell = New-Object -ComObject WScript.Shell
  \$Shortcut = \$WshShell.CreateShortcut('$destino')
  \$Shortcut.TargetPath = '$origem'
  \$Shortcut.Save()
  ''';

  final processo = Process.runSync('powershell', ['-Command', script]);

  if (processo.exitCode == 0) {
    print('Atalho criado em: $destino');
  } else {
    print('Erro ao criar atalho: ${processo.stderr}');
  }
}
semBarras(){
   doWhenWindowReady(() {
    final win = appWindow;
    // win.maximize();
    win.show();
  });
}
