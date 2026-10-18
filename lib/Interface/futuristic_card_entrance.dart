import 'package:flutter/material.dart';

/// Entrada em cascata dos cards: cada um desliza da direita e surge um pouco
/// depois do anterior, até a esteira estar montada.
///
/// Serve a três coisas ao mesmo tempo: dá um começo à tela, cobre a espera da
/// biblioteca sem o foco cair na barra de abas, e faz o motor gráfico desenhar
/// vidro, reflexo e escala antes do primeiro movimento do jogador.
class FuturisticCardEntrance extends StatelessWidget {
  const FuturisticCardEntrance(
      {super.key,
      required this.animation,
      required this.index,
      required this.child});

  /// Progresso geral da entrada, de 0 a 1.
  final Animation<double> animation;

  /// Posição do card na esteira: é o que escalona a chegada.
  final int index;
  final Widget child;

  /// Quantos cards chegam escalonados. Além disso a esteira já está fora da
  /// área visível, e esperar por eles só atrasaria a liberação do controle.
  static const escalonados = 7;

  /// Atraso entre um card e o próximo, como fração da animação inteira.
  static const _passo = .095;

  /// Quanto cada card leva para chegar, na mesma fração.
  static const _trecho = .40;

  /// Escala de tempo da cascata inteira. É aqui que se acelera ou desacelera
  /// a entrada sem mexer no ritmo entre os cards.
  static const _escala = 1850;

  /// Duração total, já contando o último card escalonado: cerca de 1,8 s, com
  /// ~175 ms entre um card e o próximo.
  static Duration get duracao => Duration(
      milliseconds:
          (((escalonados - 1) * _passo + _trecho) * _escala).round());

  @override
  Widget build(BuildContext context) {
    final inicio = (index.clamp(0, escalonados - 1)) * _passo;
    final curva = CurvedAnimation(
      parent: animation,
      curve: Interval(inicio, (inicio + _trecho).clamp(0.0, 1.0),
          curve: Curves.easeOutCubic),
    );
    return AnimatedBuilder(
      animation: curva,
      child: child,
      builder: (context, child) {
        final t = curva.value;
        return Opacity(
          // Nunca exatamente zero: em zero o Flutter descarta a pintura, e a
          // entrada deixaria de aquecer o desenho dos cards.
          opacity: t.clamp(.004, 1.0),
          child: Transform.translate(
            offset: Offset((1 - t) * 90, 0),
            child: Transform.scale(
              scale: .92 + .08 * t,
              alignment: Alignment.bottomLeft,
              child: child,
            ),
          ),
        );
      },
    );
  }
}
