import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import '../scraps/catalogo_scraper.dart';

class JogoCard extends StatelessWidget {
  final JogoCatalogo jogo;
  final VoidCallback onAbrir;
  const JogoCard({super.key, required this.jogo, required this.onAbrir});

  @override
  Widget build(BuildContext context) {
    const fallback = ColoredBox(
      color: Color(0xFF242735),
      child: Center(child: Icon(Icons.videogame_asset_outlined, size: 48)),
    );
    return Card(
      clipBehavior: Clip.antiAlias,
      color: const Color(0xFF1B1E2A),
      child: InkWell(
        onTap: onAbrir,
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
              const SizedBox(height: 10),
              const Row(children: [
                Text('Ver detalhes'),
                SizedBox(width: 6),
                Icon(Icons.open_in_new, size: 14)
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}
