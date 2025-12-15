// ignore_for_file: file_names

import 'dart:convert';
import 'dart:io';

/// Modelo de configuração do sistema (UI / tema / estilos)
/// Salva/Carrega como JSON em: <Public Documents>/v1_game_config.json (Windows)
class VariaveisSistema {
  // Exemplo de propriedades de interface
  String viewType; // 'grid' | 'list' | 'carousel'
  String primaryColorHex; // Ex: '#FF4081'
  String accentColorHex; // Ex: '#FFC107'
  String buttonStyle; // 'rounded' | 'flat' | 'outline'
  double fontSize; // valor base de fonte
  bool darkMode; // tema escuro
  double spacing; // espaçamento geral

  VariaveisSistema({
    required this.viewType,
    required this.primaryColorHex,
    required this.accentColorHex,
    required this.buttonStyle,
    required this.fontSize,
    required this.darkMode,
    required this.spacing,
  });

  /// Valores padrão
  factory VariaveisSistema.defaults() {
    return VariaveisSistema(
      viewType: 'grid',
      primaryColorHex: '#1E88E5',
      accentColorHex: '#FFC107',
      buttonStyle: 'rounded',
      fontSize: 14.0,
      darkMode: false,
      spacing: 8.0,
    );
  }

  factory VariaveisSistema.fromJson(Map<String, dynamic> json) {
    return VariaveisSistema(
      viewType: json['viewType'] ?? 'grid',
      primaryColorHex: json['primaryColorHex'] ?? '#1E88E5',
      accentColorHex: json['accentColorHex'] ?? '#FFC107',
      buttonStyle: json['buttonStyle'] ?? 'rounded',
      fontSize: (json['fontSize'] is num) ? (json['fontSize'] as num).toDouble() : 14.0,
      darkMode: json['darkMode'] ?? false,
      spacing: (json['spacing'] is num) ? (json['spacing'] as num).toDouble() : 8.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'viewType': viewType,
      'primaryColorHex': primaryColorHex,
      'accentColorHex': accentColorHex,
      'buttonStyle': buttonStyle,
      'fontSize': fontSize,
      'darkMode': darkMode,
      'spacing': spacing,
    };
  }

  VariaveisSistema copyWith({
    String? viewType,
    String? primaryColorHex,
    String? accentColorHex,
    String? buttonStyle,
    double? fontSize,
    bool? darkMode,
    double? spacing,
  }) {
    return VariaveisSistema(
      viewType: viewType ?? this.viewType,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      buttonStyle: buttonStyle ?? this.buttonStyle,
      fontSize: fontSize ?? this.fontSize,
      darkMode: darkMode ?? this.darkMode,
      spacing: spacing ?? this.spacing,
    );
  }

  static const _fileName = 'v1_game_config.json';

  /// Retorna o caminho completo do arquivo de configuração.
  /// Em Windows tenta usar a pasta pública de Documentos; se não encontrada, usa 'C:\\Users\\Public\\Documents'.
  static Future<String> _getFilePath() async {
    final sep = Platform.pathSeparator;
    if (Platform.isWindows) {
      final publicEnv = Platform.environment['PUBLIC'];
      if (publicEnv != null && publicEnv.isNotEmpty) {
        return '$publicEnv${sep}Documents$sep$_fileName';
      }
      // fallback comum
      return 'C:${sep}Users${sep}Public${sep}Documents$sep$_fileName';
    } else {
      final home = Platform.environment['HOME'] ?? '.';
      return '$home${sep}Documents$sep$_fileName';
    }
  }

  /// Carrega a configuração do arquivo; se não existir, cria com valores padrão e retorna-os.
  static Future<VariaveisSistema> load() async {
    try {
      final path = await _getFilePath();
      final file = File(path);
      if (!await file.exists()) {
        final defaults = VariaveisSistema.defaults();
        await _ensureParentDir(file);
        await file.writeAsString(jsonEncode(defaults.toJson()), flush: true);
        return defaults;
      }
      final content = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);
      return VariaveisSistema.fromJson(data);
    } catch (e) {
      // Em caso de erro, retorna padrões para não quebrar a aplicação
      return VariaveisSistema.defaults();
    }
  }

  /// Salva a configuração atual no arquivo.
  Future<bool> save() async {
    try {
      final path = await VariaveisSistema._getFilePath();
      final file = File(path);
      await _ensureParentDir(file);
      await file.writeAsString(jsonEncode(toJson()), flush: true);
      return true;
    } catch (e) {
      return false;
    }
  }

  static Future<void> _ensureParentDir(File file) async {
    try {
      final parent = file.parent;
      if (!await parent.exists()) {
        await parent.create(recursive: true);
      }
    } catch (_) {}
  }

  /// Reseta para padrão e grava no disco
  Future<bool> resetToDefaults() async {
    final d = VariaveisSistema.defaults();
    final ok = await d.save();
    if (ok) {
      // substituir valores locais
      viewType = d.viewType;
      primaryColorHex = d.primaryColorHex;
      accentColorHex = d.accentColorHex;
      buttonStyle = d.buttonStyle;
      fontSize = d.fontSize;
      darkMode = d.darkMode;
      spacing = d.spacing;
    }
    return ok;
  }
}
