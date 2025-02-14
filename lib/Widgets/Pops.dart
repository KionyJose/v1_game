// ignore_for_file: avoid_print, unused_local_variable, file_names, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';

import '../Bando de Dados/db.dart';
import '../Controllers/MovimentoSistema.dart';
import '../Modelos/IconeInicial.dart';
import '../Tela/NavegadorPasta.dart';

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

  popMenuTelHome2(BuildContext context) async {
    try{
    bool statePop = true;
    String retorno = "";

    List<FocusNode> focusNodes = [
      FocusNode(),
      FocusNode(),
      FocusNode(),
      FocusNode(),
      FocusNode()
    ];
    FocusScopeNode focusScope = FocusScopeNode();
    String str0 = "Abrir";
    String str1 = "Caminho do game";
    String str2 = "Imagem de capa";
    String str3 = "Excluir Card";
    String str4 = "Add";

    escutaPad(String event) {
      if(!statePop || event =="") return;
      debugPrint("=======   Escuta Pop Menu  =======");

      MovimentoSistema.direcaoListView(focusScope, event);

      if(event == "3"){//START
        statePop = false;
        Navigator.pop(context, "");
      }
      if(event == "2"){//Entrar
      debugPrint("======================================== $event SAINDOO");
        statePop = false;
        if (focusNodes[0].hasFocus) Navigator.pop(context, str0);
        if (focusNodes[1].hasFocus) Navigator.pop(context, str1);
        if (focusNodes[2].hasFocus) Navigator.pop(context, str2);
        if (focusNodes[3].hasFocus) Navigator.pop(context, str3);
        if (focusNodes[4].hasFocus) Navigator.pop(context, str4);
        statePop = true;
      }
    }
    





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
        builder: (_) {
          return Selector<Paad, String>(
            selector: (_, paad) => paad.click, // Escuta apenas click     
            builder: (_, valorAtual, child) {
              // WidgetsBinding.instance.addPostFrameCallback((_) {
                escutaPad(valorAtual);  // Isso pode chamar o showDialog
              // });
              return KeyboardListener(
                focusNode: FocusNode(),
                onKeyEvent: (KeyEvent event) {
                  if (event is KeyDownEvent) {
                    // Verifica a tecla pressionada
                    MovimentoSistema.direcaoListView(focusScope, event.logicalKey.keyLabel);
                    if (event.logicalKey == LogicalKeyboardKey.digit3) {
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
                      color: Colors.white.withOpacity(0.9),
                      child: Container(
                          // container da Tela ====================================
                          color: Colors.black38,
                          height: MediaQuery.of(context).size.height * 0.55,
                          width: MediaQuery.of(context).size.width * 0.17,
                          child: FocusScope(
                            // autofocus: true,
                            node: focusScope,
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
            }
          );
        }).then((value) => retorno = value.toString());

    return retorno;
    }catch(e){
      debugPrint(e.toString());
      // Pops().msgSimples(ctx,"ERRO = 1$e");
    }
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


  





  
  msgSN(BuildContext context, String str) async { 
    try{
      String retorno = "";  
      bool statePop = true; 
      List<FocusNode> focusNodes = [
        FocusNode(),
        FocusNode(),
      ];

      FocusScopeNode focusScope = FocusScopeNode();
      String str1 = "Sim";
      String str0 = "Nao";
      //teste1
      btn(String str, FocusNode focus) {
        return Padding(
          padding: const EdgeInsets.all(8.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              color: Colors.white70,
              height: 60,
              child: MaterialButton(
                  focusNode: focus,
                  autofocus: str == str0 ? true : focus.hasFocus,
                  focusColor: Colors.black45,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [ 
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 30),
                        child: Text(str,
                        style:  const TextStyle(
                          fontSize: 25,
                          color: Colors.black ,
                        )),
                      ),
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
        if(!statePop || event =="") return;
        debugPrint("=======   Escuta Pop S/N   =======");
        debugPrint("Click ==>>  $event");
        MovimentoSistema.direcaoListView(focusScope, event);
        if(event == "3"){//START
          statePop = false;
          Navigator.pop(context, "");
        }
        if(event == "2"){//Entrar
          statePop = false;
          if (focusNodes[0].hasFocus) Navigator.pop(context, str0);
          if (focusNodes[1].hasFocus) Navigator.pop(context, str1);
        }
      }

      await showDialog(
        context: context,
        builder: (_) => Selector<Paad, String>(
          selector: (_, paad) => paad.click, // Escuta apenas click      
          builder: (_, valorAtual, child) {
            escutaPad(valorAtual);         
            return KeyboardListener(
              //KeyboardListener
              focusNode: FocusNode(),
              onKeyEvent: (KeyEvent event) {
                if (event is KeyDownEvent) {
                  // Verifica a tecla pressionada
                  if (event.logicalKey == LogicalKeyboardKey.keyA) {
                    focusScope.focusInDirection(TraversalDirection.left);
                    debugPrint(event.logicalKey.toString());
                  } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
                    focusScope.focusInDirection(TraversalDirection.right);
                    debugPrint(event.logicalKey.toString());
                  } else if (event.logicalKey == LogicalKeyboardKey.digit3) {
                    statePop = false;
                    Navigator.pop(context, "");
                  } else if (event.logicalKey == LogicalKeyboardKey.digit2) {
                    statePop = false;
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
                child: Container(
                height: 250,
                width: 380,
                // decoration: decorationBOX,
                color: Colors.grey[300],
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(height: 15),
                    Flexible(
                      flex: 1,
                      child: Text(
                        str,
                        style: const TextStyle(fontSize: 25, color: Colors.black),
                        softWrap: true,
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const Spacer(),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: FocusScope(
                      // autofocus: true,
                      node: focusScope,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            btn(str0,focusNodes[0]),
                            btn(str1, focusNodes[1])
                          ],
                        ),
                      ),
                    ),
                  ],
                )),
              ),
            ));
          }
        ),
      ).then((value) => retorno = value.toString());
      return retorno;
    }catch(e){
      debugPrint(e.toString());
      debugPrint(e.toString());
    }
  }

  navPasta(BuildContext context,  String caminho, String tarefa, List<IconInicial> listiconIni, int index) async {    
    DB db = DB();
    try{
    var value = await showDialog(
      context: context, 
      builder: (context) => Pops().popScren(const NavPasta()),
    );
    if (value == null) return;
    if (value[0] == "caminho") {
      if(tarefa == "Caminho do game"){
        listiconIni[index].local = value[1];
        await db.attDados(listiconIni);
      }
      if(tarefa == "Imagem de capa"){
        listiconIni[index].imgStr = value[1];
        await db.attDados(listiconIni);
      }
      if(tarefa == "Add"){
        List<String> campos = [];

        String nome = value[1] as String;
        nome = nome.split('\\').last;
        nome = nome.split('.').first;
        
        if(value[2] != "") nome = value[2];

        campos.add("item-${listiconIni.length}");        
        campos.add("lugar: ${listiconIni.length}");        
        campos.add("nome: $nome");        
        campos.add("local: ${value[1]}");        
        campos.add("img: ");        
        campos.add("imgAux: caminho/.png");
        IconInicial ico = IconInicial(campos);
        // ico.local = value[1];

        listiconIni.add(ico);
        await db.attDados(listiconIni);
      }
    }
    if (value[0] == "alterado") {
      // saveObgrigatorio = true;
    } else {
      // saveObgrigatorio = false;
    }
    debugPrint("Finalizei navPasta dentro");
    }catch(e){
      debugPrint("Erro nav dentro = $e");
    }
  }
}
