// Trailer tocando atrás do destaque.
//
// Começa só depois de uma espera: quem passa correndo pelo mosaico não
// deve derrubar a rede abrindo um vídeo por título. Enquanto o stream não
// resolve, a arte fixa continua na tela e o vídeo entra por cima, em fusão.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:youtube_explode_dart/youtube_explode_dart.dart' hide Video;

/// Volume compartilhado pelos trailers da aba, incluindo as prévias.
class VolumeTrailerCine extends ValueNotifier<double> {
  VolumeTrailerCine() : super(100);

  Timer? _intervalo;
  int? _direcao;

  /// Aceita gatilhos PlayStation e Xbox, digitais ou com intensidade.
  /// Zero é soltura/zona morta; nulo não é um comando de volume.
  static int? passoDoGatilho(String evento) {
    final partes = evento.toUpperCase().split('-');
    final passo = switch (partes.first) {
      'R2' || 'RT' => 1,
      'L2' || 'LT' => -1,
      _ => null,
    };
    if (passo == null || partes.length > 2) return null;
    if (partes.length == 1) return passo;
    final forca = double.tryParse(partes.last);
    if (forca == null || !forca.isFinite) return null;
    final limiar = forca <= 1 ? .12 : 30;
    return forca > limiar ? passo : 0;
  }

  void ajustar(int passo) {
    if (passo == 0) {
      _intervalo?.cancel();
      return;
    }
    if (_intervalo?.isActive == true && _direcao == passo) return;
    _direcao = passo;
    value = (value + passo * 5).clamp(0.0, 100.0);
    _intervalo?.cancel();
    _intervalo = Timer(const Duration(milliseconds: 120), () {});
  }

  @override
  void dispose() {
    _intervalo?.cancel();
    super.dispose();
  }
}

class EscopoVolumeTrailer extends InheritedNotifier<VolumeTrailerCine> {
  const EscopoVolumeTrailer({
    super.key,
    required VolumeTrailerCine volume,
    required super.child,
  }) : super(notifier: volume);

  static VolumeTrailerCine? of(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<EscopoVolumeTrailer>()
      ?.notifier;
}

/// Alça do player, para quem está de fora: posição, duração, pausa e salto.
///
/// Existe porque a ficha precisa comandar um vídeo que ela não criou — e
/// porque a barra de progresso tem que se redesenhar sozinha, sem arrastar a
/// ficha inteira junto a cada quadro do vídeo.
class ControleTrailer extends ChangeNotifier {
  Player? _player;
  StreamSubscription<Duration>? _posicao;
  StreamSubscription<Duration>? _duracao;
  StreamSubscription<bool>? _tocandoAgora;

  Duration posicao = Duration.zero;
  Duration duracao = Duration.zero;
  bool pausado = false;
  bool pronto = false;

  void _anexar(Player player) {
    _soltar();
    _player = player;
    pronto = true;
    pausado = false;
    _posicao = player.stream.position.listen((valor) {
      posicao = valor;
      notifyListeners();
    });
    _duracao = player.stream.duration.listen((valor) {
      duracao = valor;
      notifyListeners();
    });
    _tocandoAgora = player.stream.playing.listen((valor) {
      pausado = !valor;
      notifyListeners();
    });
    notifyListeners();
  }

  void _soltar() {
    _posicao?.cancel();
    _duracao?.cancel();
    _tocandoAgora?.cancel();
    _posicao = null;
    _duracao = null;
    _tocandoAgora = null;
    _player = null;
    pronto = false;
    posicao = Duration.zero;
    duracao = Duration.zero;
    pausado = false;
  }

  void alternarPausa() => _player?.playOrPause();

  /// Salta [passo] para frente ou para trás, sem passar das pontas.
  void pular(Duration passo) {
    final player = _player;
    if (player == null) return;
    final alvo = posicao + passo;
    player.seek(alvo.isNegative
        ? Duration.zero
        : (duracao > Duration.zero && alvo > duracao ? duracao : alvo));
  }

  @override
  void dispose() {
    _soltar();
    super.dispose();
  }
}

class TrailerCine extends StatefulWidget {
  const TrailerCine({
    super.key,
    required this.youtubeId,
    this.tocar = true,
    this.mudo = false,
    this.espera = const Duration(milliseconds: 1400),
    this.onTocando,
    this.controle,
  });

  /// Nulo enquanto a ficha não foi detalhada, ou quando o título não tem
  /// vídeo: o widget simplesmente não desenha nada.
  final String? youtubeId;

  /// Falso quando a aba saiu de vista — o player para e solta a rede.
  final bool tocar;

  final bool mudo;
  final Duration espera;

  /// Avisa quando o vídeo entra e quando sai do ar. É o gatilho do
  /// desaparecimento das escritas que ficam por cima dele — texto só some
  /// quando existe imagem em movimento embaixo, nunca por tempo adivinhado.
  final ValueChanged<bool>? onTocando;

  /// Alça para quem precisa pausar, saltar ou mostrar o progresso.
  final ControleTrailer? controle;

  @override
  State<TrailerCine> createState() => _TrailerCineState();
}

class _TrailerCineState extends State<TrailerCine> {
  final _youtube = YoutubeExplode();
  Player? _player;
  VideoController? _video;
  String? _carregado;
  Timer? _agendado;
  bool _pronto = false;
  bool _morto = false;
  VolumeTrailerCine? _volume;

  double get _volumeAtual => widget.mudo ? 0 : (_volume?.value ?? 100);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _volume = EscopoVolumeTrailer.of(context);
    _player?.setVolume(_volumeAtual);
  }

  @override
  void initState() {
    super.initState();
    _agendar();
  }

  @override
  void didUpdateWidget(TrailerCine antigo) {
    super.didUpdateWidget(antigo);
    if (widget.youtubeId != antigo.youtubeId || widget.tocar != antigo.tocar) {
      _agendar();
    }
    if (widget.mudo != antigo.mudo) {
      _player?.setVolume(_volumeAtual);
    }
  }

  void _agendar() {
    _agendado?.cancel();
    final id = widget.youtubeId;
    if (!widget.tocar || id == null || id.isEmpty) {
      _parar();
      return;
    }
    if (id == _carregado) {
      _player?.play();
      return;
    }
    _parar();
    _agendado = Timer(widget.espera, () => _abrir(id));
  }

  Future<void> _abrir(String id) async {
    try {
      final manifesto = await _youtube.videos.streamsClient
          .getManifest(id)
          .timeout(const Duration(seconds: 20));
      if (_morto || !mounted || widget.youtubeId != id || !widget.tocar) return;
      if (manifesto.muxed.isEmpty) return;
      final player = Player();
      final video = VideoController(player);
      await player.setVolume(_volumeAtual);
      await player.setPlaylistMode(PlaylistMode.loop);
      await player
          .open(Media(manifesto.muxed.bestQuality.url.toString()))
          .timeout(const Duration(seconds: 20));
      if (_morto || !mounted || widget.youtubeId != id || !widget.tocar) {
        await player.dispose();
        return;
      }
      // O gatilho pode ter mudado o volume enquanto o stream carregava.
      await player.setVolume(_volumeAtual);
      if (_morto || !mounted || widget.youtubeId != id || !widget.tocar) {
        await player.dispose();
        return;
      }
      setState(() {
        _player = player;
        _video = video;
        _carregado = id;
        _pronto = true;
      });
      widget.controle?._anexar(player);
      widget.onTocando?.call(true);
    } catch (_) {
      // Sem trailer tocável a arte fixa continua valendo; nada a avisar.
    }
  }

  void _parar() {
    final player = _player;
    // Nada montado ainda (primeira chamada, vinda do initState) não redesenha:
    // setState antes do primeiro quadro é erro.
    final desmontou = player != null || _pronto;
    _player = null;
    _video = null;
    _carregado = null;
    _pronto = false;
    widget.controle?._soltar();
    player?.dispose();
    if (!desmontou) return;
    widget.onTocando?.call(false);
    if (mounted && !_morto) setState(() {});
  }

  @override
  void dispose() {
    _morto = true;
    widget.controle?._soltar();
    if (_pronto) widget.onTocando?.call(false);
    _agendado?.cancel();
    _youtube.close();
    _player?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final video = _video;
    return AnimatedOpacity(
      opacity: _pronto && video != null ? 1 : 0,
      duration: const Duration(milliseconds: 900),
      child: video == null
          ? const SizedBox.expand()
          : ExcludeFocus(
              child: IgnorePointer(
                child: Video(
                  controller: video,
                  controls: NoVideoControls,
                  fit: BoxFit.cover,
                  fill: Colors.transparent,
                ),
              ),
            ),
    );
  }
}
