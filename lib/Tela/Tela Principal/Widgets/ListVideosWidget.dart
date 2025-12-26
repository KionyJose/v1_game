// ignore_for_file: file_names

import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:v1_game/Tela/Tela%20Principal/PrincipalCtrl.dart';

class ListVideosWidget extends StatelessWidget {
  final PrincipalCtrl ctrl;
  final Widget Function(PrincipalCtrl ctrl, int i) cardVideo;

  const ListVideosWidget({
    super.key,
    required this.ctrl,
    required this.cardVideo,
  });

  @override
  Widget build(BuildContext context) {
    double tamanho = 0.2;
    const sdw = Shadow(color: Colors.black, blurRadius: 10);
    bool focoScop = false;

    try {
      if (ctrl.focusScope == ctrl.focusScopeVideos && !ctrl.videoAtivo) {
        tamanho = 0.27;
        focoScop = true;
      }
    } catch (_) {}

    return Align(
      alignment: Alignment.bottomLeft,
      child: AnimatedOpacity(
        opacity: ctrl.imersaoVideos ? 0 : 1.0,
        duration: const Duration(seconds: 2),
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AnimatedOpacity(
                duration: const Duration(milliseconds: 300),
                opacity: focoScop ? 1.0 : 0.0,
                child: SizedBox(
                  height: MediaQuery.of(context).size.height * 0.03,
                  child: FittedBox(
                    child: Text(
                      ctrl.videosYT[ctrl.selectedIndexVideo].titulo,
                      style: const TextStyle(
                        color: Colors.white,
                        shadows: [sdw, sdw],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 5),
              FocusScope(
                node: ctrl.focusScopeVideos,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  height: MediaQuery.of(context).size.height * tamanho,
                  width: double.infinity,
                  child: CarouselSlider(
                    carouselController: ctrl.carouselVideosCtrl,
                    options: CarouselOptions(
                      pageSnapping: true,
                      height: MediaQuery.of(context).size.height * tamanho,
                      autoPlay: ctrl.focusScopeVideos.hasFocus ? false : true,
                      enlargeCenterPage: true,
                      enableInfiniteScroll: true,
                      viewportFraction: tamanho,
                      initialPage: ctrl.selectedIndexVideo,
                      onPageChanged: (index, reason) {
                        ctrl.selectedIndexVideo = index;
                      },
                      enlargeStrategy: CenterPageEnlargeStrategy.zoom,
                    ),
                    items: [
                      for (int i = 0; i < ctrl.videosYT.length; i++)
                        cardVideo(ctrl, i)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
