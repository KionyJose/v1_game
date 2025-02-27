// ignore_for_file: file_names, constant_identifier_names, unused_local_variable

import 'dart:ffi';
import 'dart:io';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:v1_game/Class/TecladoCtrl.dart';
import 'package:v1_game/Global.dart';

final user32 = DynamicLibrary.open('user32.dll');
const MOUSEEVENTF_WHEEL = 0x0800;
final mouseEvent = user32.lookupFunction<Void Function(Uint32, Uint32, Uint32, Int32, Uint32),void Function(int, int, int, int, int)>('mouse_event');


const MOUSEEVENTF_RIGHTDOWN = 0x0008;
const MOUSEEVENTF_RIGHTUP = 0x0010;

typedef MouseEventC = Void Function(Int32 dwFlags, Int32 dx, Int32 dy, Int32 dwData, Int32 dwExtraInfo);
typedef MouseEventDart = void Function(int dwFlags, int dx, int dy, int dwData, int dwExtraInfo);
final MouseEventDart mouseClick = user32.lookupFunction<MouseEventC, MouseEventDart>('mouse_event');

typedef SetCursorPosC = Int32 Function(Int32 x, Int32 y);
typedef SetCursorPosDart = int Function(int x, int y);
final setCursorPos = user32.lookupFunction<SetCursorPosC, SetCursorPosDart>('SetCursorPos');

typedef GetCursorPosC = Int32 Function(Pointer<MouseCtrl> lpPoint);
typedef GetCursorPosDart = int Function(Pointer<MouseCtrl> lpPoint);
final getCursorPos = user32.lookupFunction<GetCursorPosC, GetCursorPosDart>('GetCursorPos');

final class MouseCtrl extends Struct {
  @Int32()
  external int x;

  @Int32()
  external int y;


  static void scrollMouse(bool horizontal,int amount) {
    if(horizontal)TecladoCtrl.holdShift();
    mouseEvent(MOUSEEVENTF_WHEEL, 0, 0, amount, 0);
    if(horizontal)TecladoCtrl.soltaShift();
  }


  static void moveCursor(int dx, int dy) {
    final point = calloc<MouseCtrl>();
    getCursorPos(point);
    final currentX = point.ref.x;
    final currentY = point.ref.y;

    setCursorPos(currentX + dx, currentY + -dy);
    calloc.free(point);
  }

  static void simularClique() {
    final point = calloc<MouseCtrl>();
    int x = point.ref.x;
    int y = point.ref.y;
    // Mover o cursor
    // mouse_event(0x0001, x, y, 0, 0);  // Movimento do mouse (MOUSEEVENTF_MOVE)
  
    // Clicar
    mouseClick(0x0002, x, y, 0, 0);  // Pressionar o botão esquerdo do mouse (MOUSEEVENTF_LEFTDOWN)
    mouseClick(0x0004, x, y, 0, 0);  // Liberar o botão esquerdo do mouse (MOUSEEVENTF_LEFTUP)
  }

  static void clickDireito() {
    mouseEvent(MOUSEEVENTF_RIGHTDOWN, 0, 0, 0, 0);
    mouseEvent(MOUSEEVENTF_RIGHTUP, 0, 0, 0, 0);
  }

  static bool clickHold(bool segurar) {
    segurar = !segurar;
    final point = calloc<MouseCtrl>();
    int x = point.ref.x;
    int y = point.ref.y;
    // Mover o cursor
    // mouse_event(0x0001, x, y, 0, 0);  // Movimento do mouse (MOUSEEVENTF_MOVE)
  
    // Clicar
    if(segurar) mouseClick(0x0002, x, y, 0, 0);  // Pressionar o botão esquerdo do mouse (MOUSEEVENTF_LEFTDOWN)
    if(!segurar)mouseClick(0x0004, x, y, 0, 0);  // Liberar o botão esquerdo do mouse (MOUSEEVENTF_LEFTUP)
    return segurar;
  }

  static primeiroMovimento() async {

    // Obtém o caminho completo do executável em execução
  String caminhoExecutavel = Platform.resolvedExecutable;

  // Cria um objeto File a partir do caminho do executável
  File arquivoExecutavel = File(caminhoExecutavel);

  // Obtém o diretório onde o executável está localizado
  Directory diretorioAtual = arquivoExecutavel.parent;

  // Obtém o diretório pai do diretório atual
  Directory diretorioPai = diretorioAtual.parent;

    
    //C:\_Flutter\Game Interfacie\v1_game\build\windows\x64\runner\Debug\assets\Scripts
    // String? minhaPasta = Platform.environment['SystemRoot'];
    // Caminho do aplicativo que você deseja usar para abrir o arquivo
    assetsPath = "${diretorioAtual.path}\\data\\flutter_assets\\assets\\";
    String caminhoAssets = "${diretorioAtual.path}\\data\\flutter_assets\\assets\\Scripts\\";
    var caminhoDoAplicativo = '${caminhoAssets}AutoHotkeyA32.exe';
    // Caminho do arquivo que você deseja abrir
    var caminhoDoArquivo = '${caminhoAssets}moovMouse.ahk';

    // Verifica se o aplicativo existe
    var aplicativo = File(caminhoDoAplicativo);
    if (await aplicativo.exists()) {
      // Verifica se o arquivo existe
      var arquivo = File(caminhoDoArquivo);
      if (await arquivo.exists()) {
        // Inicia um novo processo para abrir o arquivo com o aplicativo especificado
        Process.start(caminhoDoAplicativo, [caminhoDoArquivo]);
      } else {
        debugPrint('Arquivo não encontrado: $caminhoDoArquivo');
      }
    } else {
      debugPrint('Aplicativo não encontrado: $caminhoDoAplicativo');
    }
  }


  

  


}


