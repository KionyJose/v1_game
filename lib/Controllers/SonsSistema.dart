// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:v1_game/Global.dart';
import 'slim_mode_config_controller.dart';

class SonsSistema {
  // Instância singleton do SoLoud (inicializada uma vez)
  static final SoLoud _soloud = SoLoud.instance;
  static bool _initialized = false;
  static bool clickRetroAtivo = false;

  // Cache de sons carregados para melhor performance
  static final Map<String, AudioSource> _loadedSounds = {};

  static void direction() => SlimModeConfigController.active.value
      ? slimMove()
      : futuristicActive ? futuristicMove() : _playSound('Sons/SomMovimento.mp3');
  static void directionRL() => SlimModeConfigController.active.value
      ? slimMove()
      : futuristicActive ? futuristicMove() : _playSound('Sons/SomMovimentoBaixo.mp3');
  static void cheat() => _playSound('Sons/SomCheat.mp3');
  static void pim() => _playSound('Sons/SomCheat2.mp3');
  static void click() => SlimModeConfigController.active.value
      ? slimOpen()
      : futuristicActive ? futuristicOpen() : _playSound('Sons/SomClick.mp3');
  static bool get futuristicActive => !SlimModeConfigController.active.value &&
      configSistema.viewType == 'futurista';
  static void futuristicMove() =>
      _playSound('Sons/Futurista/click_move_futurista.wav');
  static void futuristicOpen() =>
      _playSound('Sons/Futurista/click_enter_futurista.wav');
  static void futuristicLaunch() =>
      _playSound(
        'Sons/Futurista/start_game_futurista.wav',
        volumeMultiplier: configSistema.volumeSomInicioFuturista,
      );
  static Future<SoundHandle?> startWaterAmbience() async {
    await preload('Sons/Futurista/menu_background_futurista.wav');
    final source = _loadedSounds['Sons/Futurista/menu_background_futurista.wav'];
    if (!_initialized || source == null) return null;
    return _soloud.play(source, looping: true, paused: true, volume: 0);
  }
  static void updateWaterAmbience(SoundHandle handle, bool active) {
    if (!_initialized) return;
    _soloud.setVolume(
      handle,
      configSistema.volume.clamp(0.0, 1.0) *
          configSistema.volumeMusicaFuturista.clamp(0.0, 1.0),
    );
    _soloud.setPause(handle, !active);
  }
  static Future<void> stopWaterAmbience(SoundHandle handle) async {
    if (_initialized) await _soloud.stop(handle);
  }
  static void slimMove() => _playSound('Sons/Slim/move_8bit.wav');
  static void slimOpen() => _playSound('Sons/Slim/open_8bit.wav');
  static void clickRetro() => _playSound('somClickRetro.MP3');
  static void directionAtual() => SlimModeConfigController.active.value
      ? slimMove()
      : clickRetroAtivo
          ? clickRetro()
          : direction();
  static void intro() => _playSound('Sons/Intro.mp3');

  // Inicializa o SoLoud (chamar no início do app)
  static Future<void> init() async {
    if (_initialized) return;

    try {
      await _soloud.init();
      _initialized = true;
      debugPrint('✓ SoLoud inicializado com sucesso');
    } catch (e) {
      debugPrint('✗ Erro ao inicializar SoLoud: $e');
    }
  }

  // Libera recursos do SoLoud (chamar ao fechar o app)
  static Future<void> dispose() async {
    try {
      // Dispõe todos os sons carregados
      for (var source in _loadedSounds.values) {
        await _soloud.disposeSource(source);
      }
      _loadedSounds.clear();

      // deinit() retorna void, não precisa de await
      _soloud.deinit();
      _initialized = false;
      debugPrint('✓ SoLoud finalizado com sucesso');
    } catch (e) {
      debugPrint('✗ Erro ao finalizar SoLoud: $e');
    }
  }

  // Pré-carrega um som sem tocar (útil para sons que serão usados logo)
  static Future<void> preload(String assetPath) async {
    if (!_initialized) {
      await init();
    }
    if (_loadedSounds.containsKey(assetPath)) return;
    try {
      final source = await _soloud.loadAsset('assets/$assetPath');
      _loadedSounds[assetPath] = source;
      debugPrint('✓ Som pré-carregado: $assetPath');
    } catch (erro) {
      debugPrint('✗ Erro ao pré-carregar som $assetPath: $erro');
    }
  }

  // Toca som IMEDIATAMENTE - sem await, sem delays
  // IMPORTANTE: O som DEVE estar pré-carregado!
  static void _playSound(String assetPath, {double volumeMultiplier = 1}) {
    if (!_initialized) {
      debugPrint(
          '⚠️ SoLoud não inicializado! Chame SonsSistema.init() primeiro');
      return;
    }

    // Só toca se o som JÁ estiver carregado (sem delays)
    if (!_loadedSounds.containsKey(assetPath)) {
      debugPrint(
          '⚠️ Som não pré-carregado: $assetPath - Chame preloadCommonSounds()');
      return;
    }

    try {
      final volume = configSistema.volume.clamp(0.0, 1.0) *
          volumeMultiplier.clamp(0.0, 1.0);
      if (volume == 0) return;
      final source = _loadedSounds[assetPath]!;
      // Toca IMEDIATAMENTE - sem await
      _soloud.play(source, volume: volume);
    } catch (erro) {
      debugPrint('✗ Erro ao tocar som $assetPath: $erro');
    }
  }

  // Pré-carrega TODOS os sons do sistema
  static Future<void> preloadCommonSounds() async {
    await Future.wait([
      preload('Sons/SomCheat.mp3'),
      preload('Sons/SomCheat2.mp3'),
      preload('Sons/SomClick.mp3'),
      preload('somClickRetro.MP3'),
      preload('Sons/SomMovimento.mp3'),
      preload('Sons/SomMovimentoBaixo.mp3'),
      preload('Sons/Intro.mp3'),
      preload('Sons/Slim/move_8bit.wav'),
      preload('Sons/Slim/open_8bit.wav'),
      preload('Sons/Futurista/click_move_futurista.wav'),
      preload('Sons/Futurista/click_enter_futurista.wav'),
      preload('Sons/Futurista/start_game_futurista.wav'),
    ]);
    debugPrint('✓ Todos os sons carregados e prontos para uso instantâneo');
  }
}
