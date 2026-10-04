import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class ImagemJogo extends StatelessWidget {
  final Uri? url;
  final BoxFit fit;
  const ImagemJogo({super.key, required this.url, this.fit = BoxFit.cover});

  @override
  Widget build(BuildContext context) {
    const vazio = ColoredBox(
        color: Color(0xFF181818),
        child: Center(
            child: Icon(Icons.image_outlined,
                color: Color(0xFF8B88AD), size: 42)));
    return url == null
        ? vazio
        : CachedNetworkImage(
            imageUrl: url.toString(),
            fit: fit,
            placeholder: (_, __) => vazio,
            errorWidget: (_, __, ___) => vazio);
  }
}
