// ignore_for_file: file_names, use_build_context_synchronously
// // ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/PastaCtl.dart';

import '../Bando de Dados/db.dart';
import '../Modelos/IconeInicial.dart';
import '../Widgets/Pops.dart';

class PrincipalCtrl{

  
  int indexFcs = 0;
  late List<FocusNode> focusNodeSetas;
  List<IconInicial> listIconsInicial = [];
  FocusNode focoPrincipal = FocusNode();
  DB db = DB();
  String keyPressed = '';
  int selectedIndex = 0;
  FocusScopeNode listViewFocus = FocusScopeNode();
  double positionX = 0;
  double positionY = 0;
  PastaCtrl pastaCtrl = PastaCtrl();

  bool stateTela = true;
  Paad pad = Paad();

  String imgFundoStr = "";

  

  bool isWindowFocused = true;

  
  late AnimationController ctrlAnimeBgFundo;
  late Animation<double> scaleAnimation;
  late bool showNewImage;
  late final Function() attTela;
  late BuildContext ctx;

  PrincipalCtrl(BuildContext context, this.attTela){
    ctx = context;
    iniciaTela();
  }

  dispose(){
    
    focoPrincipal.dispose();
    for (var node in focusNodeSetas) {
      node.dispose();
    }
    listViewFocus.dispose();
    
    ctrlAnimeBgFundo.dispose();
  }

  

  onFocusChange(bool hasFocus, int index){ 
    if (hasFocus) {
      showNewImage = !showNewImage;
      imgFundoStr = listIconsInicial[index].imgStr;                          
      selectedIndex = index;
      Future.delayed(const Duration(milliseconds: 1), () { 
        debugPrint("Entriiiiii");
        showNewImage = true;
        attTela();
      });
    }
  }

   iniciaTela() async {
    listIconsInicial = await db.leituraDeDados();
    focusNodeSetas = List.generate(listIconsInicial.length, (index) => FocusNode());
    attTela();
  }

  btnEntrar() async {
    await db.openFile(listIconsInicial[selectedIndex].local);
  }

  btnMais() async {
    stateTela = false;
    // PAD paad = pad;
    String retorno = await Pops().popMenuTelHome(ctx, pad);
    debugPrint(retorno);
    if (retorno == "Caminho do game" || retorno == "Imagem de capa" || retorno == "Add") {
      await pastaCtrl.navPasta(ctx, pad, "", retorno, listIconsInicial, selectedIndex);
      iniciaTela();
    }
    stateTela = true;
  }

   escutaPad(String event) async {
    // subscription = Gamepads.events.listen((GamepadEvent event) {
    verificaFocoJanela();
    // default pov 65535.0
    // esquerda pov 27000.0
    // direita pov 9000.0
    // cima pov 0.0
    // baixo pov 18000.0
    // QUADRADO = 1
    // XIS = 2
    // BOLA = 3
    // TRIANGULO = 4
    // L1 = 4
    // R1 = 5
    // L2 = 6
    // R2 = 7
    // SELECT = 8
    // START = 9
    if (!stateTela) return;
    if (!isWindowFocused) return;
    debugPrint("=======   Escuta Principal  =======");
    if (event == "ESQUERDA") {
      //ESQUERDA
      listViewFocus.focusInDirection(TraversalDirection.left);
    }
    if (event == "DIREITA") {
      //DIREITA
      listViewFocus.focusInDirection(TraversalDirection.right);
    }
    if (event == "CIMA") {
      //CIMA
      listViewFocus.focusInDirection(TraversalDirection.up);
    }
    if (event == "BAIXO") {
      //BAIXO
      listViewFocus.focusInDirection(TraversalDirection.down);
    }
    if (event == "START") {
      //START
      btnMais();
    }
    if (event == "2") {
      //Entrar
      btnEntrar();
    }

    // setState(() {
    // debugPrint("${event.key}  ::  ${event.value}");
    // final newEvents = [ event,..._lastEvents,];
    // if (newEvents.length > 3) {
    //   newEvents.removeRange(3, newEvents.length);
    // }
    // _lastEvents = newEvents;
    // });
    // });
  }

  
  keyPress(KeyEvent event) async {
    if (event is KeyDownEvent) {
      debugPrint(event.logicalKey.debugName);
      if (event.logicalKey == LogicalKeyboardKey.digit2) {
        //entrar
        btnEntrar();
      }
      if (event.logicalKey == LogicalKeyboardKey.digit3) {
        //sair
        //  db.openFile("D:\\GAMES\\HOGWARTS LEGACY\\Hogwarts Legacy\\Phoenix\\Binaries\\Win64\\HogwartsLegacy.exe");
        //openFile("C:\\Users\\Public\\Documents\\Bingo Grandioso\\BingoPresencial.exe");
      }

      if (event.logicalKey == LogicalKeyboardKey.enter) {
        //Menu
        btnMais();
      }

      if (event.logicalKey == LogicalKeyboardKey.keyW) {
        listViewFocus.focusInDirection(TraversalDirection.up);
      } else if (event.logicalKey == LogicalKeyboardKey.keyA) {
        listViewFocus.focusInDirection(TraversalDirection.left);
      } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
        listViewFocus.focusInDirection(TraversalDirection.down);
      } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
        listViewFocus.focusInDirection(TraversalDirection.right);
      }
    }
  }

  
  verificaFocoJanela() {
    // ignore: deprecated_member_use
    final appWindow = WidgetsBinding.instance.window;
    final visible = appWindow.viewInsets.bottom == 0;
    isWindowFocused = visible;
  }



  // keyPress(KeyEvent event) async {
  //   if (event is KeyDownEvent) {
            
  //           debugPrint(event.logicalKey.debugName);
  //           if(event.logicalKey == LogicalKeyboardKey.digit2){//entrar
  //             db.openFile(listIconsInicial[selectedIndex].local);
  //           }
  //           if(event.logicalKey == LogicalKeyboardKey.digit3){//sair
  //             //  db.openFile("D:\\GAMES\\HOGWARTS LEGACY\\Hogwarts Legacy\\Phoenix\\Binaries\\Win64\\HogwartsLegacy.exe");
  //             //openFile("C:\\Users\\Public\\Documents\\Bingo Grandioso\\BingoPresencial.exe");
  //           }

  //           if(event.logicalKey == LogicalKeyboardKey.enter){//Menu
  //             String retorno = await Pops().popMenuTelHome(context,listViewFocus);
  //             debugPrint(retorno);
  //             if(retorno == "Caminho do game" || retorno == "Imagem de capa" ){
  //               await pastaCtrl.navPasta(context,"",retorno, listIconsInicial, selectedIndex );
  //               iniciaTela();
  //             }
  //           }

  //           if (event.logicalKey == LogicalKeyboardKey.keyW) {
  //             listViewFocus.focusInDirection(TraversalDirection.up);
  //           } else if (event.logicalKey == LogicalKeyboardKey.keyA ) {
  //             listViewFocus.focusInDirection(TraversalDirection.left );
  //           } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
  //             listViewFocus.focusInDirection(TraversalDirection.down);
  //           } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
  //             listViewFocus.focusInDirection(TraversalDirection.right);
  //           }
            
  //         }
  

}