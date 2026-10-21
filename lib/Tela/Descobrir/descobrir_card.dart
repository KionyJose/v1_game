import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../Tela loja/scraps/catalogo_scraper.dart';

/// Um jogo no carrossel do Descobrir.
///
/// O cartão não tem foco próprio: quem está no centro é o selecionado, e a
/// navegação acontece movendo o carrossel. Por isso [destaque] controla toda
/// a aparência — escala, brilho e nitidez da borda — em vez de um `FocusNode`.
class DescobrirCard extends StatelessWidget {
  const DescobrirCard({
    super.key,
    required this.jogo,
    required this.destaque,
    required this.onAbrir,
  });

  final JogoCatalogo jogo;

  /// 1 quando o cartão está centralizado, 0 quando está na borda da tela.
  final double destaque;

  final VoidCallback onAbrir;

  static const _violeta = Color(0xFFB6A8FF);

  @override
  Widget build(BuildContext context) {
    final t = destaque.clamp(0.0, 1.0);
    return Semantics(
      button: true,
      selected: t > .5,
      label: jogo.nome,
      child: GestureDetector(
        onTap: onAbrir,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          margin: EdgeInsets.symmetric(
              horizontal: 10, vertical: 18 + (1 - t) * 26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(26),
            border: Border.all(
                color: Color.lerp(
                    Colors.white.withValues(alpha: .08), _violeta, t)!,
                width: 1 + t * 1.6),
            boxShadow: t < .2
                ? null
                : [
                    BoxShadow(
                        color: _violeta.withValues(alpha: .34 * t),
                        blurRadius: 34 * t,
                        spreadRadius: 1),
                  ],
          ),
          // O clipe acompanha a borda para a capa não vazar nos cantos.
          child: ClipRRect(
            borderRadius: BorderRadius.circular(25),
            child: Stack(fit: StackFit.expand, children: [
              _Capa(jogo: jogo),
              // Degradê do pé do cartão: o texto precisa de contraste sobre
              // capas claras, que são comuns na Steam.
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
                left: 16,
                right: 16,
                bottom: 16,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(jogo.nome,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 15 + t * 3,
                              height: 1.15,
                              color: Colors.white)),
                      if (jogo.generos.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(jogo.genero,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 12,
                                color: Colors.white
                                    .withValues(alpha: .55 + t * .35))),
                      ],
                    ]),
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

class _Capa extends StatelessWidget {
  const _Capa({required this.jogo});
  final JogoCatalogo jogo;

  @override
  Widget build(BuildContext context) {
    // Sem capa o cartão mostra a inicial do jogo, e não um buraco cinza.
    Widget reserva() => ColoredBox(
          color: const Color(0xFF1A1726),
          child: Center(
            child: Text(
                jogo.nome.isEmpty ? '?' : jogo.nome.characters.first,
                style: const TextStyle(
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF4B4470))),
          ),
        );
    final imagem = jogo.imagem;
    if (imagem == null) return reserva();
    return CachedNetworkImage(
      imageUrl: imagem.toString(),
      fit: BoxFit.cover,
      fadeInDuration: const Duration(milliseconds: 220),
      placeholder: (_, __) => const ColoredBox(color: Color(0xFF14121E)),
      errorWidget: (_, __, ___) => reserva(),
    );
  }
}
