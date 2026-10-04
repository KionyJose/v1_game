import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:path/path.dart' as p;
import '../../Downloads/downloads_controller.dart';
import '../../Downloads/downloads_tela.dart';
import 'downloads/edge_torrent_downloader.dart';
import 'downloads/torrent_download.dart';
import 'componentes/galeria_jogo.dart';
import 'componentes/imagem_jogo.dart';
import 'componentes/trailer_player.dart';
import 'scraps/catalogo_scraper.dart';
import 'scraps/gamestorrents_detalhes_scraper.dart';
import 'scraps/gamestorrents_download_scraper.dart';
import 'scraps/jogo_detalhes.dart';

class DetalhesJogoTela extends StatefulWidget {
  final JogoCatalogo jogo;
  final DetalhesScraper? scraper;
  final DownloadScraper? downloadScraper;
  final TorrentDownloader? downloader;
  final Future<void> Function(String, VersaoJogo, JogoCatalogo)?
      onTorrentRecebido;
  const DetalhesJogoTela(
      {super.key,
      required this.jogo,
      this.scraper,
      this.downloadScraper,
      this.downloader,
      this.onTorrentRecebido});
  @override
  State<DetalhesJogoTela> createState() => _DetalhesJogoTelaState();
}

class _DetalhesJogoTelaState extends State<DetalhesJogoTela> {
  late final DetalhesScraper _scraper;
  late final DownloadScraper _download;
  late final TorrentDownloader _downloader;
  late Future<JogoDetalhes> _detalhes;
  int _versao = 0;
  bool _consultando = false;
  bool _cancelamentoSolicitado = false;
  String? _erroDownload;
  String? _arquivoSalvo;
  ProgressoTorrent? _progresso;

  @override
  void initState() {
    super.initState();
    _scraper = widget.scraper ?? GamesTorrentsDetalhesScraper();
    _download = widget.downloadScraper ?? GamesTorrentsDownloadScraper();
    _downloader = widget.downloader ?? EdgeTorrentDownloader();
    _detalhes = _scraper.carregar(widget.jogo.pagina);
  }

  @override
  void dispose() {
    _scraper.dispose();
    _download.dispose();
    _downloader.cancelar();
    super.dispose();
  }

  void _atualizar() => setState(() {
        _versao = 0;
        _erroDownload = null;
        _detalhes = _scraper.carregar(widget.jogo.pagina);
      });

  Future<void> _comprar(VersaoJogo versao) async {
    setState(() {
      _consultando = true;
      _cancelamentoSolicitado = false;
      _erroDownload = null;
      _arquivoSalvo = null;
      _progresso = const ProgressoTorrent('Consultando a página de download…');
    });
    try {
      final etapa = await _download.consultar(versao.torrent);
      if (!mounted) return;
      if (_cancelamentoSolicitado) throw StateError('Download cancelado.');
      final arquivo = await _downloader.baixar(etapa, (progresso) {
        if (mounted) setState(() => _progresso = progresso);
      });
      if (mounted) setState(() => _arquivoSalvo = arquivo);
      if (widget.onTorrentRecebido != null) {
        await widget.onTorrentRecebido!(arquivo, versao, widget.jogo);
      } else {
        await DownloadsController.instance.registerPurchase(arquivo,
            sourceName: versao.fonte,
            edition: versao.titulo,
            pageUrl: widget.jogo.pagina.toString(),
            downloadUrl: versao.torrent.toString(),
            releaseInfo: versao.informacoes);
      }
      if (mounted) {
        setState(() {
          _arquivoSalvo = arquivo;
          _progresso = const ProgressoTorrent(
              'Arquivo .torrent baixado e confirmado.',
              fracao: 1);
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _erroDownload = e is ErroCatalogo
            ? e.mensagem
            : e is StateError
                ? e.message.toString()
                : 'Não foi possível consultar o download. Verifique sua conexão e tente novamente.');
      }
    } finally {
      if (mounted) {
        setState(() {
          _consultando = false;
          if (_erroDownload != null) _progresso = null;
        });
      }
    }
  }

  void _cancelarDownload() {
    _cancelamentoSolicitado = true;
    _downloader.cancelar();
    setState(() => _progresso = const ProgressoTorrent('Cancelando download…'));
  }

  Future<void> _abrirPasta() async {
    if (_arquivoSalvo == null) return;
    try {
      if (await launchUrl(Uri.directory(p.dirname(_arquivoSalvo!)),
          mode: LaunchMode.externalApplication)) {
        return;
      }
    } catch (_) {/* Exibe erro sem fechar a etapa. */}
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível abrir a pasta.')));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
      backgroundColor: const Color(0xFF10121B),
      appBar: AppBar(title: Text(widget.jogo.nome), actions: [
        IconButton(
            tooltip: 'Downloads',
            onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const DownloadsTela())),
            icon: const Icon(Icons.download_for_offline_outlined)),
        IconButton(
            tooltip: 'Atualizar detalhes',
            onPressed: _consultando ? null : _atualizar,
            icon: const Icon(Icons.refresh))
      ]),
      body: FutureBuilder<JogoDetalhes>(
          future: _detalhes,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CircularProgressIndicator());
            }
            if (snapshot.hasError || snapshot.data == null) {
              return Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(snapshot.error is ErroCatalogo
                            ? (snapshot.error as ErroCatalogo).mensagem
                            : 'Não foi possível carregar os detalhes. Verifique sua conexão.'),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: _atualizar,
                            child: const Text('Tentar novamente'))
                      ])));
            }
            final jogo = snapshot.data!;
            return SingleChildScrollView(
                child: Center(
                    child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1160),
                        child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                            child: SizedBox(
                                                width: 88,
                                                height: 118,
                                                child: ImagemJogo(
                                                    url: jogo.capa ??
                                                        widget.jogo.imagem))),
                                        const SizedBox(width: 18),
                                        Expanded(
                                            child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                              Text('PC • GAMESTORRENTS',
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .labelMedium
                                                      ?.copyWith(
                                                          color: const Color(
                                                              0xFFB6A8FF))),
                                              const SizedBox(height: 8),
                                              Text(jogo.nome,
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .headlineMedium),
                                              const SizedBox(height: 10),
                                              Wrap(
                                                  spacing: 6,
                                                  runSpacing: 6,
                                                  children: jogo.generos
                                                      .map((g) =>
                                                          Chip(label: Text(g)))
                                                      .toList()),
                                            ])),
                                      ]),
                                  const SizedBox(height: 28),
                                  Text('Imagens',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                  const SizedBox(height: 14),
                                  GaleriaJogo(
                                      key: ValueKey(jogo),
                                      imagens: jogo.imagens),
                                  const SizedBox(height: 28),
                                  Text('Trailers',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge),
                                  const SizedBox(height: 14),
                                  if (jogo.trailers.isEmpty)
                                    const Text(
                                        'Este jogo não tem trailers cadastrados.'),
                                  Wrap(
                                      spacing: 14,
                                      runSpacing: 14,
                                      children: jogo.trailers
                                          .map((trailer) => SizedBox(
                                              width: 300,
                                              child: Card(
                                                  clipBehavior: Clip.antiAlias,
                                                  child: InkWell(
                                                      onTap: () => showDialog<
                                                              void>(
                                                          context: context,
                                                          builder: (_) =>
                                                              TrailerPlayer(
                                                                  trailer:
                                                                      trailer)),
                                                      child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            AspectRatio(
                                                                aspectRatio:
                                                                    16 / 9,
                                                                child: Stack(
                                                                    fit: StackFit
                                                                        .expand,
                                                                    children: [
                                                                      ImagemJogo(
                                                                          url: trailer
                                                                              .miniatura),
                                                                      const Center(
                                                                          child: Icon(
                                                                              Icons.play_circle_fill,
                                                                              size: 58,
                                                                              color: Colors.white)),
                                                                    ])),
                                                            Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        14),
                                                                child: Text(
                                                                    trailer
                                                                        .titulo)),
                                                          ])))))
                                          .toList()),
                                  if (jogo.descricao.isNotEmpty) ...[
                                    const SizedBox(height: 28),
                                    Text('Sobre o jogo',
                                        style: Theme.of(context)
                                            .textTheme
                                            .titleLarge),
                                    const SizedBox(height: 12),
                                    Text(jogo.descricao,
                                        style: const TextStyle(height: 1.6)),
                                  ],
                                  const SizedBox(height: 28),
                                  Card(
                                      child: Padding(
                                          padding: const EdgeInsets.all(20),
                                          child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.stretch,
                                              children: [
                                                Text('Versão do jogo',
                                                    style: Theme.of(context)
                                                        .textTheme
                                                        .titleLarge),
                                                const SizedBox(height: 16),
                                                if (jogo.versoes.isEmpty)
                                                  const Text(
                                                      'Nenhum botão de torrent encontrado para este jogo.')
                                                else ...[
                                                  DropdownButtonFormField<int>(
                                                      initialValue: _versao,
                                                      isExpanded: true,
                                                      decoration: const InputDecoration(
                                                          border:
                                                              OutlineInputBorder(),
                                                          labelText:
                                                              'Selecionar versão'),
                                                      items: List.generate(
                                                          jogo.versoes.length,
                                                          (i) => DropdownMenuItem(
                                                              value: i,
                                                              child: Text(
                                                                  jogo
                                                                      .versoes[
                                                                          i]
                                                                      .titulo,
                                                                  maxLines: 1,
                                                                  overflow:
                                                                      TextOverflow
                                                                          .ellipsis))),
                                                      onChanged: _consultando
                                                          ? null
                                                          : (i) => setState(() {
                                                                _versao = i!;
                                                                _erroDownload =
                                                                    null;
                                                              })),
                                                  const SizedBox(height: 14),
                                                  Text(jogo
                                                      .versoes[_versao].fonte),
                                                  ...jogo.versoes[_versao]
                                                      .informacoes.entries
                                                      .map((e) => Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(top: 6),
                                                          child: Text(
                                                              '${e.key}: ${e.value}'))),
                                                  const SizedBox(height: 20),
                                                  FilledButton.icon(
                                                      onPressed: _consultando
                                                          ? null
                                                          : () => _comprar(
                                                              jogo.versoes[
                                                                  _versao]),
                                                      icon: _consultando
                                                          ? const SizedBox(
                                                              width: 18,
                                                              height: 18,
                                                              child:
                                                                  CircularProgressIndicator(
                                                                      strokeWidth:
                                                                          2))
                                                          : const Icon(
                                                              Icons.download),
                                                      label: Text(_consultando
                                                          ? 'Baixando torrent…'
                                                          : 'Comprar')),
                                                  const SizedBox(height: 10),
                                                  const Text(
                                                      'Salva o .torrent em Downloads/games torrent compra. Não realiza pagamento.',
                                                      textAlign:
                                                          TextAlign.center),
                                                  if (_progresso != null) ...[
                                                    const SizedBox(height: 12),
                                                    Text(_progresso!.mensagem),
                                                    if (_consultando) ...[
                                                      const SizedBox(height: 8),
                                                      LinearProgressIndicator(
                                                          value: _progresso!
                                                              .fracao),
                                                      TextButton(
                                                          onPressed:
                                                              _cancelarDownload,
                                                          child: const Text(
                                                              'Cancelar download')),
                                                    ],
                                                  ],
                                                  if (_arquivoSalvo !=
                                                      null) ...[
                                                    const SizedBox(height: 8),
                                                    SelectableText(
                                                        _arquivoSalvo!),
                                                    TextButton.icon(
                                                        onPressed: _abrirPasta,
                                                        icon: const Icon(
                                                            Icons.folder_open),
                                                        label: const Text(
                                                            'Abrir pasta')),
                                                  ],
                                                  if (_erroDownload != null)
                                                    Padding(
                                                        padding:
                                                            const EdgeInsets
                                                                .only(top: 12),
                                                        child: Text(
                                                            _erroDownload!,
                                                            style: TextStyle(
                                                                color: Theme.of(
                                                                        context)
                                                                    .colorScheme
                                                                    .error))),
                                                ],
                                              ]))),
                                ])))));
          }));
}
