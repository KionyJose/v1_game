import 'package:flutter/material.dart';

/// Logo da loja, com o ícone antigo como reserva.
///
/// O PNG é um arquivo que pode faltar no pacote, vir corrompido ou ainda não
/// ter sido desenhado. Em qualquer um desses casos o bloco precisa continuar
/// legível, então o ícone volta no lugar em vez de deixar um quadrado vazio.
class LojaLogo extends StatelessWidget {
  const LojaLogo({
    super.key,
    required this.logo,
    required this.icone,
    required this.tamanho,
    this.cor = Colors.white,
  });

  final String logo;
  final IconData icone;
  final double tamanho;
  final Color cor;

  @override
  Widget build(BuildContext context) {
    final reserva = Icon(icone, color: cor, size: tamanho);
    if (logo.isEmpty) return reserva;
    return Image.asset(
      logo,
      width: tamanho,
      height: tamanho,
      // Logo é desenho, não capa: `contain` evita cortar a marca.
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      errorBuilder: (_, __, ___) => reserva,
    );
  }
}
