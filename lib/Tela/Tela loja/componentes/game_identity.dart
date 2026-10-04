import 'package:flutter/material.dart';
import 'imagem_jogo.dart';
import '../scraps/jogo_detalhes.dart';

/// Identidade do jogo sem entradas de foco no Pad.
class GameIdentity extends StatelessWidget {
  final JogoDetalhes jogo;
  final Uri? fallbackImage;
  final bool compact;
  const GameIdentity(
      {super.key,
      required this.jogo,
      this.fallbackImage,
      this.compact = false});
  @override
  Widget build(BuildContext context) {
    final cover = ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
            width: compact ? 88 : double.infinity,
            height: compact ? 118 : 240,
            child: ImagemJogo(url: jogo.capa ?? fallbackImage)));
    final title =
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('PC • LOJA INTERNA',
          style: TextStyle(color: Color(0xFFB6A8FF), fontSize: 12)),
      const SizedBox(height: 10),
      Text(jogo.nome,
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800)),
      const SizedBox(height: 12),
      Wrap(
          spacing: 6,
          runSpacing: 6,
          children:
              jogo.generos.map((genre) => Chip(label: Text(genre))).toList()),
    ]);
    return ExcludeFocus(
        child: compact
            ? Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                cover,
                const SizedBox(width: 16),
                Expanded(child: title)
              ])
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [cover, const SizedBox(height: 18), title]));
  }
}
