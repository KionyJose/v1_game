import 'package:flutter_test/flutter_test.dart';
import 'package:v1_game/Tela/Tela%20loja/downloads/embedded_torrent_downloader.dart';

void main() {
  const host = 'www.gamestorrents.app';

  test('a mesma lista em outra ordem gera o mesmo argumento', () {
    // Foi exatamente isto que quebrou na máquina do cliente: a Cloudflare
    // devolve os dois endereços alternando a ordem, o argumento mudava entre
    // uma compra e outra e a segunda morria em ERROR_INVALID_STATE.
    const a = ['104.21.63.94', '172.67.145.29'];
    const b = ['172.67.145.29', '104.21.63.94'];
    expect(EmbeddedTorrentDownloader.mapeamentoDeHost(host, a),
        EmbeddedTorrentDownloader.mapeamentoDeHost(host, b));
  });

  test('o argumento tem a forma que o Chromium espera', () {
    expect(
        EmbeddedTorrentDownloader.mapeamentoDeHost(host, ['1.2.3.4']),
        '--host-resolver-rules="MAP $host 1.2.3.4"');
  });

  test('sem endereço não há argumento', () {
    expect(EmbeddedTorrentDownloader.mapeamentoDeHost(host, const []), isNull);
  });

  test('repetir a chamada não muda o resultado', () {
    const ips = ['9.9.9.9', '1.1.1.1', '5.5.5.5'];
    final primeiro = EmbeddedTorrentDownloader.mapeamentoDeHost(host, ips);
    for (var i = 0; i < 5; i++) {
      expect(EmbeddedTorrentDownloader.mapeamentoDeHost(host, ips), primeiro);
    }
    // Ordena como texto, então o menor vem primeiro de forma previsível.
    expect(primeiro, contains('1.1.1.1'));
  });

  test('a lista recebida não é modificada', () {
    final ips = ['9.9.9.9', '1.1.1.1'];
    EmbeddedTorrentDownloader.mapeamentoDeHost(host, ips);
    expect(ips, ['9.9.9.9', '1.1.1.1']);
  });
}
