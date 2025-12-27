// ignore_for_file: file_names
import 'package:flutter/material.dart';
import 'package:flutter_soloud/flutter_soloud.dart';
import 'package:v1_game/Global.dart';

class SonsSistema {
  // Instância singleton do SoLoud (inicializada uma vez)
  static final SoLoud _soloud = SoLoud.instance;
  static bool _initialized = false;
  
  // Cache de sons carregados para melhor performance
  static final Map<String, AudioSource> _loadedSounds = {};

  
  static void direction() => _playSound('Sons/SomMovimento.mp3');
  static void directionRL() => _playSound('Sons/SomMovimentoBaixo.mp3');
  static void cheat() => _playSound('Sons/SomCheat.mp3');
  static void pim() => _playSound('Sons/SomCheat2.mp3');
  static void click() => _playSound('Sons/SomClick.mp3');
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
  static void _playSound(String assetPath) {
    if (!_initialized) {
      debugPrint('⚠️ SoLoud não inicializado! Chame SonsSistema.init() primeiro');
      return;
    }

    // Só toca se o som JÁ estiver carregado (sem delays)
    if (!_loadedSounds.containsKey(assetPath)) {
      debugPrint('⚠️ Som não pré-carregado: $assetPath - Chame preloadCommonSounds()');
      return;
    }

    try {
      final source = _loadedSounds[assetPath]!;
      // Toca IMEDIATAMENTE - sem await
      _soloud.play(source, volume: configSistema.volume);
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
      preload('Sons/SomMovimento.mp3'),
      preload('Sons/SomMovimentoBaixo.mp3'),
      preload('Sons/Intro.mp3'),
    ]);
    debugPrint('✓ Todos os sons carregados e prontos para uso instantâneo');
  }
}