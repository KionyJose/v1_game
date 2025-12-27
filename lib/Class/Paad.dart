// ignore_for_file: file_names, constant_identifier_names

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:v1_game/Class/TecladoCtrl.dart';
import 'package:v1_game/Controllers/SonsSistema.dart';
import 'package:xinput_gamepad/xinput_gamepad.dart';
import 'package:v1_game/Global.dart';

import '../Controllers/JanelaCtrl.dart';
import 'MouseCtrl.dart';
import 'bruta.dart';

class Paad with ChangeNotifier{
  // Constantes de configuração
  static const int ZONA_MORTA_MOUSE = 3000;
  static const int ZONA_MORTA_SCROLL = 4000;
  static const int MAX_VALOR_ANALOGICO = 32768;
  static const int VELOCIDADE_MIN_MOUSE = 1;
  static const int VELOCIDADE_MAX_MOUSE = 45;
  static const int VELOCIDADE_MIN_SCROLL = 15;
  static const int VELOCIDADE_MAX_SCROLL = 150;
  static const int THROTTLE_ANALOGICO_MS = 10; // Reduz chamadas do analógico
  
  final JanelaCtrl janelaCtrl;
  List<Controller> controlesAtivos = List.empty(growable: true);
  List<Controller> controlesBKP = List.empty(growable: true);
  String click = "";
  List<String> comandoSequencia = ["0","0","0","0","0"];
  bool blockClick = false;
  bool delay = false;
  bool comandoAtivo = true;
  bool isMouse = false;
  bool padPs = true;
  
  // Throttle para analógicos
  // DateTime? _ultimoMovimentoMouse;
  // DateTime? _ultimoScroll;

  Paad({required bool escutar, required this.janelaCtrl}){
    if(escutar) escutaPaadsAsync();
    RawInputGamepad.escutarBotaoGuide((evento) => escutaClickPaad(evento));
    RawInputGamepad.escutarBotoesDualSense((botao, press) => press == padPs ? escutaClickPaad(botao) : null);
    RawInputGamepad.escutarAnalogicosDualSense((stick, x, y, valorX, valorY) {
      if(!padPs) return;
      escutaClickPaad("$stick,X,$valorX");
      escutaClickPaad("$stick,Y,$valorY");
    });
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
    if(event == "GUIDE") return voltarAoSistema();
    
    addSequencia(event);
    if(delay) return;
    if(isMouse) return MouseCtrl.mouseAdapt(event);
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
    if(event == ""|| !comandoAtivo)return;
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
    // Verifica qualquer uma das sequências de voltar tela
    if(_verificarSequencia(configSistema.sequenciaVoltarTela1) ||
       _verificarSequencia(configSistema.sequenciaVoltarTela2)) {
      voltarAoSistema();
    }
  }
  voltarAoSistema(){
    try{
    janelaCtrl.telaPresaReverse(estado: true, usarEstado: true);
    }catch(e){
      debugPrint("Erro ao voltar ao sistema: $e");
    }
    JanelaCtrl.restoreWindow();
    SonsSistema.cheat();
    delay = true;
    Timer(const Duration(microseconds: 1245), () => delay = false);     
  }
  mouseMoov(){
    // Verifica qualquer uma das sequências de ativar mouse
    if(_verificarSequencia(configSistema.sequenciaAtivaMouse1) ||
       _verificarSequencia(configSistema.sequenciaAtivaMouse2) ||
       _verificarSequencia(configSistema.sequenciaAtivaMouseCustom)) {
      ativaMouse();
    }
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
    // SELECT + SELECT + A + A + A (configurável)
    if(_verificarSequencia(configSistema.sequenciaEnter)){
      TecladoCtrl.teclaEnter();      
      SonsSistema.pim();
    }
  }
  
  teclaEspaco(){
    // SELECT + SELECT + Y + Y + Y (configurável)
    if(_verificarSequencia(configSistema.sequenciaEspaco)){
      TecladoCtrl.teclaEnter();
      SonsSistema.pim();
    }
  }


  // Função para verificar sequências de comandos de forma genérica
  bool _verificarSequencia(List<String> sequenciaEsperada) {
    if (comandoSequencia.length < sequenciaEsperada.length) return false;
    for (int i = 0; i < sequenciaEsperada.length; i++) {
      if (comandoSequencia[i] != sequenciaEsperada[i]) return false;
    }
    return true;
  }

  
  escutaPaadsAsync(){
    debugPrint("Procurando controles");
    List<Controller> listCtrl = List.empty(growable: true);
    XInputManager.enableXInput(); // usando pugin xinput_gamepad
    
    for (int controllerIndex in ControllersManager.getIndexConnectedControllers()) {
      final Controller controller = Controller(index: controllerIndex, buttonMode: ButtonMode.PRESS);

      
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