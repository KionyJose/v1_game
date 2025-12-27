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

// Constantes de configuração do mouse
const int zonaMortaMouse = 3000;
const int zonaMortaScroll = 4000;
const int maxValorAnalogico = 32768;
const int velocidadeMinMouse = 1;
const int velocidadeMaxMouse = 45;
const int velocidadeMinScroll = 15;
const int velocidadeMaxScroll = 150;

// Estados internos
bool _mouseClickHold = false;
bool _eixoScrolVertical = true;

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

    String caminhoAssets = "$localPath\\data\\flutter_assets\\assets\\Scripts\\";
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

  // Função para calcular velocidade do mouse de forma gradual e suave
  static int calcularVelocidadeMouse(int valorAnalogico) {
    int valorAbs = valorAnalogico.abs();
    bool negativo = valorAnalogico.isNegative;
    
    // Zona morta - ignora movimentos muito pequenos
    if (valorAbs < zonaMortaMouse) return 0;
    
    // Normaliza para 0-1 (remove zona morta)
    double normalizado = (valorAbs - zonaMortaMouse) / (maxValorAnalogico - zonaMortaMouse);
    
    // Aplica curva de aceleração cúbica para transição gradual
    // Ajuste o expoente: 2 = suave | 3 = balanceado | 4 = intenso
    double curva = normalizado * normalizado * normalizado;
    
    // Mapeia para faixa de velocidade
    int velocidade = (curva * (velocidadeMaxMouse - velocidadeMinMouse) + velocidadeMinMouse).round();
    
    return negativo ? -velocidade : velocidade;
  }

  // Processa movimento do analógico esquerdo
  static void processarMovimentoMouse(String event) {
    try {
      List<String> list = event.split(',');
      int valor = int.parse(list.last);
      
      // Calcula velocidade de forma gradual e suave
      int velocidade = calcularVelocidadeMouse(valor);
      
      // Se velocidade for 0 (zona morta), não move
      if (velocidade == 0) return;
      
      int dx = 0;
      int dy = 0;
      if(list[1]=="X") dx = velocidade;
      if(list[1]=="Y") dy = velocidade;
      moveCursor(dx, dy);
    } catch(e) {
      debugPrint('Erro em processarMovimentoMouse: $e');
    }
  }

  // Processa scroll do analógico direito
  static void processarScroll(String event, {required bool eixoVertical}) {
    try {
      List<String> list = event.split(',');
      int valor = int.parse(list.last);
      int valorAbs = valor.abs();
      bool negativo = valor.isNegative;
      
      // Zona morta para scroll
      if (valorAbs < zonaMortaScroll) return;
      
      // Normaliza e aplica curva de aceleração quadrática para scroll
      double normalizado = (valorAbs - zonaMortaScroll) / (maxValorAnalogico - zonaMortaScroll);
      double curva = normalizado * normalizado;
      
      // Mapeia para velocidade de scroll
      int velocidadeScroll = (curva * (velocidadeMaxScroll - velocidadeMinScroll) + velocidadeMinScroll).round();
      int valorReturn = negativo ? -velocidadeScroll : velocidadeScroll;
      
      // Altera eixo de scroll automaticamente com movimento extremo
      bool usarHorizontal = !eixoVertical;
      String eixo = eixoVertical ? "Y" : "X";
      
      // Só aplica scroll no eixo correto
      if(list[1] != eixo) return;
      
      // Envia valor para movimentar scroll
      scrollMouse(usarHorizontal, usarHorizontal ? -valorReturn : valorReturn);
    } catch(e) {
      debugPrint('Erro em processarScroll: $e');
    }
  }


  // Adaptador principal para eventos do mouse via controle
  static dynamic mouseAdapt(String event) {
    try {
      // Atalhos de teclado
      if(event.contains("RT-") || event == "RT") return TecladoCtrl.aumentarVolume();
      if(event.contains("LT-") || event == "LT") return TecladoCtrl.diminuirVolume();
      if(event == "R3") return TecladoCtrl.abrirTecladoVirtual();
      if(event == "LB") return TecladoCtrl.previusPage();
      if(event == "RB") return TecladoCtrl.nextPage();
      if(event == "[LB-RB]") return debugPrint("SSSSSSSSSSSSSSSSSSS");
      if(event == "CIMA") return TecladoCtrl.teclaF11();
      if(event == "START") return clickDireito();
      if(event == "SELECT") return TecladoCtrl.pressWinTab();
      if(event == "1") {
        _mouseClickHold = clickHold(_mouseClickHold);
        return;
      }
      if(event == "2") return simularClique();
      if(event == "3") return TecladoCtrl.voltarNavegacao();
      if(event == "4") return TecladoCtrl.teclaWindows();
      if(event == "ST-SL") return TecladoCtrl.fecharAltF4();
      
      // Movimento do mouse
      if(event.contains("ANALOGICO ESQUERDO")) {
        processarMovimentoMouse(event);
        return;
      }
      
      // Scroll do mouse
      if(event.contains("ANALOGICO DIREITO")) {
        List<String> list = event.split(',');
        int valor = int.parse(list.last);
        
        // Altera eixo de scroll com movimento extremo
        if(valor.abs() > 30000 && list[1] == "X") _eixoScrolVertical = false;
        if(valor.abs() > 30000 && list[1] == "Y") _eixoScrolVertical = true;
        
        processarScroll(event, eixoVertical: _eixoScrolVertical);
        return;
      }
      
    } catch(e, stackTrace) {
      debugPrint('Erro em mouseAdapt: $e');
      debugPrint('StackTrace: $stackTrace');
    }
    return "";
  }

}


