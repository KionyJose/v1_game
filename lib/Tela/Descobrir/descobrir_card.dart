import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../Tela loja/scraps/catalogo_scraper.dart';

/// Um jogo na grade do Descobrir.
///
/// O cartão é 21:9 — mais largo que a capa da loja, que assim preenche a
/// altura inteira e sobra nas pontas, em vez de deixar faixa vazia.
///
/// Quem está selecionado é dito por [selecionado], e não por foco próprio: a
/// grade guarda o índice e o cartão só desenha o estado.
class DescobrirCard extends StatelessWidget {
  const DescobrirCard({
    super.key,
    required this.jogo,
    required this.selecionado,
    required this.onAbrir,
  });

  final JogoCatalogo jogo;
  final bool selecionado;
  final VoidCallback onAbrir;

  static const violeta = Color(0xFFB6A8FF);

  @override
  Widget build(BuildContext context) => Semantics(
        button: true,
        selected: selecionado,
        label: jogo.nome,
        child: GestureDetector(
          onTap: onAbrir,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            scale: selecionado ? 1 : .955,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: selecionado
                        ? violeta
                        : Colors.white.withValues(alpha: .07),
                    width: selecionado ? 2.2 : 1),
                boxShadow: selecionado
                    ? [
                        BoxShadow(
                            color: violeta.withValues(alpha: .38),
                            blurRadius: 26,
                            spreadRadius: 1),
                      ]
                    : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(fit: StackFit.expand, children: [
                  _Capa(jogo: jogo),
                  // Degradê no pé: capas claras são comuns e o nome precisa
                  // se sustentar por cima delas.
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.center,
                        end: Alignment.bottomCenter,
                        colors: [Color(0x00000000), Color(0xE605040A)],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 10,
                    right: 10,
                    bottom: 8,
                    child: Text(
                      jogo.nome,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        height: 1.15,
                        color: selecionado ? Colors.white : Colors.white70,
                        shadows: const [
                          Shadow(color: Colors.black, blurRadius: 6)
                        ],
                      ),
                    ),
                  ),
                ]),
              ),
            ),
          ),
        ),
      );
}

class _Capa extends StatelessWidget {
  const _Capa({required this.jogo});
  final JogoCatalogo jogo;

  @override
  Widget build(BuildContext context) {
    // Sem capa o cartão mostra a inicial, e não um buraco cinza.
    Widget reserva() => ColoredBox(
          color: const Color(0xFF1A1726),
          child: Center(
            child: Text(jogo.nome.isEmpty ? '?' : jogo.nome.characters.first,
                style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4B4470))),
          ),
        );
    final imagem = jogo.imagem;
    if (imagem == null) return reserva();
    return CachedNetworkImage(
      imageUrl: imagem.toString(),
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 200),
      placeholder: (_, __) => const ColoredBox(color: Color(0xFF14121E)),
      errorWidget: (_, __, ___) => reserva(),
    );
  }
}
