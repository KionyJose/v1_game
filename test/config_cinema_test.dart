import 'package:flutter_test/flutter_test.dart';
import 'package:v1_game/Modelos/configs_sistema.dart';

void main() {
  group('tipo da tela de cinema', () {
    test('nasce no catálogo', () {
      expect(ConfigSistema.defaults().cinemaCatalogo, isTrue);
    });

    test('vai e volta do arquivo', () {
      final config = ConfigSistema.defaults()..cinemaCatalogo = false;
      final lido = ConfigSistema.fromJson(config.toJson());
      expect(lido.cinemaCatalogo, isFalse);
    });

    test('config antiga, sem a chave gravada, cai no catálogo', () {
      // Quem já tinha o launcher instalado não perde a aba: o arquivo
      // anterior não traz este campo, e a ausência não pode virar `false`.
      final antiga = ConfigSistema.defaults().toJson()..remove('cinemaCatalogo');
      expect(ConfigSistema.fromJson(antiga).cinemaCatalogo, isTrue);
    });

    test('copyWith carrega o campo', () {
      final base = ConfigSistema.defaults();
      expect(base.copyWith(cinemaCatalogo: false).cinemaCatalogo, isFalse);
      expect(base.copyWith().cinemaCatalogo, isTrue);
    });
  });
}
