// Coluna fixa de canais, à esquerda da tela de cinema.
//
// São os mesmos cartões de streaming do catálogo antigo (`listCinema`), com
// os mesmos índices e os mesmos FocusNode — por isso adicionar, remover e
// abrir canal continuam funcionando pelo PrincipalCtrl, sem código novo.
// Aqui eles deixam de ser uma grade no meio da tela e viram ícones de
// margem: o conteúdo é o catálogo, o canal é atalho.

import 'dart:io';

import 'package:flutter/material.dart';

import '../../Modelos/MediaCanal.dart';
import 'cinema_efeitos.dart';

class TrilhoCanais extends StatelessWidget {
  const TrilhoCanais({
    super.key,
    required this.canais,
    required this.focos,
    required this.selecionado,
    required this.ativo,
    required this.onApontar,
    required this.onAbrir,
    this.largura = larguraPadrao,
  });

  /// Largura da coluna.
  static const double larguraPadrao = 96;

  /// Onde começa a primeira capa. A coluna vai de ponta a ponta da tela,
  /// mas os ícones começam abaixo da barra de abas.
  static const double paddingTopo = 80;

  final List<MediaCanal> canais;
  final List<FocusNode> focos;
  final int selecionado;

  /// Verdadeiro quando o direcional está na coluna, e não no mosaico.
  final bool ativo;

  final ValueChanged<int> onApontar;
  final ValueChanged<int> onAbrir;
  final double largura;

  static const _diametro = 54.0;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: largura,
        child: Stack(children: [
          // Véu de vidro só sob a coluna: separa os ícones do mosaico sem
          // desenhar uma barra opaca por cima da arte.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: .62),
                    Colors.black.withValues(alpha: .10),
                  ],
                ),
              ),
            ),
          ),
          // Sem rótulo: a capa de cada canal já diz o que ele é, e a
          // palavra "canais" só roubava altura da coluna.
          ListView.builder(
            padding: const EdgeInsets.only(top: paddingTopo, bottom: 24),
            itemCount: canais.length,
            itemBuilder: (_, i) => _canal(i),
          ),
        ]),
      );

  Widget _canal(int i) {
    final canal = canais[i];
    final apontado = i == selecionado;
    final aceso = apontado && ativo;

    return Focus(
      focusNode: i < focos.length ? focos[i] : null,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => onApontar(i),
        child: GestureDetector(
          onTap: () {
            onApontar(i);
            onAbrir(i);
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 7),
            child: Center(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: aceso ? 1 : (apontado ? .4 : 0)),
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeOutCubic,
                builder: (_, t, __) => Transform.scale(
                  scale: 1 + .16 * t,
                  child: Container(
                    width: _diametro,
                    height: _diametro,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Color.lerp(Colors.white.withValues(alpha: .14),
                            Cine.realce, t)!,
                        width: 1 + 1.6 * t,
                      ),
                      boxShadow: [
                        // A coluna tem 96 px e o círculo 54: sobram 21 de
                        // cada lado, e um raio maior que isso sairia
                        // cortado na borda da coluna.
                        BoxShadow(
                          color: Cine.realce.withValues(alpha: .55 * t),
                          blurRadius: 18 * t,
                          spreadRadius: 1 * t,
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: .45),
                          blurRadius: 12,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Opacity(
                        opacity: .55 + .45 * t,
                        child: ArteCanal(canal: canal),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

}

/// A capa de um canal.
///
/// É um arquivo local gravado pelo próprio launcher; se sumir, o lugar vira
/// a inicial do nome sobre um fundo escuro, e não um ícone de imagem
/// quebrada. Usada no círculo da coluna e, grande, no painel do canal.
class ArteCanal extends StatelessWidget {
  const ArteCanal({
    super.key,
    required this.canal,
    this.fit = BoxFit.cover,
  });

  final MediaCanal canal;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (canal.imgLocal.isEmpty) return _inicial();
    return Image.file(
      File(canal.imgLocal),
      fit: fit,
      gaplessPlayback: true,
      errorBuilder: (_, __, ___) => _inicial(),
    );
  }

  Widget _inicial() => ColoredBox(
        color: const Color(0xFF15151F),
        child: Center(
          child: FittedBox(
            fit: BoxFit.scaleDown,
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                canal.nome.isEmpty ? '?' : canal.nome[0].toUpperCase(),
                style: Cine.titulo(20),
              ),
            ),
          ),
        ),
      );
}
