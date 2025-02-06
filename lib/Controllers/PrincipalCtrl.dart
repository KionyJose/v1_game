// ignore_for_file: file_names, use_build_context_synchronously
// // ignore_for_file: file_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:v1_game/Class/TickerProvider.dart';
import 'package:v1_game/Controllers/MovimentoSistema.dart';
import 'package:v1_game/Controllers/PastaCtl.dart';

import '../Bando de Dados/db.dart';
import '../Modelos/IconeInicial.dart';
import '../Widgets/Pops.dart';

class PrincipalCtrl with ChangeNotifier{

  
  int indexFcs = 0;
  late List<FocusNode> focusNodeIcones;
  List<IconInicial> listIconsInicial = [];
  FocusNode focoPrincipal = FocusNode();
  DB db = DB();
  String keyPressed = '';
  int selectedIndex = 0;
  FocusScopeNode focusScope = FocusScopeNode();
  double positionX = 0;
  double positionY = 0;
  // PastaCtrl pastaCtrl = PastaCtrl();

  bool stateTela = true;
  bool telaIniciada = false;

  String imgFundoStr = "";

  

  bool isWindowFocused = true;

  
  late AnimationController ctrlAnimeBgFundo;
  late Animation<double> scaleAnimation;
  late bool showNewImage = false;
  attTela() => notifyListeners();
  late BuildContext ctx;
  // late Notificacao notf;

  PrincipalCtrl(this.ctx,){
    iniciaTela();
  }

  @override
  dispose(){
    debugPrint("SAIU PAGE CTRL");
    super.dispose();    
    // focoPrincipal.dispose();
    // for (var node in focusNodeIcones) {
    //   node.dispose();
    // }
    // listViewFocus.dispose();    
    // ctrlAnimeBgFundo.dispose();
  }

  

  onFocusChange(bool hasFocus, int index){ 
    if (hasFocus) {
      debugPrint("FOCO ATT");
      showNewImage = !showNewImage;
      if(listIconsInicial.isNotEmpty) imgFundoStr = listIconsInicial[index].imgStr;                          
      selectedIndex = index;
      Future.delayed(const Duration(milliseconds: 1), () { 
        // debugPrint("Entriiiiii");
        showNewImage = true;
        // attTela();
      });
    }
  }

   iniciaTela() async {
    animaFundo();
    listIconsInicial = await db.leituraDeDados();
    if(listIconsInicial.isEmpty) focusNodeIcones = [FocusNode()];
    if(listIconsInicial.isNotEmpty)focusNodeIcones = List.generate(listIconsInicial.length, (index) => FocusNode());
    
    telaIniciada = true;
    attTela();
  }

  animaFundo(){
    ctrlAnimeBgFundo = AnimationController(
      duration: const Duration(seconds: 20),
      vsync:  MyTickerProvider(),
    );

    scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(ctrlAnimeBgFundo);

    ctrlAnimeBgFundo.repeat(reverse: true);
  }

  btnEntrar() async {
    if(listIconsInicial.isEmpty) return btnMais();
    await db.openFile(listIconsInicial[selectedIndex].local);
  }

  btnMais() async {
    stateTela = false;
    // PAD paad = pad;
    String retorno = await Pops().popMenuTelHome2(ctx);
    // if(retorno == null || retorno.isEmpty) return;
    debugPrint(retorno);
    
    if (retorno == "Caminho do game" || retorno == "Imagem de capa" || retorno == "Add") {
      await PastaCtrl(ctx).navPasta(ctx, "", retorno, listIconsInicial, selectedIndex);
      iniciaTela();
    }
    if (retorno == "Excluir Card") {
      var result = await Pops().msgSN(ctx, "Confirmar ação?");
      if(result ==  null) return;
      if(result == "Sim"){
        listIconsInicial.removeAt(selectedIndex);
        await db.attDados(listIconsInicial);
      }
      iniciaTela();
    }
    stateTela = true;
    // attTela();
  }

   escutaPad(String event) async {
    try{
      if(!stateTela || event == "") return;
      debugPrint("Click Paad: $event" );
      debugPrint("=======   Escuta Principal  =======");
      verificaFocoJanela();
      if (!isWindowFocused) return;
      Movimentosistema.direcaoListView(focusScope, event);
      if (event == "START") {
        //START
        btnMais();
      }
      if (event == "2") {
        //Entrar
        btnEntrar();
      }
      // attTela();
      
    }catch(erro){
      debugPrint(erro.toString());
    }
  }

  
  keyPress(KeyEvent event) async {
    if (event is KeyDownEvent) {
      debugPrint("Teclado Press: ${event.logicalKey.debugName}");
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
        focusScope.focusInDirection(TraversalDirection.up);
      } else if (event.logicalKey == LogicalKeyboardKey.keyA) {
        focusScope.focusInDirection(TraversalDirection.left);
      } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
        focusScope.focusInDirection(TraversalDirection.down);
      } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
        focusScope.focusInDirection(TraversalDirection.right);
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