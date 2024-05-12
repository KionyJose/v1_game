// ignore_for_file: use_build_context_synchronously, file_names
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:v1_game/Controllers/PrincipalCtrl.dart';
import 'package:v1_game/Widgets/cardGame.dart';

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key, required this.title});

  final String title;

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> with WidgetsBindingObserver {

  late PrincipalCtrl ctrl;
  atualizaTela(){}
  void atualizarTela() => setState((){});

  @override
  void initState() {
    super.initState();
    ctrl = PrincipalCtrl(context, atualizaTela);
    ctrl.showNewImage = false;

    WidgetsBinding.instance.addObserver(this);
    ctrl.iniciaTela();
    ctrl.pad.recebeDados(ctrl.escutaPad);

    ctrl.ctrlAnimeBgFundo = AnimationController(
      duration: const Duration(seconds: 20),
      vsync:  MyTickerProvider(),
    );

    ctrl.scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(ctrl.ctrlAnimeBgFundo)
      ..addListener(() {
        setState(() {});
      });

    ctrl.ctrlAnimeBgFundo.repeat(reverse: true);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint(state.name);
    if (state == AppLifecycleState.hidden) {
      ctrl.isWindowFocused = false;
    } else {
      ctrl.isWindowFocused = true;
    }
  }

  @override
  void dispose() {
    ctrl.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  } 
  

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      includeSemantics: false,
      focusNode: ctrl.focoPrincipal,
      autofocus: false,
      onKeyEvent: (KeyEvent event) async => ctrl.keyPress(event),
      child: scaffold()
    );
  }
  scaffold(){
    return Scaffold(
      backgroundColor: Colors.black,
      body: body(),
      floatingActionButton: floatBtns(),
    );
  }
  body(){
    return Stack(
      children: [
        backGorundfade(),
        Padding(
          padding: const EdgeInsets.only(top: 20),
          child: FocusScope(
            onFocusChange: (value) => debugPrint(value.toString()),
            node: ctrl.listViewFocus,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 10),
              itemCount: ctrl.listIconsInicial.length,
              itemBuilder: (context, index) {
                return Focus(
                  autofocus: ctrl.indexFcs == 0 ? true : false,
                  focusNode: ctrl.focusNodeSetas[index],
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
                    child:Column(
                      children: [
                        cardAnimado(index),
                        // if (ctrl.selectedIndex == index)
                        // textoBaixoCard(index)
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),        
      ],
    );
  }
  textoBaixoCard(int index){
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
  cardAnimado(int index){
    return AnimatedContainer(
      constraints: const BoxConstraints(
        minHeight: 200,
        minWidth: 200,
      ),
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.only( left: 20, right: 20, top: 20),
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
          width: ctrl.selectedIndex == index ? MediaQuery.of(context).size.width * 0.15 : MediaQuery.of(context).size.width * 0.04,
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
  

  backGroundAnimado(){
    return AnimatedBuilder(
      animation: ctrl.ctrlAnimeBgFundo,
      builder: (context, child) {
        return Transform.scale(
          scale: ctrl.scaleAnimation.value,
          child: Container(
            width: double.maxFinite,
            height: double.maxFinite,
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.5),
              borderRadius: BorderRadius.circular(50),
            ),
            child: imagemFundo(),
          ),
        );
      },
    );
  }
  
  imagemFundo() {
    return Container(
      decoration: File(ctrl.imgFundoStr).existsSync() ? BoxDecoration( image: DecorationImage(fit: BoxFit.cover, image 
      : FileImage( File(ctrl.imgFundoStr),)))
      : const BoxDecoration(color: Colors.transparent),
      height: 200,
      width: 135,
      // child: focus ? Center(child: Text(iconInitial.nome,style: const TextStyle(fontSize: 25,color: Colors.white),)) : Container()
    );
  }

  backGorundfade(){
    return AnimatedOpacity(
      opacity: ctrl.showNewImage ? 1.0 : 0.0,
      duration: !ctrl.showNewImage ?  const Duration(microseconds: 0) :  const Duration(seconds: 1),
      child: backGroundAnimado()
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

class MyTickerProvider extends TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}
