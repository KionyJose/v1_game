// ignore_for_file: file_names, use_build_context_synchronously
// // ignore_for_file: file_names

import 'dart:async';
import 'dart:math';

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:v1_game/Bando%20de%20Dados/dbYoutube.dart';
import 'package:v1_game/Class/TickerProvider.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:v1_game/Controllers/MovimentoSistema.dart';
import 'package:v1_game/Controllers/PastaCtl.dart';
import 'package:v1_game/Metodos/videoYT.dart';

import '../Bando de Dados/db.dart';
import '../Modelos/IconeInicial.dart';
import '../Widgets/Pops.dart';

class PrincipalCtrl with ChangeNotifier{
  

  bool videoAtivo = false;
  int indexFcs = 0;
  late List<FocusNode> focusNodeIcones;  
  late List<FocusNode> focusNodeVideos = List.generate(6, (index) => FocusNode());
  List<IconInicial> listIconsInicial = [];
  // FocusNode focoPrincipal = FocusNode();
  DB db = DB();
  String keyPressed = '';
  int selectedIndexIcone = 0;
  int selectedIndexVideo = 0;
  late FocusScopeNode focusScope;
  FocusScopeNode focusScopeIcones = FocusScopeNode();
  FocusScopeNode focusScopeVideos = FocusScopeNode();
  double positionX = 0;
  double positionY = 0;
  // PastaCtrl pastaCtrl = PastaCtrl();

  bool stateTela = true;
  bool telaIniciada = false;
  bool mood = false;
  String imgFundoStr = "";
  List<VideoYT> videosYT= [];

  ScrollController scrolListIcones = ScrollController();
  PageController slideIconesCtrl = PageController();

  CarouselSliderController carouselVideosCtrl = CarouselSliderController();
  CarouselSliderController carouselIconesCtrl = CarouselSliderController();


  bool isWindowFocused = true;
  List<String> tagVideo = ["gameplay","montage","funny","clip","dica","tutorial de"];  
  List<String> comandoSequencia = [];
  
  late AnimationController ctrlAnimeBgFundo;
  late Animation<double> scaleAnimation;
  late bool showNewImage = false;
  attTela() => notifyListeners();
  late BuildContext ctx;
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
    attTela();
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

  pesquisaVideosYT(String nomeGame) async {
    if(nomeGame.isEmpty)return;
    try{
      videosYT = await DbYoutube().buscarVideosNoYouTube("$nomeGame gameplay noticias");
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
      Future.delayed(const Duration(milliseconds: 1), () { 
        // debugPrint("Entriiiiii");
        // showNewImage = true;
        // attTela();
      });
    }
  }

  onFocusChangeIcones(bool hasFocus, int index){     
      debugPrint("FOCO ATT ICONE");          
    if (hasFocus) {      
      showNewImage = false;             
      selectedIndexIcone = index;
      slideIconesCtrl.animateToPage(selectedIndexIcone, duration: const Duration(milliseconds: 700), curve: Curves.decelerate);
      // scrollToNextIcon();
      // carouselIconesCtrl.animateToPage(index);s
      Future.delayed(const Duration(milliseconds: 350),() {
        showNewImage = true;        
        if(listIconsInicial.isNotEmpty) imgFundoStr = listIconsInicial[index].imgStr;
      });
    }
  }

  void moovScrolListIcones(int index) {
    
    // if (index >= 0 && index < focusNodeIcones.length) {
    //   scrolListIcones. animateTo(
    //     index * MediaQuery.of(ctx).size.width * 0.22, // Ajuste para o tamanho real do item
    //     duration: const Duration(milliseconds: 300),
    //     curve: Curves.easeInOut,
    //   );
    // }
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
      debugPrint("ERO BTNMAIS === "+e.toString());
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
      iniciaTela();
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
      iniciaTela();
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
      debugPrint("ERRO LCICK PAD VIDEOS  "+e.toString());
    }

  }
  movIcones(String event){
     try{      
      String direction = MovimentoSistema.direcaoListView(focusScope, event);
      if(direction == MovimentoSistema.horizontal){//ESQUERDA ou DIREITA
        videosYT = [];
        String proximoNome = getNextGameName();
        debugPrint("Jogo selecionado: $proximoNome");
        Timer(const Duration(milliseconds: 300),(){
          moovScrolListIcones(selectedIndexIcone);
          // pesquisaVideosYT(proximoNome);          
        });
        // pesquisaVideosYT(proximoNome);
      }
      if(event=="BAIXO"){
        debugPrint("Lista VIDEOS :${videosYT.length}");
        if(videosYT.isNotEmpty){
          focusScopeVideos.requestFocus();
          focusScope = focusScopeVideos;
        }
      }
      if (event == "START") {
        //START
        btnMais();
      }
      if (event == "2") {
        //Entrar
        btnEntrar();
      }
      // attTela();
    }catch(e){
      debugPrint(e.toString());
      
        Pops().msgSimples(ctx,"ERRO = 1$e");
    }
  }
  String getNextGameName() {
    if (listIconsInicial.isEmpty) return ""; // Verifica se a lista está vazia
    int nextIndex = (selectedIndexIcone + 1) % listIconsInicial.length; // Calcula o próximo índice (volta ao início se ultrapassar)
    return listIconsInicial[nextIndex].nome; // Retorna o nome do próximo jogo
  }

  clickVideo() async {    
    if(videoAtivo) {
      videoAtivo = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {          
        videoAtivo = true;
        attTela();
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



  // keyPress(KeyEvent event) async {
  //   if (event is KeyDownEvent) {
            
  //           debugPrint(event.logicalKey.debugName);
  //           if(event.logicalKey == LogicalKeyboardKey.digit2){//entrar
  //             db.openFile(listIconsInicial[selectedIndex].local);
  //           }
  //           if(event.logicalKey == LogicalKeyboardKey.digit3){//sair
  //             //  db.openFile("D:\\GAMES\\HOGWARTS LEGACY\\Hogwarts Legacy\\Phoenix\\Binaries\\Win64\\HogwartsLegacy.exe");
  //             //openFile("C:\\Users\\Public\\Documents\\Bingo Grandioso\\BingoPresencial.exe");
  //           }

  //           if(event.logicalKey == LogicalKeyboardKey.enter){//Menu
  //             String retorno = await Pops().popMenuTelHome(context,listViewFocus);
  //             debugPrint(retorno);
  //             if(retorno == "Caminho do game" || retorno == "Imagem de capa" ){
  //               await pastaCtrl.navPasta(context,"",retorno, listIconsInicial, selectedIndex );
  //               iniciaTela();
  //             }
  //           }

  //           if (event.logicalKey == LogicalKeyboardKey.keyW) {
  //             listViewFocus.focusInDirection(TraversalDirection.up);
  //           } else if (event.logicalKey == LogicalKeyboardKey.keyA ) {
  //             listViewFocus.focusInDirection(TraversalDirection.left );
  //           } else if (event.logicalKey == LogicalKeyboardKey.keyS) {
  //             listViewFocus.focusInDirection(TraversalDirection.down);
  //           } else if (event.logicalKey == LogicalKeyboardKey.keyD) {
  //             listViewFocus.focusInDirection(TraversalDirection.right);
  //           }
            
  //         }
  

}