// ignore_for_file: use_build_context_synchronously, file_names, deprecated_member_use
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/PrincipalCtrl.dart';
import 'package:v1_game/Widgets/cardGame.dart';

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key, required this.title});

  final String title;

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> with WidgetsBindingObserver {

  // late PrincipalCtrl ctrl;
  EdgeInsetsGeometry cardMargin = const EdgeInsets.only(left: 5, right: 5, top: 20);
  
  // void atualizarTela() => setState((){});

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);// en teste!
  }

  

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // debugPrint(state.name);
    if (state == AppLifecycleState.hidden) {
      // ctrl.isWindowFocused = false;
    } else {
      // ctrl.isWindowFocused = true;
    }
  }

  @override
  void dispose() {
    debugPrint("SAIU PAGE PAGE");
    // ctrl.dispose();
    // WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  } 
  
  

  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider(
      create: (context) => PrincipalCtrl(context), // Cria o controlador aqui
      // dispose: (context, ctrl) => ctrl.dispose(), // Remove o controlador quando sair
      child: Consumer<PrincipalCtrl>(
        builder: (context, ctrl, child) {
          debugPrint("object =========================");
          ctrl.ctx = context;
          return KeyboardListener( // Escuta teclado Press;
            includeSemantics: false,
            focusNode: ctrl.focoPrincipal,
            autofocus: false,
            onKeyEvent: (KeyEvent event) => ctrl.keyPress(event),
            child: escutaPadWid(ctrl)
          );
        },
      ),
    );
  }

  escutaPadWid(PrincipalCtrl ctrl){
    return Selector<Paad, String>(
      selector: (context, paad) => paad.click, // Escuta apenas click
      builder: (context, valorAtual, child) {
        // Aguardando o próximo frame para chamar o showDialog
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ctrl.escutaPad(valorAtual);  // Isso pode chamar o showDialog
        });
        return scaffold(ctrl);
      },
    );
  }
  scaffold(PrincipalCtrl ctrl){
    return Scaffold(
      backgroundColor: Colors.black,
      body: body(ctrl),
      floatingActionButton: floatBtns(),
    );
  }
  body(PrincipalCtrl ctrl){
    return Stack(
      children: [
        backGroundAnimado(ctrl),
        if(ctrl.telaIniciada)
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: FocusScope(
            onFocusChange: (value) => debugPrint("--------------------------------***-----------------------------"),
            node: ctrl.focusScope,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              itemCount: ctrl.focusNodeIcones.length,
              itemBuilder: (context, index) {
                if (index >= ctrl.focusNodeIcones.length) {
                  return Container(); // Retorna um placeholder ou nada
                }
                return Focus(
                  autofocus: ctrl.indexFcs == 0 ? true : false,
                  focusNode: ctrl.focusNodeIcones[index],
                  onFocusChange: (hasFocus) => ctrl.onFocusChange(hasFocus, index),
                  child: GestureDetector(
                    onTap: () async {
                      try {
                        debugPrint('Container $index clicado!');
                        await ctrl.btnMais();
                      } catch (e) {
                        debugPrint(e.toString());
                      }
                    },
                    child: Column(
                      children: [
                        if(ctrl.listIconsInicial.isNotEmpty) cardAnimado(ctrl, index),
                        if(ctrl.listIconsInicial.isEmpty) cardAnimadoAdd(ctrl, index)
                      ],
                    ) ,
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }
  textoBaixoCard(PrincipalCtrl ctrl,int index){
    return Center(
      child: Text(
        ctrl.listIconsInicial[index].nome,
        style: const TextStyle(
          fontSize: 25,
          color: Colors.white,
          shadows: [
            Shadow(
              blurRadius: 5,
              color: Colors.black
            ),
          ]
        ),
      )
    );
  }
  cardAnimado(PrincipalCtrl ctrl,int index){
    return AnimatedContainer(
      constraints: const BoxConstraints(
        minHeight: 175,
        minWidth: 175,
      ),
      duration: const Duration(milliseconds: 200),
      margin: cardMargin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Colors.pinkAccent.withOpacity(1.0),
            Colors.blue.withOpacity(1.0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pink,
            offset: const Offset(-2, 0),
            blurRadius: ctrl.selectedIndex == index ? 30 : 10,
          ),
          BoxShadow(
            color: Colors.blue,
            offset: const Offset(2, 0),
            blurRadius: ctrl.selectedIndex == index ? 30 : 10,
          ),
        ],
      ),
      child: MouseRegion(
        onEnter: (event) {
          // onHover(index, true);
        },
        onExit: (value) {
          // onHover(index, false);
        },
        child: AnimatedContainer(
          width: ctrl.selectedIndex == index ? MediaQuery.of(context).size.width * 0.18 : MediaQuery.of(context).size.width * 0.04,
          height: ctrl.selectedIndex == index ? MediaQuery.of(context).size.width * 0.25 : MediaQuery.of(context).size.width * 0.05,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: const Color(0xFF000515),
          ),
          duration: const Duration(milliseconds: 100),
          child: CardGame(
            iconInitial: ctrl.listIconsInicial[index],
            focus: ctrl.selectedIndex == index,
          ),
        ),
      ),
    );
  }
  cardAnimadoAdd(PrincipalCtrl ctrl, int index){
    return AnimatedContainer(
      constraints: const BoxConstraints(
        minHeight: 175,
        minWidth: 175,
      ),
      duration: const Duration(milliseconds: 200),
      margin: cardMargin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Colors.pinkAccent.withOpacity(1.0),
            Colors.blue.withOpacity(1.0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pink,
            offset: const Offset(-2, 0),
            blurRadius: ctrl.selectedIndex == index ? 30 : 10,
          ),
          BoxShadow(
            color: Colors.blue,
            offset: const Offset(2, 0),
            blurRadius: ctrl.selectedIndex == index ? 30 : 10,
          ),
        ],
      ),
      child: MouseRegion(
        onEnter: (event) {
          // onHover(index, true);
        },
        onExit: (value) {
          // onHover(index, false);
        },
        child: AnimatedContainer(
          width: MediaQuery.of(context).size.width * 0.12 ,
          height: MediaQuery.of(context).size.width * 0.12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: const Color(0xFF000515),
          ),
          duration: const Duration(milliseconds: 100),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage( fit: BoxFit.cover, image: AssetImage('assets/BGICOdefault.png'),
              ),),
              height: 200,
              width: 135,
              child: const FittedBox(child: Icon(Icons.add,color: Colors.white,))
              )
          ),
        ),
      ),
    );
  }

  floatBtns(){
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),                  
              color: Colors.white54,
            ),
            height: 40,
            width: 40,
            child: const FittedBox(
              child: Text("◼",textAlign: TextAlign.center,style:  TextStyle(fontSize: 20)
                
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),                  
              color: Colors.white54,
            ),
            height: 40,
            width: 40,
            child: const FittedBox(
              child: Text("▲",textAlign: TextAlign.center,style:  TextStyle(fontSize: 20)
                
              ),
            ),
          ),
        ),Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),                  
              color: Colors.white54,
            ),
            height: 40,
            width: 40,
            child: const Center(
              child: Text("◯", textAlign: TextAlign.center,style:  TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                
              ),
            ),
          ),
        ),Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),                  
              color: Colors.white54,
            ),
            height: 40,
            width: 40,
            child: const Center(
              child: Text("✕",textAlign: TextAlign.center,style:  TextStyle(fontSize: 20,fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ),
      ],
    );
  }
  

  backGroundAnimado(PrincipalCtrl ctrl){
    return AnimatedBuilder( // crece Container e diminui.
      animation: ctrl.ctrlAnimeBgFundo,
      builder: (context, child) {
        return AnimatedOpacity( // Anima A Opacidade.
          opacity: ctrl.showNewImage ? 1.0 : 0.0,
          duration: !ctrl.showNewImage ?  const Duration(microseconds: 0) :  const Duration(seconds: 1),
          child: Transform.scale(
            scale: ctrl.scaleAnimation.value,
            child: Container(
              width: double.maxFinite,
              height: double.maxFinite,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.5),
                borderRadius: BorderRadius.circular(50),
              ),
              child: imagemFundo(ctrl),
            ),
          ),
        );
      },
    );
  }
  
  imagemFundo(PrincipalCtrl ctrl) {
    final item = BoxDecoration( image: DecorationImage( fit: BoxFit.cover, image: FileImage(File('assets/BGdefault.jpeg'),scale: 5)));
    if(ctrl.listIconsInicial.isEmpty){
      return Image.asset('assets/BGdefault.jpeg',
      fit: BoxFit.cover,
      );      
    }
    return Container(
      decoration: ctrl.imgFundoStr.isNotEmpty ? File(ctrl.imgFundoStr).existsSync() ? BoxDecoration( image: DecorationImage(fit: BoxFit.cover, image 
      : FileImage( File(ctrl.imgFundoStr),)))
      : item : item,
      // : const BoxDecoration(color: Colors.transparent),
      height: 200,
      width: 135,
      // child: focus ? Center(child: Text(iconInitial.nome,style: const TextStyle(fontSize: 25,color: Colors.white),)) : Container()
    );
  }

  
  teclasPRess() {
    // var key = navigatorKey.currentState.;
    // (event) {
    //   if (event is RawKeyDownEvent) {
    //     debugPrint('Tecla pressionada: ${event.logicalKey}');
    //   } else if (event is RawKeyUpEvent) {
    //     debugPrint('Tecla liberada: ${event.logicalKey}');
    //   }
    // }) as void Function();
  }
}


