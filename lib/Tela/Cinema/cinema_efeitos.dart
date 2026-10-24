// Peças visuais reaproveitadas pelo mosaico de cinema: arte,
// brilho, inclinação, reflexo, virada e entrada.
//
// Tudo aqui é desenho puro — nenhuma peça conhece catálogo, foco ou Pad.

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

/// Paleta e tipografia da aba.
class Cine {
  Cine._();

  static const String fonte = 'Oxanium';
  static const Color fundo = Color(0xFF06060B);
  static const Color tinta = Color(0xFFF2EEFF);
  static const Color tintaFraca = Color(0x99F2EEFF);
  static const Color realce = Color(0xFFB6A8FF);

  /// Cor própria de cada título, estável entre sessões. Não existe paleta
  /// vinda da API e amostrar a capa custaria uma decodificação por cartão —
  /// o id dá uma cor consistente de graça.
  static Color cor(int id) {
    final matiz = (id * 47.0) % 360;
    return HSLColor.fromAHSL(1, matiz, .62, .62).toColor();
  }

  /// Título grande: entrelinha curta e letra levemente fechada, o desenho que
  /// cartaz de cinema usa.
  static TextStyle titulo(double tamanho, {Color? cor, FontWeight? peso}) =>
      TextStyle(
        fontFamily: fonte,
        fontSize: tamanho,
        height: 1.02,
        letterSpacing: -tamanho * .022,
        fontWeight: peso ?? FontWeight.w800,
        color: cor ?? tinta,
      );

  /// Rótulo pequeno em caixa alta, para metadados.
  static TextStyle etiqueta(double tamanho, {Color? cor}) => TextStyle(
        fontFamily: fonte,
        fontSize: tamanho,
        height: 1.1,
        letterSpacing: tamanho * .18,
        fontWeight: FontWeight.w600,
        color: cor ?? tintaFraca,
      );

  static TextStyle corpo(double tamanho, {Color? cor}) => TextStyle(
        fontFamily: fonte,
        fontSize: tamanho,
        height: 1.42,
        fontWeight: FontWeight.w400,
        color: cor ?? tintaFraca,
      );

  /// Sombra de texto sobre imagem. Substitui a caixa escura atrás da legenda:
  /// o texto fica legível sem cortar a arte.
  static List<Shadow> get sombraTexto => const [
        Shadow(blurRadius: 18, color: Color(0xCC000000)),
        Shadow(blurRadius: 42, color: Color(0x99000000)),
      ];
}

/// O espaço da marca fica reservado; só a imagem pronta aparece, em fade.
class LogoDestaqueCine extends StatelessWidget {
  const LogoDestaqueCine({super.key, required this.url});

  final String? url;

  @override
  Widget build(BuildContext context) => SizedBox(
        width: 560,
        height: 132,
        child: url == null
            ? null
            : Image.network(
                url!,
                key: ValueKey(url),
                fit: BoxFit.contain,
                alignment: Alignment.centerLeft,
                errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                frameBuilder: (_, child, frame, __) =>
                    TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: frame == null ? 0 : 1),
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  builder: (_, t, imagem) => Opacity(opacity: t, child: imagem),
                  child: child,
                ),
              ),
      );
}

/// Arte estática de um título, com reserva generativa.
///
/// Quando não há imagem — catálogo de demonstração, ou título sem capa — o
/// lugar não fica vazio nem mostra ícone de erro: desenha um gradiente
/// próprio daquele título com a inicial em marca d'água. É parte do visual,
/// não um remendo.
class ArteCine extends StatelessWidget {
  const ArteCine({
    super.key,
    required this.url,
    required this.nome,
    required this.semente,
    this.zoom = 1,
    this.alinhamento = Alignment.center,
    this.escuro = 0,
    this.desfoque = 0,
    this.larguraCache,
  });

  final String? url;
  final String nome;

  /// Id do título: define a cor da arte de reserva.
  final int semente;

  final double zoom;
  final Alignment alinhamento;

  /// 0 a 1: escurece a arte por baixo do texto.
  final double escuro;

  /// Desfoque aplicado à própria imagem. Vale para o fundo da tela: custa
  /// uma vez, enquanto um `BackdropFilter` de tela cheia custaria a cada
  /// quadro e ainda borraria o que estivesse por cima.
  final double desfoque;

  /// Teto de decodificação, em pixels. Uma capa de 780 px desenhada num
  /// cartaz de 206 px desperdiça memória e tempo de GPU; o número vem do
  /// tamanho real do ladrilho.
  final int? larguraCache;

  @override
  Widget build(BuildContext context) {
    Widget imagem = url == null || url!.isEmpty
        ? _reserva()
        : CachedNetworkImage(
            imageUrl: url!,
            fit: BoxFit.cover,
            alignment: alinhamento,
            memCacheWidth: larguraCache,
            fadeInDuration: const Duration(milliseconds: 260),
            placeholder: (_, __) => _reserva(vazio: true),
            errorWidget: (_, __, ___) => _reserva(),
          );
    if (desfoque > 0) {
      imagem = ImageFiltered(
        imageFilter: ui.ImageFilter.blur(sigmaX: desfoque, sigmaY: desfoque),
        child: imagem,
      );
    }

    return ClipRect(
      child: Stack(fit: StackFit.expand, children: [
        Transform.scale(scale: zoom, child: imagem),
        if (escuro > 0)
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  Colors.black.withValues(alpha: .92 * escuro),
                  Colors.black.withValues(alpha: .35 * escuro),
                  Colors.transparent,
                ],
                stops: const [0, .55, 1],
              ),
            ),
          ),
      ]),
    );
  }

  Widget _reserva({bool vazio = false}) {
    final cor = Cine.cor(semente);
    final inicial = nome.trim().isEmpty ? '?' : nome.trim()[0].toUpperCase();
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.lerp(cor, Colors.black, .35)!,
            Color.lerp(cor, const Color(0xFF07070C), .86)!,
          ],
        ),
      ),
      child: vazio
          ? const SizedBox.expand()
          : Stack(fit: StackFit.expand, children: [
              Align(
                alignment: const Alignment(.45, .35),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Text(
                    inicial,
                    style: TextStyle(
                      fontFamily: Cine.fonte,
                      fontWeight: FontWeight.w900,
                      color: Colors.white.withValues(alpha: .10),
                    ),
                  ),
                ),
              ),
              CustomPaint(painter: _RiscosPainter(cor)),
            ]),
    );
  }
}

/// Riscos diagonais finos da arte de reserva: dão textura sem imagem.
class _RiscosPainter extends CustomPainter {
  _RiscosPainter(this.cor);
  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final tinta = Paint()
      ..color = cor.withValues(alpha: .10)
      ..strokeWidth = 1.2;
    for (var x = -size.height; x < size.width; x += 14) {
      canvas.drawLine(
          Offset(x, size.height), Offset(x + size.height, 0), tinta);
    }
  }

  @override
  bool shouldRepaint(_RiscosPainter antigo) => antigo.cor != cor;
}

/// Varredura de luz que atravessa o ladrilho enquanto ele está selecionado.
class BrilhoVarrido extends StatefulWidget {
  const BrilhoVarrido({
    super.key,
    required this.ativo,
    required this.child,
    this.cor = Colors.white,
  });

  final bool ativo;
  final Widget child;
  final Color cor;

  @override
  State<BrilhoVarrido> createState() => _BrilhoVarridoState();
}

class _BrilhoVarridoState extends State<BrilhoVarrido>
    with SingleTickerProviderStateMixin {
  /// Nasce nulo e só é criado quando o ladrilho acende: uma faixa tem vinte
  /// cartões e a tela tem seis faixas — manter um Ticker parado em cada um
  /// seria mais de cem animações alocadas para iluminar uma.
  AnimationController? _ctrl;

  @override
  void initState() {
    super.initState();
    if (widget.ativo) _acender();
  }

  void _acender() {
    _ctrl ??= AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _ctrl!.repeat();
  }

  @override
  void didUpdateWidget(BrilhoVarrido antigo) {
    super.didUpdateWidget(antigo);
    if (widget.ativo == antigo.ativo) return;
    if (widget.ativo) {
      _acender();
    } else {
      _ctrl?.stop();
    }
  }

  @override
  void dispose() {
    _ctrl?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ctrl = _ctrl;
    if (!widget.ativo || ctrl == null) return widget.child;
    return Stack(fit: StackFit.passthrough, children: [
      // A arte fica na sua própria camada: sem isto, cada quadro da
      // varredura mandaria o cartão inteiro — imagem, texto e sombras — ser
      // repintado junto.
      RepaintBoundary(child: widget.child),
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: _VarreduraPainter(ctrl, widget.cor),
          ),
        ),
      ),
    ]);
  }
}

/// A distância é calculada pela projeção de todos os cantos do cartão.
/// Assim a faixa de luz sai inteira, inclusive em cartazes altos.
class _VarreduraPainter extends CustomPainter {
  _VarreduraPainter(this.animacao, this.cor) : super(repaint: animacao);

  final Animation<double> animacao;
  final Color cor;

  @override
  void paint(Canvas canvas, Size size) {
    final t = (animacao.value * 3).clamp(0.0, 1.0);
    if (t == 0 || t == 1 || size.isEmpty) return;
    final direcao = Offset(math.cos(math.pi / 9), math.sin(math.pi / 9));
    final alcance = size.width * direcao.dx + size.height * direcao.dy;
    final faixa = size.shortestSide * .55;
    final centro = -faixa / 2 + (alcance + faixa) * t;
    final tinta = Paint()
      ..shader = ui.Gradient.linear(
        direcao * (centro - faixa / 2),
        direcao * (centro + faixa / 2),
        [Colors.transparent, cor.withValues(alpha: .22), Colors.transparent],
        [0, .5, 1],
      );
    canvas.drawRect(Offset.zero & size, tinta);
  }

  @override
  bool shouldRepaint(_VarreduraPainter antigo) =>
      antigo.animacao != animacao || antigo.cor != cor;
}

/// Realce do ladrilho selecionado: borda e brilho, sem escala ou elevação.
/// A sombra mantém o deslocamento fixo durante todo o ciclo.
class RealceCine extends StatelessWidget {
  const RealceCine({
    super.key,
    required this.selecionado,
    required this.child,
    this.cor = Cine.realce,
    this.raio = 22,
  });

  final bool selecionado;
  final Widget child;
  final Color cor;
  final double raio;

  @override
  Widget build(BuildContext context) => TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: selecionado ? 1 : 0),
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOutCubic,
        // Sem Transform.scale: crescer a partir do centro já empurrava a
        // borda de cima pra cima — pouco, mas pedido repetidas vezes pra
        // sumir de vez. O realce agora é só borda e brilho, do tamanho que
        // o cartão sempre teve; nada se move.
        builder: (_, t, filho) => DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(raio),
            boxShadow: [
              // Sombra parada: ela não desce com o realce. Sombra que
              // desce é a própria linguagem de "objeto subindo".
              BoxShadow(
                color: Colors.black.withValues(alpha: .55 * t + .25),
                blurRadius: 30 * t + 12,
                offset: const Offset(0, 6),
              ),
              // Raio contido de propósito: ele precisa caber na folga da
              // faixa (`MedidaCine.folga`), senão a lista corta o brilho
              // numa linha reta. Mudou um, revise o outro.
              if (t > 0)
                BoxShadow(
                  color: cor.withValues(alpha: .42 * t),
                  blurRadius: 34 * t,
                  spreadRadius: 1.5 * t,
                ),
            ],
          ),
          child: filho,
        ),
        child: child,
      );
}

/// Reflexo espelhado sob o ladrilho, desvanecendo — o chão de vidro das
/// faixas quadradas.
///
/// A cópia espelhada é **decoração**: sai da árvore de semântica e não
/// recebe toque. Sem o `ExcludeSemantics`, o mesmo cartão aparecia duas
/// vezes para o leitor de tela, dentro de uma transformação invertida, e a
/// compilação da semântica caía em `!semantics.parentDataDirty` ao rolar a
/// faixa.
///
/// O espelho é medido pela altura real do cartão ([alturaFilho]) e recortado
/// por um `ClipRect`. O `OverflowBox` recebe altura **exata**, e não
/// `double.infinity`: o filho precisa poder passar do recorte, mas restrição
/// infinita dentro de lista que rola é o que deixa `parentData` sujo.
class ReflexoCine extends StatelessWidget {
  const ReflexoCine({
    super.key,
    required this.child,
    required this.altura,
    required this.alturaFilho,
    required this.larguraFilho,
    this.opacidade = .30,
  });

  final Widget child;

  /// Altura do reflexo: quanto do espelho aparece antes de desaparecer.
  final double altura;

  /// Altura do próprio ladrilho, que o reflexo espelha.
  final double alturaFilho;

  /// Largura do ladrilho. Numa faixa que rola na horizontal não existe
  /// largura vinda de cima, e sem este número o espelho tentaria ser
  /// infinito.
  final double larguraFilho;

  final double opacidade;

  @override
  Widget build(BuildContext context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          child,
          SizedBox(
            width: larguraFilho,
            height: altura,
            child: ShaderMask(
              blendMode: BlendMode.dstIn,
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: opacidade),
                  Colors.transparent,
                ],
              ).createShader(rect),
              child: ClipRect(
                child: OverflowBox(
                  alignment: Alignment.topCenter,
                  minWidth: larguraFilho,
                  maxWidth: larguraFilho,
                  minHeight: alturaFilho,
                  maxHeight: alturaFilho,
                  child: Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..scaleByDouble(1, -1, 1, 1),
                    child: ExcludeSemantics(
                      child: IgnorePointer(child: child),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      );
}

/// Vira o cartão: frente é a capa, verso é a ficha curta.
///
/// Quando virar é decisão da tela, que conta o tempo parado e encadeia a
/// virada com o painel que desliza depois dela — por isso [espera] nasce
/// zerada: dois relógios para a mesma animação sairiam do passo.
///
/// [duracao] é lida pela tela para saber quando a virada terminou.
class ViradaCine extends StatefulWidget {
  const ViradaCine({
    super.key,
    required this.virado,
    required this.frente,
    required this.verso,
    this.espera = Duration.zero,
  });

  /// Quanto dura a virada. A tela agenda o passo seguinte por este valor.
  static const Duration duracao = Duration(milliseconds: 620);

  final bool virado;
  final Widget frente;
  final Widget verso;
  final Duration espera;

  @override
  State<ViradaCine> createState() => _ViradaCineState();
}

class _ViradaCineState extends State<ViradaCine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: ViradaCine.duracao,
        reverseDuration: const Duration(milliseconds: 260));
    if (widget.virado) _ctrl.value = 1;
  }

  @override
  void didUpdateWidget(ViradaCine antigo) {
    super.didUpdateWidget(antigo);
    if (widget.virado == antigo.virado) return;
    if (!widget.virado) {
      _ctrl.reverse();
      return;
    }
    if (widget.espera == Duration.zero) {
      _ctrl.forward();
      return;
    }
    Future.delayed(widget.espera, () {
      if (mounted && widget.virado) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final t = Curves.easeInOutCubic.transform(_ctrl.value);
          final angulo = t * math.pi;
          final mostrandoVerso = t > .5;
          return Transform(
            alignment: Alignment.center,
            // Giro ortográfico: a perspectiva aumentava a borda próxima
            // durante a rotação, dando a impressão de elevação.
            transform: Matrix4.identity()..rotateY(angulo),
            child: mostrandoVerso
                ? Transform(
                    alignment: Alignment.center,
                    transform: Matrix4.identity()..rotateY(math.pi),
                    child: widget.verso,
                  )
                : widget.frente,
          );
        },
      );
}

/// Entrada em cascata: cada ladrilho sobe e aparece um pouco depois do
/// anterior, para a faixa se montar em vez de piscar inteira.
class EntradaCine extends StatefulWidget {
  const EntradaCine({
    super.key,
    required this.indice,
    required this.child,
    this.deslocamento = 34,
  });

  final int indice;
  final Widget child;
  final double deslocamento;

  @override
  State<EntradaCine> createState() => _EntradaCineState();
}

class _EntradaCineState extends State<EntradaCine>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    // Atraso proporcional ao índice, com teto: a décima coluna não pode
    // esperar um segundo inteiro para existir.
    Future.delayed(
      Duration(milliseconds: math.min(widget.indice * 55, 420)),
      () {
        if (mounted) _ctrl.forward();
      },
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
        animation: _ctrl,
        child: widget.child,
        builder: (_, filho) {
          final t = Curves.easeOutCubic.transform(_ctrl.value);
          return Opacity(
            opacity: t,
            child: Transform.translate(
              offset: Offset(0, (1 - t) * widget.deslocamento),
              child: filho,
            ),
          );
        },
      );
}
