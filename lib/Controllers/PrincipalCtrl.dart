// ignore_for_file: file_names, use_build_context_synchronously
// // ignore_for_file: file_names

import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:v1_game/Bando%20de%20Dados/MediaCatalogo.dart';
import 'package:v1_game/Class/TecladoCtrl.dart';
import 'package:v1_game/Class/TickerProvider.dart';
import 'package:v1_game/Class/WebScrap.dart';
import 'package:v1_game/Controllers/JanelaCtrl.dart';
import 'package:v1_game/Controllers/MovimentoSistema.dart';
import 'package:v1_game/Controllers/NavWebCtrl.dart';
import 'package:v1_game/Global.dart';
import 'package:v1_game/Modelos/MediaCanal.dart';
import 'package:v1_game/Modelos/modeloVariaveisSistema.dart';
import 'package:v1_game/Modelos/videoYT.dart';
import 'package:v1_game/Widgets/ImagemFullScren.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../Bando de Dados/db.dart';
import '../Class/Paad.dart';
import '../Modelos/IconeInicial.dart';
import '../Tela/SeletorImagens.dart';
import '../Widgets/Pops.dart';

class PrincipalCtrl with ChangeNotifier{
  
  DB db = DB();  
  late BuildContext ctx;
  attTela() => notifyListeners();
  List<IconInicial> listIconsInicial = [];
  FocusNode keyboradEscutaNode = FocusNode();

  late List<FocusNode> focusNodeCardInf = [FocusNode(),FocusNode()];
  late List<FocusNode> focusNodeIcones; 
  late List<FocusNode> focusNodeMusica; 
  late List<FocusNode> focusNodeCinema; 
  late List<FocusNode> focusNodeAbaGuias;  
  List<FocusNode> focusNodeTagVid = List.generate(8, (index) => FocusNode());
  List<FocusNode> focusNodeVideos = [];
  
  CarouselSliderController carouselVideosCtrl = CarouselSliderController();
  CarouselSliderController carouselIconesCtrl =  CarouselSliderController();

  FocusScopeNode focusScope = FocusScopeNode();
  
  FocusScopeNode focusScopeMusica = FocusScopeNode();
  FocusScopeNode focusScopeCinema = FocusScopeNode();
  FocusScopeNode focusScopeAbaGuias = FocusScopeNode();
  FocusScopeNode focusScopeIcones = FocusScopeNode();
  FocusScopeNode focusScopeVideos = FocusScopeNode();
  FocusScopeNode focusScopeCardInf = FocusScopeNode();
  

  ScrollController scrolListIcones = ScrollController();  
  ScrollController scrolListStream = ScrollController();
  ScrollController scrolListMusica = ScrollController();
  
  ScrollController scrolListAbaGuias = ScrollController();

  PageController slideIconesCtrl = PageController();
  int selectedIndexCardInfo = 0;
  int selectedIndexIcone = 0;
  int selectedIndexVideo = 0;
  int selectedIndexCinema = 0;
  int selectedIndexAbaGuias = 0;
  int selectedIndexMusica = 0;

  // final ValueNotifier<int> selectedIndexNotifier = ValueNotifier<int>(0);
  Timer? timerLoadVideos;
  Timer? timerImersaoVideos;
  Timer? timerImersao;

  bool cardInf = false;
  bool cardGamesGrid = true;
  bool contadorVideo = false;
  bool imersao = false;
  bool imersaoVideos = false;
  bool gameIniciado = false;
  bool videoAtivo = false;
  bool videoCarregando = false;  
  bool stateTela = true;
  bool telaIniciada = false;
  bool videosCarregados = false;
  bool mood = false;
  bool showNewImage = false;
  String imgFundoStr = "";
  bool home = true;
  bool load = false;
  // bool trocandoView = false;
  List<VideoYT> videosYT= [];
  late VariaveisSistema cfg;
  

  PageController bodyCtrl = PageController();

  late Player mediaPlayer;
  late VideoController mediaController;
  List<String> tagVideo = ["gameplay","montage","funny","clip","dica","tutorial de","Shorts","Engraçado","lool","noticias","Novidades","Update","review","análise","walkthrough","speedrun","highlights","best moments","top plays","epic moments"];
  
  List<String> listAbaGuias= ["Games","Cinema","Musica"];
  static String cine = "Cine";
  static String musc = "Musc";
  static String gridItem = "GridItem";
  
  List<MediaCanal> listCinema = [];
  List<MediaCanal> listMusica = [];
  List<List<VideoYT>> videosIndexYT = [];
  Duration duracaoTotal = Duration.zero;
  Duration duracaoAtual = Duration.zero;

  List<String> comandoSequencia = [];
  
  late AnimationController ctrlAnimeBgFundo;
  late Animation<double> scaleAnimation;
  // late Notificacao notf;

  PrincipalCtrl(this.ctx,){
    iniciaTela();
  }

  bool get exibirVideos {
    return videosYT.isNotEmpty && telaIniciada && videosCarregados && selectedIndexAbaGuias == 0 && (cardGamesGrid && cardInf || !cardGamesGrid);
  }

  urlImgFilme(int i ){
    String str = listCinema[i].imgLocal;
    return str;
  }
  //initState
  iniciaTela() async {
    cfg = await VariaveisSistema.load();
    cardGamesGrid = cfg.viewType == "grid";
    selectedIndexIcone = 0;
    selectedIndexVideo = 0;
    selectedIndexCinema = 0;
    selectedIndexAbaGuias = 0;
    selectedIndexMusica = 0;
    
    // Inicializa media_kit player
    mediaPlayer = Player();
    mediaController = VideoController(mediaPlayer);
    
    // Escuta duração e posição
    mediaPlayer.stream.duration.listen((duration) {
      duracaoTotal = duration;
      attTela();
    });
    
    mediaPlayer.stream.position.listen((position) {
      duracaoAtual = position;
      attTela();
    });
    
    // Escuta quando o vídeo termina para tocar o próximo
    mediaPlayer.stream.completed.listen((completed) {
      if (completed && videoAtivo) {
        debugPrint("🎬 Vídeo finalizado, carregando próximo...");
        // Avança para o próximo vídeo
        int proximoIndex = selectedIndexVideo + 1;
        if (proximoIndex < videosYT.length) {
          selectedIndexVideo = proximoIndex;
          carregaNovoVideo(selectedIndexVideo - 1);
        } else {
          debugPrint("🎬 Fim da playlist, voltando ao início");
          selectedIndexVideo = 0;
          carregaNovoVideo(videosYT.length - 1);
        }
      }
    });
    
    focusNodeAbaGuias = List.generate(listAbaGuias.length, (index) => FocusNode());
    focusNodeAbaGuias[0].requestFocus();
    focusScopeIcones.requestFocus();
    focusScope = focusScopeIcones;
    selectedIndexIcone = 0;
    animaFundo();
    listCinema = MediaCatalogo.catalogoCine();
    listMusica = MediaCatalogo.catalogoMusc();
    focusNodeCinema = List.generate(listCinema.length, (index) => FocusNode());
    focusNodeMusica = List.generate(listMusica.length, (index) => FocusNode());

    await iniciaLitIcones();

    telaIniciada = true;
    showNewImage = true;
    stateTela = true;
    keyboradEscutaNode.requestFocus();
    focusNodeIcones[0].requestFocus();
    home = false;
    load = false;
    attTela();   

    // JanelaCtrl.restoreWindow("v1_game");
  }

  iniciaLitIcones()async{
    listIconsInicial = await db.leituraDeDados();
    if(listIconsInicial.isNotEmpty){
      focusNodeIcones = List.generate(listIconsInicial.length, (index) => FocusNode());
      videosIndexYT = List.generate(listIconsInicial.length, (index) => []);
      imgFundoStr = listIconsInicial.first.imgStr;
      videosYT.clear();
      pesquisaVideosYT(listIconsInicial.first.nome,0);
    }
    if(listIconsInicial.isEmpty) focusNodeIcones = [FocusNode()];
  }

  @override
  dispose(){
    timerImersao?.cancel();
    timerImersaoVideos?.cancel();
    timerLoadVideos?.cancel();
    try { mediaPlayer.dispose(); } catch (_) {}
    try { ctrlAnimeBgFundo.dispose(); } catch (_) {}
    try { scrolListIcones.dispose(); } catch (_) {}
    try { scrolListStream.dispose(); } catch (_) {}
    try { scrolListMusica.dispose(); } catch (_) {}
    try { scrolListAbaGuias.dispose(); } catch (_) {}
    try { focusScopeIcones.dispose(); } catch (_) {}
    try { focusScopeAbaGuias.dispose(); } catch (_) {}
    try { focusScopeCinema.dispose(); } catch (_) {}
    try { focusScopeMusica.dispose(); } catch (_) {}
    try { focusScopeVideos.dispose(); } catch (_) {}
    try { focusScope.dispose(); } catch (_) {}
    try { focusScopeCardInf.dispose(); } catch (_) {}
    for (var f in focusNodeIcones) { try { f.dispose(); } catch (_) {} }
    for (var f in focusNodeCinema) { try { f.dispose(); } catch (_) {} }
    for (var f in focusNodeMusica) { try { f.dispose(); } catch (_) {} }
    for (var f in focusNodeAbaGuias) { try { f.dispose(); } catch (_) {} }
    for (var f in focusNodeTagVid) { try { f.dispose(); } catch (_) {} }
    for (var f in focusNodeVideos) { try { f.dispose(); } catch (_) {} }
    debugPrint("SAIU PAGE CTRL");
    super.dispose();
  }

  pesquisaVideosYT(String nomeGame, int index) async {
    if(nomeGame.isEmpty)return;
    try{
      if(videosIndexYT[index].isEmpty) {
        String aux = tagVideo[Random().nextInt(tagVideo.length)];
        // Busca Pela Api Youtube
        // videosIndexYT[index] = await DbYoutube().buscarVideosNoYouTube("$nomeGame $aux",nomeGame);
        videosIndexYT[index] = await WebScrap.buscaVideosYT("$nomeGame $aux",nomeGame);        
      }
      videosYT = List.generate(videosIndexYT[index].length, (i) => videosIndexYT[index][i]);// videosIndexYT[index];
      focusNodeVideos = List.generate(videosYT.length, (index) => FocusNode());
      videosCarregados = true;
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
    // if (trocandoView) return;
    selectedIndexIcone = index;
      // selectedIndexNotifier.value = index; // Atualiza o índice quando um item ganha o foco
      
      // Future.delayed(Duration.zero,() {
        try {
          if (scrolListIcones.hasClients) {
            scrolListIcones.animateTo(
              index * tamanho, // Multiplica pelo tamanho do item
              duration: const Duration(milliseconds: 700),
              curve: Curves.decelerate,
            );
          }
        } catch (_) {}
  }
  mouseFora(int index,double tamanho){

  }


  
  onFocusChangeGrid(int index, String tipo ){
  
    // debugPrint("FOCO ATT VIDEO");
    if(tipo == cine) selectedIndexCinema = index;    
    if(tipo == musc) selectedIndexMusica = index;
    attTela();
    
  }

  onFocusChangeVideos(bool hasFocus, int index){ 
    if (hasFocus) {
      // debugPrint("FOCO ATT VIDEO");
      // print(index);
      selectedIndexVideo = index;
      carouselVideosCtrl.animateToPage(index);
      attTela();
    }
  }
  onFocusChangeAbaGuias(bool hasFocus, int index,{ double tamanho = 0}){
    if (!hasFocus ) return;
    selectedIndexAbaGuias = index;    
    // Movimenta Scrol para onde esta selecionado Icone
      try {
        if (scrolListAbaGuias.hasClients) {
          scrolListAbaGuias.animateTo(
            index * tamanho, // Multiplica pelo tamanho do item
            duration: const Duration(milliseconds: 700),
            curve: Curves.decelerate,
          );
        }
      } catch (_) {}
  }

  imersaoRestart() async {
    if(imersao){
      imersao = false;
      attTela();
      await Future.delayed(const Duration(milliseconds: 10));
    }
    timerImersao?.cancel();
    timerImersao = Timer(const Duration(seconds: 10), () {
      imersao = true;
      attTela();
    });    
  }

  carregaVideosDoGame(){
    selectedIndexVideo = 0;
    videosYT.clear();
    videosCarregados = false;
    timerLoadVideos?.cancel();
    timerLoadVideos = Timer(const Duration(milliseconds: 350), () {
      if(selectedIndexAbaGuias != 0)return;
      showNewImage = true;        
      if(listIconsInicial.isNotEmpty){
        imgFundoStr = listIconsInicial[selectedIndexIcone].imgStr;
        pesquisaVideosYT(listIconsInicial[selectedIndexIcone].nome,selectedIndexIcone);
      }
    });
  }


  imersaoVideoRestart() async {
    if(!videoAtivo) return imersaoVideos = false;
    if(imersaoVideos){
      imersaoVideos = false;
      attTela();
      await Future.delayed(const Duration(milliseconds: 10));
    }
    timerImersaoVideos?.cancel();
    timerImersaoVideos = Timer(const Duration(seconds: 5), () {
      imersaoVideos = true;
      attTela();
    });    
  }

  onFocusChangeIcones(bool hasFocus, int index,{ double tamanho = 0}) async{
    if (!hasFocus || selectedIndexIcone == index) return;
    if(cardGamesGrid){
      
      selectedIndexIcone = index; 
      return attTela();
    }
    try{    
      // debugPrint("FOCO ATT ICONE $index");      
      await imersaoRestart();
      showNewImage = false;
      if(selectedIndexIcone != index){
        //PAusar somente quando click estiver acionado;
        // debugPrint(e.toString());
        // debugPrint(e.toString());
      }
      selectedIndexIcone = index;      
      // selectedIndexNotifier.value = index; // Atualiza o índice quando um item ganha o foco
      
      // Future.delayed(Duration.zero,() {
      try {
        if (scrolListIcones.hasClients) {
          scrolListIcones.animateTo(
            index * tamanho, // Multiplica pelo tamanho do item
            duration: const Duration(milliseconds: 700),
            curve: Curves.decelerate,
          );
        }
      } catch (_) {}
      
      attTela();
      
      selectedIndexVideo = 0;
      videosYT.clear();
      videosCarregados = false;
      timerLoadVideos?.cancel();
      timerLoadVideos = Timer(const Duration(milliseconds: 350), () {
        if(selectedIndexAbaGuias != 0)return;
        showNewImage = true;        
        if(listIconsInicial.isNotEmpty){
          imgFundoStr = listIconsInicial[index].imgStr;
          pesquisaVideosYT(listIconsInicial[selectedIndexIcone].nome,index);
        }
      });
    }catch(e){
      debugPrint(e.toString());
      debugPrint(e.toString());
    }
  }
  
  onFocusChangeCardInf(bool hasFocus, int index) async{
    if (!hasFocus || selectedIndexCardInfo == index) return;
    try{    
      debugPrint("FOCO ATT ICONE =======================================((((((((((((((((((())))))))))))))))))) $index");
      selectedIndexCardInfo = index;
      attTela();
    }catch(e){
      debugPrint(e.toString());
      debugPrint(e.toString());
    }
  }

  carregaNovoVideo(int index) async {
    if(!videoAtivo) return;
    
    // Verifica se há vídeos disponíveis
    if (videosYT.isEmpty) {
      // Para o vídeo antes de sair
      try {
        await mediaPlayer.stop();
      } catch (_) {}
      videoAtivo = false;
      attTela();
      return;
    }
    
    if(index == selectedIndexVideo){
      int total = videosYT.length-1;
      bool primeiro = total == index;
      primeiro ? selectedIndexVideo = 0 : selectedIndexVideo = index + 1;
    }
    
    // Garante que o índice está dentro dos limites
    if (selectedIndexVideo < 0 || selectedIndexVideo >= videosYT.length) {
      selectedIndexVideo = 0;
    }
    
    contadorVideo = true;
    duracaoTotal = Duration.zero;
    duracaoAtual = Duration.zero;
   
    // Para o vídeo atual imediatamente
    try {
      await mediaPlayer.stop();
    } catch (_) {}
    
    // Mantém vídeo ativo e ativa loading IMEDIATAMENTE
    videoAtivo = true;
    videoCarregando = true;
    attTela();

    // Carrega o novo vídeo sem delay
    Timer(const Duration(milliseconds: 50), () async {
      // Verifica novamente antes de carregar
      if (videosYT.isNotEmpty && selectedIndexVideo >= 0 && selectedIndexVideo < videosYT.length) {
        
        // Extrai URL direta do YouTube
        try {
          final yt = YoutubeExplode();
          final videoId = VideoId(videosYT[selectedIndexVideo].url);
          final manifest = await yt.videos.streamsClient.getManifest(videoId);
          
          // Pega a melhor qualidade muxed (vídeo + áudio)
          final streamInfo = manifest.muxed.bestQuality;
          
          await mediaPlayer.open(Media(streamInfo.url.toString()));
          debugPrint("Novo vídeo carregado: ${streamInfo.url}");
          
          // Aguarda um pouco para o vídeo começar a renderizar
          await Future.delayed(const Duration(milliseconds: 500));
          videoCarregando = false; // Desativa o loading após vídeo carregar
          
          yt.close();
        } catch (e) {
          debugPrint("ERRO ao carregar novo vídeo: $e");
          videoCarregando = false; // Desativa loading em caso de erro
        }
        
        attTela();
      }
    });
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
      videosIndexYT = List.generate(listIconsInicial.length, (index) => []);
      Provider.of<JanelaCtrl>(ctx, listen: false).telaPresaReverse(usarEstado: true, estado: false);
      await moverIcoPosicaoInicial(listIconsInicial[selectedIndexIcone]);
      selectedIndexIcone = 0;
      focusNodeIcones[selectedIndexIcone].requestFocus();
      attTela();
      await Future.delayed(const Duration(milliseconds: 650));
      await Pops().carregandoGames(ctx,"Entrando no game..." );
      gameIniciado = false;
      Provider.of<JanelaCtrl>(ctx, listen: false).telaPresaReverse();
      // Desativa o uso do mouse;
      Provider.of<Paad>(ctx, listen: false).ativaMouse( usarEstado: true,  estado: false);
      
      // Garantir que o foco volte para o escopo correto após abrir o arquivo
      focusNodeIcones[selectedIndexIcone].requestFocus();
      focusScopeIcones.requestFocus();
      focusScope = focusScopeIcones;
    }catch(e){
      debugPrint(e.toString());
    }
  }

  moverIcoPosicaoInicial(IconInicial ico )async {
    selectedIndexIcone = 0;
    listIconsInicial.remove(ico);
    listIconsInicial.insert(0, ico);
    await db.attDados(listIconsInicial);
      try {
        if (scrolListIcones.hasClients) {
          scrolListIcones.animateTo(0,duration: const Duration(milliseconds: 700),curve: Curves.fastEaseInToSlowEaseOut,);
        }
      } catch (_) {}
  }

  btnMais() {
    try{
    stateTela = false;
    // PAD paad = pad;
    WidgetsBinding.instance.addPostFrameCallback((_) async  {

      String retorno = await Pops().popMenuTelHome2(ctx);
      debugPrint(retorno);
      if(retorno.isEmpty){ 
        stateTela = true;
        return;
      }
    
      if (retorno == "Caminho do game" || retorno == "Caminho de Imagem" || retorno == "Add") {
        debugPrint("Entrei navPasta");
        final nome = await Pops().navPasta(ctx, "", retorno, listIconsInicial, selectedIndexIcone);
        if(retorno=="Add" && nome != null && nome != ""){
          selectedIndexIcone = 0;
          await salvaImgDownload();
        }else{
          debugPrint("Sai navPasta");
          Timer(const Duration(milliseconds: 500), () => iniciaTela());  
        }
        debugPrint("Sai navPasta");
        Timer(const Duration(milliseconds: 500), () => iniciaTela());  
      }else if(retorno == "Imagem da Download"){
        salvaImgDownload();
      }
      else if (retorno == "Excluir Card") {        
        Timer(const Duration(milliseconds: 500  ),() async {
          var result = await Pops().msgSN(ctx, "Confirmar ação?");
          if(result ==  null || result == "Nao"){ 
            stateTela = true;
            return;
          }
          if(result == "Sim"){
            listIconsInicial.removeAt(selectedIndexIcone);
            await db.attDados(listIconsInicial);
            Timer(const Duration(milliseconds: 500), () => iniciaTela());
          }
        });
      }else if(retorno == "Atalhos"){
        await Pops.popTela(ctx,ImagemFullScren(urlImg: "${assetsPath}tutorial.png"));
        Timer(const Duration(milliseconds: 500), () => iniciaTela());  
      }
      else{        
        Timer(const Duration(milliseconds: 500), () => iniciaTela());
      }
      

    });
    debugPrint("Finalizei btnMais");
    }catch(e){
      debugPrint("ERO BTNMAIS === $e");
      // Pops().msgSimples(ctx,"ERRO = 1$e");
    }
  }

  imagem(){
    return Scaffold(
        body: Container(
          height: MediaQuery.of(ctx).size.height,
          width: MediaQuery.of(ctx).size.width,
        decoration: BoxDecoration(
          image: DecorationImage(
            fit: BoxFit.cover,
            image:FileImage(File("${assetsPath}tutorial.png")), //AssetImage('assets/BGICOdefault.png'),
          ),
        ),
      ),
    );
  }
  
  salvaImgDownload() async {
    videosYT.clear();
    selectedIndexVideo=0;
    stateTela = false;
    await iniciaLitIcones();
    String nomeJogo = listIconsInicial[selectedIndexIcone].nome;
    var result = await Pops.popTela(ctx, SeletorImagens(nome: nomeJogo));
    if(result == null){ 
      stateTela = true;
      return debugPrint("Retorno NULO img Download"); // ERRO NULO PARA AQUI
    }
    String novoCaminho = result as String;
    // stateTela = true;        
    novoCaminho = await WebScrap.downloadImage(novoCaminho,listIconsInicial[selectedIndexIcone].nome);
    if(novoCaminho.contains("Erro::")) {
      debugPrint(novoCaminho); // ERRO SALVAMENTO PARA AQUI
      return Timer(const Duration(milliseconds: 500), () => iniciaTela());
    }
    listIconsInicial[selectedIndexIcone].imgStr = novoCaminho;
    await db.attDados(listIconsInicial);
    load = true;
    return iniciaTela();
  }
  

  

  escutaPad(String event) async {    
    try{
      if(!stateTela || event == "") return;
      // debugPrint(" ===== Click Paad: => $event" );
      if((event == "RB"||event=="LB") && focusScope != focusScopeVideos){
        movAbaGuias(event);}
      else if(focusScope == focusScopeIcones && selectedIndexAbaGuias == 0){
        movIcones(event);}
      else if(focusScope == focusScopeCardInf && selectedIndexAbaGuias == 0){
        movCardInf(event);}
      else if(focusScope == focusScopeVideos && selectedIndexAbaGuias == 0){
        movVideos(event);}
      else if(focusScope == focusScopeCinema && selectedIndexAbaGuias == 1){
        movFilmes(event);}
      else if(focusScope == focusScopeMusica && selectedIndexAbaGuias == 2){
        movMusica(event);}      
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


  movVideos(String event) async {
    try{      
      MovimentoSistema.direcaoListView(focusScope, event);
      // imersaoVideoRestart();
      if(event=="CIMA" && !videoAtivo){
        imersaoRestart();
        cardGamesGrid ? focusScopeCardInf.requestFocus() : focusScopeIcones.requestFocus();
        focusScope = cardGamesGrid ? focusScopeCardInf : focusScopeIcones;        
      }
      if (event == "RB"){
        // mediaPlayer.seek(Duration.zero);
      }
      
      // L1: Retroceder 10 segundos
      if (event == "LB") {
        debugPrint("L1 pressionado - videoAtivo: $videoAtivo, duracaoTotal: ${duracaoTotal.inSeconds}s, duracaoAtual: ${duracaoAtual.inSeconds}s");
        if (videoAtivo && duracaoTotal != Duration.zero) {
          final novaPosicao = duracaoAtual - const Duration(seconds: 10);
          final posicaoFinal = novaPosicao.isNegative ? Duration.zero : novaPosicao;
          try {
            await mediaPlayer.seek(posicaoFinal);
            duracaoAtual = posicaoFinal; // Atualiza imediatamente a posição
            attTela(); // Força atualização da barra de progresso
            debugPrint("✓ Retrocedeu para: ${posicaoFinal.inSeconds}s");
          } catch (e) {
            debugPrint("✗ Erro ao retroceder: $e");
          }
        }
      }
      
      // R1: Avançar 10 segundos
      if (event == "RB") {
        debugPrint("R1 pressionado - videoAtivo: $videoAtivo, duracaoTotal: ${duracaoTotal.inSeconds}s, duracaoAtual: ${duracaoAtual.inSeconds}s");
        if (videoAtivo && duracaoTotal != Duration.zero) {
          final novaPosicao = duracaoAtual + const Duration(seconds: 10);
          final posicaoFinal = novaPosicao > duracaoTotal ? duracaoTotal : novaPosicao;
          try {
            await mediaPlayer.seek(posicaoFinal);
            duracaoAtual = posicaoFinal; // Atualiza imediatamente a posição
            attTela(); // Força atualização da barra de progresso
            debugPrint("✓ Avançou para: ${posicaoFinal.inSeconds}s");
          } catch (e) {
            debugPrint("✗ Erro ao avançar: $e");
          }
        }
      }
      
      if(event=="R3") { imersaoVideos = !imersaoVideos;}
      if(event.contains("RT-")) TecladoCtrl.aumentarVolume();
      if(event.contains("LT-")) TecladoCtrl.diminuirVolume();
      if (event == "START") mediaPlayer.playOrPause();
      if (event == "2") {
        // Verifica se há vídeos disponíveis antes de ativar
        if (videosYT.isEmpty || selectedIndexVideo < 0 || selectedIndexVideo >= videosYT.length) {
          debugPrint("ERRO: Não há vídeos disponíveis ou índice inválido");
          return;
        }
        
        duracaoTotal = Duration.zero;
        duracaoAtual = Duration.zero;
        
        // Para o vídeo atual imediatamente
        try {
          await mediaPlayer.stop();
        } catch (_) {}
        
        // Ativa vídeo e loading IMEDIATAMENTE ao clicar
        videoAtivo = true;
        videoCarregando = true;
        attTela();
        
        Timer(const Duration(milliseconds: 50), () async {
          if (videosYT.isNotEmpty && selectedIndexVideo >= 0 && selectedIndexVideo < videosYT.length) {
            contadorVideo = true;
            
            // Extrai URL direta do YouTube e abre no media_kit
            try {
              final yt = YoutubeExplode();
              final videoId = VideoId(videosYT[selectedIndexVideo].url);
              final manifest = await yt.videos.streamsClient.getManifest(videoId);
              
              // Pega a melhor qualidade muxed (vídeo + áudio)
              final streamInfo = manifest.muxed.bestQuality;
              
              await mediaPlayer.open(Media(streamInfo.url.toString()));
              debugPrint("Vídeo aberto: ${streamInfo.url}");
              
              // Aguarda um pouco para o vídeo começar a renderizar
              await Future.delayed(const Duration(milliseconds: 500));
              videoCarregando = false; // Desativa loading
              
              yt.close();
            } catch (e) {
              debugPrint("ERRO ao abrir vídeo do YouTube: $e");
              videoCarregando = false; // Desativa loading em caso de erro
            }
            
            attTela();
          }
        });
      }
      if (event == "3" || event == "BAIXO"){
        imersaoVideos = false;
        
        // Para o vídeo imediatamente ao sair
        try {
          await mediaPlayer.stop();
          debugPrint("Vídeo parado ao sair");
        } catch (_) {}
        
        videoAtivo = false;
        attTela();
      }
    }catch(e){
      debugPrint("ERRO CLICK PAD VIDEOS  $e");
    }

  }

  sairDaTelaMedia(String url, String texto)async {
    
      gameIniciado = true;
      // Liberar Tela do sistema
      Provider.of<JanelaCtrl>(ctx, listen: false).telaPresaReverse(usarEstado: true, estado: false);
      // Ativar Mouse
      Provider.of<Paad>(ctx, listen: false).ativaMouse(usarEstado: true,  estado: true);
      await NavWebCtrl.openLink(url);
      // await Future.delayed(const Duration(milliseconds: 650));
      await Pops().carregandoGames(ctx, texto);
      // Desativa o uso do mouse;
      Provider.of<Paad>(ctx, listen: false).ativaMouse( usarEstado: true,  estado: false);
      // Trava na tela novamente
      // Provider.of<JanelaCtrl>(ctx, listen: false).telaPresaReverse();
      gameIniciado = false;
  }

  movAbaGuias(String event) async {
    if(gameIniciado) return;
    
    if(event=="LB"){
      // focusScope = focusScopeIcones;
      if(focusScope == focusScopeCinema){

        // MovimentoSistema.direcaoListView(focusScope, "DIREITA");e
        focusScope = cardGamesGrid && cardInf ? focusScopeCardInf : focusScopeIcones;
        cardGamesGrid && cardInf ? focusNodeCardInf[selectedIndexCardInfo].requestFocus() : focusNodeIcones[selectedIndexIcone].requestFocus();
        if(selectedIndexIcone != 0) selectedIndexIcone --;
        
      }
      else if(focusScope == focusScopeMusica){
        focusScope = focusScopeCinema;
        focusNodeCinema[selectedIndexCinema].requestFocus();
      }
      focusScopeAbaGuias.focusInDirection(TraversalDirection.left);
      // focusNodeIcones[selectedIndexIcone].requestFocus();
      bodyCtrl.previousPage(duration: const Duration(milliseconds: 500), curve: Curves.decelerate); 
    }
    if(event=="RB"){      
      // focusNodeCinema[selectedIndexCinema].requestFocus();
      if(focusScope == focusScopeIcones){
        focusScope = focusScopeCinema;
        focusNodeCinema[selectedIndexCinema].requestFocus();
      }
      else if(focusScope == focusScopeCinema){
        focusScope = focusScopeMusica;
        focusNodeMusica[selectedIndexMusica].requestFocus();
      }
      
      focusScopeAbaGuias.focusInDirection(TraversalDirection.right);
      bodyCtrl.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.decelerate);
    }
  }

  movCardGrid(String event) async {    
    MovimentoSistema.direcaoListView(focusScope, event);
    if(gameIniciado) {
      if(event == "3") Navigator.pop(ctx);
      return;
    }    
    if (event == "START") {
      btnMais();
    }else if (event == "2"){
      if(!cardInf){
        cardInf = true;
        focusScopeCardInf.requestFocus();
        focusScope = focusScopeCardInf;
        focusNodeCardInf[0].requestFocus();
        carregaVideosDoGame();
      }
    }else if (event == 'SELECT'){
      trocaViewIcones();
    }
  
  }
  
  movMusica(String event) async {    
    MovimentoSistema.direcaoListView(focusScope, event);
    if(gameIniciado) {
      if(event == "3") Navigator.pop(ctx);
      return;
    }
    if (event == "2"){
      await sairDaTelaMedia(listMusica[selectedIndexMusica].url, "Festa Ativa!");
      // Garantir que o foco volte para o escopo correto após abrir o arquivo
      focusNodeMusica[selectedIndexMusica].requestFocus();
      focusScopeMusica.requestFocus();
      focusScope = focusScopeMusica;
    }
  }

  movFilmes(String event) async {    
    MovimentoSistema.direcaoListView(focusScope, event);
    if(gameIniciado) {
      if(event == "3") Navigator.pop(ctx);
      return;
    }
    if (event == "2"){
      await sairDaTelaMedia(listCinema[selectedIndexCinema].url, "Comendo pipoca.");
      // Garantir que o foco volte para o escopo correto após abrir o arquivo
      focusNodeCinema[selectedIndexCinema].requestFocus();
      focusScopeCinema.requestFocus();
      focusScope = focusScopeCinema;
    }
  }

  movCardInf(String event) async {
    try{
      String result = MovimentoSistema.direcaoListView(focusScope, event);
      if(gameIniciado) {
        if(event == "3") Navigator.pop(ctx);
        return;
      }
      if(result == MovimentoSistema.horizontal || result == MovimentoSistema.vertical  ){
        // desativado temporariamente
        if(event=="BAIXO"){
          debugPrint("Lista VIDEOS :${videosYT.length}");
          if(videosYT.isNotEmpty){
            focusNodeVideos[selectedIndexVideo].requestFocus();
            focusScopeVideos.requestFocus();
            focusScope = focusScopeVideos;
          }
        }
      }else if(event == "3" || event == "2" && selectedIndexCardInfo == 1){
        cardInf = false;
        focusScopeIcones.requestFocus();
        focusScope = focusScopeIcones;
        focusNodeIcones[selectedIndexIcone].requestFocus();
      }else if (event == "2" && selectedIndexCardInfo == 0){
        btnEntrar();
      }else if (event == "START"){
        btnMais();
      }
    }catch(e){
      debugPrint("ERRO CLICK PAD CARD INF $e");
    }
  
  }

  movIcones(String event){
     try{
      if(gameIniciado) {
        if(event == "3") Navigator.pop(ctx);
        return;
      }
      if(cardGamesGrid) return movCardGrid(event);
      String result = MovimentoSistema.direcaoListView(focusScope, event);
      debugPrint(result);

      if(result == MovimentoSistema.horizontal || result == MovimentoSistema.vertical  ){
        // desativado temporariamente
        if(event=="BAIXO"){
          debugPrint("Lista VIDEOS :${videosYT.length}");
          if(videosYT.isNotEmpty){
            focusNodeVideos[selectedIndexVideo].requestFocus();
            focusScopeVideos.requestFocus();
            focusScope = focusScopeVideos;
          }
        }
      }
      
      if (event == 'SELECT')trocaViewIcones();
      if (event == "START")btnMais();      
      if (event == "2")btnEntrar();
      // if(event == "4")mostrarBottomSheet();
      
    }catch(e){
      debugPrint(e.toString());
      // Pops().msgSimples(ctx,"ERRO = 1$e");
    }
  }

  trocaViewIcones() async {
    // Salva o índice atual antes de trocar
    // final indexAtual = selectedIndexIcone;
    
    // Bloqueia operações
    
    // Troca o modo de visualização
    cardGamesGrid = !cardGamesGrid;
    cfg.viewType = cardGamesGrid ? "grid" : "list";
    cfg.save();
    
    // Atualiza a tela para reconstruir com novo layout
    // attTela();
    
    // Aguarda a reconstrução completa do widget
    // await Future.delayed(const Duration(milliseconds: 150));
    
    // Após reconstrução, recalcula e reposiciona
    // WidgetsBinding.instance.addPostFrameCallback((_) async {
    //   // Aguarda mais um frame para garantir que o layout está pronto
    //   await Future.delayed(const Duration(milliseconds: 50));
      
    //   // Reaplica o foco no índice correto
    //   if (indexAtual >= 0 && indexAtual < focusNodeIcones.length) {
    //     selectedIndexIcone = indexAtual;
    //     focusNodeIcones[indexAtual].requestFocus();
        
    //     // Se o controller tem clientes (widget montado), posiciona sem animação
    //     if (scrolListIcones.hasClients) {
    //       try {
    //         // Calcula posição aproximada baseada no índice (ajuste conforme tamanho do item)
    //         const tamanhoItem = 380.0; // Ajuste conforme seu tamanho de item
    //         final posicao = indexAtual * tamanhoItem;
    //         scrolListIcones.jumpTo(posicao.clamp(0.0, scrolListIcones.position.maxScrollExtent));
    //       } catch (e) {
    //         debugPrint("Erro ao posicionar scroll: $e");
    //       }
    //     }
    //   }
      
    //   // Desbloqueia operações
    //   // Força atualização final
    //   attTela();
    // });
  }
  

  

  
  keyPress(KeyEvent key) async {
    if (key is KeyDownEvent || key is KeyRepeatEvent) {
      debugPrint("Teclado Press: ${key.logicalKey.debugName}");
      String event = MovimentoSistema.convertKeyBoard(key.logicalKey.keyLabel);
      escutaPad(event);
    }
  }

  





}