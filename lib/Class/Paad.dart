// ignore_for_file: file_names

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:v1_game/Class/TecladoCtrl.dart';
import 'package:v1_game/Controllers/SonsSistema.dart';
import 'package:xinput_gamepad/xinput_gamepad.dart';

import '../Controllers/JanelaCtrl.dart';
import 'MouseCtrl.dart';

class Paad with ChangeNotifier{
  late BuildContext ctx;
  List<Controller> controlesAtivos = List.empty(growable: true);
  List<Controller> controlesBKP = List.empty(growable: true);
  String click = "";
  List<String> comandoSequencia = ["0","0","0","0","0"];
  bool blockClick = false;
  bool delay = false;
  bool isMouse = false;

  Paad({required bool escutar, required this.ctx}){
    if(escutar) escutaPaadsAsync();
  }


  attSequencia() {
    notifyListeners();
    if (click == "") return;
    debugPrint("passei");
    Timer(const Duration(milliseconds: 100), () => attSequencia());
    
  }
  
  escutaClickPaad(String event) async {
    // debugPrint(event);
    if(event == "SELECT"){
    }
    addSequencia(event);
    if(delay) return;
    if(isMouse) return mouseAdapt(event);
    click = event;
    if(await naTela() && !delay)notifyListeners();

    // X  10.000 >>  32.512
    // X -10.000 << -32.768
    // Y  10.000 ^^  32.768
    // Y -10.000 ↓↓ -32.512
  }
  attTela(){
    notifyListeners();
  }

 Future <bool> naTela() async {
    
    bool it =  await JanelaCtrl.janelaAtiva();
    if (!it) debugPrint(" ===== Aplicativo está INATIVO. =====");
    // if (it) debugPrint(" ===== NA TELA =====");
    return it;
  }

  addSequencia(String event){    
    if(event == "")return;
    if(comandoSequencia.length == 5){
      comandoSequencia.removeAt(0);
      comandoSequencia.add(event);
      teclaEspaco();
      teclaEnter();
      voltaTela();
      mouseMoov();
    }else{        
      comandoSequencia.add(event);
    }
    // if(!isMouse)debugPrint("=--------------------  $comandoSequencia");
    
  }
  voltaTela(){
    int total = 0;
    // RestauraTela
    if(comandoSequencia[0] == "SELECT" || comandoSequencia[0] == "START")total++;
    if(comandoSequencia[1] == "SELECT" || comandoSequencia[0] == "START")total++;
    if(comandoSequencia[2] == "LB")total++;
    if(comandoSequencia[3] == "RB")total++;
    if(comandoSequencia[4] == "2")total++;
    if(total == 5) voltarAoSistema();
  }
  voltarAoSistema(){

    JanelaCtrl.restoreWindow();
    SonsSistema.cheat();
    delay = true;
    // Provider.of<PrincipalCtrl>(ctx, listen: false).focusScope.requestFocus();
    Timer(const Duration(microseconds: 1245), () {

      delay = false;
      ativaMouse();
      // click = "HOME";
      // notifyListeners();
      // click = "";
      // notifyListeners();
    });     
  }
  mouseMoov(){
    int total = 0;
    // RestauraTela
    if(comandoSequencia[0] == "SELECT" || comandoSequencia[0] == "START")total++;
    if(comandoSequencia[1] == "SELECT" || comandoSequencia[0] == "START")total++;
    if(comandoSequencia[2] == "LB")total++;
    if(comandoSequencia[3] == "RB")total++;
    if(comandoSequencia[4] == "4")total++;
    if(total == 5) ativaMouse();
    
  }
  ativaMouse({bool usarEstado = false, bool estado = false}){
    if(usarEstado){
      isMouse = estado;
    }else{
      isMouse = !isMouse;      
    }
    delay = true;
    // Provider.of<PrincipalCtrl>(ctx, listen: false).focusScope.requestFocus();
    Timer(const Duration(microseconds: 1245), () => delay = false );   
    JanelaCtrl().telaPresa = isMouse;
    SonsSistema.cheat();
    MouseCtrl.primeiroMovimento();
  }

  teclaEnter(){
    int total = 0;
    // RestauraTela
    if(comandoSequencia[0] == "SELECT")total++;
    if(comandoSequencia[1] == "SELECT")total++;
    if(comandoSequencia[2] == "2")total++;
    if(comandoSequencia[3] == "2")total++;
    if(comandoSequencia[4] == "2")total++;
    if(total == 5){
      TecladoCtrl.teclaEnter();      
      SonsSistema.pim();
    }
  }
  teclaEspaco(){
    int total = 0;
    // RestauraTela
    if(comandoSequencia[0] == "SELECT")total++;
    if(comandoSequencia[1] == "SELECT")total++;
    if(comandoSequencia[2] == "4")total++;
    if(comandoSequencia[3] == "4")total++;
    if(comandoSequencia[4] == "4")total++;
    if(total == 5){
      TecladoCtrl.teclaEnter();
      SonsSistema.pim();
    }
  }

  abrirTecladoVitual(){
    // Ativar Mouse
    ativaMouse(usarEstado: true,  estado: true);
    TecladoCtrl.abrirTecladoVirtual(); 
  }

  
  bool mouseClickHold = false;
  bool eixoScrolYMouse = true;
  mouseAdapt(String event){
    try{
      
      if(event.contains("RT-")) TecladoCtrl.aumentarVolume();
      if(event.contains("LT-")) TecladoCtrl.diminuirVolume();
      if(event == "R3") return abrirTecladoVitual();
      if(event == "LB") return TecladoCtrl.previusPage();
      if(event == "RB") return TecladoCtrl.nextPage();
      if(event == "[LB-RB]") return debugPrint("SSSSSSSSSSSSSSSSSSS");
      if(event == "CIMA") return TecladoCtrl.teclaF11();
      if(event == "START") return MouseCtrl.clickDireito();      
      if(event == "SELECT") return TecladoCtrl.pressWinTab();
      if(event == "1") return mouseClickHold = MouseCtrl.clickHold(mouseClickHold);
      if(event == "2") return MouseCtrl.simularClique();
      if(event == "3") return TecladoCtrl.voltarNavegacao();
      // if(event == "3") return TecladoCtrl.teclaEsc();
      if(event == "4") return TecladoCtrl.teclaWindows();
      // if(event =="R3") return eixoScrolYMouse = !eixoScrolYMouse;
      if(event == "ST-SL") return TecladoCtrl.fecharAltF4();
      
      if(event.contains("ANALOGICO ESQUERDO")){
        //Verifica e convert em valor pro mouse locomover na velocidade
        List<String> list = event.split(',');
        int valor = int.parse(list.last);
        bool negtv = valor.isNegative;
        valor += negtv ? (valor.abs() *2) : 0;
        int valorReturn = 0;
        // debugPrint("${list[1]}$valor");
        if(valor > 2000 && valor < 10000) valorReturn = negtv ? -1 : 1; 
        if(valor > 10000 && valor < 20000) valorReturn = negtv ? -5 : 5;        
        if(valor > 20000 && valor < 30000) valorReturn = negtv ? - 15 : 15;
        if(valor > 30000) valorReturn = negtv ? -35 : 35;
        int  xy = list[1] == "Y" ? valorReturn : valorReturn;
        String retorno ="${list[0]},${list[1]},$xy";
        debugPrint("  ${list[1]}  ==  $xy");
        mousecontroler(retorno);
        return retorno;
      }
      if(event.contains("ANALOGICO DIREITO")){
        // Verifica e convert em valor pro Scrol do mouse locomover na velocidade
        // Define Variaveis usada no metodo ===========================
        List<String> list = event.split(',');
        int valor = int.parse(list.last);
        bool negtv = valor.isNegative;
        valor += negtv ? (valor.abs() *2) : 0;
        int valorReturn = 0;
        //=============================================================

        // Calcula Quanditade a Movimentar ============================
        if(valor > 4000 && valor < 10000) valorReturn = negtv ? -15 : 15; 
        if(valor > 10000 && valor < 20000) valorReturn = negtv ? -25 : 25;        
        if(valor > 20000 && valor < 30000) valorReturn = negtv ? - 145 : 145;
        if(valor > 30000) valorReturn = negtv ? -35 : 35;        
        //=============================================================
        
        // Altera Eixo de Scrol usando Tecla Alt =====================
        if(valor > 30000 && list[1] == "X") eixoScrolYMouse = false;
        if(valor > 30000 && list[1] == "Y") eixoScrolYMouse = true;
        String eixo = eixoScrolYMouse ? "Y" : "X";
        if(list[1] != eixo) return; // Caso eixo nao setado
        int  xy = list[1] == "Y" ? valorReturn : valorReturn;
        // if(eixo == "X")TecladoCtrl.pressionarShift();    
        //=============================================================

        // Envia Valor para Movimentar Scrol ==========================
        MouseCtrl.scrollMouse(eixo == "X" ,eixo == "X" ? -xy : xy);
        debugPrint("  ${list[1]}  ==  $xy");
        return;
        //=============================================================
      }
      
    }catch(_){}
    return "";
  }
  mousecontroler(String event){
    List<String> list = event.split(',');
    int dx = 0;
    int dy = 0;
    if(list[1]=="X") dx = int.parse(list.last);
    if(list[1]=="Y") dy = int.parse(list.last);
    MouseCtrl.moveCursor(dx, dy);
  }

  escutaPaadsAsync(){
    debugPrint("Procurando controles");
    List<Controller> listCtrl = List.empty(growable: true);
    XInputManager.enableXInput(); // usando pugin xinput_gamepad
    
    for (int controllerIndex in ControllersManager.getIndexConnectedControllers()) {
      final Controller controller = Controller(index: controllerIndex, buttonMode: ButtonMode.HOLD);

      
      controller.buttonsMapping = {
        // controller.vibrate(const Duration(seconds: 3));
        ControllerButton.A_BUTTON: () => escutaClickPaad("2"),
        ControllerButton.B_BUTTON: () => escutaClickPaad("3"),
        ControllerButton.X_BUTTON: () => escutaClickPaad("1"),
        ControllerButton.Y_BUTTON: () => escutaClickPaad("4"),
        ControllerButton.DPAD_UP: () => escutaClickPaad("CIMA"),
        ControllerButton.DPAD_DOWN: () => escutaClickPaad("BAIXO"),
        ControllerButton.DPAD_LEFT: () => escutaClickPaad("ESQUERDA"),
        ControllerButton.DPAD_RIGHT: () => escutaClickPaad("DIREITA"),
        ControllerButton.LEFT_SHOULDER: () => escutaClickPaad("LB"),
        ControllerButton.RIGHT_SHOULDER: () => escutaClickPaad("RB"),      
        ControllerButton.LEFT_THUMB: () => escutaClickPaad("L3"),
        ControllerButton.RIGHT_THUMB: () => escutaClickPaad("R3"),
        ControllerButton.START: () => escutaClickPaad("START"),
        ControllerButton.BACK: () => escutaClickPaad("SELECT"),
      };
      controller.buttonsCombination = {
        { ControllerButton.LEFT_SHOULDER,ControllerButton.RIGHT_SHOULDER }: () => escutaClickPaad("[LB-RB]"),
        { ControllerButton.START, ControllerButton.BACK} :() => escutaClickPaad("ST-SL"),
        { ControllerButton.LEFT_THUMB, ControllerButton.RIGHT_THUMB}: () => escutaClickPaad("[L3; R3]"),
        { ControllerButton.LEFT_SHOULDER, ControllerButton.RIGHT_SHOULDER, ControllerButton.A_BUTTON }: () => escutaClickPaad("[LB; RB; A (2)]"),
        { ControllerButton.LEFT_SHOULDER,ControllerButton.RIGHT_SHOULDER,ControllerButton.A_BUTTON,ControllerButton.DPAD_DOWN }: () => escutaClickPaad("HOME"),
      };
      controller.variableKeysMapping = {
        VariableControllerKey.LEFT_TRIGGER: (value) => escutaClickPaad("LT-$value"),
        VariableControllerKey.RIGHT_TRIGGER: (value) => escutaClickPaad("RT-$value"),


        VariableControllerKey.THUMB_LX: (value) => escutaClickPaad("ANALOGICO ESQUERDO,X,$value"),
        VariableControllerKey.THUMB_LY: (value) => escutaClickPaad("ANALOGICO ESQUERDO,Y,$value"),
        VariableControllerKey.THUMB_RX: (value) => escutaClickPaad("ANALOGICO DIREITO,X,$value"),
        VariableControllerKey.THUMB_RY: (value) => escutaClickPaad("ANALOGICO DIREITO,Y,$value")
      };
      // Detectar soltura de botões
      controller.onReleaseButton = (button) => escutaClickPaad("");

      listCtrl.add(controller);
      
      
    }

    
    
    
    if(controlesAtivos.length != listCtrl.length){
      for (int i =0 ; i < listCtrl.length; i++) {
        bool isAlreadyAdded = controlesBKP.any((ctrl) => ctrl.index == listCtrl[i].index);
        if (!isAlreadyAdded) {
          listCtrl[i].listen(); // Adiciona apenas se não foi adicionado ainda
          controlesBKP.add(listCtrl[i]);
        }
      }
      controlesAtivos = List.empty(growable: true);
      controlesAtivos.addAll(listCtrl);
      notifyListeners();
    }
    Future.delayed(const Duration(seconds: 5), () => escutaPaadsAsync());
  } 




}