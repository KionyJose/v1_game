// ignore_for_file: file_names, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Classe para capturar botões especiais (Xbox Guide, PlayStation Home)
/// usando Method Channel para comunicação com código nativo Windows
class RawInputGamepad {
  static const MethodChannel _channel = MethodChannel('gamepad_guide_button');
  
  /// Callback chamado quando o botão Guide/Home é pressionado
  static Function(String)? onGuideButton;
  
  /// Callback chamado quando qualquer botão do DualSense é pressionado/solto
  static Function(String botao, bool pressionado)? onDualSenseButton;
  
  /// Callback chamado quando os analógicos do DualSense são movidos
  /// valorX e valorY são no formato XInput (-32768 a 32767)
  static Function(String stick, double x, double y, int valorX, int valorY)? onDualSenseAnalog;
  
  /// Inicializa o listener do botão Guide
  static Future<void> inicializar() async {
    try {
      // Registra Raw Input no lado nativo
      final bool sucesso = await _channel.invokeMethod('registerRawInput');
      
      if (sucesso) {
        debugPrint('✓ Raw Input registrado para capturar botão Xbox/PS');
        
        // Configura listener para receber eventos
        _channel.setMethodCallHandler(_handleMethodCall);
      } else {
        debugPrint('✗ Falha ao registrar Raw Input');
      }
    } catch (e) {
      debugPrint('Erro ao inicializar Raw Input: $e');
    }
  }
  
  /// Handler para eventos vindos do código nativo
  static Future<dynamic> _handleMethodCall(MethodCall call) async {
    switch (call.method) {
      case 'onDualSenseButton':
        // Novo evento: botão individual do DualSense
        final args = call.arguments as Map;
        String botao = args['button'] as String;
        final pressionado = args['pressed'] as bool;
        // Lista EXATA de eventos a ignorar (fornecidos por você)

        if(!pressionado) botao = '';
        debugPrint('🎮 DualSense: $botao ${pressionado ? "PRESSIONADO" : "SOLTO"}');
        if (botao == "GUIDE" && pressionado) return onGuideButton?.call('GUIDE');
        onDualSenseButton?.call(botao, true);
        break;
      
      case 'onDualSenseAnalog':
        // Novo evento: movimento dos analógicos
        final args = call.arguments as Map;
        final stick = args['stick'] as String;
        final x = args['x'] as double;
        final y = args['y'] as double;
        final rawX = args['rawX'] as int;
        final rawY = args['rawY'] as int;
        
        // Converter para valores int de -32768 a 32767 (formato XInput)
        final int valorX = (x * 32768).round();
        // inverter o valor de y de positivo pra negativo caso necessarios se nao o inverso
        final int valorY = (-y * 32768).round();
        
        debugPrint('🕹️ $stick: X=$x Y=$y (raw: $rawX, $rawY)');
        onDualSenseAnalog?.call(stick, x, y, valorX, valorY);
        break;
        
      case 'onGuideButtonPressed':
        final args = call.arguments as Map?;
        final controller = args?['controller'] ?? 'unknown';
        final byte = args?['byte'] ?? 'unknown';
        if(controller == "Xbox" && byte == 12) {
          debugPrint('   ✅ Xbox Controller - Guide Button (byte 12)');
          onGuideButton?.call('GUIDE');
        }
        break;        
      default: break;
    }
  }
  
  /// Define o callback para quando o botão Guide for pressionado
  static void escutarBotaoGuide(Function(String) callback) {
    onGuideButton = callback;
  }
  
  /// Define o callback para todos os botões do DualSense
  static void escutarBotoesDualSense(Function(String botao, bool pressionado) callback) {
    onDualSenseButton = callback;
  }
  
  /// Define o callback para os analógicos do DualSense
  /// valorX e valorY são no formato XInput (-32768 a 32767)
  static void escutarAnalogicosDualSense(Function(String stick, double x, double y, int valorX, int valorY) callback) {
    onDualSenseAnalog = callback;
  }
}

// ============================================================================
// INSTRUÇÕES DE USO:
// ============================================================================
//
// 1. No main.dart, inicialize antes de runApp:
//
//    void main() async {
//      WidgetsFlutterBinding.ensureInitialized();
//      await RawInputGamepad.inicializar();
//      runApp(MyApp());
//    }
//
// 2. Em Paad.dart (ou onde quiser escutar), configure o callback:
//
//    RawInputGamepad.escutarBotaoGuide((evento) {
//      debugPrint('Botão Guide detectado: $evento');
//      if(evento == 'GUIDE') {
//        // Ação quando pressionar
//        SonsSistema.cheat();
//        // Exemplo: voltar para tela inicial
//      }
//    });
//
// 3. IMPORTANTE: Implemente o código C++ em flutter_window.cpp
//    (veja próximo arquivo que vou criar)
//
// ============================================================================
