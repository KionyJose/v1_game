// ignore_for_file: file_names, use_build_context_synchronously
// // ignore_for_file: file_names

import 'dart:async';
import 'dart:math';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Bando%20de%20Dados/dbYoutube.dart';
import 'package:v1_game/Class/MouseCtrl.dart';
import 'package:v1_game/Class/TickerProvider.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:v1_game/Controllers/MovimentoSistema.dart';
import 'package:v1_game/Metodos/videoYT.dart';
import 'package:v1_game/Widgets/LoadWid.dart';
import '../Bando de Dados/db.dart';
import '../Class/Paad.dart';
import '../Modelos/IconeInicial.dart';
import '../Widgets/Pops.dart';

class PrincipalCtrl with ChangeNotifier{
  
  DB db = DB();  
  late BuildContext ctx;
  attTela() => notifyListeners();
  List<IconInicial> listIconsInicial = [];
  FocusNode keyboradEscutaNode = FocusNode();
  late List<FocusNode> focusNodeIcones;  
  List<FocusNode> focusNodeVideos = List.generate(6, (index) => FocusNode());
  CarouselSliderController carouselVideosCtrl = CarouselSliderController();
   CarouselSliderController carouselIconesCtrl =  CarouselSliderController();
  late FocusScopeNode focusScope;
  FocusScopeNode focusScopeIcones = FocusScopeNode();
  FocusScopeNode focusScopeVideos = FocusScopeNode();
  ScrollController scrolListIcones = ScrollController();
  PageController slideIconesCtrl = PageController();
  int selectedIndexIcone = 0;
  int selectedIndexVideo = 0;

  bool gameIniciado = false;
  bool videoAtivo = false;  
  bool stateTela = true;
  bool telaIniciada = false;
  bool mood = false;
  bool showNewImage = false;
  String imgFundoStr = "";
  bool home = false;
  List<VideoYT> videosYT= [];


  List<String> tagVideo = ["gameplay","montage","funny","clip","dica","tutorial de","Shorts"];  
  List<String> comandoSequencia = [];
  
  late AnimationController ctrlAnimeBgFundo;
  late Animation<double> scaleAnimation;
  // late Notificacao notf;

  PrincipalCtrl(this.ctx,){
    iniciaTela();
  }
  //initState
  iniciaTela() async {
    focusScopeIcones.requestFocus();
    focusScope = focusScopeIcones;
    selectedIndexIcone = 0;
    animaFundo();
    listIconsInicial = await db.leituraDeDados();
    if(listIconsInicial.isNotEmpty){
      focusNodeIcones = List.generate(listIconsInicial.length, (index) => FocusNode());
      imgFundoStr = listIconsInicial.first.imgStr;      
      // pesquisaVideosYT(listIconsInicial.first.nome);
    }
    if(listIconsInicial.isEmpty) focusNodeIcones = [FocusNode()];
    telaIniciada = true;
    showNewImage = true;
    stateTela = true;
    keyboradEscutaNode.requestFocus();
    focusNodeIcones[0].requestFocus();
    home = false;
    attTela();   

    // JanelaCtrl.restoreWindow("v1_game");
  }

  @override
  dispose(){
    debugPrint("SAIU PAGE CTRL");
    super.dispose();
  }

  pesquisaVideosYT(String nomeGame) async {
    if(nomeGame.isEmpty)return;
    try{
      String aux = tagVideo[Random().nextInt(tagVideo.length)];
      videosYT = await DbYoutube().buscarVideosNoYouTube("$nomeGame $aux");
      attTela();
    }catch(e){
      debugPrint(e.toString());
      debugPrint(e.toString());
    }  
  }
  

  onFocusChangeVideos(bool hasFocus, int index){ 
    if (hasFocus) {
      // debugPrint("FOCO ATT VIDEO");
      selectedIndexVideo = index;
      carouselVideosCtrl.animateToPage(index);
    }
  }

  onFocusChangeIcones(bool hasFocus, int index){     
    if (hasFocus) {      
      debugPrint("FOCO ATT ICONE $index");          
      showNewImage = false;             
      selectedIndexIcone = index;
      slideIconesCtrl.animateToPage(selectedIndexIcone, duration: const Duration(milliseconds: 700), curve: Curves.decelerate);
      
      // if(selectedIndexIcone < index)carouselIconesCtrl.animateToPage(index);
      // if(selectedIndexIcone > index) carouselIconesCtrl.previousPage();
      
      videosYT = [];
      Future.delayed(const Duration(milliseconds: 350),() {
        showNewImage = true;        
        if(listIconsInicial.isNotEmpty){
          imgFundoStr = listIconsInicial[index].imgStr;
          // pesquisaVideosYT(listIconsInicial[selectedIndexIcone].nome);
        }
      });
    }
  }
  animaFundo(){
    ctrlAnimeBgFundo = AnimationController(
      duration: const Duration(seconds: 20),
      vsync:  MyTickerProvider(),
    );

    scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(ctrlAnimeBgFundo);

    ctrlAnimeBgFundo.repeat(reverse: true);
  }

  btnEntrar() async {
    if(!stateTela) return;
    if(listIconsInicial.isEmpty) return btnMais();
    await db.openFile(listIconsInicial[selectedIndexIcone].local);
    gameIniciado = true;
    await Pops().carregandoGames(ctx);
    gameIniciado = false;
    // Garantir que o foco volte para o escopo correto após abrir o arquivo
    focusScopeIcones.requestFocus();
    focusScope = focusScopeIcones;
  }

  btnMais() {
    try{
    stateTela = false;
    // PAD paad = pad;
    WidgetsBinding.instance.addPostFrameCallback((_) async  {

      String retorno = await Pops().popMenuTelHome2(ctx);
      debugPrint(retorno);
    
      if (retorno == "Caminho do game" || retorno == "Imagem de capa" || retorno == "Add") {
        debugPrint("Entrei navPasta");
        await Pops().navPasta(ctx, "", retorno, listIconsInicial, selectedIndexIcone);
        debugPrint("Sai navPasta");       
        Timer(const Duration(milliseconds: 500), () => iniciaTela());  
      }
      else if (retorno == "Excluir Card") {        
        Timer(const Duration(milliseconds: 500  ),() async {
          var result = await Pops().msgSN(ctx, "Confirmar ação?");
          if(result ==  null) return;
          if(result == "Sim"){
            listIconsInicial.removeAt(selectedIndexIcone);
            await db.attDados(listIconsInicial);            
            Timer(const Duration(milliseconds: 500), () => iniciaTela());
          }
        });
      }
      else{        
        Timer(const Duration(milliseconds: 500), () => iniciaTela());
      }
      

    });
    debugPrint("Finalizei btnMais");
    }catch(e){
      debugPrint("ERO BTNMAIS === $e");
      Pops().msgSimples(ctx,"ERRO = 1$e");
    }
  }

  

  

  escutaPad(String event) async {    
    try{
      //   if(event == "HOME" && !home){
      //   home = true;
      //   debugPrint("Tela resetada");
      //   return iniciaTela();
      // }
      if(!stateTela || event == "") return;
      debugPrint(" ===== Click Paad: => $event" );     
      if(focusScope == focusScopeIcones)movIcones(event); 
      if(focusScope == focusScopeVideos )movVideos(event);
      
    }catch(erro){
      debugPrint("ERRO ESCUTA PAD CLICK$erro");
    }
    if(event == "HOME" ){
      home = true;
      Provider.of<Paad>(ctx, listen: false).click = "";
      debugPrint("Tela resetada");
      iniciaTela();
      Provider.of<Paad>(ctx, listen: false).attTela();

    }
  }


  movVideos(String event){
    try{      
      MovimentoSistema.direcaoListView(focusScope, event);
      
      if(event=="CIMA" && !videoAtivo){
        focusScopeIcones.requestFocus();
        focusScope = focusScopeIcones;        
      }
      if (event == "START") {
        //START
        btnMais();
      }
      if (event == "BAIXO") videoAtivo = false;
      if (event == "2") clickVideo();
      if (event == "3") videoAtivo = false;
      // attTela();
    }catch(e){
      debugPrint("ERRO LCICK PAD VIDEOS  $e");
    }

  }
  movIcones(String event){
     try{
      if(gameIniciado) {
        if(event == "3") Navigator.pop(ctx);
        return;
      }
      String result = MovimentoSistema.direcaoListView(focusScope, event);
      debugPrint(result);

      if(result == MovimentoSistema.horizontal || result == MovimentoSistema.vertical  ){
        // int totalIndex = event == "ESQUERDA" ? selectedIndexIcone-1 : selectedIndexIcone+1;
        // if(totalIndex < focusNodeIcones.length && totalIndex >= 0) selectedIndexIcone = totalIndex;
        // carouselIconesCtrl.animateToPage(selectedIndexIcone, duration: const Duration(milliseconds: 700), curve: Curves.decelerate);
          
        
        if(event=="BAIXO"){
          debugPrint("Lista VIDEOS :${videosYT.length}");
          if(videosYT.isNotEmpty){
            focusScopeVideos.requestFocus();
            focusScope = focusScopeVideos;
          }
        }
      }
      
      
      if (event == "START")btnMais();      
      if (event == "2")btnEntrar();
      // if(event == "4")mostrarBottomSheet();
      
    }catch(e){
      debugPrint(e.toString());
      Pops().msgSimples(ctx,"ERRO = 1$e");
    }
  }
  

  clickVideo() async {    
    if(videoAtivo) {
      videoAtivo = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {          
        videoAtivo = true;
        });
      return;
    }
    videoAtivo = true;
    // videoAtivo = !videoAtivo;
  }

  
  keyPress(KeyEvent key) async {
    if (key is KeyDownEvent || key is KeyRepeatEvent) {
      debugPrint("Teclado Press: ${key.logicalKey.debugName}");
      String event = MovimentoSistema.convertKeyBoard(key.logicalKey.keyLabel);
      escutaPad(event);
    }
  }

  
  verificaFocoJanela() {
    // ignore: deprecated_member_use
    final appWindow = WidgetsBinding.instance.window;
    bool visible = appWindow.viewInsets.bottom == 0;
    visible = naTela();
  }

  bool naTela(){
    bool value = false;
    final AppLifecycleState? estadoAtual = WidgetsBinding.instance.lifecycleState;
    if (estadoAtual == AppLifecycleState.resumed) {
      // debugPrint("O aplicativo está na frente (ativo).");
      value = true;
    } else if (estadoAtual == AppLifecycleState.inactive) {
      debugPrint(" ===== Aplicativo está INATIVO. =====");
      value = false;
    } else if (estadoAtual == AppLifecycleState.paused) {
      debugPrint("O aplicativo está em segundo plano (pausado).");
      value = false;
    } else {
      
      debugPrint("ESTADO ALTERNATIVO:  $estadoAtual");
      value = true;
    }
    return value;
  }




}