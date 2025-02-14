// ignore_for_file: file_names, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Bando%20de%20Dados/db.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/Notificacao.dart';
import 'package:v1_game/Tela/NavegadorPasta.dart';
import 'package:v1_game/Widgets/Pops.dart';

import '../Metodos/leituraArquivo.dart';
import '../Modelos/IconeInicial.dart';
import '../Modelos/Item.dart';
import 'MovimentoSistema.dart';

class PastaCtrl {
  DB db = DB();
  late BuildContext ctx;
  late final Function() attTela;

  
  String imgLoadPreview = "";
  String caminhoFinal = "";
  List<String> listCaminho = [];

  bool stateTela = false;
  bool load = true;
  bool loadArquivos = false;
      
  FocusScopeNode gridViewFocus1 = FocusScopeNode();
  FocusScopeNode gridViewFocus2 = FocusScopeNode();
  late FocusScopeNode focusScope;

  List<FocusNode> focusNodeSetas1 = List.generate(200, (index) => FocusNode());
  List<FocusNode> focusNodeSetas2 = List.generate(200, (index) => FocusNode());
  
  int selectedIndex1 = 0;  
  int selectedIndex2 = 0;

  LerArquivos lerArquivos = LerArquivos();
  List<String> unidades = [];
  List<Item> items = [];
  late Paad paad;




  PastaCtrl({required  this.ctx,  required this.attTela} ){
    iniciaTela();
    
  }
  
  disposeCtrl(){
    // paad.dispose();
    debugPrint("SAIU PASTA CTRL");
    // focoPrincipal.dispose();
    // for (var node in focusNodeIcones) {
    //   node.dispose();
    // }
    // listViewFocus.dispose();    
    // ctrlAnimeBgFundo.dispose();
  }

  iniciaEscutaPad()async {
      // Escutando mudanças no 'click' manualmente
    WidgetsBinding.instance.addPostFrameCallback((_) {
      paad = Provider.of<Paad>(ctx, listen: false);
      paad.addListener(() => escutaPad(paad.click));
    });
  }
  bool entrei = false;

  iniciaTela()async { 
    if(entrei)return;
    iniciaEscutaPad();

    entrei = true;
    // Configuração inicial e carregamento de dados
    unidades = lerArquivos.getUnidadesWindows();
    caminhoFinal = "${unidades[0]}:";
    listCaminho.add(caminhoFinal);
    String caminhoDesktop = await lerArquivos.getDesktopPath();
    unidades.insert(0, caminhoDesktop); // "Área de Trabalho"
    items = await lerArquivos.lerDadosPasta(caminhoDesktop);
    listCaminho.add(caminhoDesktop);
  
    // Configura o foco inicial
    focusScope = gridViewFocus2; // Define qual grid terá foco inicial
    gridViewFocus2.requestFocus();
    requerirFoco();
    load = false;
    stateTela = true;
    attTela();
    
     
  }
  // late Paad paad;

  requerirFoco(){
    if (focusNodeSetas1.isNotEmpty && selectedIndex1 < focusNodeSetas1.length) {
      focusNodeSetas1[selectedIndex1].requestFocus(); // Foca no item inicial do Grid 1
    }
    if (focusNodeSetas2.isNotEmpty && selectedIndex2 < focusNodeSetas2.length) {
      focusNodeSetas2[selectedIndex2].requestFocus(); // Foca no item inicial do Grid 2
    }
  }

  caminhoExiste(){
    bool retorno;
    retorno = imgLoadPreview.isNotEmpty;
    if(retorno) retorno = File(imgLoadPreview).existsSync();
    return retorno;
  }

  selectItemDireito(bool hasFocus, int index){
    debugPrint("object1");print("=================<<<<<<<<<<<  $selectedIndex2");
    if (hasFocus) {
      selectedIndex2 = index;
      print("=================<<<<<<<<<<<  $selectedIndex2");
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
  }


  selectItemEsquerdo(bool hasFocus, int index) async {
    if (!hasFocus)  return;
    String compare = caminhoFinal;
    selectedIndex1= index;
    caminhoFinal = "${unidades[selectedIndex1]}${selectedIndex1==0 ? "" : ":"}";
    if(compare == caminhoFinal) return;
    // Inicia Busca Novos arquivos
    loadArquivos = true;
    items = await lerArquivos.lerDadosPasta(caminhoFinal);
    loadArquivos = false;
    if(caminhoFinal != listCaminho.last ) listCaminho.add(caminhoFinal);
    if(ctx.mounted)attTela();
  }

  

  escutaPad(String event) async {
    if(!stateTela || load || event == "" || loadArquivos ) return;
      debugPrint("Click Paad PASSSTAAACTRLLL: $event  =======");
    String direction = "";
    try{
      direction =  MovimentoSistema.direcaoListView(focusScope, event);
    }catch(_){}
    if(event == "START"){//START
      // btnMais();
    }
    else if(event == "2"){//Entrar
      await btnEntrar();
    }
    else if(event == "3"){//Sair
      await clickVoltar();
    }
    else if(event == "LB"){// esquerda
      gridViewFocus1.requestFocus();
      focusScope = gridViewFocus1;
    }
    else if(event == "RB"){// Direita
      gridViewFocus2.requestFocus();
      focusScope = gridViewFocus2;
    }
    attTela();
  }

   btnEntrar() async {
    try{
      if(focusScope == gridViewFocus1){ // UNIDADES 
        focusScope = gridViewFocus2;
        selectedIndex2 = 0;
        return requerirFoco();
      }
      else if(focusScope == gridViewFocus2){ // PASTAS E ARQUIVOS Navegação
        // String brs = "\\";
        // if(selectedIndex2 == 0) return;
        caminhoFinal = items[selectedIndex2].caminho;
        
        
        if(!items[selectedIndex2].pasta){ // ARQUIVO Selecionado!
          loadArquivos = true;
          stateTela = false;

          // String resposta = await Pops().msgSN(ctx, "Confirmar acão?");
          // if(resposta == "Sim"){
            List<String> listAux = listCaminho.last.split('\\');
            String caminho = "";
            for (var item in listAux) {
              caminho += "$item\\\\";
            }
            return Navigator.pop(
              ctx,
              [
                "caminho",
                (items[selectedIndex2].url ? caminhoFinal : caminho + caminhoFinal),
                items[selectedIndex2].url ? items[selectedIndex2].nome : ""
              ]);
          // }else{
            // stateTela = true;
          // }

          
           
        }else{
          loadArquivos = true;
          attTela();
          items = await lerArquivos.lerDadosPasta(caminhoFinal);
          if(caminhoFinal != listCaminho.last ) listCaminho.add(caminhoFinal);
          selectedIndex2 = 0;
          loadArquivos= false;
          attTela();
          // requerirFoco();
        }



        // setState(() {});

      }

        

    }catch(e){ //notificacaoPop = true;
      debugPrint(e.toString());
      Provider.of<Notificacao>(ctx, listen: false).notificarIn(Icons.error, e.toString());
    }
  }
  clickVoltar() async {
    // if(selectedIndex2 == 0)return;
    if(listCaminho.last.length < 4) stateTela = false;
    if(listCaminho.last.length < 4 ) {
      return Navigator.pop(ctx);
    }
    listCaminho.removeLast();
    caminhoFinal = listCaminho.last;
    loadArquivos = true;
    attTela();
    items = await lerArquivos.lerDadosPasta(caminhoFinal);   
    loadArquivos = false;
    attTela();
  }

  
}