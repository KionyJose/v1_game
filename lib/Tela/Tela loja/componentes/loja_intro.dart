import 'package:flutter/material.dart';

/// Identidade e busca centralizadas, mantendo as categorias livres abaixo.
class LojaIntro extends StatelessWidget {
  final String descricao;
  final Widget busca;
  final double viewportWidth;
  final bool carregando;
  const LojaIntro(
      {super.key,
      required this.descricao,
      required this.busca,
      required this.viewportWidth,
      this.carregando = false});

  @override
  Widget build(BuildContext context) {
    final titleStyle = Theme.of(context).textTheme.headlineMedium!;
    return Column(children: [
      ExcludeFocus(
          child: Column(children: [
        Image.asset('assets/IconeAppV1.png',
            width: 64, height: 64, semanticLabel: 'Logo do app'),
        const SizedBox(height: 12),
        Text('Loja Interna',
            textAlign: TextAlign.center,
            style: titleStyle.copyWith(
                fontSize: titleStyle.fontSize! * 1.1,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        Text(descricao.replaceAll('GamesTorrents', 'atualmente'),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Color(0xFFB8B3C5))),
      ])),
      const SizedBox(height: 24),
      if (carregando)
        const Center(child: CircularProgressIndicator())
      else
        Center(
          child: SizedBox(
              width: viewportWidth >= 900 ? viewportWidth / 3 : double.infinity,
              child: busca)),
    ]);
  }
}
