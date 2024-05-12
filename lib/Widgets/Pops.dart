// ignore_for_file: avoid_print, unused_local_variable, file_names
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:v1_game/Class/Paad.dart';

class Pops {
  popScren(Widget tela) {
    return AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: const EdgeInsets.all(0),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: tela,
      ),
    );
  }

  popMenuTelHome(BuildContext context, Paad pad) async {
    bool statePop = true;
    String retorno = "";

    List<FocusNode> focusNodes = [
      FocusNode(),
      FocusNode(),
      FocusNode(),
      FocusNode(),
      FocusNode()
    ];
    FocusScopeNode listViewFocus = FocusScopeNode();
    String str0 = "Abrir";
    String str1 = "Caminho do game";
    String str2 = "Imagem de capa";
    String str3 = "Excluir Card";
    String str4 = "Add";

    escutaPad(String event) {
      if(!statePop) return;
      debugPrint("=======   Escuta Pop Menu  =======");
      if(event == "ESQUERDA"){//ESQUERDA
        listViewFocus.focusInDirection(TraversalDirection.left);
      }
      if(event == "DIREITA"){//DIREITA
        listViewFocus.focusInDirection(TraversalDirection.right);
      }
      if(event == "CIMA"){//CIMA
        listViewFocus.focusInDirection(TraversalDirection.up);
      }
      if(event == "BAIXO"){//BAIXO
        listViewFocus.focusInDirection(TraversalDirection.down);
      }
      if(event == "3"){//START
        statePop = false;
        Navigator.pop(context, "");
      }
      if(event == "2"){//Entrar
        statePop = false;
        if (focusNodes[0].hasFocus) Navigator.pop(context, str0);
        if (focusNodes[1].hasFocus) Navigator.pop(context, str1);
        if (focusNodes[2].hasFocus) Navigator.pop(context, str2);
        if (focusNodes[3].hasFocus) Navigator.pop(context, str3);
        if (focusNodes[4].hasFocus) Navigator.pop(context, str4);
      }
    }
    

    pad.recebeDados(escutaPad);




    btn(String str, FocusNode focus, bool iconActive, ico) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            color: Colors.black38,
            height: 40,
            child: MaterialButton(
                focusNode: focus,
                autofocus: str == str0 ? true : focus.hasFocus,
                focusColor: Colors.white70,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (iconActive) ico,
                    Text(str,
                        style: const TextStyle(
                          fontSize: 18,
                          color: Colors.white,
                        )),
                  ],
                ),
                onPressed: () => Navigator.pop(context, str)),
          ),
        ),
      );
    }

    await showDialog(
        context: context,
        builder: (context) {
          return KeyboardListener(
            //KeyboardListener
            focusNode: FocusNode(),
            onKeyEvent: (KeyEvent event) {
              if (event is KeyDownEvent) {
                // Verifica a tecla pressionada
                if (event.logicalKey == LogicalKeyboardKey.keyW) {
                  listViewFocus.focusInDirection(TraversalDirection.up);
                  debugPrint(event.logicalKey.toString());
                } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
                  listViewFocus.focusInDirection(TraversalDirection.down);
                  debugPrint(event.logicalKey.toString());
                } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
                  Navigator.pop(context, "");
                } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
                  if (focusNodes[0].hasFocus) Navigator.pop(context, str0);
                  if (focusNodes[1].hasFocus) Navigator.pop(context, str1);
                  if (focusNodes[2].hasFocus) Navigator.pop(context, str2);
                  if (focusNodes[3].hasFocus) Navigator.pop(context, str3);
                  if (focusNodes[4].hasFocus) Navigator.pop(context, str4);
                }
                debugPrint(event.logicalKey.toString());
              }
            },
            child: AlertDialog(
              
              backgroundColor: Colors.transparent,
              contentPadding:
                  const EdgeInsets.only(left: 8, right: 8, bottom: 4),
              content: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  color: Colors.white70,
                  child: Container(
                      // container da Tela ====================================
                      color: Colors.black38,
                      height: MediaQuery.of(context).size.height * 0.55,
                      width: MediaQuery.of(context).size.width * 0.17,
                      child: FocusScope(
                        // autofocus: true,
                        node: listViewFocus,
                        child: ListView(children: [
                          const SizedBox(height: 5),
                          const Center(
                              child: Text(
                            "Mais Opções",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          )),
                          const SizedBox(height: 20),
                          btn(str0, focusNodes[0], false, null),
                          btn(str1, focusNodes[1], false, null),
                          btn(str2, focusNodes[2], false, null),
                          btn(str3, focusNodes[3], false, null),
                          // const Spacer(),

                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              btn(
                                str4,
                                focusNodes[4],
                                true,
                                const Icon(
                                  Icons.add,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ]),
                      )),
                ),
              ),
            ),
          );
        }).then((value) => retorno = value.toString());

    return retorno;
  }

  msgSimples(BuildContext context, String str) async{
    return showDialog(
        context: context,
        builder: (_) => AlertDialog(
              backgroundColor: Colors.transparent,
              contentPadding: const EdgeInsets.all(0),
              content: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Container(
                    height: 200,
                    // decoration: decorationBOX,
                    color: Colors.green[300],
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                          height: 125,
                          width: double.maxFinite,
                          child: ListView(
                            children: [
                              const SizedBox(height: 15),
                              Text(str,style: const TextStyle(fontSize: 18, color: Colors.white),softWrap: true, textAlign: TextAlign.center,),
                            ],
                          ),
                        ),
                        SizedBox(
                          height: 70,
                          width: 250,
                          child: MaterialButton(
                            onPressed: ()  =>  Navigator.pop(context,"OK"),
                            child: const Text('OK',
                                style: TextStyle(
                                    fontSize: 25, color: Colors.white)),
                          ),
                        )
                      ],
                    )),
              ),
            ));
  }

  msgSN(BuildContext context,Paad pad, String str) async{
    return showDialog(
      context: context,
      builder: (_) => _msgSN(context,pad, str)
    );
  }
  
  _msgSN(BuildContext context,Paad pad, String str) async {   
    bool statePop = true; 
    List<FocusNode> focusNodes = [
      FocusNode(),
      FocusNode(),
    ];
    
    FocusScopeNode listViewFocus = FocusScopeNode();
    String str1 = "Sim";
    String str0 = "Nao";

    btn(String str, FocusNode focus) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            color: Colors.white70,
            height: 40,
            child: MaterialButton(
                focusNode: focus,
                autofocus: str == str0 ? true : focus.hasFocus,
                focusColor: Colors.black45,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [ 
                    Text(str,
                    style:  const TextStyle(
                      fontSize: 18,
                      color: Colors.black ,
                    )),
                  ],
                ),
                onPressed: () {                  
                    if (focusNodes[0].hasFocus) Navigator.pop(context, str0);
                    if (focusNodes[1].hasFocus) Navigator.pop(context, str1);
                } ),
          ),
        ),
      );
    }

    
    escutaPad(String event) {
      if(!statePop) return;
      debugPrint("=======   Escuta Msg SN  =======");
      if(event == "ESQUERDA"){//ESQUERDA        
        listViewFocus.focusInDirection(TraversalDirection.left);
      }
      if(event == "DIREITA"){//DIREITA        
        listViewFocus.focusInDirection(TraversalDirection.right);
      }
      if(event == "3"){//START
        statePop = false;
        Navigator.pop(context, "");
      }
      if(event == "2"){//Entrar
        // statePop = false;
        if (focusNodes[0].hasFocus) Navigator.pop(context, str0);;
        if (focusNodes[1].hasFocus) Navigator.pop(context, str1);
      }
    }
    

    pad.recebeDados(escutaPad);


    return KeyboardListener(
      //KeyboardListener
      focusNode: FocusNode(),
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {
          // Verifica a tecla pressionada
          if (event.logicalKey == LogicalKeyboardKey.keyA) {
            listViewFocus.focusInDirection(TraversalDirection.left);
            debugPrint(event.logicalKey.toString());
          } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
            listViewFocus.focusInDirection(TraversalDirection.right);
            debugPrint(event.logicalKey.toString());
          } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
            statePop = false;
            Navigator.pop(context, "");
          } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
            // statePop = false;
            if (focusNodes[0].hasFocus) Navigator.pop(context, str0);
            if (focusNodes[1].hasFocus) Navigator.pop(context, str1);
          }
        }
      },
      child: AlertDialog(
      backgroundColor: Colors.transparent,
      contentPadding: const EdgeInsets.all(0),
      content: ClipRRect(
        borderRadius: BorderRadius.circular(20),  
        child: FocusScope(
              // autofocus: true,
              node: listViewFocus,
              child: Container(
              height: 200,
              width: 200,
              // decoration: decorationBOX,
              color: Colors.grey[300],
              child: ListView(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          const SizedBox(height: 15),
                       Text(
                        str,
                        style: const TextStyle(fontSize: 18, color: Colors.black),
                        softWrap: true,
                        textAlign: TextAlign.center,
                      ),
                  
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            btn(str0,focusNodes[0],),
                            const SizedBox(width: 20),
                            btn(str1, focusNodes[1])
                          ],
                        ),
                      )
                      
                    ],
                  ),
                ],
              )),
        ),
      ),
    ),
          );
    
    
    
  }
}
