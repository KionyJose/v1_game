// ignore_for_file: file_names, use_build_context_synchronously

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Bando%20de%20Dados/db.dart';
import 'package:v1_game/Controllers/Notificacao.dart';
import 'package:v1_game/Tela/NavegadorPasta.dart';
import 'package:v1_game/Widgets/Pops.dart';

import '../Metodos/leituraArquivo.dart';
import '../Modelos/IconeInicial.dart';
import '../Modelos/Item.dart';
import 'MovimentoSistema.dart';

class PastaCtrl with ChangeNotifier{
  DB db = DB();
  BuildContext ctx;

  
  String imgLoadPreview = "";
  String caminhoFinal = "";
  List<String> listCaminho = [];

  bool stateTela = false;
  bool load = true;
      
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

  attTela() => notifyListeners();



  PastaCtrl(this.ctx){
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
  bool entrei = false;

  iniciaTela()async { 
    if(entrei)return;
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
    debugPrint("object1");
    if (hasFocus) {
      selectedIndex2 = index;
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
    selectedIndex1= index;
    caminhoFinal = "${unidades[selectedIndex1]}${selectedIndex1==0 ? "" : ":"}";
    items = await lerArquivos.lerDadosPasta(caminhoFinal);
    if(caminhoFinal != listCaminho.last ) listCaminho.add(caminhoFinal);    
  }

  

  escutaPad(String event)async {
    if(!stateTela || load || event == "") return;
    debugPrint("Click Paad: $event  =======");
    Movimentosistema.direcaoListView(focusScope, event);
    if(event == "START"){//START
      // btnMais();
    }
    if(event == "2"){//Entrar
      btnEntrar();
    }
    if(event == "3"){//Sair
      clickVoltar();
    }
    if(event == "LB"){// esquerda
      gridViewFocus1.requestFocus();
      focusScope = gridViewFocus1;
    }
    if(event == "RB"){// Direita
      gridViewFocus2.requestFocus();
      focusScope = gridViewFocus2;
    }
    // attTela();
  }

   btnEntrar() async {
    try{
      if(focusScope == gridViewFocus1){ // UNIDADES 
        focusScope = gridViewFocus2;
        selectedIndex2 = 0;
        return requerirFoco();
        
        
      }
      else if(focusScope == gridViewFocus2){ // PASTAS E ARQUIVOS
        // String brs = "\\";
        caminhoFinal = items[selectedIndex2].caminho;

        if(!items[selectedIndex2].pasta){
          stateTela = false;
          // await Pops().msgSimples(ctx,"boa");
          String resposta = await Pops().msgSN (ctx, "Confirmar acão?");
          if(resposta == "Sim"){
            List<String> listAux = listCaminho.last.split('\\');
            String caminho = "";
            for (var item in listAux) {
              caminho += "$item\\\\";
            }
            return Navigator.pop(ctx,["caminho", items[selectedIndex2].url ? caminhoFinal : caminho + caminhoFinal]);
          }
        }



        // setState(() {});

      }

        items = await lerArquivos.lerDadosPasta(caminhoFinal);
        if(caminhoFinal != listCaminho.last ) listCaminho.add(caminhoFinal);
        requerirFoco();

    }catch(e){ //notificacaoPop = true;
      debugPrint(e.toString());
      Provider.of<Notificacao>(ctx, listen: false).notificarIn(Icons.error, e.toString());
    }
  }
  clickVoltar() async {
    
    if(listCaminho.last.length < 4) stateTela = false;
    if(listCaminho.last.length < 4) return Navigator.pop(ctx);
    listCaminho.removeLast();
    caminhoFinal = listCaminho.last;
    items = await lerArquivos.lerDadosPasta(caminhoFinal);   
    // attTela();
  }

  navPasta(BuildContext context,  String caminho, String tarefa, List<IconInicial> listiconIni, int index) async {
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
  }
}