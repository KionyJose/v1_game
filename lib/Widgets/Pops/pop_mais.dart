import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/MovimentoSistema.dart';

class PopMais {
  
  static mais(BuildContext context) async {    
    List<String> commandos = [];
    try{
    bool statePop = true;
    String retorno = "";
    int total = 9; // 9 botões/nodes: de str0 até str7 + botão extra (índices 0-8)
    FocusScopeNode focusScope = FocusScopeNode();
    String str0 = "busca";
    String str1 = "Caminho do game";
    String str2 = "Caminho de Imagem";
    String str3 = "Imagem da Download";
    String str4 = "Atalhos";
    String str5 = "Excluir Card";
    String str6 = "Add";
    String str7 = "Cfg";

    List<FocusNode> focusNodes = List.generate(total, (value)=> FocusNode());


    comandos(BuildContext context, String event){
      int total = 0;
      if(commandos.length == 2){
        commandos.removeAt(0);
        commandos.add(event);
        if(commandos[0] == "SELECT")total++;
        if(commandos[1] == "SELECT")total++;
        if(total == 2) Navigator.pop(context, "");
        if(total == 2) return false;
      }
      commandos.add(event);
      return true;
    }

    escutaPad(String event) {
      if(!statePop || event =="") return;
      debugPrint("=======   Escuta Pop Menu  =======");

      statePop = comandos(context, event);
      

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
        if (focusNodes[5].hasFocus) Navigator.pop(context, str5);
        if (focusNodes[6].hasFocus) Navigator.pop(context, str6);
        if (focusNodes[7].hasFocus) Navigator.pop(context, str7);
        // if (focusNodes.length > 8 && focusNodes[8].hasFocus) Navigator.pop(context, str0);
        statePop = true;
      }
    }
    

    btnM(String str, FocusNode focus, IconData ico) {
      return Flexible(
        flex: 1,
        // padding: const EdgeInsets.symmetric(vertical: 6),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6.0),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              color: Colors.black38,
              height: 40,
              child: MaterialButton(
                padding: EdgeInsets.zero,
                  focusNode: focus,
                  autofocus: str == str0 ? true : focus.hasFocus,
                  focusColor: Colors.white70,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(ico,color: Colors.white),
                    ],
                  ),
                  onPressed: () => Navigator.pop(context, str)),
            ),
          ),
        ),
      );
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
                      if (focusNodes[5].hasFocus) Navigator.pop(context, str5);                    
                      if (focusNodes[6].hasFocus) Navigator.pop(context, str6);                   
                      if (focusNodes[7].hasFocus) Navigator.pop(context, str7);
                      // if (focusNodes.length > 8 && focusNodes[8].hasFocus) Navigator.pop(context, str0);
                    }
                    debugPrint(event.logicalKey.toString());
                  }
                },
                child: AlertDialog(
                  
                  backgroundColor: Colors.transparent,
                  contentPadding: const EdgeInsets.only(left: 8, right: 8, bottom: 4),
                  content: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      color: Colors.white70,
                      child: Container(
                          // container da Tela ====================================
                          color: Colors.black38,
                          // height: MediaQuery.of(context).size.height * 0.55,
                          width: MediaQuery.of(context).size.width * 0.17,
                          child: FocusScope(
                            // autofocus: true,
                            node: focusScope,
                            child: Builder(builder: (_) {
                              // Constrói lista dinâmica de botões para calcular altura
                              final List<Widget> optionButtons = [
                                // btn(str0, focusNodes[0], false, null),
                                btn(str1, focusNodes[1], false, null),
                                btn(str2, focusNodes[2], false, null),
                                btn(str3, focusNodes[3], false, null),
                                btn(str4, focusNodes[4], false, null),
                                btn(str5, focusNodes[5], false, null),
                              ];

                              // Medidas aproximadas (ajustáveis) por item e áreas fixas
                              const double itemHeight = 56.0; // inclui padding
                              const double headerHeight = 84.0; // título e espaçamento
                              const double footerHeight = 80.0; // botões inferiores

                              double totalHeight = optionButtons.length * itemHeight + headerHeight + footerHeight;
                              double maxHeight = MediaQuery.of(context).size.height * 0.8;
                              double containerHeight = totalHeight > maxHeight ? maxHeight : totalHeight;

                              return SizedBox(
                                height: containerHeight,
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
                                  const SizedBox(height: 14),
                                  // botões principais
                                  ...optionButtons,
                                  const SizedBox(height: 6),
                                  const Text('Adicionar jogos e configurações',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      )),
                                  // botões inferiores em uma linha
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 8, right: 8, left: 8, top: 8),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        btnM(
                                          str6,
                                          focusNodes[6],
                                          Icons.add,
                                        ),
                                        btnM(
                                          str0,
                                          focusNodes[0],
                                          Icons.search,
                                        ),
                                        btnM(
                                          str7,
                                          focusNodes[7],
                                          Icons.settings,
                                        ),
                                      ],
                                    ),
                                  ),
                                  // const SizedBox(height: 10),
                                ]),
                              );
                            }),
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
}