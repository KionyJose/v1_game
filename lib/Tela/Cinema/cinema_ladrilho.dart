// Os ladrilhos do mosaico. Uma mesma peça em cinco formatos: quadro largo,
// cartaz, quadrado com reflexo, círculo e bloco de mosaico.
//
// O ladrilho não tem foco próprio nem conhece o Pad: ele recebe
// [selecionado], [virado] e [expandido] e desenha o estado. Quem conta o
// tempo parado e encadeia virada, abertura e trailer é a tela.

import 'package:flutter/material.dart';

import 'cinema_efeitos.dart';
import 'cinema_trailer.dart';
import 'tmdb_cine.dart';

class LadrilhoCine extends StatelessWidget {
  const LadrilhoCine({
    super.key,
    required this.titulo,
    required this.forma,
    required this.selecionado,
    required this.indice,
    required this.tamanho,
    required this.onAbrir,
    this.onApontar,
    this.virado = false,
    this.expandido = false,
    this.comPrevia = true,
    this.tocarTrailer = false,
    this.onVideo,
    this.onPreviaAberta,
  });

  final TituloCine titulo;
  final FormaCine forma;
  final bool selecionado;
  final int indice;
  final Size tamanho;
  final VoidCallback onAbrir;
  final VoidCallback? onApontar;

  /// Mostrando o verso.
  final bool virado;

  /// Prévia aberta ao lado direito.
  final bool expandido;

  /// Falso no mosaico, onde a prévia é desenhada pela faixa, solta na pilha:
  /// ali o bloco tem posição fixa e crescer para o lado estouraria o retângulo.
  final bool comPrevia;

  final bool tocarTrailer;
  final ValueChanged<bool>? onVideo;
  final VoidCallback? onPreviaAberta;

  Color get _cor => Cine.cor(titulo.id);

  /// Quem vira.
  ///
  /// Só o cartaz em pé e os blocos **pequenos** do mosaico. O quadro largo,
  /// o quadrado e o círculo ficam parados: neles a arte é o conteúdo, e
  /// girar um painel de texto por cima dela não acrescenta nada. No mosaico,
  /// o bloco grande também fica — ele já mostra o que o verso diria.
  ///
  /// A regra vale para o ciclo inteiro: quem não vira também não abre
  /// prévia nem toca trailer.
  static bool podeVirar(FormaCine forma, Size tamanho) =>
      forma == FormaCine.poster ||
      (forma == FormaCine.mosaico && tamanho.width <= 300);

  bool get _vira_ => podeVirar(forma, tamanho);

  /// Altura do cartão em si — sem o reflexo, que é chão e não conteúdo.
  double get alturaNucleo => switch (forma) {
        FormaCine.quadrado => tamanho.width,
        FormaCine.circulo => tamanho.width,
        _ => tamanho.height,
      };

  @override
  Widget build(BuildContext context) {
    final corpo = switch (forma) {
      FormaCine.largo => _largo(),
      FormaCine.poster => _poster(),
      FormaCine.quadrado => _quadrado(),
      FormaCine.circulo => _circulo(),
      FormaCine.mosaico => _mosaico(),
    };

    return Semantics(
      button: true,
      selected: selecionado,
      label: titulo.titulo,
      child: MouseRegion(
        onEnter: (_) => onApontar?.call(),
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () {
            onApontar?.call();
            onAbrir();
          },
          child: EntradaCine(
            indice: indice,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                corpo,
                if (comPrevia && _vira_)
                  PreviaCine(
                    titulo: titulo,
                    aberta: expandido,
                    tocar: tocarTrailer,
                    onVideo: onVideo,
                    onAberta: onPreviaAberta,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Envolve a frente do cartão na virada, quando este formato vira. Nos
  /// outros, devolve a frente direto — sem ViradaCine não há nem o
  /// controlador de animação dela.
  Widget _vira(Widget frente, Widget verso) => _vira_
      ? ViradaCine(virado: virado, frente: frente, verso: verso)
      : frente;

  // ------------------------------------------------------------------ largo

  /// Quadro 16:9 com a arte de fundo, logo do título e metadados. É a faixa
  /// de destaque: grande o bastante para a imagem contar a história.
  Widget _largo() => RealceCine(
        selecionado: selecionado,
        cor: _cor,
        raio: 24,
        child: _vira(
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BrilhoVarrido(
              ativo: selecionado,
              cor: _cor,
              child: SizedBox(
                width: tamanho.width,
                height: tamanho.height,
                child: Stack(fit: StackFit.expand, children: [
                  ArteCine(
                    url: titulo.arteLarga(tamanho: 'w780'),
                    nome: titulo.titulo,
                    semente: titulo.id,
                    escuro: .92,
                    larguraCache: (tamanho.width * 1.6).round(),
                  ),
                  // Sem título escrito: a arte do filme já o traz, e texto
                  // por cima de cartaz é informação repetida tapando
                  // desenho. O que fica é a linha curta de dados.
                  Positioned(left: 20, right: 20, bottom: 16, child: _meta()),
                  if (selecionado) _contorno(24),
                ]),
              ),
            ),
          ),
          _verso(tamanho, 24),
        ),
      );

  // ----------------------------------------------------------------- poster

  /// Cartaz 2:3.
  Widget _poster() => RealceCine(
        selecionado: selecionado,
        cor: _cor,
        raio: 20,
        child: _vira(
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: BrilhoVarrido(
              ativo: selecionado,
              cor: _cor,
              child: SizedBox(
                width: tamanho.width,
                height: tamanho.height,
                child: Stack(fit: StackFit.expand, children: [
                  ArteCine(
                    url: titulo.arteFechada(tamanho: 'w342'),
                    nome: titulo.titulo,
                    semente: titulo.id,
                    escuro: .55,
                    larguraCache: (tamanho.width * 1.6).round(),
                  ),
                  Positioned(top: 12, left: 12, child: _nota()),
                  if (selecionado) _contorno(20),
                ]),
              ),
            ),
          ),
          _verso(tamanho, 20),
        ),
      );

  // --------------------------------------------------------------- quadrado

  /// Quadrado com reflexo embaixo: a faixa das séries fica apoiada num chão
  /// de vidro, o que a separa das vizinhas sem precisar de moldura. O
  /// espelho copia a virada junto.
  Widget _quadrado() {
    final lado = Size(tamanho.width, tamanho.width);
    return ReflexoCine(
      altura: tamanho.width * .32,
      alturaFilho: tamanho.width,
      larguraFilho: tamanho.width,
      child: RealceCine(
        selecionado: selecionado,
        cor: _cor,
        raio: 26,
        child: _vira(
          ClipRRect(
            borderRadius: BorderRadius.circular(26),
            child: BrilhoVarrido(
              ativo: selecionado,
              cor: _cor,
              child: SizedBox(
                width: lado.width,
                height: lado.height,
                child: Stack(fit: StackFit.expand, children: [
                  ArteCine(
                    url: titulo.arteFechada(tamanho: 'w342'),
                    nome: titulo.titulo,
                    semente: titulo.id,
                    escuro: .8,
                    larguraCache: (lado.width * 1.6).round(),
                  ),
                  Positioned(
                    left: 16,
                    right: 16,
                    bottom: 14,
                    child: Row(children: [
                      _nota(),
                      const SizedBox(width: 10),
                      Text(
                        titulo.ano.isEmpty ? 'Série' : 'Série · ${titulo.ano}',
                        style: Cine.etiqueta(9)
                            .copyWith(shadows: Cine.sombraTexto),
                      ),
                    ]),
                  ),
                  if (selecionado) _contorno(26),
                ]),
              ),
            ),
          ),
          _verso(lado, 26),
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- círculo

  /// Círculo com anel de luz e o nome embaixo — recorte leve para a faixa de
  /// animação e família.
  Widget _circulo() {
    final diametro = tamanho.width;
    return SizedBox(
      width: diametro,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: selecionado ? 1 : 0),
            duration: const Duration(milliseconds: 340),
            curve: Curves.easeOutBack,
            builder: (_, t, filho) {
              // easeOutBack passa de 1 na ida e **abaixo de zero** na volta.
              // Isso é o charme da escala e é veneno para o resto: raio de
              // sombra negativo é erro de verdade, derruba o cartão e põe um
              // ErrorWidget de 100000 px dentro da faixa no lugar dele.
              final luz = t.clamp(0.0, 1.0);
              return Transform.scale(
                scale: 1 + .10 * t,
                child: Container(
                  width: diametro,
                  height: diametro,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Color.lerp(
                          Colors.white.withValues(alpha: .12), _cor, luz)!,
                      width: 1.5 + 2 * luz,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _cor.withValues(alpha: .45 * luz),
                        blurRadius: 34 * luz,
                        spreadRadius: 1.5 * luz,
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: .5),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: filho,
                ),
              );
            },
            child: _vira(
              ClipOval(
                child: BrilhoVarrido(
                  ativo: selecionado,
                  cor: _cor,
                  child: ArteCine(
                    url: titulo.arteFechada(tamanho: 'w342'),
                    nome: titulo.titulo,
                    semente: titulo.id,
                    zoom: 1.06,
                    larguraCache: (diametro * 1.6).round(),
                  ),
                ),
              ),
              _versoRedondo(diametro),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------- mosaico

  /// Bloco de tamanho variável. A faixa decide a medida; aqui só muda o peso
  /// do texto conforme o espaço.
  Widget _mosaico() {
    final grande = tamanho.width > 300;
    return RealceCine(
      selecionado: selecionado,
      cor: _cor,
      raio: 18,
      child: _vira(
        ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: BrilhoVarrido(
            ativo: selecionado,
            cor: _cor,
            child: SizedBox(
              width: tamanho.width,
              height: tamanho.height,
              child: Stack(fit: StackFit.expand, children: [
                ArteCine(
                  url: grande
                      ? titulo.arteLarga(tamanho: 'w780')
                      : titulo.arteFechada(tamanho: 'w342'),
                  nome: titulo.titulo,
                  semente: titulo.id,
                  escuro: .88,
                  larguraCache: (tamanho.width * 1.6).round(),
                ),
                if (grande)
                  Positioned(left: 14, right: 14, bottom: 12, child: _meta())
                else
                  Positioned(top: 10, left: 10, child: _nota()),
                if (selecionado) _contorno(18),
              ]),
            ),
          ),
        ),
        _verso(tamanho, 18),
      ),
    );
  }

  // ------------------------------------------------------------------ peças

  /// Verso do cartão: a ficha curta, no mesmo recorte da frente. Em cartão
  /// baixo a sinopse não entra — ela viraria duas linhas cortadas, que não
  /// informam nada.
  Widget _verso(Size medida, double raio) {
    final cabeSinopse = medida.height >= 210;
    return ClipRRect(
      borderRadius: BorderRadius.circular(raio),
      child: Container(
        width: medida.width,
        height: medida.height,
        padding: EdgeInsets.all(medida.width > 260 ? 22 : 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color.lerp(_cor, Colors.black, .62)!,
              const Color(0xFF07070C),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo.titulo,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Cine.titulo(medida.width > 260 ? 22 : 16),
            ),
            const SizedBox(height: 6),
            Text(titulo.linhaMeta,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Cine.etiqueta(9)),
            if (cabeSinopse) ...[
              const SizedBox(height: 12),
              Expanded(
                child: Text(
                  titulo.sinopse.isEmpty
                      ? 'Sem sinopse cadastrada para este título.'
                      : titulo.sinopse,
                  overflow: TextOverflow.fade,
                  style: Cine.corpo(12),
                ),
              ),
            ] else
              const Spacer(),
            Row(children: [
              _nota(),
              const Spacer(),
              if (titulo.trailer != null)
                Text('trailer', style: Cine.etiqueta(8.5, cor: _cor)),
            ]),
          ],
        ),
      ),
    );
  }

  /// Verso do círculo: só o essencial, centralizado — texto corrido dentro
  /// de 150 px de diâmetro não se lê.
  Widget _versoRedondo(double diametro) => ClipOval(
        child: Container(
          width: diametro,
          height: diametro,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.lerp(_cor, Colors.black, .58)!,
                const Color(0xFF07070C),
              ],
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                titulo.titulo,
                maxLines: 3,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: Cine.titulo(13),
              ),
              const SizedBox(height: 10),
              _nota(),
            ],
          ),
        ),
      );

  Widget _meta() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _nota(),
          const SizedBox(width: 10),
          Flexible(
            child: Text(
              titulo.linhaMeta,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Cine.etiqueta(9.5).copyWith(shadows: Cine.sombraTexto),
            ),
          ),
        ],
      );

  /// Nota sem pílula: um ponto colorido e o número, para não virar caixinha.
  Widget _nota() => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _cor,
              boxShadow: [
                BoxShadow(color: _cor.withValues(alpha: .8), blurRadius: 8),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Text(
            titulo.notaTexto,
            style: Cine.titulo(12, cor: Cine.tinta)
                .copyWith(shadows: Cine.sombraTexto),
          ),
        ],
      );

  /// Contorno fino de seleção, por dentro do recorte.
  Widget _contorno(double raio) => IgnorePointer(
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(raio),
            border: Border.all(
                color: Colors.white.withValues(alpha: .85), width: 2),
          ),
        ),
      );
}

/// Cartaz e trailer deslizam em sequencia, sem esticar as imagens.
class PreviaCine extends StatefulWidget {
  const PreviaCine(
      {super.key,
      required this.titulo,
      required this.aberta,
      this.tocar = false,
      this.onVideo,
      this.onAberta});
  final TituloCine titulo;
  final bool aberta;
  final bool tocar;
  final ValueChanged<bool>? onVideo;
  final VoidCallback? onAberta;

  static const double escalaCartoes = 1.2;
  static const double alturaCartoes = 309 * escalaCartoes;
  static const Size tamanhoCartaz = Size(206 * escalaCartoes, alturaCartoes);
  static const Size tamanhoTrailer =
      Size(alturaCartoes * 16 / 9, alturaCartoes);
  static const double vao = 14;
  static const Duration duracao = Duration(milliseconds: 920);
  static const Duration recolhimento = Duration(milliseconds: 240);
  static final double espaco =
      tamanhoCartaz.width + tamanhoTrailer.width + 2 * vao;
  static double progressoCartaz(double t) =>
      Curves.easeOutCubic.transform((t * 2).clamp(0.0, 1.0));
  static double progressoTrailer(double t) =>
      Curves.easeOutCubic.transform((t * 2 - 1).clamp(0.0, 1.0));
  static double espacoEm(double t) =>
      (tamanhoCartaz.width + vao) * progressoCartaz(t) +
      (tamanhoTrailer.width + vao) * progressoTrailer(t);

  @override
  State<PreviaCine> createState() => _PreviaCineState();
}

class _PreviaCineState extends State<PreviaCine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: PreviaCine.duracao,
        reverseDuration: PreviaCine.recolhimento)
      ..addStatusListener((status) {
        if (status == AnimationStatus.completed) {
          setState(() {});
          widget.onAberta?.call();
        } else if (status == AnimationStatus.dismissed) {
          setState(() {});
        }
      });
    if (widget.aberta) _ctrl.forward();
  }

  @override
  void didUpdateWidget(PreviaCine antigo) {
    super.didUpdateWidget(antigo);
    if (widget.aberta != antigo.aberta) {
      if (widget.aberta) {
        _ctrl.forward(from: 0);
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Imagens fora do builder. Fechada, nao cria imagem nem player.
    if (!widget.aberta && _ctrl.isDismissed) return const SizedBox.shrink();
    final cartaz = _moldura(
      'previa-cartaz',
      PreviaCine.tamanhoCartaz,
      ArteCine(
        url: widget.titulo.arteFechada(tamanho: 'w342'),
        nome: widget.titulo.titulo,
        semente: widget.titulo.id,
        larguraCache: (PreviaCine.tamanhoCartaz.width * 2).round(),
      ),
    );
    final trailer = _moldura(
      'previa-trailer',
      PreviaCine.tamanhoTrailer,
      Stack(fit: StackFit.expand, children: [
        ArteCine(
          url: widget.titulo.arteLarga(tamanho: 'w780'),
          nome: widget.titulo.titulo,
          semente: widget.titulo.id,
          larguraCache: 780,
        ),
        if (widget.titulo.trailer != null && widget.aberta && _ctrl.isCompleted)
          TrailerCine(
            youtubeId: widget.titulo.trailer,
            tocar: widget.tocar,
            espera: Duration.zero,
            onTocando: widget.onVideo,
          ),
      ]),
    );
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) => SizedBox(
        width: PreviaCine.espacoEm(_ctrl.value),
        height: PreviaCine.tamanhoCartaz.height,
        child: ClipRect(
            child: Stack(children: [
          _slide(cartaz, PreviaCine.tamanhoCartaz,
              PreviaCine.progressoCartaz(_ctrl.value), 0),
          _slide(
              trailer,
              PreviaCine.tamanhoTrailer,
              PreviaCine.progressoTrailer(_ctrl.value),
              PreviaCine.tamanhoCartaz.width + PreviaCine.vao),
        ])),
      ),
    );
  }

  Widget _slide(Widget child, Size tamanho, double t, double esquerda) =>
      Positioned(
        left: esquerda,
        top: 0,
        width: tamanho.width + PreviaCine.vao,
        height: tamanho.height,
        child: ClipRect(
            child: Transform.translate(
          offset: Offset(-(tamanho.width + PreviaCine.vao) * (1 - t), 0),
          child: Padding(
            padding: const EdgeInsets.only(left: PreviaCine.vao),
            child: child,
          ),
        )),
      );

  Widget _moldura(String chave, Size tamanho, Widget child) => SizedBox(
        key: ValueKey(chave),
        width: tamanho.width,
        height: tamanho.height,
        child: ClipRRect(borderRadius: BorderRadius.circular(18), child: child),
      );
}
