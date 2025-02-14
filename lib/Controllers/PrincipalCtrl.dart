// ignore_for_file: file_names, use_build_context_synchronously
// // ignore_for_file: file_names

import 'dart:async';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:v1_game/Bando%20de%20Dados/dbYoutube.dart';
import 'package:v1_game/Class/TickerProvider.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:v1_game/Controllers/MovimentoSistema.dart';
import 'package:v1_game/Metodos/videoYT.dart';
import '../Bando de Dados/db.dart';
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
  late FocusScopeNode focusScope;
  FocusScopeNode focusScopeIcones = FocusScopeNode();
  FocusScopeNode focusScopeVideos = FocusScopeNode();
  ScrollController scrolListIcones = ScrollController();
  PageController slideIconesCtrl = PageController();
  int selectedIndexIcone = 0;
  int selectedIndexVideo = 0;
  
  bool isWindowFocused = true;
  bool videoAtivo = false;
  bool stateTela = true;
  bool telaIniciada = false;
  bool mood = false;
  bool showNewImage = false;
  String imgFundoStr = "";
  List<VideoYT> videosYT= [];


  List<String> tagVideo = ["gameplay","montage","funny","clip","dica","tutorial de"];  
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
      pesquisaVideosYT(listIconsInicial.first.nome);
    }
    if(listIconsInicial.isEmpty) focusNodeIcones = [FocusNode()];
    telaIniciada = true;
    showNewImage = true;
    stateTela = true;
    keyboradEscutaNode.requestFocus();
    focusNodeIcones[0].requestFocus();
    attTela();
  }

  @override
  dispose(){
    debugPrint("SAIU PAGE CTRL");
    super.dispose();
  }

  pesquisaVideosYT(String nomeGame) async {
    if(nomeGame.isEmpty)return;
    videosYT = [];
    try{
      videosYT = await DbYoutube().buscarVideosNoYouTube("$nomeGame gameplay noticias");
      // attTela();
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
      debugPrint("FOCO ATT ICONE");          
      showNewImage = false;             
      selectedIndexIcone = index;
      slideIconesCtrl.animateToPage(selectedIndexIcone, duration: const Duration(milliseconds: 700), curve: Curves.decelerate);
      
      // scrollToNextIcon();
      // carouselIconesCtrl.animateToPage(index);s
      Future.delayed(const Duration(milliseconds: 350),() {
        showNewImage = true;        
        if(listIconsInicial.isNotEmpty){
          imgFundoStr = listIconsInicial[index].imgStr;
          pesquisaVideosYT(listIconsInicial[selectedIndexIcone].nome);
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

  addSequencia(String event){    
    if(event == "")return;
    if(comandoSequencia.length == 5){
      comandoSequencia.removeAt(0);
      comandoSequencia.add(event);
      verificaSequencia();
    }else{        
      comandoSequencia.add(event);
    }
    debugPrint("=--------------------  $comandoSequencia");
    
  }
  verificaSequencia(){
    int total = 0;
    // RestauraTela
    if(comandoSequencia[0] == "START")total++;
    if(comandoSequencia[1] == "START")total++;
    if(comandoSequencia[2] == "LB")total++;
    if(comandoSequencia[3] == "RB")total++;
    if(comandoSequencia[4] == "2")total++;
    if(total == 5){
      JanelaCtrl.restoreWindow("v1_game");
      MovimentoSistema.audioMovMent();
    }
  }


  escutaPad(String event) async {
    addSequencia(event);
    try{
      if(!stateTela || event == "") return;
      verificaFocoJanela();
      debugPrint(" ===== Click Paad: => $event" );
      
      // debugPrint("=======   Escuta Principal  =======");
      if (isWindowFocused){
        if(focusScope == focusScopeIcones)movIcones(event);
        if(focusScope == focusScopeVideos )movVideos(event);
      }else{
        debugPrint("isWindowFocused  FALSOOO");
      }
    }catch(erro){
      debugPrint("ERRO ESCUTA PAD CLICK$erro");
    }
    if(event == "HOME"){
      JanelaCtrl.restoreWindow("v1_game");
      MovimentoSistema.audioMovMent();
      // iniciaTela();
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
      MovimentoSistema.direcaoListView(focusScope, event); 
      if(event=="BAIXO"){
        debugPrint("Lista VIDEOS :${videosYT.length}");
        if(videosYT.isNotEmpty){
          focusScopeVideos.requestFocus();
          focusScope = focusScopeVideos;
        }
      }
      if (event == "START")btnMais();      
      if (event == "2")btnEntrar();
      
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
    if (key is KeyDownEvent) {
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
    isWindowFocused = visible;
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