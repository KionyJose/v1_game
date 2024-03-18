// ignore_for_file: file_names, avoid_print, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:v1_game/Controllers/PastaCtl.dart';
import 'package:v1_game/Metodos/leituraArquivo.dart';
import 'package:v1_game/Modelos/Item.dart';
import 'package:v1_game/Widgets/Pops.dart';

class NavPasta extends StatefulWidget {
  const NavPasta({super.key});

  @override
  State<NavPasta> createState() => _NavPastaState();
}

class _NavPastaState extends State<NavPasta> {

  String imgLoadPreview = "";
  String caminhoFinal = "";
  List<String> listCaminho = [];
      
  FocusScopeNode gridViewFocus1 = FocusScopeNode();
  FocusScopeNode gridViewFocus2 = FocusScopeNode();
  late FocusScopeNode gridFocoAtual;

  List<FocusNode> focusNodeSetas1 = List.generate(200, (index) => FocusNode());
  List<FocusNode> focusNodeSetas2 = List.generate(200, (index) => FocusNode());
  
  int selectedIndex1 = 0;  
  int selectedIndex2 = 0;

  PastaCtrl pastaCtrl = PastaCtrl();
  LerArquivos lerArquivos = LerArquivos();
  List<String> unidades = [];
  List<Item> items = [];

  @override
  void initState() {
    super.initState();
    iniciaTela();
  }

  iniciaTela()async { 
    gridFocoAtual = gridViewFocus2;
    
    unidades = lerArquivos.getUnidadesWindows();
    caminhoFinal = "${unidades[0]}:";
    listCaminho.add(caminhoFinal);
    items = await lerArquivos.lerDadosPasta("C:");
    setState(() {
      
    });

  }

  click() async {

    
    
    if(gridFocoAtual == gridViewFocus1){
      caminhoFinal = "${unidades[selectedIndex1]}:";
      items = await lerArquivos.lerDadosPasta(caminhoFinal);
      if(caminhoFinal != listCaminho.last ) listCaminho.add(caminhoFinal);
      setState(() {});
    }
    if(gridFocoAtual == gridViewFocus2){
      // String brs = "\\";
      caminhoFinal = items[selectedIndex2].caminho;

      if(items[selectedIndex2].pasta == false){
        return Pops().msgSN(context, "Definir este caminho?", () {
          List<String> listAux = listCaminho.last.split('\\');
          String caminho = "";
          for (var item in listAux) {
            caminho += "$item\\\\";
          }
          Navigator.pop(context);
          Navigator.pop(context,["caminho", items[selectedIndex2].url ? caminhoFinal : caminho + caminhoFinal]);
        });
      }


      
      items = await lerArquivos.lerDadosPasta(caminhoFinal);      
      if(caminhoFinal != listCaminho.last ) listCaminho.add(caminhoFinal);
      setState(() {});
      
    }

  }
  clickVoltar() async {
    
    if(listCaminho.last.length < 4) return Navigator.pop(context);
    listCaminho.removeLast();
    caminhoFinal = listCaminho.last;
    items = await lerArquivos.lerDadosPasta(caminhoFinal);   
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return KeyboardListener(
      focusNode: FocusNode(),      
      onKeyEvent: (KeyEvent event) {
          if (event is KeyDownEvent) {
            print(event.logicalKey);
            // Verifica a tecla pressionada
            print(event.logicalKey);
            
            if(event.logicalKey == LogicalKeyboardKey.digit2){//entrar
              // openFile("C:\\Users\\Public\\Documents\\Bingo Grandioso\\BingoPresencial.exe");
              click();
            }
            if(event.logicalKey == LogicalKeyboardKey.digit3){//sair
              //openFile("C:\\Users\\Public\\Documents\\Bingo Grandioso\\BingoPresencial.exe");
              clickVoltar();
            }

            if(event.logicalKey == LogicalKeyboardKey.digit5){//L1
              //openFile("C:\\Users\\Public\\Documents\\Bingo Grandioso\\BingoPresencial.exe");
              gridViewFocus1.requestFocus();
              gridFocoAtual = gridViewFocus1;
            }
            if(event.logicalKey == LogicalKeyboardKey.digit6){//R1
              //openFile("C:\\Users\\Public\\Documents\\Bingo Grandioso\\BingoPresencial.exe");
              gridViewFocus2.requestFocus();
              gridFocoAtual = gridViewFocus2;
            }
            // if (event.logicalKey == LogicalKeyboardKey.arrowLeft) {      
            if (event.logicalKey == LogicalKeyboardKey.keyW) {
              gridFocoAtual.focusInDirection(TraversalDirection.up);
            } else if (event.logicalKey == LogicalKeyboardKey.keyA) {
              gridFocoAtual.focusInDirection(TraversalDirection.left );
            } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
              gridFocoAtual.focusInDirection(TraversalDirection.down);
            } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
              gridFocoAtual.focusInDirection(TraversalDirection.right);
            }
            
          }
        },
      child: Container(// container da Tela ====================================
        color: Colors.white70,
        height: MediaQuery.of(context).size.height * 0.90,
        width: MediaQuery.of(context).size.width * 0.90,
        child:  Column(
          children: [            
            const FittedBox (
              child:  Text("Navegando nos arquivos",style: TextStyle(fontSize: 20),)),
            Flexible(
              flex: 30,
              child: Row(
                children: [
                  SizedBox(        
                    width: 150,
                    height: 800,
                    // color: Colors.black87,
        
                    child: FocusScope(
                      node: gridViewFocus1,
                      child: ListView.builder(
                        scrollDirection: Axis.vertical,
                        padding: const EdgeInsets.only(left: 5),
                        itemCount: unidades.length,
                        itemBuilder: (context, index) {
    
                          return Focus(
                            focusNode: focusNodeSetas1[index],
                            onFocusChange: (hasFocus) {
                              setState(() {
                                if (hasFocus) {
                                  selectedIndex1= index;
                                }
                              });
                            },
                            child: GestureDetector(
                              onTap: () async{
                                print('Container $index clicado!');
                                try{
                                  print('Abrindoo.......');
                                }catch(e){
                                  print(e.toString());
                                }
                              },
    
                              child: arquivo(index,"Disco ${unidades[index]}", context,selectedIndex1)
                              ));     
                        },
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 3,right: 3),
                    child: Container(
                      color: Colors.black,
                      height: 1200,
                      width: 2,
                    ),
                  ),
                  Flexible(
                    child: Stack(
                      children: [
                        
                          listItemsList(),
                        
                        Padding(
                          padding: const EdgeInsets.only(right: 15,top: 20),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Container(
                                // color: Colors.white10,
                                decoration: File(imgLoadPreview).existsSync() ?   BoxDecoration(
                                  borderRadius: BorderRadius.circular(25),
                                  boxShadow: const [
                                     BoxShadow(
                                      color: Colors.white60,
                                      blurRadius: 30,
                                      spreadRadius: 11
                                    ),
                                  ],
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: FileImage(File(imgLoadPreview),))
                                ) : const BoxDecoration(color: Colors.transparent),
                                width: MediaQuery.of(context).size.width * 0.23,
                                height: MediaQuery.of(context).size.width * 0.23,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  listItemsList(){
    return Container(
      color: Colors.black38,
      child: FocusScope(
        node: gridViewFocus2,
        child: ListView.builder(
          // gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            // crossAxisCount: 5,
          // ),
          itemCount: items.length,
          itemBuilder: (context, index) {
      
            return Focus(
            focusNode: focusNodeSetas2[index],
            onFocusChange: (hasFocus) {
              setState(() {
                if (hasFocus) {
                  selectedIndex2= index;
                  String extencao = items[index].extencao.toUpperCase();
                  if(extencao == "JPG"  || extencao == "PNG" ||  extencao == "JPEG"|| extencao == "WEBP"|| extencao == "GIF" || extencao == "BMP" ) {
                    List<String> listAux = listCaminho.last.split('\\');
                    String caminho = "";
                    for (var item in listAux) {
                      caminho += "$item\\\\";
                    }
                    imgLoadPreview = caminho + items[index].caminho;

                  }else{ imgLoadPreview = "";}
                }
              });
            },
            child: GestureDetector(
              onTap: () async{
                print('Container $index clicado!');
                try{
                  print('Abrindoo.......');
                }catch(e){
                  print(e.toString());
                }
              },
      
              child: widListItem(index, items[index],context,selectedIndex2)
              ));
          },
                    
          
        ),
      ),
    );
  }
  widListItem(int index, Item item, BuildContext context ,int selectedIndex){
    return Container(
      padding: const EdgeInsets.only(left: 10),
      color: selectedIndex == index ?  Colors.black54 : Colors.transparent,
      height: 40, 
      child: Row(
        children: [
          item.icone,const SizedBox(width: 10),
          Text(item.nome + item.extencao,style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  listItemsItem(){
    return Flexible(
      child: Container(
        color: Colors.black38,
        child: FocusScope(
          node: gridViewFocus2,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 5,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
  
              return Focus(
              focusNode: focusNodeSetas2[index],
              onFocusChange: (hasFocus) {
                setState(() {
                  if (hasFocus) {
                    selectedIndex2= index;
                  }
                });
              },
              child: GestureDetector(
                onTap: () async{
                  print('Container $index clicado!');
                  try{
                    print('Abrindoo.......');
                  }catch(e){
                    print(e.toString());
                  }
                },
  
                child: widItem(index, items[index],context,selectedIndex2)
                ));
            },
                      
            
          ),
        ),
      ),
    );
  }
  

  widItem(int index, Item item, BuildContext context ,int selectedIndex){
    return FittedBox(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            color: selectedIndex == index ?  Colors.black54 : Colors.transparent,
            height: 90,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                item.icone,                
                Container(
                  width: 100,
                  padding: const EdgeInsets.only(left: 5,right: 5),
                  child: Center(
                    child: Text(item.nome ,style: const TextStyle(color: Colors.white))),
                ),
                
              ],
            ),
          ),
        ),
      ),
    );
  }

  // popScren(Widget tela) {
  arquivo(int index, String name, BuildContext context ,int selectedIndex){
    return FittedBox(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            color: selectedIndex == index ?  Colors.black54 : Colors.transparent,
            height: 90,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.folder,color: Colors.white,),
                Container(
                  width: 100,
                  padding: const EdgeInsets.only(left: 5,right: 5),
                  child: Center(
                    child: Text(name,style: const TextStyle(color: Colors.white))),
                ),
                
              ],
            ),
          ),
        ),
      ),
    );
  }
}