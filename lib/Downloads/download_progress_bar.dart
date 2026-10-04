import 'package:flutter/material.dart';
import 'download_record.dart';

class DownloadProgressBar extends StatelessWidget {
  final DownloadRecord item;
  final Color color;
  const DownloadProgressBar(
      {super.key, required this.item, required this.color});

  @override
  Widget build(BuildContext context) {
    final waiting = item.waitingForData && item.state != DownloadState.queued;
    final loadingColor =
        item.checkingFinalData ? const Color(0xFF74D8DC) : color;
    final remaining = item.analysisRemaining;
    final time = '${remaining.inMinutes.toString().padLeft(2, '0')}:'
        '${(remaining.inSeconds % 60).toString().padLeft(2, '0')}';
    final label = waiting
        ? '${item.checkingFinalData ? 'Verificando dados finais' : 'Analisando torrent'} • $time'
        : item.state == DownloadState.queued
            ? 'Na fila'
            : '${(item.progress * 100).toStringAsFixed(1)}%';
    return Semantics(
      label: 'Progresso do download',
      value: label,
      child: SizedBox(
        height: 52,
        child: Stack(alignment: Alignment.center, children: [
          Positioned.fill(
              child: LinearProgressIndicator(
            value: waiting ? null : item.progress,
            borderRadius: BorderRadius.circular(12),
            color: (waiting ? loadingColor : color).withValues(alpha: 0.48),
            backgroundColor: Color.alphaBlend(
                (waiting ? loadingColor : color).withValues(alpha: 0.10),
                const Color(0xFF242424)),
          )),
          Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                      shadows: [
                        Shadow(color: Colors.black54, blurRadius: 4)
                      ]))),
        ]),
      ),
    );
  }
}
