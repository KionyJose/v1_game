// ignore_for_file: use_build_context_synchronously, file_names, deprecated_member_use
import 'dart:io';
import 'dart:math';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:snappy_list_view/snappy_list_view.dart';
import 'package:v1_game/Class/MouseCtrl.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/PrincipalCtrl.dart';
import 'package:v1_game/Widgets/YouTubeTela.dart';
import 'package:v1_game/Widgets/cardGame.dart';
import 'package:v1_game/Widgets/videoSliders.dart';

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key, required this.title});

  final String title;

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> with WidgetsBindingObserver {

  late PrincipalCtrl ctrlOff;
  // PaadGet jogadorRepository = GetIt.instance.get<PaadGet>();
  EdgeInsetsGeometry cardMargin = const EdgeInsets.symmetric(horizontal: 8);
  
  // void atualizarTela() => setState((){});

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);// en teste!
    // simulateGamepadInput();
  }
  

  void simulateGamepadInput() {
    // Movimentos simulados do joystick (substituir com lógica real)
    final random = Random();
    int dx = random.nextInt(11) - 5; // Valores entre -5 e 5
    int dy = random.nextInt(11) - 5;
   

    // Atualizar continuamente
    Future.delayed(const Duration(milliseconds: 50), simulateGamepadInput);
  }
  

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // debugPrint(state.name);
    // if (state == AppLifecycleState.inactive) {
    //   // SAIU DA TELA
    //   ctrlOff.isWindowFocused = false;
    // }
    // if (state == AppLifecycleState.resumed) {
    //   // ENTROU NA TELA
    //   ctrlOff.isWindowFocused = true;
    // }
  }

  @override
  void dispose() {
    debugPrint("SAIU PAGE PAGE");
    // ctrl.dispose();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  } 


  
  
  

  @override
  Widget build(BuildContext context) {

    return ChangeNotifierProvider(
      create: (context) => PrincipalCtrl(context), // Cria o controlador aqui
      // dispose: (context, ctrl) => ctrl.dispose(), // Remove o controlador quando sair
      child: Consumer<PrincipalCtrl>(
        builder: (context, ctrl, child) {
          // debugPrint("object =========================");
          ctrl.ctx = context;
          ctrlOff = ctrl;
          return scaffold(ctrl);
          
          
        },
      ),
    );
  }

  escutaPadWid(PrincipalCtrl ctrl){
    return Selector<Paad, String>(
      selector: (context, paad) => paad.click, // Escuta apenas click
      builder: (context, valorAtual, child) {
        
        // Aguardando o próximo frame para chamar o showDialog   if(event == "HOME" && !home){
        if(!ctrl.home){
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ctrl.escutaPad(valorAtual);// Isso pode chamar o showDialog
          });
        }
        return body(ctrl);
      },
    );
  }
  scaffold(PrincipalCtrl ctrl){
    return Scaffold(
      backgroundColor: Colors.black,
      body: KeyboardListener( // Escuta teclado Press;
            includeSemantics: false,
            focusNode: ctrl.keyboradEscutaNode,//ctrl.focoPrincipal,
            autofocus: false,
            onKeyEvent: (KeyEvent event) => ctrl.keyPress(event),
            child: escutaPadWid(ctrl)
          ),
      floatingActionButton: floatBtns(),
    );
  }
  escurecerTela(PrincipalCtrl ctrl){
    return  AnimatedOpacity( // Anima A Opacidade.
      opacity: ctrl.videoAtivo ? 1.0 : 0.0,
      duration: !ctrl.videoAtivo ?  const Duration(microseconds: 0) :  const Duration(seconds: 1),
      child: Transform.scale(
        scale: ctrl.scaleAnimation.value,
        child: Container(
          width: double.maxFinite,
          height: double.maxFinite,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.9),
            borderRadius: BorderRadius.circular(50),
          ),
        ),
      ),
    );
  }

  body(PrincipalCtrl ctrl){
    return Stack(
      children: [
      backGroundAnimado(ctrl), // Fundo animado
      if (ctrl.telaIniciada)listIcones(ctrl),// Ícones horizontais
      escurecerTela(ctrl),// Escurecer tela      
      if (ctrl.videoAtivo)
      videoAtivo(ctrl),// Player de vídeo
      if (ctrl.videosYT.isNotEmpty && ctrl.telaIniciada)
      VideoSliders(child: listVideos(ctrl)),// Lista de vídeos
    ],
    );
  }

  videoAtivo(PrincipalCtrl ctrl){
    return Align(
      alignment: Alignment.center,
      child: Container(
        margin: const EdgeInsets.only(bottom: 80),
        height: MediaQuery.of(context).size.height * 0.70,
        width: MediaQuery.of(context).size.height * 0.70 * 1.809, // Aspect ratio 16:9
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50),
          child: YoutubeTela(
            url: ctrl.videosYT[ctrl.selectedIndexVideo].urlVideo,
          ),
        ),
      ),
    );
  }

  listaIcones(PrincipalCtrl ctrl){
    double tamanho = 0.24;
    try{
    if(ctrl.focusScope == ctrl.focusScopeIcones)tamanho = 0.35;
    }catch(e){}
    return  Align(
      alignment: Alignment.topLeft,
      child: FocusScope(
        node: ctrl.focusScopeIcones,
        child: AnimatedContainer(          
          height: MediaQuery.of(context).size.height * tamanho,  // Altura do carrossel
          duration: const Duration(milliseconds: 100),
          width: double.infinity,
          child: CarouselSlider.builder(
            carouselController: ctrl.carouselIconesCtrl,
            itemCount: ctrl.focusNodeIcones.length,
            itemBuilder: (context, i, realIndex) {
              bool isFoco = ctrl.selectedIndexIcone == i;
              return FittedBox(
                child: Container(
                margin: const EdgeInsets.symmetric(vertical: 35),
                height: isFoco ? 1100 : 500, 
                width: 1000,
                  child: Focus(
                    focusNode: ctrl.focusNodeIcones[i],
                    onFocusChange: (hasFocus) => ctrl.onFocusChangeIcones(hasFocus, i),              
                    child: ctrl.listIconsInicial.isEmpty ? cardAnimadoAdd(ctrl, i) :  cardAnimado(ctrl, i),
                  ),
                ),
              );
            },            
            options: CarouselOptions(              
              height: MediaQuery.of(context).size.height, // Altura do carrossel
              aspectRatio: 14.5,
              initialPage: 0, // Inicia no primeiro item
              enableInfiniteScroll: false,
              viewportFraction: 0.17, // Tamanho do item visível
              enlargeCenterPage: false, // Desativa o aumento do item central
              disableCenter: true, // Desativa o alinhamento central
              padEnds: false, // Remove o espaçamento nas extremidades
              scrollDirection: Axis.horizontal,
              // Outras opções conforme necessário
              ),
          ),
            
        ),
      ),
    );
  }

  listIcones(PrincipalCtrl ctrl){
    return Align(
      alignment: Alignment.topLeft,
      child: FocusScope(
        node: ctrl.focusScopeIcones,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          width: double.infinity,
          child: SnappyListView(
            snapAlignment: SnapAlignment. custom((i) =>  0.03 ),
            snapOnItemAlignment: SnapAlignment. custom((i) =>  0.03 ),
            controller: ctrl.slideIconesCtrl,
            scrollDirection: Axis.horizontal,
            itemCount: ctrl.focusNodeIcones.length,
            
            itemBuilder: (context, i) {
              return Container(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Focus(
                      focusNode: ctrl.focusNodeIcones[i],
                      onFocusChange: (hasFocus) => ctrl.onFocusChangeIcones(hasFocus, i),              
                      child: ctrl.listIconsInicial.isEmpty ? cardAnimadoAdd(ctrl, i) :  cardAnimado(ctrl, i),
                    ),
                ),
              );
            }
          ),
            
        ),
      ),
    );
    
  }

  

  listVideos(PrincipalCtrl ctrl){
    double tamanho = 0.2;
    try{
    if(ctrl.focusScope == ctrl.focusScopeVideos && !ctrl.videoAtivo)tamanho = 0.27;
    }catch(_){}
    
    return  Align(
      alignment: Alignment.bottomLeft,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: FocusScope(
          node: ctrl.focusScopeVideos,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 100),
            height: MediaQuery.of(context).size.height * tamanho,
            width: double.infinity,
            child: CarouselSlider(
              carouselController: ctrl.carouselVideosCtrl,
                options: CarouselOptions(
                  pageSnapping: true,                    
                  height: MediaQuery.of(context).size.height * tamanho, // Altura do carrossel
                  autoPlay: ctrl.focusScopeVideos.hasFocus ? false : true, // Habilita autoplay quando nao focado.
                  enlargeCenterPage: true, // Centraliza e destaca o item ativo
                  enableInfiniteScroll: true,
                  viewportFraction: tamanho, // Tamanho do item visível
                  initialPage: ctrl.selectedIndexVideo,
                  // scrollDirection: Axis.vertical
                  enlargeStrategy: CenterPageEnlargeStrategy.zoom
                ),
                items: [
                  for(int i = 0; i < ctrl.videosYT.length; i++)
                  Focus(
                    focusNode: ctrl.focusNodeVideos[i],
                    onFocusChange: (hasFocus) => ctrl.onFocusChangeVideos(hasFocus, i),              
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 16),
                      width: MediaQuery.of(context).size.width,
                      // margin: const EdgeInsets.symmetric(horizontal: 5.0),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(25),
                        color: Colors.white12,
                        image: DecorationImage(
                          opacity: 0.9,
                          image: NetworkImage(ctrl.videosYT[i].capaG),
                          fit: BoxFit.cover,
                        ),
                        border: ctrl.selectedIndexVideo == i && ctrl.focusScopeVideos.hasFocus ? Border.all(
                          color: Colors.blueAccent, // Cor da borda
                          width: 3,                // Espessura da borda
                        ) : null,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.play_circle_fill,
                          size: 60.0,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ),
                    
                  
                ]
              ),
          ),
        ),
      ),
    );
  }

  textoBaixoCard(PrincipalCtrl ctrl,int index){
    return Center(
      child: Text(
        ctrl.listIconsInicial[index].nome,
        style: const TextStyle(
          fontSize: 25,
          color: Colors.white,
          shadows: [
            Shadow(
              blurRadius: 5,
              color: Colors.black
            ),
          ]
        ),
      )
    );
  }
  cardAnimado(PrincipalCtrl ctrl,int index){
    bool foco = ctrl.selectedIndexIcone == index;
    return AnimatedContainer(
      constraints: const BoxConstraints(
        minHeight: 140,
        minWidth: 140,
      ),
      duration: const Duration(milliseconds: 200),
      margin: cardMargin,
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          if(foco)BoxShadow(
            color: Colors.pink,
            offset: const Offset(-2, 0),
            blurRadius: foco ? 28 : 10,
          ),
          if(foco)BoxShadow(
            color: Colors.blue,
            offset: const Offset(2, 0),
            blurRadius: foco ? 28 : 10,
          ),
        ],
      ),
      child: MouseRegion(
        onEnter: (event) {
          // onHover(index, true);
        },
        onExit: (value) {
          // onHover(index, false);
        },
        child: AnimatedContainer(
          width: foco ? MediaQuery.of(context).size.width * 0.12 : MediaQuery.of(context).size.width * 0.08,
          height: foco ? MediaQuery.of(context).size.width * 0.26 : MediaQuery.of(context).size.width * 0.08,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: Colors.transparent,
          ),
          duration: const Duration(milliseconds: 100),
          child: AnimatedOpacity(
            opacity: foco ? 1.0 : 1.0,
            duration: foco ?  const Duration(milliseconds: 350) :  const Duration(seconds: 1),
            child: CardGame(
              iconInitial: ctrl.listIconsInicial[index],
              focus: ctrl.selectedIndexIcone == index,
            ),
          ),
        ),
      ),
    );
  }
  cardAnimadoAdd(PrincipalCtrl ctrl, int index){
    return AnimatedContainer(
      constraints: const BoxConstraints(
        minHeight: 175,
        minWidth: 175,
      ),
      duration: const Duration(milliseconds: 200),
      // margin: cardMargin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30),
        gradient: LinearGradient(
          colors: [
            Colors.pinkAccent.withOpacity(1.0),
            Colors.blue.withOpacity(1.0),
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.pink,
            offset: const Offset(-2, 0),
            blurRadius: ctrl.selectedIndexIcone == index ? 30 : 10,
          ),
          BoxShadow(
            color: Colors.blue,
            offset: const Offset(2, 0),
            blurRadius: ctrl.selectedIndexIcone == index ? 30 : 10,
          ),
        ],
      ),
      child: MouseRegion(
        onEnter: (event) {
          // onHover(index, true);
        },
        onExit: (value) {
          // onHover(index, false);
        },
        child: AnimatedContainer(
          width: MediaQuery.of(context).size.width * 0.12 ,
          height: MediaQuery.of(context).size.width * 0.12,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: const Color(0xFF000515),
          ),
          duration: const Duration(milliseconds: 100),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(30),
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage( fit: BoxFit.cover, image: AssetImage('assets/BGICOdefault.png'),
              ),),
              height: 200,
              width: 135,
              child: const FittedBox(child: Icon(Icons.add,color: Colors.white,))
              )
          ),
        ),
      ),
    );
  }

  floatBtns(){
    return  Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text("Desenvolvido por: @KionyJose",style: TextStyle(color: Colors.yellowAccent.withOpacity(0.2)),)
      ],
    );
  }
  

  backGroundAnimado(PrincipalCtrl ctrl){
    return AnimatedBuilder( // crece Container e diminui.
      animation: ctrl.ctrlAnimeBgFundo,
      builder: (context, child) {
        // debugPrint(ctrl.showNewImage.toString());
        return AnimatedOpacity( // Anima A Opacidade.
          opacity: ctrl.showNewImage ? 1.0 : 0.0,
          duration: !ctrl.showNewImage ?  const Duration(milliseconds: 350) :  const Duration(seconds: 1),
          child: Transform.scale(
            scale: ctrl.scaleAnimation.value,
            child: Container(
              width: double.maxFinite,
              height: double.maxFinite,
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.5),
                borderRadius: BorderRadius.circular(50),
              ),
              child: imagemFundo(ctrl),
            ),
          ),
        );
      },
    );
  }
  
  imagemFundo(PrincipalCtrl ctrl) {
    final item = BoxDecoration( image: DecorationImage( fit: BoxFit.cover, image: FileImage(File('assets/BGdefault.jpeg'),scale: 5)));
    if(ctrl.listIconsInicial.isEmpty){
      return Image.asset('assets/BGdefault.jpeg',
      fit: BoxFit.cover,
      );      
    }
    return Container(
      decoration: ctrl.imgFundoStr.isNotEmpty ? File(ctrl.imgFundoStr).existsSync() ? BoxDecoration( image: DecorationImage(fit: BoxFit.cover, image 
      : FileImage( File(ctrl.imgFundoStr),)))
      : item : item,
      // : const BoxDecoration(color: Colors.transparent),
      height: 200,
      width: 135,
      // child: focus ? Center(child: Text(iconInitial.nome,style: const TextStyle(fontSize: 25,color: Colors.white),)) : Container()
    );
  }

  
}


