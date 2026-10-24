// Ficha do título: a tela inteira vira o filme.
//
// Sem janela, sem moldura e sem painel cinza — a arte ocupa tudo, o texto
// flutua sobre ela e o trailer entra por cima quando resolve. O que está
// selecionado é dito pela cor viva da ação, não por uma caixa de botão.

import 'package:flutter/material.dart';

import 'cinema_efeitos.dart';
import 'cinema_trailer.dart';
import 'tmdb_cine.dart';

/// Ações do rodapé da ficha, na ordem em que o direcional as percorre.
enum AcaoFicha { trailer, ondeAssistir, fechar }

/// Em que faixa da ficha o direcional está.
///
/// [player] é o estado em que o texto saiu de cena e o trailer manda na
/// tela: ali o direcional é controle de vídeo, não de navegação.
enum ZonaFicha { acoes, provedores, player }

class FichaCine extends StatelessWidget {
  const FichaCine({
    super.key,
    required this.titulo,
    required this.acoes,
    required this.acao,
    required this.onAcao,
    required this.visivel,
    this.carregando = false,
    this.trailerLigado = false,
    this.escritasVisiveis = true,
    this.onVideo,
    this.zona = ZonaFicha.acoes,
    this.provedor = 0,
    this.onProvedor,
    this.controle,
  });

  final TituloCine titulo;

  /// Ações disponíveis para este título — a tela calcula a lista uma vez e a
  /// usa tanto para desenhar quanto para andar com o direcional.
  final List<AcaoFicha> acoes;

  final AcaoFicha acao;
  final ValueChanged<AcaoFicha> onAcao;

  /// Falso quando a aba de cinema saiu de vista: o trailer para.
  final bool visivel;

  final bool carregando;

  /// Trailer rodando com som, pedido pelo usuário.
  final bool trailerLigado;

  /// Falso enquanto houver vídeo no ar: a coluna de texto sai de cena para
  /// não ficar escrita por cima do trailer.
  final bool escritasVisiveis;

  final ValueChanged<bool>? onVideo;

  final ZonaFicha zona;

  /// Provedor apontado, quando o direcional está na faixa deles.
  final int provedor;

  final ValueChanged<int>? onProvedor;

  /// Alça do player: progresso e pausa.
  final ControleTrailer? controle;

  /// Quais ações cabem a um título. Trailer só aparece quando existe vídeo;
  /// Sem serviços individuais, oferece a busca do título no Google.
  static List<AcaoFicha> acoesDe(TituloCine titulo) => [
        if (titulo.trailer != null) AcaoFicha.trailer,
        if (titulo.provedores.isEmpty) AcaoFicha.ondeAssistir,
        AcaoFicha.fechar,
      ];

  Color get _cor => Cine.cor(titulo.id);

  @override
  Widget build(BuildContext context) {
    final largura = MediaQuery.sizeOf(context).width;
    final disponivel = (largura - 56 - 48).clamp(0.0, double.infinity);
    final larguraTitulo =
        (largura * .42).clamp(320.0, 620.0).clamp(0.0, disponivel);
    final larguraDescricao = (larguraTitulo * 1.2).clamp(0.0, disponivel);

    return ColoredBox(
      color: Cine.fundo,
      child: Stack(fit: StackFit.expand, children: [
        // Arte e trailer ocupam a tela inteira; o texto vem por cima.
        ArteCine(
          // `original` chega a 4K: decodificar isso para preencher uma tela
          // de 1080 engasga a abertura da ficha e come memória à toa.
          url: titulo.fundoUrl(tamanho: 'w1280') ??
              titulo.arteLarga(tamanho: 'w1280'),
          nome: titulo.titulo,
          semente: titulo.id,
          zoom: 1.02,
          larguraCache: 1600,
        ),
        if (trailerLigado)
          TrailerCine(
            youtubeId: titulo.trailer,
            tocar: visivel,
            mudo: false,
            espera: const Duration(milliseconds: 120),
            onTocando: onVideo,
            controle: controle,
          ),
        AnimatedOpacity(
          key: const ValueKey('ficha-informacoes'),
          opacity: escritasVisiveis ? 1 : 0,
          duration: const Duration(seconds: 2),
          curve: Curves.easeInOut,
          child: IgnorePointer(
            ignoring: !escritasVisiveis,
            child: Stack(fit: StackFit.expand, children: [
              // Dois véus cruzados: um escurece a esquerda, onde mora o texto; o
              // outro apoia o rodapé. Juntos substituem a caixa de legenda.
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Color(0xF206060B),
                      Color(0x9906060B),
                      Color(0x1A06060B)
                    ],
                    stops: [0, .48, 1],
                  ),
                ),
              ),
              const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Color(0xE606060B), Color(0x0006060B)],
                    stops: [0, .6],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(56, 48, 48, 40),
                child: SizedBox(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Text(titulo.rotuloTipo.toUpperCase(),
                          // style: Cine.etiqueta(10, cor: _cor)),
                      const SizedBox(height: 16),
                      SizedBox(
                        key: const ValueKey('ficha-titulo'),
                        width: larguraTitulo,
                        child: _marca(larguraTitulo),
                      ),
                      const SizedBox(height: 18),
                      _linhaMeta(),
                      const SizedBox(height: 22),
                      Expanded(
                        child: SizedBox(
                          key: const ValueKey('ficha-descricao'),
                          width: larguraDescricao,
                          child: ShaderMask(
                            blendMode: BlendMode.dstIn,
                            shaderCallback: (rect) => const LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.white,
                                Colors.white,
                                Colors.transparent
                              ],
                              stops: [0, .85, 1],
                            ).createShader(rect),
                            child: SingleChildScrollView(
                              child: Text(
                                carregando && titulo.sinopse.isEmpty
                                    ? 'Carregando a ficha…'
                                    : titulo.sinopse.isEmpty
                                        ? 'Este título ainda não tem sinopse em '
                                            'português no catálogo.'
                                        : titulo.sinopse,
                                style: Cine.corpo(16,
                                    cor: const Color(0xDDF2EEFF)),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 26),
                      _acoes(),
                    ],
                  ),
                ),
              ),
            ]),
          ),
        ),
        if (zona == ZonaFicha.player && controle != null)
          BarraTrailer(controle: controle!, cor: _cor, nome: titulo.titulo),
      ]),
    );
  }

  /// Logo do filme quando existe; o nome em tipo grande quando não. Nunca os
  /// dois — é a mesma informação.
  Widget _marca(double largura) {
    final logo = titulo.logoUrl(tamanho: 'w500');
    if (logo != null) {
      return ConstrainedBox(
        constraints: BoxConstraints(maxWidth: largura * .9, maxHeight: 150),
        child: Image.network(
          logo,
          fit: BoxFit.contain,
          alignment: Alignment.centerLeft,
          cacheWidth: (largura * 1.6).round(),
          errorBuilder: (_, __, ___) => _nome(),
        ),
      );
    }
    return _nome();
  }

  Widget _nome() => Text(
        titulo.titulo,
        maxLines: 3,
        style: Cine.titulo(54).copyWith(shadows: Cine.sombraTexto),
      );

  Widget _linhaMeta() => Row(children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _cor,
            boxShadow: [BoxShadow(color: _cor, blurRadius: 12)],
          ),
        ),
        const SizedBox(width: 8),
        Text(titulo.notaTexto, style: Cine.titulo(18)),
        const SizedBox(width: 18),
        Flexible(
          child: Text(
            [
              if (titulo.ano.isNotEmpty) titulo.ano,
              if (titulo.generos.isNotEmpty) titulo.generos.take(3).join(' · '),
            ].join('   ·   '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Cine.etiqueta(10),
          ),
        ),
      ]);

  /// Os serviços onde dá para assistir. São alvos de verdade: o direcional
  /// entra na faixa, e confirmar copia o nome do filme e abre o site — é o
  /// caminho que a pessoa faria à mão, com o nome já na área de
  /// transferência para colar na busca de lá.
  Widget _provedores() {
    final lista = titulo.provedores;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        for (var i = 0; i < lista.length; i++)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Builder(builder: (context) {
              final apontado = zona == ZonaFicha.provedores && i == provedor;
              if (apontado) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (context.mounted) {
                    // Revela apenas o serviço na lista local. A versão
                    // estática também rolava o PageView das abas externas.
                    final lista = Scrollable.maybeOf(context);
                    final alvo = context.findRenderObject();
                    if (lista != null && alvo != null && alvo.attached) {
                      lista.position.ensureVisible(alvo,
                          alignment: .5,
                          duration: const Duration(milliseconds: 220));
                    }
                  }
                });
              }
              return _provedorItem(lista[i], i, apontado);
            }),
          ),
      ]),
    );
  }

  /// Um serviço: a fotinha e o nome embaixo.
  ///
  /// O logo sozinho, a 44 px, não identifica — Disney+, Prime Video e Max
  /// têm ícones parecidos a esse tamanho. O nome embaixo é o que resolve:
  /// a pessoa confirma o que está escolhendo antes de confirmar.
  Widget _provedorItem(ProvedorCine provedor, int indice, bool apontado,
      {VoidCallback? onAbrir}) {
    final logo = provedor.logoUrl();
    return Semantics(
      key: ValueKey('ficha-provedor-$indice'),
      button: true,
      selected: apontado,
      label: provedor.nome,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: onAbrir ?? () => onProvedor?.call(indice),
          child: SizedBox(
            width: 68,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  padding: EdgeInsets.all(apontado ? 3 : 0),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: apontado ? _cor : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: apontado
                        ? [
                            BoxShadow(
                                color: _cor.withValues(alpha: .5),
                                blurRadius: 22),
                          ]
                        : null,
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: logo == null
                          ? ColoredBox(
                              color: Colors.white.withValues(alpha: .08),
                              child: Center(
                                child: Text(
                                  provedor.nome.isEmpty
                                      ? '?'
                                      : provedor.nome[0].toUpperCase(),
                                  style: Cine.titulo(16),
                                ),
                              ),
                            )
                          : Image.network(
                              logo,
                              fit: BoxFit.cover,
                              cacheWidth: 96,
                              errorBuilder: (_, __, ___) => ColoredBox(
                                  color: Colors.white.withValues(alpha: .08)),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  provedor.nome,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: Cine.etiqueta(8.5,
                      cor: apontado ? Cine.tinta : Cine.tintaFraca),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _acoes() => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (acoes.contains(AcaoFicha.trailer)) ...[
            Column(mainAxisSize: MainAxisSize.min, children: [
              Text('Trailer', style: Cine.etiqueta(9)),
              const SizedBox(height: 10),
              _acaoItem(AcaoFicha.trailer),
            ]),
            const SizedBox(width: 24),
          ],
          if (titulo.provedores.isNotEmpty ||
              acoes.contains(AcaoFicha.ondeAssistir))
            Expanded(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Onde assistir', style: Cine.etiqueta(9)),
                const SizedBox(height: 10),
                if (titulo.provedores.isNotEmpty)
                  _provedores()
                else
                  KeyedSubtree(
                    key: const ValueKey('ficha-google'),
                    child: _provedorItem(
                      const ProvedorCine(nome: 'Google'),
                      0,
                      zona == ZonaFicha.acoes && acao == AcaoFicha.ondeAssistir,
                      onAbrir: () => onAcao(AcaoFicha.ondeAssistir),
                    ),
                  ),
              ],
            ))
          else
            const Spacer(),
          const SizedBox(width: 24),
          Padding(
            padding: const EdgeInsets.only(top: 20),
            child: _acaoItem(AcaoFicha.fechar),
          ),
        ],
      );

  Widget _acaoItem(AcaoFicha item) {
    final escolhida = zona == ZonaFicha.acoes && item == acao;
    final (chave, rotulo, icone) = switch (item) {
      AcaoFicha.trailer => (
          'ficha-trailer',
          'Reproduzir trailer',
          Icons.play_arrow_rounded
        ),
      AcaoFicha.ondeAssistir => (
          'ficha-onde-assistir',
          'Ver sites onde assistir',
          Icons.open_in_new_rounded
        ),
      AcaoFicha.fechar => ('ficha-voltar', 'Voltar', Icons.arrow_back_rounded),
    };
    return Semantics(
      key: ValueKey(chave),
      button: true,
      selected: escolhida,
      label: rotulo,
      child: Tooltip(
        message: rotulo,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => onAcao(item),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: escolhida
                    ? _cor.withValues(alpha: .16)
                    : Colors.transparent,
                border: Border.all(
                    color: escolhida ? _cor : Colors.transparent, width: 2),
              ),
              child:
                  Icon(icone, size: 34, color: escolhida ? _cor : Cine.tinta),
            ),
          ),
        ),
      ),
    );
  }
}

/// A régua do player, embaixo da tela, enquanto o trailer manda.
///
/// Redesenha sozinha a cada posição nova: ela escuta o [ControleTrailer]
/// direto, em vez de a ficha inteira se reconstruir quatro vezes por segundo
/// por causa de um relógio.
class BarraTrailer extends StatelessWidget {
  const BarraTrailer({
    super.key,
    required this.controle,
    required this.cor,
    required this.nome,
  });

  final ControleTrailer controle;
  final Color cor;
  final String nome;

  static String _relogio(Duration d) {
    final minutos = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final segundos = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return d.inHours > 0
        ? '${d.inHours}:$minutos:$segundos'
        : '$minutos:$segundos';
  }

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.bottomCenter,
        child: AnimatedBuilder(
          animation: controle,
          builder: (_, __) {
            final total = controle.duracao.inMilliseconds;
            final andado = controle.posicao.inMilliseconds;
            final fracao = total <= 0 ? 0.0 : (andado / total).clamp(0.0, 1.0);
            return Padding(
              padding: const EdgeInsets.fromLTRB(56, 0, 56, 34),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Icon(
                      controle.pausado
                          ? Icons.play_arrow_rounded
                          : Icons.pause_rounded,
                      color: cor,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        nome,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style:
                            Cine.titulo(15).copyWith(shadows: Cine.sombraTexto),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${_relogio(controle.posicao)}  /  '
                      '${_relogio(controle.duracao)}',
                      style: Cine.etiqueta(9),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  // Régua fina: o trailer é o conteúdo, a barra é só
                  // referência de onde ele está.
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: SizedBox(
                      height: 4,
                      child: Stack(children: [
                        Positioned.fill(
                          child: ColoredBox(
                              color: Colors.white.withValues(alpha: .18)),
                        ),
                        FractionallySizedBox(
                          widthFactor: fracao,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: cor,
                              boxShadow: [
                                BoxShadow(
                                    color: cor.withValues(alpha: .7),
                                    blurRadius: 10),
                              ],
                            ),
                          ),
                        ),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
}
