import '../scraps/jogo_detalhes.dart';

class ProgressoTorrent {
  final String mensagem;
  final double? fracao;
  const ProgressoTorrent(this.mensagem, {this.fracao});
}

abstract class TorrentDownloader {
  Future<String> baixar(
      EtapaDownload etapa, void Function(ProgressoTorrent) progresso);
  void cancelar();
}
