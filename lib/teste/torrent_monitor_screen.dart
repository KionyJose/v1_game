import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import 'torrent_download_manager.dart';
import 'torrent_model.dart';

void _log(String message) {
  final time = DateTime.now().toIso8601String().substring(11, 19);
  debugPrint('[TorrentUI $time] $message');
}

class TorrentMonitorScreen extends StatefulWidget {
  const TorrentMonitorScreen({Key? key}) : super(key: key);

  @override
  State<TorrentMonitorScreen> createState() => _TorrentMonitorScreenState();
}

class _TorrentMonitorScreenState extends State<TorrentMonitorScreen> {
  final TorrentDownloadManager _manager = TorrentDownloadManager();
  final TextEditingController _magnetController = TextEditingController();

  @override
  void dispose() {
    _magnetController.dispose();
    _manager.dispose();
    super.dispose();
  }

  Future<void> _pickTorrentFile() async {
    _log('Clique: botao Selecionar .torrent');
    if (Platform.isAndroid || Platform.isIOS) {
      final status = await Permission.storage.request();
      if (status.isDenied && !await Permission.manageExternalStorage.request().isGranted) {
        _log('ERRO: permissao de armazenamento negada pelo usuario.');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permissao de armazenamento negada.')),
          );
        }
        return;
      }
    }

    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['torrent'],
    );

    if (result == null || result.files.single.path == null) {
      _log('Selecao de arquivo cancelada pelo usuario.');
      return;
    }

    _log('Arquivo selecionado: ${result.files.single.path}');
    await _manager.initTask(result.files.single.path!);
  }

  Future<void> _startMagnet() async {
    _log('Clique: botao baixar magnet');
    final magnet = _magnetController.text.trim();
    if (magnet.isEmpty) {
      _log('Magnet ignorado: campo vazio.');
      return;
    }
    await _manager.initMagnet(magnet);
  }

  String _statusLabel(TorrentStatus status) {
    switch (status) {
      case TorrentStatus.idle:
        return 'OCIOSO';
      case TorrentStatus.parsing:
        return 'PREPARANDO';
      case TorrentStatus.downloading:
        return 'BAIXANDO';
      case TorrentStatus.paused:
        return 'PAUSADO';
      case TorrentStatus.checkingIntegrity:
        return 'VERIFICANDO INTEGRIDADE';
      case TorrentStatus.completed:
        return 'CONCLUIDO';
      case TorrentStatus.error:
        return 'ERRO';
    }
  }

  String _formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    var value = bytes.toDouble();
    var i = 0;
    while (value >= 1024 && i < suffixes.length - 1) {
      value /= 1024;
      i++;
    }
    return '${value.toStringAsFixed(2)} ${suffixes[i]}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Downloader Torrent'),
        centerTitle: true,
      ),
      body: StreamBuilder<TorrentModel>(
        stream: _manager.onProgressChanged,
        initialData: _manager.currentState,
        builder: (context, snapshot) {
          final torrent = snapshot.data ?? TorrentModel.initial();

          return Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    ElevatedButton.icon(
                      onPressed: _pickTorrentFile,
                      icon: const Icon(Icons.file_open),
                      label: const Text('Selecionar .torrent'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 16,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: 520,
                      child: TextField(
                        controller: _magnetController,
                        minLines: 1,
                        maxLines: 2,
                        decoration: InputDecoration(
                          hintText: 'magnet:?xt=urn:btih:...',
                          suffixIcon: IconButton(
                            onPressed: _startMagnet,
                            icon: const Icon(Icons.play_arrow),
                            tooltip: 'Baixar magnet',
                          ),
                          border: const OutlineInputBorder(),
                          isDense: true,
                        ),
                        onSubmitted: (_) => _startMagnet(),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Card(
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          torrent.name,
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (torrent.saveDirectory.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            'Destino: ${torrent.saveDirectory}',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        const SizedBox(height: 16),
                        LinearProgressIndicator(
                          value: torrent.progress,
                          minHeight: 12,
                          borderRadius: BorderRadius.circular(6),
                          backgroundColor: Colors.grey[800],
                          valueColor: AlwaysStoppedAnimation<Color>(
                            torrent.status == TorrentStatus.completed
                                ? Colors.green
                                : Colors.blue,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              '${(torrent.progress * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            Text(
                              '${_formatBytes(torrent.downloadedBytes)} / ${_formatBytes(torrent.totalBytes)}',
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                        const Divider(height: 32),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _InfoColumn(
                              icon: Icons.downloading,
                              color: Colors.blue,
                              label: '${torrent.downloadSpeed.toStringAsFixed(1)} KB/s',
                            ),
                            _InfoColumn(
                              icon: Icons.group,
                              color: Colors.orange,
                              label: '${torrent.peersCount} peers',
                            ),
                            _InfoColumn(
                              icon: Icons.info_outline,
                              color: Colors.purple,
                              label: _statusLabel(torrent.status),
                            ),
                          ],
                        ),
                        if (torrent.status == TorrentStatus.checkingIntegrity) ...[
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              const Icon(Icons.hourglass_top, color: Colors.amber, size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Sem progresso ha 10 minutos. Verificando integridade do '
                                  'arquivo por mais alguns minutos antes de desistir...',
                                  style: TextStyle(color: Colors.amber[300]),
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (torrent.errorMessage != null) ...[
                          const SizedBox(height: 16),
                          Text(
                            torrent.errorMessage!,
                            style: const TextStyle(color: Colors.redAccent),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    FloatingActionButton.extended(
                      heroTag: 'btnStart',
                      onPressed: torrent.status == TorrentStatus.downloading
                          ? null
                          : () => _manager.start(),
                      backgroundColor: Colors.green,
                      icon: const Icon(Icons.play_arrow),
                      label: const Text('Iniciar'),
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton.extended(
                      heroTag: 'btnPause',
                      onPressed: torrent.status == TorrentStatus.downloading
                          ? () => _manager.pause()
                          : null,
                      backgroundColor: Colors.amber,
                      icon: const Icon(Icons.pause),
                      label: const Text('Pausar'),
                    ),
                    const SizedBox(width: 16),
                    FloatingActionButton.extended(
                      heroTag: 'btnStop',
                      onPressed: () => _manager.stop(),
                      backgroundColor: Colors.red,
                      icon: const Icon(Icons.stop),
                      label: const Text('Parar'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;

  const _InfoColumn({
    required this.icon,
    required this.color,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
