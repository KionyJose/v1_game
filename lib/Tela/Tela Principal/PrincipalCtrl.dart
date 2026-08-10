// ignore_for_file: file_names, use_build_context_synchronously

import 'dart:async';
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
import 'package:v1_game/Controllers/SonsSistema.dart';
import 'package:v1_game/Global.dart';
import 'package:v1_game/Modelos/MediaCanal.dart';
import 'package:v1_game/Modelos/NoticiaGame.dart';
import 'package:v1_game/Modelos/videoYT.dart';
import 'package:v1_game/Tela/games_busca.dart/games_busca_tela.dart';
import 'package:v1_game/Widgets/ImagemFullScren.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:v1_game/Widgets/Pops/pop_config.dart';
import 'package:v1_game/Widgets/Pops/pop_mais.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart';
import '../../Bando de Dados/db.dart';
import '../../Class/Paad.dart';
import '../../Modelos/IconeInicial.dart';
import '../SeletorImagens/SeletorImagens.dart';
import '../../Widgets/Pops/Pops.dart';

class PrincipalCtrl with ChangeNotifier{
  
  DB db = DB();  
  bool _disposed = false;
  late BuildContext ctx;
  attTela() {
    if(_disposed) return;
    notifyListeners();
  }
  List<IconInicial> listIconsInicial = [];
  FocusNode keyboradEscutaNode = FocusNode();

  late List<FocusNode> focusNodeCardInf = [FocusNode(),FocusNode()];
  late List<FocusNode> focusNodeIcones; 
  late List<FocusNode> focusNodeMusica; 
  late List<FocusNode> focusNodeCinema; 
  late List<FocusNode> focusNodeAbaGuias;  
  List<FocusNode> focusNodeVideos = [];
  List<FocusNode> focusNodeNoticias = [];
  
  CarouselSliderController carouselVideosCtrl = CarouselSliderController();
  
  // Callback para abrir notícia no Widget
  void Function(NoticiaGame)? abrirNoticiaCallback;
  // Controle de popup de notícia — recebe eventos de gamepad enquanto aberto
  NoticiaGame? noticiaPopupAberta;
  VoidCallback? fecharNoticiaPopup;

  FocusScopeNode focusScope = FocusScopeNode();
  
  FocusScopeNode focusScopeMusica = FocusScopeNode();
  FocusScopeNode focusScopeCinema = FocusScopeNode();
  FocusScopeNode focusScopeAbaGuias = FocusScopeNode();
  FocusScopeNode focusScopeIcones = FocusScopeNode();
  FocusScopeNode focusScopeVideos = FocusScopeNode();
  FocusScopeNode focusScopeCardInf = FocusScopeNode();
  FocusScopeNode focusScopeNoticias = FocusScopeNode();
  

  ScrollController scrolListIcones = ScrollController();  
  ScrollController scrolListAbaGuias = ScrollController();
  int selectedIndexCardInfo = 0;
  int selectedIndexIcone = 0;
  int selectedIndexVideo = 0;
  int selectedIndexCinema = 0;
  int selectedIndexAbaGuias = 0;
  int selectedIndexMusica = 0;
  int selectedIndexNoticia = 0;
  int cinemaScrollTopRequest = 0;
  int musicaScrollTopRequest = 0;

  // final ValueNotifier<int> selectedIndexNotifier = ValueNotifier<int>(0);
  Timer? timerLoadVideos;
  Timer? timerFundoCard;
  Timer? timerImersaoVideos;
  Timer? timerImersao;

  bool cardInf = false;
  bool cardGamesGrid = false;
  bool cardGamesModerno = false;
  bool cardGamesRetro = false;
  bool contadorVideo = false;
  bool imersao = false;
  bool imersaoVideos = false;
  bool gameIniciado = false;
  bool videoAtivo = false;
  bool videoCarregando = false;  
  bool stateTela = true;
  bool telaIniciada = false;
  bool videosCarregados = false;
  bool showNewImage = false;
  bool showBgVideo = false;
  int _fundoCardVersao = 0;
  String imgFundoStr = "";
  bool home = true;
  bool load = false;
  List<VideoYT> videosYT= [];
  List<NoticiaGame> noticias = []; 
  bool loadingNoticias = false;
  bool get mouseBloqueado => load || gameIniciado || !stateTela;
  

  PageController bodyCtrl = PageController();

  late Player mediaPlayer;
  late VideoController mediaController;
  late Player bgMediaPlayer;
  late VideoController bgMediaController;
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
  
  late AnimationController ctrlAnimeBgFundo;
  late Animation<double> scaleAnimation;
  // late Notificacao notf;

  PrincipalCtrl(this.ctx,){
    iniciaTela();
  }

  String _prettifyName(String raw) {
    if (raw.isEmpty) return raw;
    // replace underscores/hyphens with space
    var s = raw.replaceAll(RegExp(r'[_\-]+'), ' ');
    // insert space before capital letters that follow a lowercase/digit (CamelCase -> Camel Case)
    s = s.replaceAllMapped(RegExp(r'(?<=[a-z0-9])([A-Z])'), (m) => ' ${m[1]}');
    // collapse multiple spaces and trim
    s = s.replaceAll(RegExp(r'\s+'), ' ').trim();
    // capitalize each word
    s = s.split(' ').map((w) {
      if (w.isEmpty) return w;
      return w.length == 1 ? w.toUpperCase() : (w[0].toUpperCase() + w.substring(1));
    }).join(' ');
    return s;
  }

  bool get exibirVideos {
    return 
    configSistema.videosTelaPrincipal &&
    videosYT.isNotEmpty &&
    telaIniciada &&
    videosCarregados &&
    selectedIndexAbaGuias == 0 &&
    !cardGamesGrid &&
    !cardGamesModerno &&
    !cardGamesRetro;
  }

  urlImgFilme(int i ){
    String str = listCinema[i].imgLocal;
    return str;
  }

  iniciaTela() async {
    if(_disposed) return;
    cardGamesGrid = configSistema.viewType == "grid";
    cardGamesModerno = configSistema.viewType == "moderno";
    cardGamesRetro = configSistema.viewType == "retro";
    selectedIndexIcone = 0;
    selectedIndexVideo = 0;
    selectedIndexCinema = 0;
    selectedIndexAbaGuias = 0;
    selectedIndexMusica = 0;
    
    // Inicializa media_kit player
    mediaPlayer = Player();
    mediaController = VideoController(mediaPlayer);
    bgMediaPlayer = Player();
    bgMediaController = VideoController(bgMediaPlayer);
    bgMediaPlayer.setVolume(0);
    
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
    listCinema = await MediaCatalogo.catalogoCine();
    listMusica = await MediaCatalogo.catalogoMusc();
    focusNodeCinema = List.generate(listCinema.length, (index) => FocusNode());
    focusNodeMusica = List.generate(listMusica.length, (index) => FocusNode());

    await iniciaLitIcones();
    if(_disposed) return;

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
      try {
        for (final f in focusNodeIcones) {
          f.dispose();
        }
      } catch (_) {}
      focusNodeIcones = List.generate(listIconsInicial.length, (index) => FocusNode());
      videosIndexYT = List.generate(listIconsInicial.length, (index) => []);
      selectedIndexIcone = selectedIndexIcone.clamp(0, listIconsInicial.length - 1);
      imgFundoStr = listIconsInicial.first.imgStr;
      videosYT.clear();
      pesquisaVideosYT(listIconsInicial.first.nome,0);
    }
    if(listIconsInicial.isEmpty) {
      try {
        for (final f in focusNodeIcones) {
          f.dispose();
        }
      } catch (_) {}
      selectedIndexIcone = 0;
      focusNodeIcones = [FocusNode()];
    }
  }

  @override
  dispose(){
    _disposed = true;
    timerImersao?.cancel();
    timerImersaoVideos?.cancel();
    timerLoadVideos?.cancel();
    timerFundoCard?.cancel();
    try { mediaPlayer.dispose(); } catch (_) {}
    try { bgMediaPlayer.dispose(); } catch (_) {}
    try { ctrlAnimeBgFundo.dispose(); } catch (_) {}
    try { scrolListIcones.dispose(); } catch (_) {}
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
    for (var f in focusNodeVideos) { try { f.dispose(); } catch (_) {} }
    debugPrint("SAIU PAGE CTRL");
    super.dispose();
  }

  pesquisaVideosYT(String nomeGame, int index) async {
    if(nomeGame.isEmpty)return;
    try{
      if(videosIndexYT[index].isEmpty) {
        String aux = tagVideo[Random().nextInt(tagVideo.length)];
        videosIndexYT[index] = await WebScrap.buscaVideosYT("$nomeGame $aux",nomeGame);        
      }
      videosYT = List.generate(videosIndexYT[index].length, (i) => videosIndexYT[index][i]);
      focusNodeVideos = List.generate(videosYT.length, (index) => FocusNode());
      videosCarregados = true;
      attTela();
    }catch(e){
      debugPrint(e.toString());
    }  
  }

  mouseDentro(int index,double tamanho){
    if(_disposed) return;
    if(mouseBloqueado) return;
    selectedIndexIcone = index;
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

  mouseFora(int index, double tamanho) {
    if(mouseBloqueado) return;
    // Método vazio - usado por MouseRegion em cardAnimado
  }

  onFocusChangeGrid(int index, String tipo ){
    if(tipo == cine) selectedIndexCinema = index;    
    if(tipo == musc) selectedIndexMusica = index;
    attTela();
    
  }

  onFocusChangeVideos(bool hasFocus, int index){ 
    if (hasFocus) {
      selectedIndexVideo = index;
      carouselVideosCtrl.animateToPage(index);
      attTela();
    }
  }
  onFocusChangeAbaGuias(bool hasFocus, int index,{ double tamanho = 0}){
    if(_disposed) return;
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
      if(_disposed) return;
      if(selectedIndexAbaGuias != 0)return;
      showNewImage = true;        
      if(listIconsInicial.isNotEmpty){
        imgFundoStr = listIconsInicial[selectedIndexIcone].imgStr;
        pesquisaVideosYT(listIconsInicial[selectedIndexIcone].nome,selectedIndexIcone);
      }
    });
  }

  void agendarFundoCard(int index) {
    if(index < 0 || index >= listIconsInicial.length) return;
    if(!cardGamesRetro) {
      aplicarFundoImagem(index);
      return;
    }

    final versao = ++_fundoCardVersao;
    timerFundoCard?.cancel();
    timerLoadVideos?.cancel();
    showNewImage = false;
    showBgVideo = false;
    selectedIndexVideo = 0;
    videosYT.clear();
    videosCarregados = false;
    try { bgMediaPlayer.stop(); } catch (_) {}
    attTela();

    timerFundoCard = Timer(const Duration(milliseconds: 1500), () async {
      if(_disposed) return;
      if(versao != _fundoCardVersao || selectedIndexIcone != index || selectedIndexAbaGuias != 0) return;

      final item = listIconsInicial[index];
      var videoAberto = false;

      if(item.nome.isNotEmpty) {
        YoutubeExplode? yt;
        try {
          yt = YoutubeExplode();
          final pesquisa = await yt.search.search('${item.nome} gameplay');
          final resultado = pesquisa.first;
          final manifest = await yt.videos.streamsClient.getManifest(resultado.id);
          final stream = manifest.muxed.bestQuality;

          if(versao == _fundoCardVersao && selectedIndexIcone == index && selectedIndexAbaGuias == 0) {
            await bgMediaPlayer.open(Media(stream.url.toString()));
            await bgMediaPlayer.setVolume(0);
            showBgVideo = true;
            showNewImage = false;
            videoAberto = true;
            attTela();
            pesquisaVideosYT(item.nome, index);
          }
        } catch (e) {
          debugPrint('Fundo video indisponivel: $e');
        } finally {
          yt?.close();
        }
      }

      if(videoAberto || versao != _fundoCardVersao || selectedIndexIcone != index || selectedIndexAbaGuias != 0) return;

      imgFundoStr = item.imgStr;
      showBgVideo = false;
      showNewImage = true;
      attTela();

      if(versao == _fundoCardVersao && selectedIndexIcone == index && selectedIndexAbaGuias == 0) {
        pesquisaVideosYT(item.nome, index);
      }
    });
  }

  void aplicarFundoImagem(int index) {
    if(index < 0 || index >= listIconsInicial.length) return;
    timerFundoCard?.cancel();
    showBgVideo = false;
    showNewImage = true;
    imgFundoStr = listIconsInicial[index].imgStr;
    try { bgMediaPlayer.stop(); } catch (_) {}
    attTela();
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
    if(_disposed) return;
    if (!hasFocus || selectedIndexIcone == index) return;
    if(cardGamesGrid){
      
      selectedIndexIcone = index; 
      return attTela();
    }
    try{    
      await imersaoRestart();
      if(_disposed) return;
      showNewImage = false;
      selectedIndexIcone = index;
      
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

      if(!cardGamesModerno && !cardGamesRetro && !cardGamesGrid) {
        aplicarFundoImagem(index);
        carregaVideosDoGame();
      } else {
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
      }
    }catch(e){
      debugPrint(e.toString());
    }
  }
  
  onFocusChangeCardInf(bool hasFocus, int index) async{
    if (!hasFocus || selectedIndexCardInfo == index) return;
    try{    
      selectedIndexCardInfo = index;
      attTela();
    }catch(e){
      debugPrint(e.toString());
    }
  }

  void abrirCardInfDoJogoAtual() {
    if (listIconsInicial.isEmpty) return;
    cardInf = true;
    selectedIndexCardInfo = 0;
    focusScopeCardInf.requestFocus();
    focusScope = focusScopeCardInf;
    focusNodeCardInf[0].requestFocus();
    carregaVideosDoGame();
    attTela();
  }

  Future<void> adicionarMediaCard(String tipo) async {
    try {
      stateTela = false;
      final novo = await Pops.popNovoMediaCard(ctx, tipo);
      if (novo != null) {
        if (tipo == cine) {
          listCinema.insert(0, novo);
          await MediaCatalogo.salvarCatalogo('cinema', listCinema);
          for (final f in focusNodeCinema) {
            try { f.dispose(); } catch (_) {}
          }
          focusNodeCinema =
              List.generate(listCinema.length, (index) => FocusNode());
          selectedIndexCinema = 0;
          focusNodeCinema[selectedIndexCinema].requestFocus();
          focusScopeCinema.requestFocus();
          focusScope = focusScopeCinema;
        } else {
          listMusica.insert(0, novo);
          await MediaCatalogo.salvarCatalogo('musica', listMusica);
          for (final f in focusNodeMusica) {
            try { f.dispose(); } catch (_) {}
          }
          focusNodeMusica =
              List.generate(listMusica.length, (index) => FocusNode());
          selectedIndexMusica = 0;
          focusNodeMusica[selectedIndexMusica].requestFocus();
          focusScopeMusica.requestFocus();
          focusScope = focusScopeMusica;
        }
      }
    } catch (e) {
      debugPrint('ERRO adicionarMediaCard $e');
    } finally {
      stateTela = true;
      attTela();
    }
  }

  Future<void> editarMediaCard(String tipo, int index) async {
    try {
      stateTela = false;
      final lista = tipo == cine ? listCinema : listMusica;
      if (index < 0 || index >= lista.length) return;
      final editado = await Pops.popNovoMediaCard(ctx, tipo, inicial: lista[index]);
      if (editado == null) return;

      lista[index] = editado;
      await MediaCatalogo.salvarCatalogo(tipo == cine ? 'cinema' : 'musica', lista);
      if (tipo == cine) {
        selectedIndexCinema = index.clamp(0, listCinema.length - 1);
        focusNodeCinema[selectedIndexCinema].requestFocus();
        focusScopeCinema.requestFocus();
        focusScope = focusScopeCinema;
      } else {
        selectedIndexMusica = index.clamp(0, listMusica.length - 1);
        focusNodeMusica[selectedIndexMusica].requestFocus();
        focusScopeMusica.requestFocus();
        focusScope = focusScopeMusica;
      }
    } catch (e) {
      debugPrint('ERRO editarMediaCard $e');
    } finally {
      stateTela = true;
      attTela();
    }
  }

  Future<void> removerMediaCard(String tipo, int index) async {
    try {
      stateTela = false;
      final lista = tipo == cine ? listCinema : listMusica;
      if (index < 0 || index >= lista.length) return;
      final nome = lista[index].nome;
      final ok = await Pops().msgSN(ctx, 'Remover "$nome"?');
      try {
        final paad = Provider.of<Paad>(ctx, listen: false);
        paad.click = "";
        paad.delay = true;
        paad.attTela();
        Timer(const Duration(milliseconds: 350), () { if(!_disposed) paad.delay = false; });
      } catch (_) {}
      if (ok != 'Sim') return;

      lista.removeAt(index);
      await MediaCatalogo.salvarCatalogo(tipo == cine ? 'cinema' : 'musica', lista);
      if (tipo == cine) {
        for (final f in focusNodeCinema) {
          try { f.dispose(); } catch (_) {}
        }
        focusNodeCinema = List.generate(listCinema.length, (_) => FocusNode());
        selectedIndexCinema = listCinema.isEmpty
            ? 0
            : index.clamp(0, listCinema.length - 1);
        focusScopeCinema.requestFocus();
        focusScope = focusScopeCinema;
        if (focusNodeCinema.isNotEmpty) {
          focusNodeCinema[selectedIndexCinema].requestFocus();
        }
      } else {
        for (final f in focusNodeMusica) {
          try { f.dispose(); } catch (_) {}
        }
        focusNodeMusica = List.generate(listMusica.length, (_) => FocusNode());
        selectedIndexMusica = listMusica.isEmpty
            ? 0
            : index.clamp(0, listMusica.length - 1);
        focusScopeMusica.requestFocus();
        focusScope = focusScopeMusica;
        if (focusNodeMusica.isNotEmpty) {
          focusNodeMusica[selectedIndexMusica].requestFocus();
        }
      }
      try {
        final paad = Provider.of<Paad>(ctx, listen: false);
        paad.click = "";
        paad.attTela();
      } catch (_) {}
      await Future.delayed(const Duration(milliseconds: 200));
    } catch (e) {
      debugPrint('ERRO removerMediaCard $e');
    } finally {
      stateTela = true;
      attTela();
    }
  }

  Future<void> opcoesMediaCard(String tipo) async {
    final index = tipo == cine ? selectedIndexCinema : selectedIndexMusica;
    final lista = tipo == cine ? listCinema : listMusica;
    if (index < 0 || index >= lista.length) return;
    stateTela = false;
    try {
      final paad = Provider.of<Paad>(ctx, listen: false);
      paad.click = "";
      await paad.ativaMouse(usarEstado: true, estado: true);
      paad.attTela();
    } catch (_) {}
    final opcao = await Pops.popOpcoesMediaCard(ctx);
    stateTela = true;
    if (opcao == 'editar') {
      await editarMediaCard(tipo, index);
    } else if (opcao == 'remover') {
      try {
        await Provider.of<Paad>(ctx, listen: false).ativaMouse(usarEstado: true, estado: false);
      } catch (_) {}
      await removerMediaCard(tipo, index);
    } else {
      if (tipo == cine && focusNodeCinema.isNotEmpty) {
        focusNodeCinema[selectedIndexCinema].requestFocus();
        focusScopeCinema.requestFocus();
        focusScope = focusScopeCinema;
      }
      if (tipo == musc && focusNodeMusica.isNotEmpty) {
        focusNodeMusica[selectedIndexMusica].requestFocus();
        focusScopeMusica.requestFocus();
        focusScope = focusScopeMusica;
      }
      attTela();
    }
  }

  Future<void> moverMediaUsadaParaTopo(String tipo, int index) async {
    try {
      if (tipo == cine) {
        if (index <= 0 || index >= listCinema.length) return;
        final item = listCinema.removeAt(index);
        listCinema.insert(0, item);
        await MediaCatalogo.salvarCatalogo('cinema', listCinema);
        selectedIndexCinema = 0;
        cinemaScrollTopRequest++;
        focusNodeCinema[0].requestFocus();
      } else {
        if (index <= 0 || index >= listMusica.length) return;
        final item = listMusica.removeAt(index);
        listMusica.insert(0, item);
        await MediaCatalogo.salvarCatalogo('musica', listMusica);
        selectedIndexMusica = 0;
        musicaScrollTopRequest++;
        focusNodeMusica[0].requestFocus();
      }
      attTela();
    } catch (e) {
      debugPrint('ERRO moverMediaUsadaParaTopo $e');
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
      stateTela = false; // Desativa eventos durante o processo
      await Provider.of<Paad>(ctx, listen: false).ativaMouse(usarEstado: true, estado: false);
      videosIndexYT = List.generate(listIconsInicial.length, (index) => []);
      Provider.of<JanelaCtrl>(ctx, listen: false).telaPresaReverse(usarEstado: true, estado: false);
      await moverIcoPosicaoInicial(listIconsInicial[selectedIndexIcone]);
      selectedIndexIcone = 0;
      // focusNodeIcones[selectedIndexIcone].requestFocus();
      cardGamesGrid && cardInf ? focusNodeCardInf[selectedIndexCardInfo].requestFocus() : focusNodeIcones[selectedIndexIcone].requestFocus();

      attTela();
      await Future.delayed(const Duration(milliseconds: 650));
      await Pops().carregandoGames(ctx,"Entrando no game..." );
      gameIniciado = false;
      Provider.of<JanelaCtrl>(ctx, listen: false).telaPresaReverse(estado: true, usarEstado: true);
      // Desativa o uso do mouse;
      await Provider.of<Paad>(ctx, listen: false).ativaMouse( usarEstado: true,  estado: false);
      
      // Garantir que o foco volte para o escopo correto após abrir o arquivo

      cardInf = false;
      focusScopeIcones.requestFocus();
      focusScope = focusScopeIcones;
      if (focusNodeIcones.isNotEmpty) {
        selectedIndexIcone =
            selectedIndexIcone.clamp(0, focusNodeIcones.length - 1);
        focusNodeIcones[selectedIndexIcone].requestFocus();
      }
      
      // Delay antes de reativar eventos para evitar cliques duplos
      await Future.delayed(const Duration(milliseconds: 300));
      stateTela = true;

      // focusNodeIcones[selectedIndexIcone].requestFocus();
      // focusScopeIcones.requestFocus();
      // focusScope = focusScopeIcones;
    }catch(e){
      debugPrint(e.toString());
    }
  }

  Future<void> btnFecharJogoAberto() async {
    try {
      final fechado = await db.closeOpenedFile();
      gameIniciado = false;
      stateTela = true;
      Provider.of<JanelaCtrl>(ctx, listen: false)
          .telaPresaReverse(estado: true, usarEstado: true);
      Provider.of<Paad>(ctx, listen: false)
          .ativaMouse(usarEstado: true, estado: false);
      focusScopeCardInf.requestFocus();
      focusScope = focusScopeCardInf;
      selectedIndexCardInfo = 1;
      focusNodeCardInf[1].requestFocus();
      debugPrint(fechado
          ? 'Jogo fechado pelo botao FECHAR.'
          : 'Nao foi possivel fechar o jogo pelo PID salvo.');
      attTela();
    } catch (e) {
      debugPrint('ERRO btnFecharJogoAberto $e');
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
    WidgetsBinding.instance.addPostFrameCallback((_) async  {

      String retorno = await PopMais.mais(ctx);
      debugPrint(retorno);
      if(retorno.isEmpty){ 
        stateTela = true;
        return;
      }

      switch (retorno) {
        
        case "Caminho do game" || "Caminho de Imagem" || "Add": {
          debugPrint("Entrei navPasta");
          final nome = await Pops().navPasta(ctx, "", retorno, listIconsInicial, selectedIndexIcone);
          if(retorno=="Add" && nome != null && nome != ""){
            selectedIndexIcone = 0;
            limparClickPad();
            await Future.delayed(const Duration(milliseconds: 250));
            await salvaImgDownload();
          }else{
            debugPrint("Sai navPasta");
        Timer(const Duration(milliseconds: 500), () => iniciaTela());
          }
          debugPrint("Sai navPasta");
          Timer(const Duration(milliseconds: 500), () => iniciaTela()); 
        }
        case "Imagem da Download": {
          await salvaImgDownload();
        }
        case  "Excluir Card":{
          Timer(const Duration(milliseconds: 500  ),() async {
            var result = await Pops().msgSN(ctx, "Confirmar ação?");
            try {
              final paad = Provider.of<Paad>(ctx, listen: false);
              paad.click = "";
              paad.delay = true;
              paad.attTela();
              Timer(const Duration(milliseconds: 350), () { if(!_disposed) paad.delay = false; });
            } catch (_) {}
            if(result ==  null || result == "Nao"){ 
              Timer(const Duration(milliseconds: 350), () { if(!_disposed) stateTela = true; });
              return;
            }
            if(result == "Sim"){
              listIconsInicial.removeAt(selectedIndexIcone);
              await db.attDados(listIconsInicial);
              Timer(const Duration(milliseconds: 500), () => iniciaTela());
            }
          });
        }
        case "Atalhos":{
          await Pops.popTela(ctx,ImagemFullScren(urlImg: "${assetsPath}tutorial.png"));
          Timer(const Duration(milliseconds: 500), () => iniciaTela());  
        }
        case "Cfg":{
          String retorno = await PopConfig.config(ctx);
          if(retorno.isEmpty || retorno == "cancelar"){
            // Restaura o foco após cancelar
            focusNodeIcones[selectedIndexIcone].requestFocus();
            focusScopeIcones.requestFocus();
            focusScope = focusScopeIcones;
            Timer(const Duration(milliseconds: 300), () {
              stateTela = true;
              focusNodeIcones[selectedIndexIcone].requestFocus();
              focusScopeIcones.requestFocus();
            });
            attTela();
            return;
          }
          if(retorno == "salvar"){
            configSistema.save();
            // Aplica viewType imediatamente
            cardGamesGrid   = configSistema.viewType == "grid";
            cardGamesModerno = configSistema.viewType == "moderno";
            attTela();
            Timer(const Duration(milliseconds: 300), () {
              stateTela = true;
              focusNodeIcones[selectedIndexIcone].requestFocus();
              focusScopeIcones.requestFocus();
              focusScope = focusScopeIcones;
              iniciaTela();
            });
          }
        }
        case "busca":{
          final retorno = await GamesBuscaTela.abrir(ctx);
          if(retorno == null || retorno == "cancelar"){            
            // Restaura o foco após cancelar
            focusNodeIcones[selectedIndexIcone].requestFocus();
            focusScopeIcones.requestFocus();
            focusScope = focusScopeIcones;
            Timer(const Duration(milliseconds: 500), () => stateTela = true);
            attTela();
            return;
          }
          // suporte a retorno antigo (string com caminho) ou novo modelo `JogoBuscado`
          String caminhoExe;
          String nome;
          if (retorno is String) {
            caminhoExe = retorno;
            nome = retorno.split('\\').last.split('.').first;
            nome = _prettifyName(nome);
          } else {
            // assume JogoBuscado-like
            try {
              caminhoExe = retorno.exePath ?? '';
              nome = retorno.name ?? caminhoExe.split('\\').last.split('.').first;
              nome = _prettifyName(nome);
            } catch (_) {
              // fallback
              caminhoExe = '';
              nome = 'Jogo';
            }
          }

          debugPrint(nome);
          debugPrint(caminhoExe);

          List<String> campos = [];
          campos.add("item-${listIconsInicial.length}");        
          campos.add("lugar: ${listIconsInicial.length}");        
          campos.add("nome: $nome");        
          campos.add("local: $caminhoExe");        
          campos.add("img: ");        
          campos.add("imgAux: caminho/.png");
          IconInicial ico = IconInicial(campos);

          listIconsInicial.insert(0,ico);
          await db.attDados(listIconsInicial);

          selectedIndexIcone = 0;
          limparClickPad();
          await Future.delayed(const Duration(milliseconds: 250));
          await salvaImgDownload();

          debugPrint("Sai navPasta");
          Timer(const Duration(milliseconds: 500), () => iniciaTela());  


          
          // if(retorno == "salvar"){
          //   configSistema.save();
          //   Timer(const Duration(milliseconds: 500), () => iniciaTela());
          // }
        }
        default:{
          Timer(const Duration(milliseconds: 500), () => iniciaTela());
        }
      }      

    });
    debugPrint("Finalizei btnMais");
    }catch(e){
      debugPrint("ERO BTNMAIS === $e");
      // Pops().msgSimples(ctx,"ERRO = 1$e");
    }
  }

  void limparClickPad({int delayMs = 450}) {
    try {
      final paad = Provider.of<Paad>(ctx, listen: false);
      paad.click = "";
      paad.delay = true;
      paad.attTela();
      Timer(Duration(milliseconds: delayMs), () { if(!_disposed) paad.delay = false; });
    } catch (_) {}
  }
  
  salvaImgDownload() async {
    videosYT.clear();
    selectedIndexVideo=0;
    stateTela = false;
    await iniciaLitIcones();
    String nomeJogo = listIconsInicial[selectedIndexIcone].nome;
    var result = await Pops.popTela(ctx, SeletorImagens(nome: nomeJogo));
    if(result == null){ 
      Timer(const Duration(milliseconds: 500), () => stateTela = true);
      attTela();
      return debugPrint("Retorno NULO img Download"); // ERRO NULO PARA AQUI
    }
    String novoCaminho = result as String;

    novoCaminho = await WebScrap.downloadImage(novoCaminho,listIconsInicial[selectedIndexIcone].nome);
    if(novoCaminho.contains("Erro::")) {
      debugPrint(novoCaminho); // ERRO SALVAMENTO PARA AQUI
      return Timer(const Duration(milliseconds: 500), () => iniciaTela());
    }
    listIconsInicial[selectedIndexIcone].imgStr = novoCaminho;
    await db.attDados(listIconsInicial);
    
    load = true;    
    attTela();
    await iniciaLitIcones();    
    stateTela = true;
    load = false;      
    attTela();
    // Timer(const Duration(milliseconds: 500), () {
    // });
    // return iniciaTela();
  }
  

  

  escutaPad(String event) async {    
    try{
      event = MovimentoSistema.normalizaEntrada(event);
      if(!stateTela || event == "") return;
      SonsSistema.clickRetroAtivo =
          selectedIndexAbaGuias == 0 && cardGamesRetro && !cardGamesGrid;

      // Intercept: popup de notícia aberto — roteamento A=2 e B=3 para popup
      if (noticiaPopupAberta != null) {
        if (event == "3") {
          fecharNoticiaPopup?.call(); // fecha o pop, foco volta automaticamente
          noticiaPopupAberta = null;
          fecharNoticiaPopup = null;
        } else if (event == "2") {
          final url = noticiaPopupAberta!.url;
          final cb = fecharNoticiaPopup;
          noticiaPopupAberta = null;
          fecharNoticiaPopup = null;
          cb?.call();
          if (url.isNotEmpty) unawaited(sairDaTelaMedia(url, 'Lendo notícia.'));
        }
        return;
      }



      if( event == "4"){
        // JogosExistentes je = JogosExistentes();
        // List<JogoEncontrado> jogosE = await je.buscarJogosInstalados();

        // List<String> itens = [];

        // for( var jogo in jogosE ) {
        //   itens.add(jogo.nome);
        // }
        // await mostrarPopLista(
        //   context: ctx,
        //   titulo: "Comandos Salvos",
        //   itens: itens,
        //   onItemSelecionado: (item) {
        //     // TecladoCtrl.enviarComandoSequencia(item);
        //   },
        // );
      }

      if((event == "RB"||event=="LB") && focusScope != focusScopeVideos){
        movAbaGuias(event);}
      else if(focusScope == focusScopeIcones && selectedIndexAbaGuias == 0){
        movIcones(event);}
      else if(focusScope == focusScopeCardInf && selectedIndexAbaGuias == 0){
        movCardInf(event);}
      else if(focusScope == focusScopeNoticias && selectedIndexAbaGuias == 0){
        movNoticias(event);}
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
        if(cardGamesModerno){
          // No modo moderno CIMA sobe para as notícias
          focusScopeNoticias.requestFocus();
          focusScope = focusScopeNoticias;
          if (focusNodeNoticias.isNotEmpty) focusNodeNoticias[selectedIndexNoticia.clamp(0, focusNodeNoticias.length - 1)].requestFocus();
          attTela();
        } else {
          cardGamesGrid ? focusScopeCardInf.requestFocus() : focusScopeIcones.requestFocus();
          focusScope = cardGamesGrid ? focusScopeCardInf : focusScopeIcones;
        }
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
      stateTela = false; // Desativa eventos durante o processo
      // Liberar Tela do sistema
      Provider.of<JanelaCtrl>(ctx, listen: false).telaPresaReverse(usarEstado: true, estado: false);
      // Ativar Mouse
      await Provider.of<Paad>(ctx, listen: false).ativaMouse(usarEstado: true,  estado: true);
      await NavWebCtrl.openLink(url);
      await Pops().carregandoGames(ctx, texto);
      
      JanelaCtrl.restoreWindow();
      await Future.delayed(const Duration(milliseconds: 350));
      await JanelaCtrl.garantirFocoSeNaFrente();
      await Provider.of<Paad>(ctx, listen: false).ativaMouse(usarEstado: true,  estado: false);
      // Trava na tela novamente
      Provider.of<JanelaCtrl>(ctx, listen: false).telaPresaReverse(usarEstado: true, estado: true);
      gameIniciado = false;
      
      // Delay antes de reativar eventos para evitar cliques duplos
      await Future.delayed(const Duration(milliseconds: 300));
      stateTela = true;
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
    if(gameIniciado) {
      if(event == "3") Navigator.pop(ctx);
      return;
    }
    if (cardInf) return movCardInf(event);

    MovimentoSistema.direcaoListView(focusScope, event);
    if (event == "START") {
      btnMais();
    }else if (event == "2"){
      if(!cardInf){
        abrirCardInfDoJogoAtual();
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
    if (event == "START") {
      await adicionarMediaCard(musc);
      return;
    }
    if (event == "SELECT"){
      await opcoesMediaCard(musc);
      return;
    }
    if (event == "2"){
      final indexUsado = selectedIndexMusica;
      final url = listMusica[indexUsado].url;
      await moverMediaUsadaParaTopo(musc, indexUsado);
      await sairDaTelaMedia(url, "Festa Ativa!");
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
    if (event == "START") {
      await adicionarMediaCard(cine);
      return;
    }
    if (event == "SELECT"){
      await opcoesMediaCard(cine);
      return;
    }
    if (event == "2"){
      final indexUsado = selectedIndexCinema;
      final url = listCinema[indexUsado].url;
      await moverMediaUsadaParaTopo(cine, indexUsado);
      await sairDaTelaMedia(url, "Comendo pipoca.");
      // Garantir que o foco volte para o escopo correto após abrir o arquivo
      focusNodeCinema[selectedIndexCinema].requestFocus();
      focusScopeCinema.requestFocus();
      focusScope = focusScopeCinema;
    }
  }

  movNoticias(String event){
    try{
      MovimentoSistema.direcaoListView(focusScopeNoticias, event);
      if(event == "CIMA"){
        // Sobe para o strip de ícones
        focusScopeIcones.requestFocus();
        focusScope = focusScopeIcones;
        focusNodeIcones[selectedIndexIcone].requestFocus();
        attTela();
      }
      if(event == "BAIXO"){
        // No modo moderno vai direto se há vídeos; senão usa gate completo
        final podeIr = exibirVideos;
        if(podeIr){
          focusNodeVideos[selectedIndexVideo].requestFocus();
          focusScopeVideos.requestFocus();
          focusScope = focusScopeVideos;
          attTela();
        }
      }
      if(event == "3"){
        // Volta para ícones (botão B/Backspace)
        focusScopeIcones.requestFocus();
        focusScope = focusScopeIcones;
        focusNodeIcones[selectedIndexIcone].requestFocus();
        attTela();
      }
      if(event == "2"){
        // Abre a notícia selecionada
        if(abrirNoticiaCallback != null && noticias.isNotEmpty){
          abrirNoticiaCallback!(noticias[selectedIndexNoticia]);
        }
      }
    }catch(e){
      debugPrint("ERRO movNoticias $e");
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
        if(event=="BAIXO"){
          // No modo moderno, BAIXO vai para as notícias
          if(cardGamesModerno){
            focusScopeNoticias.requestFocus();
            focusScope = focusScopeNoticias;
            if (focusNodeNoticias.isNotEmpty) focusNodeNoticias[selectedIndexNoticia.clamp(0, focusNodeNoticias.length - 1)].requestFocus();
            attTela();
          } else {
            debugPrint("Lista VIDEOS :${videosYT.length}");
            if(exibirVideos){
              focusNodeVideos[selectedIndexVideo].requestFocus();
              focusScopeVideos.requestFocus();
              focusScope = focusScopeVideos;
            }
          }
        }
      }else if(event == "3"){
        cardInf = false;
        focusScopeIcones.requestFocus();
        focusScope = focusScopeIcones;
        focusNodeIcones[selectedIndexIcone].requestFocus();
        attTela();
      }else if (event == "2" && selectedIndexCardInfo == 1){
        await btnFecharJogoAberto();
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

      // No modo moderno, CIMA vai para o card glass (inferior direito)
      if(event == "CIMA" && cardGamesModerno){
        focusScopeCardInf.requestFocus();
        focusScope = focusScopeCardInf;
        focusNodeCardInf[selectedIndexCardInfo].requestFocus();
        attTela();
        return;
      }

      // No modo moderno, BAIXO vai para as notícias
      if(event == "BAIXO" && cardGamesModerno){
        focusScopeNoticias.requestFocus();
        focusScope = focusScopeNoticias;
        if (focusNodeNoticias.isNotEmpty) focusNodeNoticias[selectedIndexNoticia.clamp(0, focusNodeNoticias.length - 1)].requestFocus();
        attTela();
        return;
      }

      String result = MovimentoSistema.direcaoListView(focusScope, event);

      if(result == MovimentoSistema.horizontal || result == MovimentoSistema.vertical  ){
        // desativado temporariamente
        //verificar se a opçao de ver videos esta ativa e se tem videos para mostrar
        if(event=="BAIXO" && exibirVideos){
          debugPrint("Lista VIDEOS :${videosYT.length}");
          focusNodeVideos[selectedIndexVideo].requestFocus();
          focusScopeVideos.requestFocus();
          focusScope = focusScopeVideos;
        }
      }
      
      if (event == 'SELECT')trocaViewIcones();
      if (event == "START")btnMais();      
      if (event == "2"){
        if(cardGamesModerno){
          abrirCardInfDoJogoAtual();
        } else {
          btnEntrar();
        }
      }
      // if(event == "4")mostrarBottomSheet();
      
    }catch(e){
      debugPrint(e.toString());
      // Pops().msgSimples(ctx,"ERRO = 1$e");
    }
  }

  trocaViewIcones() async {
    // SELECT: alterna entre o modo Grid e o modo salvo nas configurações (Normal, Moderno ou Retro)
    if (!cardGamesGrid) {
      // Entra no modo Grid
      cardGamesGrid = true;
      cardGamesModerno = false;
      cardGamesRetro = false;
    } else {
      // Sai do modo Grid e volta para o modo que está salvo no configSistema
      cardGamesGrid = false;
      cardGamesModerno = configSistema.viewType == "moderno";
      cardGamesRetro = configSistema.viewType == "retro";
      // Se não for nenhum dos dois, o modo padrão (BodyIconesJogos) será exibido
    }
    
    // Reseta o estado de informações extras ao trocar de visão
    cardInf = false;
    
    // Notifica a mudança para atualizar a UI
    attTela();
  }
  

  

  
  keyPress(KeyEvent key) async {
    if (key is KeyDownEvent || key is KeyRepeatEvent) {
      debugPrint("Teclado Press: ${key.logicalKey.debugName}");
      String event = MovimentoSistema.convertKeyBoard(key.logicalKey.keyLabel);
      escutaPad(event);
    }
  }

  





}
