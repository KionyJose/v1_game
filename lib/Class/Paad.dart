// ignore_for_file: file_names

import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:v1_game/Class/TecladoCtrl.dart';
import 'package:xinput_gamepad/xinput_gamepad.dart';

import '../Controllers/JanelaCtrl.dart';
import '../Controllers/MovimentoSistema.dart';
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
  final AudioPlayer audioPlayer = AudioPlayer();


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
    if(event == "SELECT"){
      // await audioPlayer.play(AssetSource("som_movimento.mp3")); // Caminho do asset
    }
    addSequencia(event);
    if(isMouse) return mouseAdapt(event);
    click = event;
    if(naTela() && !delay)notifyListeners();

    // X  10.000 >>  32.512
    // X -10.000 << -32.768
    // Y  10.000 ^^  32.768
    // Y -10.000 ↓↓ -32.512
  }
  attTela(){
    notifyListeners();
  }

  bool naTela(){
    bool value = false;
    final AppLifecycleState? estadoAtual = WidgetsBinding.instance.lifecycleState;
    if (estadoAtual == AppLifecycleState.resumed) {
      // debugPrint("O aplicativo está na frente (ativo).");
      value = true;
    } else if (estadoAtual == AppLifecycleState.inactive) {
      debugPrint(" ===== Aplicativo está INATIVO. =====");
      value = false;
    } else if (estadoAtual == AppLifecycleState.paused) {
      debugPrint("O aplicativo está em segundo plano (pausado).");
      value = false;
    } else {      
      debugPrint("ESTADO ALTERNATIVO:  $estadoAtual");
      value = true;
    }
    return value;
  }

  addSequencia(String event){    
    if(event == "")return;
    if(comandoSequencia.length == 5){
      comandoSequencia.removeAt(0);
      comandoSequencia.add(event);
      teclaEspaco();
      teclaEnter();
      verificaSequencia();
      mouseMoov();
    }else{        
      comandoSequencia.add(event);
    }
    // if(!isMouse)debugPrint("=--------------------  $comandoSequencia");
    
  }
  verificaSequencia(){
    int total = 0;
    // RestauraTela
    if(comandoSequencia[0] == "SELECT")total++;
    if(comandoSequencia[1] == "SELECT")total++;
    if(comandoSequencia[2] == "LB")total++;
    if(comandoSequencia[3] == "RB")total++;
    if(comandoSequencia[4] == "2")total++;
    if(total == 5) voltarAoSistema();
  }
  voltarAoSistema(){

    JanelaCtrl.restoreWindow("v1_game");
    MovimentoSistema.audioCheat();
    delay = true;
    // Provider.of<PrincipalCtrl>(ctx, listen: false).focusScope.requestFocus();
    Timer(const Duration(microseconds: 1245), () {

      delay = false;
      click = "HOME";
      notifyListeners();
      // click = "";
      // notifyListeners();
    });     
  }
  mouseMoov(){
    int total = 0;
    // RestauraTela
    if(comandoSequencia[0] == "SELECT")total++;
    if(comandoSequencia[1] == "SELECT")total++;
    if(comandoSequencia[2] == "LB")total++;
    if(comandoSequencia[3] == "RB")total++;
    if(comandoSequencia[4] == "4")total++;
    if(total == 5){
      isMouse = !isMouse;
      MovimentoSistema.audioCheat();
    }
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
      MovimentoSistema.audioPim();
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
      MovimentoSistema.audioPim();
    }
  }

  

  mouseAdapt(String event){
    try{
      if(event == "2") return MouseCtrl.simularClique();

      //Verifica e convert em valor pro mouse locomover na velocidade
      List<String> list = event.split(',');
      int valor = int.parse(list.last);
      bool negtv = valor.isNegative;
      valor += negtv ? (valor.abs() *2) : 0;
      int valorReturn = 0;
      // debugPrint("${list[1]}$valor");
      if(valor > 4000 && valor < 10000) valorReturn = negtv ? -1 : 1; 
      if(valor > 10000 && valor < 20000) valorReturn = negtv ? -5 : 5;        
      if(valor > 20000 && valor < 30000) valorReturn = negtv ? - 15 : 15;
      if(valor > 30000) valorReturn = negtv ? -35 : 35;
      int  xy = list[1] == "Y" ? valorReturn : valorReturn;
      String retorno ="${list[0]},${list[1]},$xy";
      debugPrint("  ${list[1]}  ==  $xy");
      mousecontroler(retorno);
      return retorno;
      
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
      final Controller controller = Controller(index: controllerIndex, buttonMode: ButtonMode. PRESS);
      
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
        { ControllerButton.LEFT_SHOULDER,ControllerButton.RIGHT_SHOULDER }: () => escutaClickPaad("[LB; RB]"),
        { ControllerButton.LEFT_THUMB, ControllerButton.RIGHT_THUMB}: () => escutaClickPaad("[L3; R3]"),
        { ControllerButton.LEFT_SHOULDER, ControllerButton.RIGHT_SHOULDER, ControllerButton.A_BUTTON }: () => escutaClickPaad("[LB; RB; A (2)]"),
        { ControllerButton.LEFT_SHOULDER,ControllerButton.RIGHT_SHOULDER,ControllerButton.A_BUTTON,ControllerButton.DPAD_DOWN }: () => escutaClickPaad("HOME"),
      };
      controller.variableKeysMapping = {
        VariableControllerKey.LEFT_TRIGGER: (value) => escutaClickPaad("LT - $value"),
        VariableControllerKey.RIGHT_TRIGGER: (value) => escutaClickPaad("RT - $value"),


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