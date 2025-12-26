// ignore_for_file: file_names, unnecessary_null_comparison, use_build_context_synchronously

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Class/TecladoCtrl.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:v1_game/Controllers/MovimentoSistema.dart';
import 'package:v1_game/Widgets/Pops.dart';
import 'package:v1_game/Widgets/VisualizadorImgWeb.dart';
import '../../Class/WebScrap.dart';
import '../../Modelos/ImgWebScrap.dart';

class SeletorImgCtrl with ChangeNotifier{
  late BuildContext ctx;
  attTela() => ctx.mounted ? notifyListeners() : null;
  FocusScopeNode focusScope = FocusScopeNode();
  FocusNode txtFoco = FocusNode();
  FocusNode buscaFocos = FocusNode();
  TextEditingController txtNome = TextEditingController();
  late String nome;
  String txtEscrita = "";

  bool load = true;
  bool stateTela = false;
  bool teclando = false;

  List<String> listComandos =[];
  List<ImgWebScrap> listUser = [];
  List<ImgWebScrap> listImgs = [];  
  late List<FocusNode> focusNodesGrid;    
  int selectedIndexGrid = 0;
  ScrollController scrollGridCtrl = ScrollController();
  SeletorImgCtrl(this.ctx, this.nome){
    iniciaTela(nome);
  }

  iniciaTela(String nomeAux) async {
    load = true;
    stateTela = false;
    alteraTxtNome(nomeAux);
    attTela();
      // var result = await  WebScrap.buscaUsersWalpaperCave(nome);
    // if(result == null) return;
    // listUser = result[1] as List<ImgWebScrap>;
    listUser.clear();
    bool winer = false;
    List<String> nomes = nomeAux.split(' ');
    nomes.add("sair");
    while(!winer){
      nomes.removeAt(nomes.length-1);
      if(nomes.isEmpty)break;
      String nomAlterado = nomes.join(' ');
      var result = await  WebScrap.buscaUsersWalpaperCave(nomAlterado); 

      if(result == null) break;
      listUser = result[1] as List<ImgWebScrap>;
      if(listUser.isNotEmpty){
        alteraTxtNome(nomAlterado);
        winer = true;
        listUser = result[1] as List<ImgWebScrap>;
      }
    }
    if(listUser.isEmpty){      
      load = false;
      stateTela =true;
      return attTela();
    }
    focusNodesGrid = List.generate(listUser.length, (value) => FocusNode());
    // focusScope.requestFocus();
    focusNodesGrid.first.requestFocus();
    load = false;
    stateTela =true;
    attTela();
  }


  alteraTxtNome(String  str){
    txtNome.text = str;
    txtEscrita = str;
  }

  escreveTxt(String str){
    if(str.length == 1) alteraTxtNome(txtEscrita + str);
    if(str.isEmpty) alteraTxtNome(txtEscrita.substring(0,txtEscrita.length-1));
  }
  txtSelecionado(String str)async {
    
    // Garante que o cursor fique no final do texto
    txtNome.selection = TextSelection.fromPosition(
      TextPosition(offset: txtNome.text.length),
    );
    // txtSelecionado("");
    // TecladoCtrl.abrirTeclado();
    // txtFoco.requestFocus();
    // attTela();
  
  }

    clickPasta(String str)async{
    stateTela = false;
    load = true;
    // Pops.popTela(ctx,const LoadingIco());
    attTela();
    
    debugPrint('========================================');
    debugPrint('SELETOR DE IMAGENS - CLIQUE NA PASTA');
    debugPrint('Nome original da pasta: $str');
    
    // Tratamento correto do nome para URL
    // Remove "Wallpapers" do final se existir
    String strProcessado = str;
    // if(strProcessado.toLowerCase().endsWith(' wallpapers')) {
    //   strProcessado = strProcessado.substring(0, strProcessado.length - 11).trim();
    // }
    
    // Remove caracteres especiais inválidos para URL
    strProcessado = strProcessado
        .replaceAll('™', '') // Substitui barras por hífens
        .replaceAll(':', '') // Remove dois pontos
        .replaceAll('?', '') // Remove interrogação
        .replaceAll('!', '') // Remove exclamação
        .replaceAll('&', 'and') // Substitui & por and
        .replaceAll('  ', ' ') // Remove espaços duplos
        .trim();
    
    // Substitui espaços por hífens
    strProcessado = strProcessado.replaceAll(' ', '-');
    
    debugPrint('Nome processado para busca: $strProcessado');
    debugPrint('URL que será acessada: https://wallpapercave.com/$strProcessado');
    debugPrint('========================================');
    
    var result = await WebScrap.buscaImgsWalpaperCave(strProcessado);
    
    if(result == null) {
      debugPrint('========================================');
      debugPrint('ERRO: WebScrap retornou NULL');
      debugPrint('========================================');
      // loadArquivos = false;
      stateTela = true;
      attTela();
      return;
    }
    
    listImgs = result[1] as List<ImgWebScrap>;
    
    debugPrint('========================================');
    debugPrint('RESULTADO DA BUSCA:');
    debugPrint('Total de imagens encontradas: ${listImgs.length}');
    if(listImgs.isNotEmpty) {
      debugPrint('Primeira imagem URL: ${listImgs.first.imageUrl}');
      debugPrint('Primeira imagem dimensões: ${listImgs.first.largura}x${listImgs.first.altura}');
    }
    debugPrint('========================================');
    
    var imgSelect = await Pops.popTela(ctx, VisualizadorImgWeb(list: listImgs));
    stateTela = true;
    load = false;
    focusScope.requestFocus();
    focusNodesGrid[selectedIndexGrid].requestFocus();
    Timer(const Duration(milliseconds: 500), () => attTela());
    if(imgSelect == null) return;
    stateTela = false;
    Navigator.pop(ctx,imgSelect);
    // attTela();
  }

  clickBtnBuscar()async {
    await iniciaTela(txtNome.text);
    // Desativa o uso do mouse;
    // Provider.of<Paad>(ctx, listen: false).ativaMouse( usarEstado: true,  estado: false);
  }

  keyPress(KeyEvent key) async {
    if (key is KeyDownEvent || key is KeyRepeatEvent) {      
      debugPrint("Teclado Press: ${key.logicalKey.debugName}");
      String event = MovimentoSistema.convertKeyBoard(key.logicalKey.keyLabel);
      escutaPad(event);
      attTela();
    }
  }

  escutaPad(String event) async {   
    try{      
      if(!stateTela || event == "") return;
      if(teclando){
        int total = 0;
        listComandos.insert(0,event);
        if(listComandos.length == 3){
          listComandos.removeLast();          
          if(listComandos[0] == '3') total++;
          if(listComandos[1] == '3') total++;
          if(total!=2) return;
          teclando = false;
        }
        return;
      }
      MovimentoSistema.direcaoListView(focusScope, event);
      
      if(event == "3"){
        stateTela = false;
        return Navigator.pop(ctx);}
      else if (event == "2"){
        
        if(buscaFocos.hasFocus) return await iniciaTela(txtNome.text);
        if(txtFoco.hasFocus){
          teclando = true;
          TecladoCtrl.abrirTecladoVirtual();
          // Provider.of<Paad>(ctx, listen: false).ativaMouse(usarEstado: true,  estado: true);
          // Liberar Tela do sistema
          Provider.of<JanelaCtrl>(ctx, listen: false).telaPresaReverse(usarEstado: true, estado: false);
          return;
        }
        clickPasta(listUser[selectedIndexGrid].title);
      }    
      debugPrint(" ===== Click Paad: => $event" );
      
    }catch(erro){
      debugPrint("ERRO ESCUTA PAD CLICK$erro");
    }
    if(event == "HOME" ){
      // home = true;
      // Provider.of<Paad>(ctx, listen: false).click = "";
      // debugPrint("Tela resetada");
      // iniciaTela();
      // Provider.of<Paad>(ctx, listen: false).attTela();
    }
    
    Provider.of<Paad>(ctx, listen: false).click = "";
    Provider.of<Paad>(ctx, listen: false).attTela();
  }


}