import 'dart:async';

import 'package:flutter/material.dart';
import 'futuristic_card_effect.dart';

/// A faixa de brilho do card só é desenhada quando a seleção assenta, 70 ms
/// depois de um movimento. Como nada a desenha enquanto a tela está parada, é
/// no primeiro movimento que o motor gráfico compila o pipeline dela — e é por
/// isso que só o primeiro engasga, e dali em diante tudo corre liso.
///
/// Este aquecimento desenha o mesmo efeito, com o mesmo widget, logo após o
/// primeiro quadro: num quadrado pequeno, quase transparente e fora do
/// alcance do toque. Quando o jogador move para o card do lado, o pipeline já
/// está compilado.
///
/// A opacidade é baixa, mas **não** zero de propósito: em zero o Flutter
/// descarta a pintura e o aquecimento não aconteceria.
class FuturisticWarmup extends StatefulWidget {
  const FuturisticWarmup({super.key});

  /// Quanto o brilho leva para percorrer o card, com folga para terminar.
  static const duracao = Duration(milliseconds: 1250);

  @override
  State<FuturisticWarmup> createState() => _FuturisticWarmupState();
}

class _FuturisticWarmupState extends State<FuturisticWarmup> {
  int _revisao = 0;
  bool _concluido = false;
  Timer? _encerramento;

  @override
  void initState() {
    super.initState();
    // Depois do primeiro quadro: aquecer durante a montagem só atrasaria a
    // própria abertura da tela.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.disableAnimationsOf(context)) {
        setState(() => _concluido = true);
        return;
      }
      setState(() => _revisao++);
      _encerramento = Timer(FuturisticWarmup.duracao, () {
        if (mounted) setState(() => _concluido = true);
      });
    });
  }

  @override
  void dispose() {
    _encerramento?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_concluido || MediaQuery.disableAnimationsOf(context)) {
      return const SizedBox.shrink();
    }
    return IgnorePointer(
      child: Opacity(
        opacity: .004,
        child: SizedBox(
          width: 48,
          height: 48,
          child: FuturisticCardEffect(
            selected: true,
            focused: true,
            settledRevision: _revisao,
            child: const ColoredBox(color: Color(0xFF101014)),
          ),
        ),
      ),
    );
  }
}
