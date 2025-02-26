// ignore_for_file: file_names, unused_local_variable

import 'dart:async';
import 'dart:io';
import 'package:process_run/shell_run.dart';
import 'package:v1_game/Class/TecladoCtrl.dart';

class NavWebCtrl{
  static Future<void> openLink(String url) async {
    
    final Uri uri = Uri.parse(url);    
    Process.run('cmd', ['/c', 'start', url]); // Abre e foca no Windows
    Timer(const Duration(milliseconds: 800), (){
      TecladoCtrl.teclaF11();
    });

    // Aguardar um tempo para garantir que o navegador tenha aberto
    Timer(const Duration(seconds: 1), () {
      // Tenta focar a janela do navegador após um pequeno atraso (dependendo do navegador, isso pode ou não funcionar)
      Process.run('cmd', ['/c', 'nircmd.exe', 'win', 'activate', 'title', '.*']);
    });
  
  }

  static openSite(String url)async{
    // Comando para abrir o navegador em tela cheia
  // final  command = 'start $url';
  final command = 'start chrome --start-fullscreen $url';

  // Executa o comando no sistema operacional
  await run(command, verbose: true);

  }

}