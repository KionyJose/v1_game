// ignore_for_file: non_constant_identifier_names, use_build_context_synchronously

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:v1_game/Bando%20de%20Dados/TESTES.dart';
import 'package:v1_game/Class/MouseCtrl.dart';
import 'package:v1_game/Tela/MyApp.dart';
import 'package:window_manager/window_manager.dart';
import 'package:y_player/y_player.dart';

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
      // await windowManager.maximize();
      await windowManager.show();
      await windowManager.focus();
    },
  );
  
  MouseCtrl.primeiroMovimento();
  // semBarras();
  await TESTES().testes();

  // Solicitar permissão de armazenamento externo
  var status = await Permission.storage.request();  
  if (status.isGranted) runApp(const MyApp());
  // Se a permissão não for concedida, exiba uma mensagem ao usuário ou tome outra ação apropriada
  if (!status.isGranted) debugPrint('Permissão de armazenamento não concedida');
  

}

  

semBarras(){
   doWhenWindowReady(() {
    final win = appWindow;
    // win.maximize();
    win.show();
  });
}
