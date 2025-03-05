import 'package:flutter/material.dart';

class IsoscelesClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final Path path = Path();
    path.lineTo(0, 0); // Ponto superior esquerdo
    path.lineTo(size.width, 0); // Ponto superior direito
    path.lineTo(size.width * 0.85, size.height); // Ponto inferior direito mais próximo do centro
    path.lineTo(size.width * 0.15, size.height); // Ponto inferior esquerdo mais próximo do centro
    path.close();
    return path;
  }

  @override
  bool shouldReclip(CustomClipper<Path> oldClipper) => false;
}