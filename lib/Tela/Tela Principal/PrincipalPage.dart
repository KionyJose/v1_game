// ignore_for_file: use_build_context_synchronously, file_names, deprecated_member_use
import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:scroll_snap_list/scroll_snap_list.dart';
import 'package:v1_game/Class/Paad.dart';
import 'package:v1_game/Tela/Tela%20Principal/PrincipalCtrl.dart';
import 'package:v1_game/Global.dart';
import 'package:v1_game/Widgets/BarraProgressoYT.dart';
import 'package:v1_game/Widgets/LoadWid.dart';
import 'package:v1_game/Widgets/TituloGames.dart';
import 'package:v1_game/Widgets/cardGame.dart';
import 'package:v1_game/Widgets/videoSliders.dart';
import 'package:window_manager/window_manager.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'Widgets/BodyIconesJogos.dart';
import 'Widgets/BodyIconesCinema.dart';
import 'Widgets/BodyIconesMusica.dart';
import 'Widgets/BodyIconesJogosGrid.dart';
import 'Widgets/CardInfWidget.dart';
import 'Widgets/ListVideosWidget.dart';

class SafeCurve extends Curve {
  final Curve _inner;
  const SafeCurve(this._inner);
  @override
  double transform(double t) => _inner.transform(t.clamp(0.0, 1.0));
}

class PrincipalPage extends StatefulWidget {
  const PrincipalPage({super.key, required this.title});

  final String title;

  @override
  State<PrincipalPage> createState() => _PrincipalPageState();
}

class _PrincipalPageState extends State<PrincipalPage> with WindowListener {

  late PrincipalCtrl ctrlOff;
  bool naTela = false;
  

  @override
  void onWindowFocus() => naTela= true;

  @override
  void onWindowBlur() => naTela = false;
  
  

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
  scaffold(PrincipalCtrl ctrl){   
    return Scaffold(
      backgroundColor: Colors.black,
      floatingActionButton: floatBtns(),
      body: KeyboardListener( // Escuta teclado Press;
            includeSemantics: false,
            focusNode: ctrl.keyboradEscutaNode,//ctrl.focoPrincipal,
            autofocus: false,
            onKeyEvent: (KeyEvent event) => ctrl.keyPress(event),
            child: escutaPadWid(ctrl)
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
        }if(!ctrl.telaIniciada) return Container();
        return ctrl.load ? const LoadingIco(color: Colors.pink,)
        : body(ctrl);
      },
    );
  }

  body(PrincipalCtrl ctrl){
    bool filmes = ctrl.focusScope == ctrl.focusScopeCinema || ctrl.focusScope == ctrl.focusScopeMusica;
    return Stack(
      children: [
      backGroundAnimado(ctrl), // Fundo animado
      cabeca(ctrl),
      desfoqueTela(filmes),
      if (ctrl.telaIniciada) bodyPageView(ctrl),// Ícones horizontais
      abaGuias(ctrl),
      escurecerTela(ctrl),// Escurecer tela      
      if (ctrl.videoAtivo)
      videoAtivo(ctrl),// Player de vídeo
      // if (ctrl.videosYT.isNotEmpty && ctrl.telaIniciada && ctrl.videosCarregados && ctrl.selectedIndexAbaGuias == 0 && !ctrl.cardGamesGrid)
      if(ctrl.exibirVideos)
      VideoSliders(child: ListVideosWidget(ctrl: ctrl, cardVideo: cardVideo)),// Lista de vídeos
    ],
    );
  } 
  cabeca(PrincipalCtrl ctrl){
    if(ctrl.listIconsInicial.isEmpty) return Container(); 
    return TituloGames(nome: ctrlOff.listIconsInicial[ctrlOff.selectedIndexIcone].nome,imerso: ctrlOff.imersao);
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

  desfoqueTela(bool ativo){
    return TweenAnimationBuilder<double>(
      duration: const  Duration(seconds: 1),
      tween: Tween(begin: 0, end: ativo ? 5 : 0),
      builder: (context, blur, child) {
        return BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(color: Colors.black.withOpacity(0)),
        );
      },
    );
  }

  

  abaGuias(PrincipalCtrl ctrl){
    double tamanhoBloco = 80;
    double telaWidth = MediaQuery.of(context).size.width;
    return Positioned(
      left: -telaWidth + 16, // Ajuste este valor para mover para a esquerda
      top: -5,
      child: SizedBox(
        height: telaWidth/4,
        width: (telaWidth * 2) + tamanhoBloco * 1.5,
        child: FocusScope(
          node: ctrl.focusScopeAbaGuias,
          child: ScrollSnapList(
            background: Colors.red,
            padding: EdgeInsets.zero,
            listController: ctrl.scrolListAbaGuias, 
            itemCount: ctrl.listAbaGuias.length,
            onItemFocus: (i) { }, // Atualiza o índice do item em foco,
            itemSize: tamanhoBloco, // Tamanho horizontal
            itemBuilder: (context, i) {
              bool isFoco = ctrl.selectedIndexAbaGuias == i;
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  AnimatedContainer(
                    decoration: isFoco ? BoxDecoration(
                      borderRadius: BorderRadius.circular(40),
                      color: Colors.black87,
                    ) : const BoxDecoration(),
                    margin: const EdgeInsets.symmetric(vertical: 20,horizontal: 13) ,
                    width:  isFoco ? (tamanhoBloco - 26) * 3 : (tamanhoBloco -26 ),  // Largura do item base
                    duration: const Duration(milliseconds: 150),
                    child: Focus(
                      focusNode: ctrl.focusNodeAbaGuias[i],
                      onFocusChange: (hasFocus) => ctrl.onFocusChangeAbaGuias(hasFocus, i, tamanho: tamanhoBloco),
                      child:  btnAba(ctrl.listAbaGuias[i],isFoco),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
    // return Container(
    //   color: Colors.black38,
    //   margin: EdgeInsets.only(top: 10,left: 50),
    //   child: Row(
    //     mainAxisAlignment: MainAxisAlignment.start,
    //     crossAxisAlignment: CrossAxisAlignment.end,
    //     children: [
    //       btnAba("Jogos",true),
    //       btnAba("Filmes",false),
    //       // btnAba("Series",false),
    //     ],
    //   ),
    // );
  }

  btnAba(String txt,bool foco){
    const sombra = Shadow(color: Colors.black,blurRadius: 4);
    List<Shadow> sombras = [sombra,sombra,sombra];
    final stilo = TextStyle(color: Colors.white,shadows: sombras,fontSize: foco ? 25 : 15);
    return MaterialButton(
      elevation: 0,
      // color: Colors.transparent,
      padding: EdgeInsets.zero,
      onPressed: (){},
      child: FittedBox(child: Text(txt,style: stilo,)),
    );
  }

  



  videoAtivo(PrincipalCtrl ctrl){
    // Verifica se há vídeos disponíveis e se o índice é válido
    if (ctrl.videosYT.isEmpty || 
        ctrl.selectedIndexVideo < 0 || 
        ctrl.selectedIndexVideo >= ctrl.videosYT.length) {
      return const SizedBox.shrink();
    }

    double height = MediaQuery.of(context).size.height;
    return Align(
      alignment: Alignment.center,
      child: AnimatedContainer(
        curve: Curves.easeInOut,
        duration: const Duration(seconds: 3),
        margin: ctrl.imersaoVideos ? const EdgeInsets.all(10) : const EdgeInsets.only(bottom: 80),
        height: ctrl.imersaoVideos ? height : height * 0.70,
        width:  ctrl.imersaoVideos ? MediaQuery.of(context).size.width * 0.935 : height * 0.70 * 1.74, // Aspect ratio 16:9
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(50),
              child: Video(
                key: ValueKey('${ctrl.selectedIndexVideo}_${ctrl.videosYT[ctrl.selectedIndexVideo].url}'),
                controller: ctrl.mediaController,
                controls: NoVideoControls,
              ),
            ),
            // Loading bonito do vídeo
            if(ctrl.videoCarregando)
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.black.withOpacity(0.85),
                        Colors.black.withOpacity(0.95),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Animação de loading circular com efeito de pulse
                        _LoadingCircular(),
                        const SizedBox(height: 30),
                        // Texto animado
                        _LoadingTexto(),
                        const SizedBox(height: 15),
                        // Pontos animados
                        _LoadingPontos(),
                      ],
                    ),
                  ),
                ),
              ),
            if(ctrl.duracaoTotal != Duration.zero)
              Align(
                alignment: Alignment.bottomCenter ,
                child: AnimatedContainer(
                  margin: EdgeInsets.only(bottom: ctrl.imersaoVideos ? 5  : 40),
                  duration: const Duration(seconds: 3),
                  height: MediaQuery.of(context).size.height * 0.015,
                  child: BarraProgressoYT(duracaoTotal: ctrl.duracaoTotal, duracaoInicial: ctrl.duracaoAtual)),
              ),
          ],
        ),
      ),
    );
  }

  

  bodyPageView(PrincipalCtrl ctrl){
    double tamanhoBloco = 120;
    return PageView(
      scrollDirection: Axis.horizontal,
      controller: ctrl.bodyCtrl,
      children: [
        if(ctrl.cardGamesGrid) gridAnimado(ctrl, tamanhoBloco),
        if(!ctrl.cardGamesGrid) BodyIconesJogos(
          ctrl: ctrl,
          tamanhoBloco: tamanhoBloco,
          cardAnimado: (ctrl, index, tamanho) => cardAnimado(ctrl, index, tamanho: tamanho),
          cardAnimadoAdd: (ctrl, index) => cardAnimadoAdd(ctrl, index),
        ),
        if(ctrl.selectedIndexAbaGuias != 0) BodyIconesCinema(ctrl: ctrl, tamanhoBloco: tamanhoBloco),
        if(ctrl.selectedIndexAbaGuias != 0) BodyIconesMusica(ctrl: ctrl, tamanhoBloco: tamanhoBloco),
      ],      
    ); 
  }

  gridAnimado(PrincipalCtrl ctrl, double tamanhoBloco){
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      switchInCurve: const SafeCurve(Curves.easeOutBack),
      switchOutCurve: const SafeCurve(Curves.easeIn),
      transitionBuilder: (child, animation) {
        // Detect child by key to decide zoom direction: cardInf should zoom in.
        final isCardInf = child.key == const ValueKey('cardInf');
        final begin = isCardInf ? 0.75 : 1.0; // cardInf: small -> 1.0 (zoom in); grid: normal -> shrink
        final end = isCardInf ? 1.0 : 0.9;
        final scaleAnim = Tween<double>(begin: begin, end: end)
            .animate(CurvedAnimation(parent: animation, curve: const SafeCurve(Curves.easeOut)));
        return FadeTransition(
          opacity: animation.drive(Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: const SafeCurve(Curves.linear)))),
          child: ScaleTransition(
            scale: scaleAnim,
            child: child,
          ),
        );
      },
      child: !ctrl.cardInf ? KeyedSubtree(key: const ValueKey('grid'), child: BodyIconesJogosGrid(ctrl: ctrl, tamanhoBloco: tamanhoBloco))
                          : KeyedSubtree(key: const ValueKey('cardInf'), child: CardInfWidget(ctrl: ctrl)),
    );
  }

  

  

  botaoTag(String str){
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 5),
      decoration: BoxDecoration(
        color: Colors.white54,
        borderRadius: BorderRadius.circular(5)
      ),
      child: MaterialButton(
        onPressed: (){

        },
        child: Text(str,style: const TextStyle(color: Colors.brown),),
      ),
    );
  }

  

  

  Widget cardVideo(PrincipalCtrl ctrl, int i){
    if(i < 0 || i > ctrl.videosYT.length) return Container();
    return Focus(
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
    );
  }

  cardAnimado(PrincipalCtrl ctrl,int index,{double tamanho = 0}){
    return MouseRegion(
      onEnter: (event) {
        ctrl.mouseDentro(index,tamanho);
      },
      onExit: (value) {
        ctrl.mouseFora(index,tamanho);
      },
      child: CardGame(
        iconInitial: ctrl.listIconsInicial[index],
        focus: ctrl.selectedIndexIcone == index,
        imersao: ctrl.imersao,
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
              decoration:  BoxDecoration(
                image: DecorationImage( fit: BoxFit.cover, image:FileImage(File("${assetsPath}BGICOdefault.png")), //AssetImage('assets/BGICOdefault.png'),
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
    final item = BoxDecoration( image: DecorationImage( fit: BoxFit.cover, image: FileImage(File("${assetsPath}BGdefault.jpeg"),scale: 5)));
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

// Widgets de Loading Animado
class _LoadingCircular extends StatefulWidget {
  @override
  State<_LoadingCircular> createState() => _LoadingCircularState();
}

class _LoadingCircularState extends State<_LoadingCircular> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Transform.scale(
          scale: 0.8 + (_controller.value * 0.3),
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Colors.red,
                  Colors.red.withOpacity(0.1),
                ],
                stops: [_controller.value, _controller.value],
                transform: GradientRotation(_controller.value * 6.28),
              ),
            ),
            child: Center(
              child: Container(
                width: 90,
                height: 90,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black,
                ),
                child: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.red,
                  size: 50,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _LoadingTexto extends StatefulWidget {
  @override
  State<_LoadingTexto> createState() => _LoadingTextoState();
}

class _LoadingTextoState extends State<_LoadingTexto> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: 0.5 + (_controller.value * 0.5),
          child: const Text(
            'Carregando vídeo...',
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w500,
              letterSpacing: 1.2,
            ),
          ),
        );
      },
    );
  }
}

class _LoadingPontos extends StatefulWidget {
  @override
  State<_LoadingPontos> createState() => _LoadingPontosState();
}

class _LoadingPontosState extends State<_LoadingPontos> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        int activeDot = (_controller.value * 3).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (index) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 5),
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: index <= activeDot 
                    ? Colors.red 
                    : Colors.white.withOpacity(0.3),
              ),
            );
          }),
        );
      },
    );
  }
}


