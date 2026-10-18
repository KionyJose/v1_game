import 'package:flutter_test/flutter_test.dart';
import 'package:v1_game/Downloads/repack_decoder_tuning.dart';

const _gigabyte = 1073741824;

/// O CLS.ini real do repack usa estas formas de orçamento.
const _config = '''
[Srep]
Bufsize=24m
Memory=60%-2048m
TempPath={app}

[Precomp]
Memory=128
TempPath={app}

[mtx]
Threads=100p
TmpPath={app}

[magic2l]
MaxMemoryUsage=75%-10m
ldmfMaxMemoryUsage=1024m
ldmfTempPath={app}
MaxThreadsUsage=100%
''';

void main() {
  test('reduz os orçamentos à memória livre e preserva o resto do CLS.ini',
      () {
    final tuned = tuneDecoderConfig(_config, r'D:\V1 Jogos\Jogo',
        memory: (total: 16 * _gigabyte, available: 2 * _gigabyte));
    // 70% de 2 GB = 1433 MB: só o que passava desse teto é reescrito.
    expect(tuned, contains('Memory=1433m'));
    expect(tuned, contains('MaxMemoryUsage=1433m'));
    expect(tuned, isNot(contains('75%')));
    expect(tuned, isNot(contains('60%')));
    // Abaixo do teto, thread e buffer continuam como o repack definiu.
    expect(tuned, contains('Memory=128'));
    expect(tuned, contains('ldmfMaxMemoryUsage=1024m'));
    expect(tuned, contains('Threads=100p'));
    expect(tuned, contains('MaxThreadsUsage=100%'));
    expect(tuned, contains('Bufsize=24m'));
    // O destino entra no lugar de {app}, inclusive nos caminhos de temporário.
    expect(tuned, contains(r'TempPath=D:\V1 Jogos\Jogo'));
    expect(tuned, contains(r'ldmfTempPath=D:\V1 Jogos\Jogo'));
    expect(tuned, isNot(contains('{app}')));
  });

  test('só mexe no orçamento que não cabe na folga da máquina', () {
    final tuned = tuneDecoderConfig(_config, r'D:\Jogo',
        memory: (total: 16 * _gigabyte, available: 15 * _gigabyte));
    // Com 15 GB livres o teto é 10752 MB: `75%-10m` pede 12278 MB e cai nele,
    // mas `60%-2048m` pede 8259 MB e segue como o repack escreveu.
    expect(tuned, contains('MaxMemoryUsage=10752m'));
    expect(tuned, contains('Memory=60%-2048m'));
    expect(tuned, contains('ldmfMaxMemoryUsage=1024m'));
    expect(tuned, contains('Memory=128'));
  });

  test('nunca desce abaixo do mínimo viável de 256 MB', () {
    expect(decoderMemoryBudget(64 * 1048576), 256 * 1048576);
    expect(decoderMemoryBudget(10 * _gigabyte), 10 * _gigabyte * 7 ~/ 10);
  });

  test('sem leitura de memória, apenas resolve {app}', () {
    final tuned = tuneDecoderConfig('Memory=75%-10m\nTempPath={app}\n', r'D:\Jogo',
        memory: (total: 0, available: 0));
    expect(tuned, 'Memory=75%-10m\nTempPath=D:\\Jogo\n');
  });

  test('preserva o fim de linha CRLF do arquivo original', () {
    final tuned = tuneDecoderConfig('[Srep]\r\nMemory=75%\r\n', r'D:\Jogo',
        memory: (total: 16 * _gigabyte, available: 1 * _gigabyte));
    expect(tuned, '[Srep]\r\nMemory=716m\r\n');
  });
}
