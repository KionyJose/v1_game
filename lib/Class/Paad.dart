// ignore_for_file: file_names

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:xinput_gamepad/xinput_gamepad.dart';

class Paad with ChangeNotifier{

  List<Controller> controlesAtivos = List.empty(growable: true);
  String click = "";
  bool blockClick = false;
  bool pressionando = false;

  Paad({required bool escutar}){
    if(escutar) escutaPaadsAsync();
  }
  attSequencia() {
    notifyListeners();
    if (click == "") return;
    debugPrint("passei");
    Timer(const Duration(milliseconds: 100), () => attSequencia());
    
  }
  

  escutaClickPaad(String event) async {
    click = event;
    notifyListeners();
    // attSequencia();
    // Timer(const Duration(milliseconds: 1000), () {
    
      // });
    // }

    

    // pressionando = true;
    // if(event==""){
    //   blockClick = false;
    //   pressionando = false;
    //   click = event;
    //   return notifyListeners();
    // }
    // debugPrint("clicandoo");
    // if(blockClick) {
    //   debugPrint("BLoqueado");
    //   return; // Bloqueia múltiplos cliques em alta frequência
    // }

    // click = event;
    // blockClick = true;
    // notifyListeners();
    // Timer(const Duration(milliseconds: 1000), () {
    //   if(!pressionando){
    //     blockClick = false;
    //   }
    // });
  }


  escutaPaadsAsync(){
    debugPrint("Procurando controles");
    List<Controller> listCtrl = List.empty(growable: true);
    int totalPads = 0;
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
      };
      controller.variableKeysMapping = {
        VariableControllerKey.LEFT_TRIGGER: (value) => escutaClickPaad("LT - $value"),
        VariableControllerKey.RIGHT_TRIGGER: (value) => escutaClickPaad("RT - $value"),


        VariableControllerKey.THUMB_LX: (value) => escutaClickPaad("ANALOGICO ESQUERDO X - $value"),
        VariableControllerKey.THUMB_LY: (value) => escutaClickPaad("ANALOGICO ESQUERDO Y - $value"),
        VariableControllerKey.THUMB_RX: (value) => escutaClickPaad("ANALOGICO DIREITO X - $value"),
        VariableControllerKey.THUMB_RY: (value) => escutaClickPaad("ANALOGICO DIREITO Y - $value")
      };
      // Detectar soltura de botões
      controller.onReleaseButton = (button) => escutaClickPaad("");

      listCtrl.add(controller);
      
      
    }

    for (Controller controller in listCtrl) {
      controller.listen();
    }
    
    
    if(controlesAtivos.length != listCtrl.length){
      controlesAtivos = List.empty(growable: true);
      controlesAtivos.addAll(listCtrl);
      notifyListeners();
    }
    Future.delayed(const Duration(seconds: 5), () => escutaPaadsAsync());
  }
  

  // Simula um método para pegar os controles conectados, adaptando conforme sua API
  List<int> getControlesConectados() {
    return ControllersManager.getIndexConnectedControllers();
  }

  escutaPaadsAsyncBKP(){
    debugPrint("Procurando controles");
    int totalPads = 0;
    XInputManager.enableXInput();// usando pugin xinput_gamepad
    try{
      totalPads = controlesAtivos.length;    
    }catch(erro){
      controlesAtivos = List.empty(growable: true);
    }
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
      };
      controller.variableKeysMapping = {
        VariableControllerKey.LEFT_TRIGGER: (value) => escutaClickPaad("LT - $value"),
        VariableControllerKey.RIGHT_TRIGGER: (value) => escutaClickPaad("RT - $value"),


        VariableControllerKey.THUMB_LX: (value) => escutaClickPaad("ANALOGICO ESQUERDO X - $value"),
        VariableControllerKey.THUMB_LY: (value) => escutaClickPaad("ANALOGICO ESQUERDO Y - $value"),
        VariableControllerKey.THUMB_RX: (value) => escutaClickPaad("ANALOGICO DIREITO X - $value"),
        VariableControllerKey.THUMB_RY: (value) => escutaClickPaad("ANALOGICO DIREITO Y - $value")
      };
      // Detectar soltura de botões
      controller.onReleaseButton = (button) => escutaClickPaad("");

      controlesAtivos.add(controller);
      
      
    }

    for (Controller controller in controlesAtivos) {
      controller.listen();
    }
    if(controlesAtivos.length != totalPads) notifyListeners();
    Future.delayed(const Duration(seconds: 5), () => escutaPaadsAsync());
    
    
    
  }


}