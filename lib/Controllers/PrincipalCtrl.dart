// ignore_for_file: file_names, use_build_context_synchronously
// // ignore_for_file: file_names

import 'dart:async';
import 'dart:math';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Bando%20de%20Dados/CinemaCatalogo.dart';
import 'package:v1_game/Bando%20de%20Dados/dbYoutube.dart';
import 'package:v1_game/Class/TickerProvider.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:v1_game/Controllers/MovimentoSistema.dart';
import 'package:v1_game/Controllers/NavWebCtrl.dart';
import 'package:v1_game/Modelos/CinemaCanal.dart';
import 'package:v1_game/Metodos/videoYT.dart';
import 'package:y_player/y_player.dart';
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
  
  late List<FocusNode> focusNodeCinema; 
  late List<FocusNode> focusNodeAbaGuias;  
  List<FocusNode> focusNodeTagVid = List.generate(8, (index) => FocusNode());
  List<FocusNode> focusNodeVideos = List.generate(6, (index) => FocusNode());
  
  CarouselSliderController carouselVideosCtrl = CarouselSliderController();
   CarouselSliderController carouselIconesCtrl =  CarouselSliderController();

  FocusScopeNode focusScope = FocusScopeNode();
  FocusScopeNode focusScopeCinema = FocusScopeNode();
  FocusScopeNode focusScopeAbaGuias = FocusScopeNode();
  FocusScopeNode focusScopeIcones = FocusScopeNode();
  FocusScopeNode focusScopeVideos = FocusScopeNode();

  ScrollController scrolListIcones = ScrollController();  
  ScrollController scrolListStream = ScrollController();
  
  ScrollController scrolListAbaGuias = ScrollController();

  PageController slideIconesCtrl = PageController();
  int selectedIndexIcone = 0;
  int selectedIndexVideo = 0;  
  int selectedIndexCinema = 0;
  int selectedIndexAbaGuias = 0;

  // final ValueNotifier<int> selectedIndexNotifier = ValueNotifier<int>(0);
  bool gameIniciado = false;
  bool videoAtivo = false;  
  bool stateTela = true;
  bool telaIniciada = false;
  bool videosShow = false;
  bool mood = false;
  bool showNewImage = false;
  String imgFundoStr = "";
  bool home = true;
  List<VideoYT> videosYT= [];

  PageController bodyCtrl = PageController();

  YPlayerController ctrlVideo = YPlayerController();
  List<String> tagVideo = ["gameplay","montage","funny","clip","dica","tutorial de","Shorts"];
  
  List<String> listAbaGuias= ["Games","Cinema"];
  
  List<CinemaCanal> listCinema = [];
  List<List<VideoYT>> videosIndexYT = [];

  List<String> comandoSequencia = [];
  
  late AnimationController ctrlAnimeBgFundo;
  late Animation<double> scaleAnimation;
  // late Notificacao notf;

  PrincipalCtrl(this.ctx,){
    iniciaTela();
  }
  urlFilme(int i ){
    String str = listCinema[i].imgLocal;
    return str;
  }
  //initState
  iniciaTela() async {
    focusNodeAbaGuias = List.generate(listAbaGuias.length, (index) => FocusNode());
    focusNodeAbaGuias[0].requestFocus();
    focusScopeIcones.requestFocus();
    focusScope = focusScopeIcones;
    selectedIndexIcone = 0;
    animaFundo();
    listIconsInicial = await db.leituraDeDados();
    listCinema = CinemaCatalogo.catalogo();
    focusNodeCinema = List.generate(listCinema.length, (index) => FocusNode());
    if(listIconsInicial.isNotEmpty){
      focusNodeIcones = List.generate(listIconsInicial.length, (index) => FocusNode());
      videosIndexYT = List.generate(listIconsInicial.length, (index) => []);
      imgFundoStr = listIconsInicial.first.imgStr;      
      pesquisaVideosYT(listIconsInicial.first.nome,0);
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

  pesquisaVideosYT(String nomeGame, int index) async {
    if(nomeGame.isEmpty)return;
    try{
      if(videosIndexYT[index].isEmpty) {
        String aux = tagVideo[Random().nextInt(tagVideo.length)];
        videosIndexYT[index] = await DbYoutube().buscarVideosNoYouTube("$nomeGame $aux",nomeGame);        
      }
      videosYT = videosIndexYT[index];
      videosShow = true;
      attTela();
    }catch(e){
      debugPrint(e.toString());
      debugPrint(e.toString());
    }  
  }
  onFocusChangeTagVid(bool hasFocus, int index){ 
    if (hasFocus) {
      // debugPrint("FOCO ATT VIDEO");
      // selectedIndexVideo = index;
      // carouselVideosCtrl.animateToPage(index);
    }
  }

  mouseDentro(int index,double tamanho){
    selectedIndexIcone = index;
      // selectedIndexNotifier.value = index; // Atualiza o índice quando um item ganha o foco
      
      // Future.delayed(Duration.zero,() {
        // scrolListIcones.animateTo(
        //   index * tamanho, // Multiplica pelo tamanho do item
        //   duration: const Duration(milliseconds: 700),
        //   curve: Curves.decelerate,
        // );
        // attTela();
  }
  mouseFora(int index,double tamanho){

  }
  onFocusChangeCinema(bool hasFocus, int index){ 
    if (hasFocus) {
      // debugPrint("FOCO ATT VIDEO");
      selectedIndexCinema = index;
      // carouselVideosCtrl.animateToPage(index);
      attTela();
    }
  }

  onFocusChangeVideos(bool hasFocus, int index){ 
    if (hasFocus) {
      // debugPrint("FOCO ATT VIDEO");
      selectedIndexVideo = index;
      carouselVideosCtrl.animateToPage(index);
      attTela();
    }
  }
  onFocusChangeAbaGuias(bool hasFocus, int index,{ double tamanho = 0}){
    if (!hasFocus ) return;
    selectedIndexAbaGuias = index;    
    // Movimenta Scrol para onde esta selecionado Icone
    scrolListAbaGuias.animateTo(
      index * tamanho, // Multiplica pelo tamanho do item
      duration: const Duration(milliseconds: 700),
      curve: Curves.decelerate,
    );
    attTela();
  }

  onFocusChangeIcones(bool hasFocus, int index,{ double tamanho = 0}){
    if (!hasFocus || selectedIndexIcone == index) return;
    try{    
      debugPrint("FOCO ATT ICONE $index");          
      showNewImage = false;
      if(selectedIndexIcone != index){
        //PAusar somente quando click estiver acionado;
        debugPrint(e.toString());
        debugPrint(e.toString());
      }
      selectedIndexIcone = index;      
      // selectedIndexNotifier.value = index; // Atualiza o índice quando um item ganha o foco
      
      // Future.delayed(Duration.zero,() {
      scrolListIcones.animateTo(
        index * tamanho, // Multiplica pelo tamanho do item
        duration: const Duration(milliseconds: 700),
        curve: Curves.decelerate,
      );
      // print(listIconsInicial[selectedIndexIcone].nome);
      // print(videosYT[index].nomeGame);
      String nm = "";
      if(videosYT.isNotEmpty) nm = videosYT.last.nomeGame;

      
      if(listIconsInicial[index].nome != nm && nm != "Fake" && nm.isNotEmpty) videosShow = false;
      attTela();
      // });
      // slideIconesCtrl.animateToPage(selectedIndexIcone, duration: const Duration(milliseconds: 700), curve: Curves.decelerate);
      
      // if(selectedIndexIcone < index)carouselIconesCtrl.animateToPage(index);
      // if(selectedIndexIcone > index) carouselIconesCtrl.previousPage();
      
      
      Future.delayed(const Duration(milliseconds: 350),() {
        if(selectedIndexAbaGuias != 0)return;
        showNewImage = true;        
        if(listIconsInicial.isNotEmpty){
          imgFundoStr = listIconsInicial[index].imgStr;
          // attTela();
          if(!videosShow) pesquisaVideosYT(listIconsInicial[selectedIndexIcone].nome,index);
        }
      });
    }catch(e){
      debugPrint(e.toString());
      debugPrint(e.toString());
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
    try{
      if(!stateTela) return;
      if(listIconsInicial.isEmpty) return btnMais();
      await db.openFile(listIconsInicial[selectedIndexIcone].local);
      gameIniciado = true;      
      Provider.of<JanelaCtrl>(ctx, listen: false).telaPresaReverse(usarEstado: true, estado: false);
      await moverIcoPosicaoInicial(listIconsInicial[selectedIndexIcone]);
      attTela();
      await Future.delayed(const Duration(milliseconds: 650));
      await Pops().carregandoGames(ctx,"Entrando no game..." );
      gameIniciado = false;
      Provider.of<JanelaCtrl>(ctx, listen: false).telaPresaReverse();
      // Garantir que o foco volte para o escopo correto após abrir o arquivo
      focusNodeIcones[selectedIndexIcone].requestFocus();
      focusScopeIcones.requestFocus();
      focusScope = focusScopeIcones;
    }catch(e){
      debugPrint(e.toString());
    }
  }

  moverIcoPosicaoInicial(IconInicial ico )async {
    scrolListIcones.animateTo(0,duration: const Duration(milliseconds: 700),curve: Curves.fastEaseInToSlowEaseOut,);
    selectedIndexIcone = 0;
    listIconsInicial.remove(ico);
    listIconsInicial.insert(0, ico);
    await db.attDados(listIconsInicial);
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
      if(event == "RB"||event=="LB"){
        movAbaGuias(event);}
      else if(focusScope == focusScopeIcones && selectedIndexAbaGuias == 0){
        movIcones(event);}
      else if(focusScope == focusScopeVideos && selectedIndexAbaGuias == 0){
        movVideos(event);}
      else if(focusScope == focusScopeCinema && selectedIndexAbaGuias == 1){
        movFilmes(event);}
      
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
    
    Provider.of<Paad>(ctx, listen: false).click = "";
    Provider.of<Paad>(ctx, listen: false).attTela();
  }


  movVideos(String event){
    try{      
      MovimentoSistema.direcaoListView(focusScope, event);
      
      if(event=="CIMA" && !videoAtivo){
        focusScopeIcones.requestFocus();
        focusScope = focusScopeIcones;        
      }
      if(event=="RB"){
        ctrlVideo.pause();

      }if(event=="LB"){
        ctrlVideo.play();
      }
      if (event == "START") {
        //START
        btnMais();
      }
      if (event == "2") {    
        if(videoAtivo) return videoAtivo = true;
        videoAtivo = true;
        attTela();
      }
      if (event == "3" || event == "BAIXO"){
        videoAtivo = false;
        attTela();
      }
      // attTela();
    }catch(e){
      debugPrint("ERRO LCICK PAD VIDEOS  $e");
    }

  }

  movAbaGuias(String event){    
    if(event=="LB"){
      focusScope = focusScopeIcones;
      focusScopeAbaGuias.focusInDirection(TraversalDirection.left);
      focusNodeIcones[selectedIndexIcone].requestFocus();
      bodyCtrl.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.decelerate); 
    }
    if(event=="RB"){
      
      focusNodeCinema[selectedIndexCinema].requestFocus();
      focusScope = focusScopeCinema;
      focusScopeAbaGuias.focusInDirection(TraversalDirection.right);
      bodyCtrl.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
    }
  }

  movFilmes(String event) async {
    
    MovimentoSistema.direcaoListView(focusScope, event);

    if(gameIniciado) {
      if(event == "3") Navigator.pop(ctx);
      return;
    }
    if (event == "2"){
      gameIniciado = true;
      // Liberar Tela do sistema
      Provider.of<JanelaCtrl>(ctx, listen: false).telaPresaReverse(usarEstado: true, estado: false);
      // Ativar Mouse
      Provider.of<Paad>(ctx, listen: false).ativaMouse(usarEstado: true,  estado: true);

      await NavWebCtrl.openLink(listCinema[selectedIndexCinema].url);

      // await Future.delayed(const Duration(milliseconds: 650));
      await Pops().carregandoGames(ctx, "Cinema Ativo");
      // Desativa o uso do mouse;
      Provider.of<Paad>(ctx, listen: false).ativaMouse( usarEstado: true,  estado: false);
      // Trava na tela novamente
      // Provider.of<JanelaCtrl>(ctx, listen: false).telaPresaReverse();
      gameIniciado = false;

      // Garantir que o foco volte para o escopo correto após abrir o arquivo
      focusNodeCinema[selectedIndexCinema].requestFocus();
      focusScopeCinema.requestFocus();
      focusScope = focusScopeCinema;

      // attTela();
    }
    // await Future.delayed(const Duration(milliseconds: 300));
    // attTela();

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
  

  

  
  keyPress(KeyEvent key) async {
    if (key is KeyDownEvent || key is KeyRepeatEvent) {
      debugPrint("Teclado Press: ${key.logicalKey.debugName}");
      String event = MovimentoSistema.convertKeyBoard(key.logicalKey.keyLabel);
      escutaPad(event);
    }
  }

  





}