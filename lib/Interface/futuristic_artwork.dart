import 'dart:io';
import 'package:flutter/material.dart';

class FuturisticArtwork extends StatelessWidget {
  const FuturisticArtwork(
      {super.key, required this.image, this.fit = BoxFit.cover});
  final String image;
  final BoxFit fit;
  @override
  Widget build(BuildContext context) {
    const fallback = ColoredBox(
        color: Color(0xFF242037),
        child: Center(
            child: Icon(Icons.sports_esports_rounded,
                color: Color(0xFFA9EEE4), size: 64)));
    if (image.isEmpty) return fallback;
    if (image.startsWith('assets/')) {
      return Image.asset(image,
          fit: fit, errorBuilder: (_, __, ___) => fallback);
    }
    if (image.startsWith('http')) {
      return Image.network(image,
          fit: fit, errorBuilder: (_, __, ___) => fallback);
    }
    return Image.file(File(image),
        fit: fit, errorBuilder: (_, __, ___) => fallback);
  }
}
