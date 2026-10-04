import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../scraps/catalogo_scraper.dart';

class JogoCard extends StatefulWidget {
  final JogoCatalogo jogo;
  final VoidCallback onAbrir;
  final FocusNode? focusNode;
  const JogoCard(
      {super.key, required this.jogo, required this.onAbrir, this.focusNode});

  @override
  State<JogoCard> createState() => _JogoCardState();
}

class _JogoCardState extends State<JogoCard> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    final jogo = widget.jogo;
    const fallback = ColoredBox(
      color: Color(0xFF202020),
      child: Center(child: Icon(Icons.videogame_asset_outlined, size: 48)),
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFF141414),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
              color: _focused ? const Color(0xFFA99AFF) : Colors.transparent,
              width: 3)),
      child: InkWell(
        focusNode: widget.focusNode,
        onTap: widget.onAbrir,
        focusColor: const Color(0x338B7CFF),
        onFocusChange: (value) => setState(() => _focused = value),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(
              child: SizedBox.expand(
                  child: jogo.imagem == null
                      ? fallback
                      : CachedNetworkImage(
                          imageUrl: jogo.imagem.toString(),
                          fit: BoxFit.cover,
                          placeholder: (_, __) => fallback,
                          errorWidget: (_, __, ___) => fallback,
                        ))),
          Padding(
            padding: const EdgeInsets.all(12),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(jogo.nome,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Text(jogo.genero,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style:
                      const TextStyle(color: Color(0xFFB8B3DF), fontSize: 12)),
            ]),
          ),
        ]),
      ),
    );
  }
}
