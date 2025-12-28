// ignore_for_file: file_names, library_private_types_in_public_api

import 'package:flutter/material.dart';
import 'package:v1_game/Widgets/isosceles.dart';

class TituloGames extends StatefulWidget {
  const TituloGames({required this.imerso, required this.nome, super.key});
  final String nome;
  final bool imerso;

  @override
  _TituloGamesState createState() => _TituloGamesState();
}

class _TituloGamesState extends State<TituloGames> {
  bool mostraFundo = false;
  bool mostraTitulo = false;

  @override
  void initState() {
    super.initState();
    _startAnimations();
  }

  void _startAnimations() async {
    if(widget.imerso && mostraFundo)return;
    if (mounted) {
      setState(() {
        mostraFundo = false;
        mostraTitulo = false;
      });
    }
    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        mostraFundo = true;
      });
    }
    await Future.delayed(const Duration(milliseconds: 100));
    if (mounted) {
      setState(() {
        mostraTitulo = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // NÃO chame animação aqui!
    return Align(
      alignment: Alignment.topCenter,
      child: AnimatedSlide(       
        offset: mostraFundo ? const Offset(0, -0) : const Offset(0, -1),
        duration: const Duration(milliseconds: 900),
        curve: Curves.decelerate,
        child:ClipPath(
          clipper: IsoscelesClipper(),
          child:  AnimatedOpacity(
          opacity: widget.imerso ? 1.0 :  0.0,
          duration: const Duration(milliseconds: 500),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.5,
              height: MediaQuery.of(context).size.height * 0.05,
              decoration: const BoxDecoration(
                color: Colors.black54,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: AnimatedSlide(
                  offset: mostraTitulo ? const Offset(0, 0) : const Offset(0, -5),
                  duration: const  Duration(milliseconds: 900),
                  curve: Curves.decelerate,
                  child:  FittedBox(
                    child: Text(
                      widget.nome,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ),
                    ),
          ),
      ),)
    );
    
  }
  }

