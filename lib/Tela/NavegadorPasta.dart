// ignore_for_file: file_names, avoid_print, use_build_context_synchronously, must_be_immutable

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/MovimentoSistema.dart';
import 'package:v1_game/Controllers/PastaCtl.dart';
import 'package:v1_game/Modelos/Item.dart';
import 'package:v1_game/Widgets/LoadWid.dart';

class NavPasta extends StatefulWidget {
  const NavPasta({super.key});

  @override
  State<NavPasta> createState() => _NavPastaState();
}

class _NavPastaState extends State<NavPasta> {

  @override
  Widget build(BuildContext context) {
    
    return ChangeNotifierProvider(
      create: (context) => PastaCtrl(context), // Cria o controlador aqui
      child: Consumer<PastaCtrl>(
        builder: (context,ctrl,child) {
          // ctrl.ctx = context;
          // WidgetsBinding.ins tance.addPostFrameCallback((_) => ctrl.focusScope = ctrl.gridViewFocus2); 
          return escutas(ctrl);
        }
      ),
    );
  }
  escutas(PastaCtrl ctrl){
    return KeyboardListener(
      child: escutaPadWid(ctrl),
      focusNode: FocusNode(),
      onKeyEvent: (KeyEvent event) {
        if (event is KeyDownEvent) {            
          Movimentosistema.direcaoListView(ctrl.focusScope, event.logicalKey.keyLabel);            
          if(event.logicalKey == LogicalKeyboardKey.digit2){//entrar
            // openFile("C:\\Users\\Public\\Documents\\Bingo Grandioso\\BingoPresencial.exe");
            ctrl.btnEntrar();
          }
          if(event.logicalKey == LogicalKeyboardKey.digit3){//sair
            //openFile("C:\\Users\\Public\\Documents\\Bingo Grandioso\\BingoPresencial.exe");
            ctrl.clickVoltar();
          }        
          if(event.logicalKey == LogicalKeyboardKey.digit5){//L1
            //openFile("C:\\Users\\Public\\Documents\\Bingo Grandioso\\BingoPresencial.exe");
            ctrl.gridViewFocus1.requestFocus();
            ctrl.focusScope = ctrl.gridViewFocus1;
          }
          if(event.logicalKey == LogicalKeyboardKey.digit6){//R1
            //openFile("C:\\Users\\Public\\Documents\\Bingo Grandioso\\BingoPresencial.exe");
            ctrl.gridViewFocus2.requestFocus();
            ctrl.focusScope = ctrl.gridViewFocus2;
          }            
        }
      },
    );
  }

  escutaPadWid(PastaCtrl ctrl){
    return Selector<Paad, String>(
      selector: (context, paad) => paad.click, // Escuta apenas click
      builder: (context, valorAtual, child) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ctrl.escutaPad(valorAtual); 
        });
          
        return ctrl.load ? const LoadingIco() : body(ctrl);
      },
    );
  }

  body(PastaCtrl ctrl){
    return Container(// container da Tela ====================================
      color: Colors.white70,
      height: MediaQuery.of(context).size.height * 0.90,
      width: MediaQuery.of(context).size.width * 0.90,
      child:   Column(
        children: [
          FittedBox (child:  Text("Navegando ${ctrl.listCaminho.last }",style: const TextStyle(fontSize: 20),)),
          Flexible(
            flex: 30,
            child: Row(
              children: [
                ladoEsquerdo(ctrl),
                espacamento(),
                ladoDireito(ctrl),
              ],
            ),
          ),
        ],
      ),
    );
  }

  espacamento(){
    return Padding(
      padding: const EdgeInsets.only(left: 3,right: 3),
      child: Container(
        color: Colors.black,
        height: 1200,
        width: 2,
      ),
    );
  }

  ladoEsquerdo(PastaCtrl ctrl){
    return SizedBox(        
      width: 150,
      height: 800,    
      child: FocusScope(
        node: ctrl.gridViewFocus1,
        child: ListView.builder(
          scrollDirection: Axis.vertical,
          padding: const EdgeInsets.only(left: 5),
          itemCount: ctrl.unidades.length,
          itemBuilder: (context, index) {    
            String name = "Disco ${ctrl.unidades[index]}";
            if(0 == index) name = "Area Trabalho";    
            return Focus(
              focusNode: ctrl.focusNodeSetas1[index],
              onFocusChange: (hasFocus) => ctrl.selectItemEsquerdo(hasFocus,index),
              child: GestureDetector(
                onTap: null,
                child: arquivo(ctrl, index,name, context, ctrl.selectedIndex1)
              ),
            );
          },
        ),
      ),
    );
  }
  ladoDireito(PastaCtrl ctrl){
    return Flexible(
      child: Stack(
        children: [                              
          listItemsList(ctrl),                              
          fotoAux(ctrl)
        ],
      ),
    );
  }

  

  listItemsList(PastaCtrl ctrl){
    return Container(
      color: Colors.black38,
      child: FocusScope(
        node: ctrl.gridViewFocus2,
        child: ListView.builder(
          itemCount: ctrl.items.length,
          itemBuilder: (context, index) {      
            return Focus(
            focusNode: ctrl.focusNodeSetas2[index],
            onFocusChange: (hasFocus) => ctrl.selectItemDireito(hasFocus, index),
            child: GestureDetector(
              onTap:  null,
              child: widListItem(ctrl, index, ctrl.items[index],context,ctrl.selectedIndex2)
              ));
          },
        ),
      ),
    );
  }
  widListItem(PastaCtrl ctrl, int index, Item item, BuildContext context ,int selectedIndex){
    Color corFinal = ctrl.gridViewFocus2 == ctrl.focusScope ? Colors.black54 : Colors.white24;
    return Container(
      padding: const EdgeInsets.only(left: 10),
      color: selectedIndex == index ?  corFinal : Colors.transparent,
      height: 40, 
      child: Row(
        children: [
          item.icone,const SizedBox(width: 10),
          Text("${item.nome}${item.extencao.isEmpty ? "" : "."}${item.extencao}",style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }


  fotoAux(PastaCtrl ctrl){
    return Padding(
      padding: const EdgeInsets.only(right: 15,top: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Container(
            // color: Colors.white10,
            decoration: ctrl.caminhoExiste() ?   BoxDecoration(
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
              image: FileImage(File(ctrl.imgLoadPreview),))
            ) : const BoxDecoration(color: Colors.transparent),
            width: MediaQuery.of(context).size.width * 0.23,
            height: MediaQuery.of(context).size.width * 0.23,
          ),
        ],
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
  arquivo(PastaCtrl ctrl,int index, String name, BuildContext context ,int selectedIndex){
    Color corFinal = ctrl.gridViewFocus1 == ctrl.focusScope ? Colors.black87.withOpacity(0.7) : Colors.black45;
    return FittedBox(
      child: Padding(
        padding: const EdgeInsets.all(5),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(30),
          child: Container(
            color: selectedIndex == index ?  corFinal : Colors.transparent,
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