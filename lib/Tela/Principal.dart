// ignore_for_file: use_build_context_synchronously, file_names
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:v1_game/Bando%20de%20Dados/db.dart';
import 'package:v1_game/Controllers/PastaCtl.dart';
import 'package:v1_game/Modelos/IconeInicial.dart';
import 'package:v1_game/Widgets/Pops.dart';
import 'package:v1_game/Widgets/cardGame.dart';



class Principal extends StatefulWidget {
  const Principal({super.key, required this.title});

  final String title;

  @override
  State<Principal> createState() => _PrincipalState();
}

class _PrincipalState extends State<Principal> {
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

  
  @override
  void initState() {
    iniciaTela();
    super.initState();    
    // iniciaTeste();
    // LerArquivo().lerDados();
  }

  @override
  void dispose() {
    focoPrincipal.dispose();
    for (var node in focusNodeSetas) {
      node.dispose();
    }
    listViewFocus.dispose();
    super.dispose();
  }
  
  iniciaTela()async {    
    listIconsInicial = await db.leituraDeDados();
    focusNodeSetas = List.generate(listIconsInicial.length, (index) => FocusNode());    
    listViewFocus.previousFocus();
    setState(() {});
  }

  keyPress(KeyEvent event) async {
    if (event is KeyDownEvent) {
            
            debugPrint(event.logicalKey.debugName);
            if(event.logicalKey == LogicalKeyboardKey.digit2){//entrar
              db.openFile(listIconsInicial[selectedIndex].local);
            }
            if(event.logicalKey == LogicalKeyboardKey.digit3){//sair
              //  db.openFile("D:\\GAMES\\HOGWARTS LEGACY\\Hogwarts Legacy\\Phoenix\\Binaries\\Win64\\HogwartsLegacy.exe");
              //openFile("C:\\Users\\Public\\Documents\\Bingo Grandioso\\BingoPresencial.exe");
            }

            if(event.logicalKey == LogicalKeyboardKey.enter){//Menu
              String retorno = await Pops().popMenuTelHome(context,listViewFocus);
              debugPrint(retorno);
              if(retorno == "Caminho do game" || retorno == "Imagem de capa" ){
                await pastaCtrl.navPasta(context,"",retorno, listIconsInicial, selectedIndex );
                iniciaTela();
              }
            }  

            if (event.logicalKey == LogicalKeyboardKey.keyW) {
              listViewFocus.focusInDirection(TraversalDirection.up);
            } else if (event.logicalKey == LogicalKeyboardKey.keyA ) {
              listViewFocus.focusInDirection(TraversalDirection.left );
            } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
              listViewFocus.focusInDirection(TraversalDirection.down);
            } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
              listViewFocus.focusInDirection(TraversalDirection.right);
            }
            
          }
  }
  
  

  @override
  Widget build(BuildContext context) {

    return KeyboardListener(
      includeSemantics: false,
      focusNode: focoPrincipal,
      autofocus: false,
      onKeyEvent: (KeyEvent event) async => await keyPress(event),
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SizedBox(
          height: MediaQuery.of(context).size.width * 0.15 ,
          // width: 600,
          child: FocusScope(
            onFocusChange: (value)  {
              debugPrint("object");
            },
            // autofocus: true,
            node: listViewFocus,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 30,vertical: 10),
              // gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                // crossAxisCount: 5,
              // ),
            itemCount: listIconsInicial.length,
            itemBuilder: (context, index) {
              return Focus(
                autofocus: indexFcs == 0 ? true : false,
                focusNode: focusNodeSetas[index],
                onFocusChange: (hasFocus) {
                  setState(() {
                    if (hasFocus) {
                      selectedIndex = index;
                    }
                  });
                },
                child: GestureDetector(
                  onTap: () async{
                    debugPrint('Container $index clicado!');
                    try{
                      pastaCtrl.navPasta(context,"","", listIconsInicial, selectedIndex );
                      // LerArquivo().leituraDeDados("");
                      // openFile("C:\\Users\\Public\\Documents\\Bingo Grandioso\\BingoPresencial.exe");
                      debugPrint('Abrindoo.......');
                    }catch(e){
                      debugPrint(e.toString());
                    }
                  },
          
                  child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  margin: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 20.0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    gradient: LinearGradient(
                      colors: [
                        Colors.pinkAccent.withOpacity( 1.0 ),
                        Colors.blue.withOpacity(1.0 ),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.pink,
                        offset: const Offset(-2, 0),
                        blurRadius: selectedIndex == index ? 30 : 10,
                      ),
                      BoxShadow(
                        color: Colors.blue,
                        offset: const Offset(2, 0),
                        blurRadius: selectedIndex == index ? 30 : 10,
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
                      width: selectedIndex == index ? MediaQuery.of(context).size.width * 0.21 : MediaQuery.of(context).size.width * 0.13,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: const Color(0xFF000515),
                      ),
                      duration: const Duration(milliseconds: 100),
                      child: 
                      CardGame(
                        iconInitial: listIconsInicial[index],
                        focus:  selectedIndex == index,
                      ),
                      // Text(
                      //   listIconsInicial[index].nome,
                      //   style:const  TextStyle(color: Colors.white),
                      // ),
                    ),
                  ),
                ),
          
                ),
              );
            },
                ),
          ),
        ),


        floatingActionButton: FloatingActionButton(
          onPressed: (){},
          tooltip: 'Increment',
          child: const Icon(Icons.add),
        ), 
      ),
    );
  }


  teclasPRess(){
    
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