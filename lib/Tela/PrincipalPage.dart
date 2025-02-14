// ignore_for_file: use_build_context_synchronously, file_names, deprecated_member_use
import 'dart:io';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:provider/provider.dart';
import 'package:snappy_list_view/snappy_list_view.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Controllers/PrincipalCtrl.dart';
import 'package:v1_game/Rotas/PaadGet.dart';
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
  }

  

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // debugPrint(state.name);
    // print(state);
    if (state == AppLifecycleState.inactive) {
      // SAIU DA TELA
      ctrlOff.isWindowFocused = false;
    }
    if (state == AppLifecycleState.resumed) {
      // ENTROU NA TELA
      ctrlOff.isWindowFocused = true;
    }

    // } else {
    //   debugPrint("SAI");
    //   // ctrl.isWindowFocused = true;
    // }
    // if (state != AppLifecycleState.hidden) {
    //   debugPrint("Entrei-1");
    //   // ctrl.isWindowFocused = false;
    // } else {
    //   debugPrint("SAI-1");
    //   // ctrl.isWindowFocused = true;
    // }
  }

  @override
  void dispose() {
    debugPrint("SAIU PAGE PAGE");
    // ctrl.dispose();
    // WidgetsBinding.instance.removeObserver(this);
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
          return KeyboardListener( // Escuta teclado Press;
            includeSemantics: false,
            focusNode: FocusNode(),//ctrl.focoPrincipal,
            autofocus: false,
            onKeyEvent: (KeyEvent event) => ctrl.keyPress(event),
            child: escutaPadWid(ctrl)
          );
        },
      ),
    );
  }

  escutaPadWid(PrincipalCtrl ctrl){
    return Selector<Paad, String>(
      selector: (context, paad) => paad.click, // Escuta apenas click
      builder: (context, valorAtual, child) {
        // Aguardando o próximo frame para chamar o showDialog
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ctrl.escutaPad(valorAtual);// Isso pode chamar o showDialog
        });
        return scaffold(ctrl);
      },
    );
  }
  scaffold(PrincipalCtrl ctrl){
    return Scaffold(
      backgroundColor: Colors.black,
      body: body(ctrl),
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
              return Container(
                height: 200,
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Focus(
                  autofocus: ctrl.indexFcs == 0 ? true : false,
                  focusNode: ctrl.focusNodeIcones[i],
                  onFocusChange: (hasFocus) => ctrl.onFocusChangeIcones(hasFocus, i),              
                  child: ctrl.listIconsInicial.isEmpty ? cardAnimadoAdd(ctrl, i) :  cardAnimado(ctrl, i),
                ),
              );
            },
            
            options: CarouselOptions(
                // pageSnapping: true,
                // autoPlay: true, // Habilita autoplay quando nao focado.
                
                // height: MediaQuery.of(context).size.height * tamanho,  // Altura do carrossel
                enlargeCenterPage: true, // Centraliza e destaca o item ativo
      
                enableInfiniteScroll: true,
                viewportFraction: 0.17, // Tamanho do item visível
                initialPage: ctrl.selectedIndexIcone,
                // reverse: true,
                animateToClosest: true,
                disableCenter: true,
                padEnds: true,
                // scrollDirection: Axis.vertical
                // pauseAutoPlayOnManualNavigate: true,
                // pauseAutoPlayInFiniteScroll: true,
                enlargeStrategy: CenterPageEnlargeStrategy.zoom
              ),
          ),
            
        ),
      ),
    );
  }
  body(PrincipalCtrl ctrl){

  final screenHeight = MediaQuery.of(context).size.height;
    return Stack(
      children: [
      // Fundo animado
      backGroundAnimado(ctrl),

      // Ícones horizontais
      if (ctrl.telaIniciada) listIcones2(ctrl),
      // listaIcones(ctrl),
      // iconesListHorizontal(ctrl),

      // Escurecer tela
      escurecerTela(ctrl),

      // Player de vídeo
      if (ctrl.videoAtivo)
        Align(
          alignment: Alignment.center,
          child: Container(
            margin: const EdgeInsets.only(bottom: 80),
            height: screenHeight * 0.70,
            width: screenHeight * 0.70 * 1.809, // Aspect ratio 16:9
            child: ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: YoutubeTela(
                url: ctrl.videosYT[ctrl.selectedIndexVideo].urlVideo,
              ),
            ),
          ),
        ),
      
      if (ctrl.videosYT.isNotEmpty && ctrl.telaIniciada)
      VideoSliders(child: listVideos(ctrl)),
      // Lista de vídeos
      // if (ctrl.videosYT.isNotEmpty && ctrl.telaIniciada)
        // Align(
        //   alignment: Alignment.bottomCenter,
        //   child: listVideos(ctrl),
        // ),
    ],
    );
  }

  listIcones2(PrincipalCtrl ctrl){

    return Align(
      alignment: Alignment.topLeft,
      child: FocusScope(
        node: ctrl.focusScopeIcones,
        child: AnimatedContainer(
          // color: Colors.black54,
          height: MediaQuery.of(context).size.height * 0.55,  // Altura do carrossel
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
                // height: 500,
                // width: MediaQuery.of(context).size.height * 0.2,
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Align(
                  alignment: Alignment.topLeft,
                  child: Focus(
                      // autofocus: ctrl.indexFcs == 0 ? true : false,
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
    }catch(e){}
    
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
                    autofocus: ctrl.indexFcs == 0 ? true : false,
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

  iconesListHorizontal(PrincipalCtrl ctrl){
    return Align(
      alignment: Alignment.topLeft,
      child: FocusScope(
        // onFocusChange: (value) => debugPrint("--------------------------------***-----------------------------"),
        node: ctrl.focusScopeIcones,
        child: ListView.builder(
          controller: ctrl.scrolListIcones,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 30,vertical: 45),
          itemCount: ctrl.focusNodeIcones.length,
          itemBuilder: (context, index) {
            if (index >= ctrl.focusNodeIcones.length) {
              return Container(); // Retorna um placeholder ou nada
            }
            return Focus(
              autofocus: ctrl.indexFcs == 0 ? true : false,
              focusNode: ctrl.focusNodeIcones[index],
              onFocusChange: (hasFocus) => ctrl.onFocusChangeIcones(hasFocus, index),
              child: GestureDetector(
                onTap: () async {
                  try {
                    debugPrint('Container $index clicado!');
                    await ctrl.btnMais();
                  } catch (e) {
                    debugPrint(e.toString());
                  }
                },
                child: Column(
                  children: [
                    if(ctrl.listIconsInicial.isNotEmpty) cardAnimado(ctrl, index),
                    if(ctrl.listIconsInicial.isEmpty) cardAnimadoAdd(ctrl, index)
                  ],
                ) ,
              ),
            );
          },
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
    return AnimatedContainer(
      constraints: const BoxConstraints(
        minHeight: 175,
        minWidth: 175,
      ),
      duration: const Duration(milliseconds: 200),
      margin: cardMargin,
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
          width: ctrl.selectedIndexIcone == index ? MediaQuery.of(context).size.width * 0.13 : MediaQuery.of(context).size.width * 0.08,
          height: ctrl.selectedIndexIcone == index ? MediaQuery.of(context).size.width * 0.35 : MediaQuery.of(context).size.width * 0.08,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            color: const Color(0xFF000515),
          ),
          duration: const Duration(milliseconds: 100),
          child: CardGame(
            iconInitial: ctrl.listIconsInicial[index],
            focus: ctrl.selectedIndexIcone == index,
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),                  
              color: Colors.white54,
            ),
            height: 40,
            width: 40,
            child: const FittedBox(
              child: Text("◼",textAlign: TextAlign.center,style:  TextStyle(fontSize: 20)
                
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),                  
              color: Colors.white54,
            ),
            height: 40,
            width: 40,
            child: const FittedBox(
              child: Text("▲",textAlign: TextAlign.center,style:  TextStyle(fontSize: 20)
                
              ),
            ),
          ),
        ),Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),                  
              color: Colors.white54,
            ),
            height: 40,
            width: 40,
            child: const Center(
              child: Text("◯", textAlign: TextAlign.center,style:  TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                
              ),
            ),
          ),
        ),Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),                  
              color: Colors.white54,
            ),
            height: 40,
            width: 40,
            child: const Center(
              child: Text("✕",textAlign: TextAlign.center,style:  TextStyle(fontSize: 20,fontWeight: FontWeight.bold)
              ),
            ),
          ),
        ),
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

  
  teclasPRess() {
    // var key = navigatorKey.currentState.;
    // (event) {
    //   if (event is RawKeyDownEvent) {
    //     debugPrint('Tecla pressionada: ${event.logicalKey}');
    //   } else if (event is RawKeyUpEvent) {
    //     debugPrint('Tecla liberada: ${event.logicalKey}');
    //   }
    // }) as void Function();
  }
}


