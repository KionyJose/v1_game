import 'package:flutter/material.dart';

Future<T?> abrirTelaLauncher<T>(BuildContext context, Widget tela) =>
    Navigator.of(context).push<T>(PageRouteBuilder<T>(
      transitionDuration: const Duration(milliseconds: 320),
      reverseTransitionDuration: const Duration(milliseconds: 240),
      pageBuilder: (_, __, ___) => tela,
      transitionsBuilder: (_, animation, __, child) {
        final curve = animation.drive(CurveTween(curve: Curves.easeOutCubic));
        return FadeTransition(
            opacity: curve,
            child: SlideTransition(
                position: curve.drive(
                    Tween(begin: const Offset(0, .035), end: Offset.zero)),
                child: child));
      },
    ));
