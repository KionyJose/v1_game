// ignore_for_file: file_names

import 'dart:convert';
import 'dart:io';

/// Modelo de configuração do sistema (UI / tema / estilos)
/// Salva/Carrega como JSON em: <Public Documents>/v1_game_config.json (Windows)
class ConfigSistema {
  // Exemplo de propriedades de interface
  String viewType; // 'grid' | 'list' | 'carousel'
  String primaryColorHex; // Ex: '#FF4081'
  String accentColorHex; // Ex: '#FFC107'
  String buttonStyle; // 'rounded' | 'flat' | 'outline'
  double fontSize; // valor base de fonte
  bool darkMode; // tema escuro
  double spacing; // espaçamento geral
  
  // Propriedades de ConfigSistema
  double volume; // Volume do sistema (0.0 - 1.0)
  int telaInicialTipo; // Tipo de tela inicial
  bool videosTelaPrincipal; // Exibir vídeos na tela principal
  bool noticias; // Exibir vídeos no card do game
  bool intro; // Tocar som de introdução

  ConfigSistema({
    required this.viewType,
    required this.primaryColorHex,
    required this.accentColorHex,
    required this.buttonStyle,
    required this.fontSize,
    required this.darkMode,
    required this.spacing,
    required this.volume,
    required this.telaInicialTipo,
    required this.videosTelaPrincipal,
    required this.noticias,
    required this.intro,
  });

  /// Valores padrão
  factory ConfigSistema.defaults() {
    return ConfigSistema(
      viewType: 'list',
      primaryColorHex: '#1E88E5',
      accentColorHex: '#FFC107',
      buttonStyle: 'rounded',
      fontSize: 14.0,
      darkMode: false,
      spacing: 8.0,
      volume: 0.9,
      telaInicialTipo: 1,
      videosTelaPrincipal: true,
      noticias: false,
      intro: false,
    );
  }

  factory ConfigSistema.fromJson(Map<String, dynamic> json) {
    return ConfigSistema(
      viewType: json['viewType'] ?? 'list',
      primaryColorHex: json['primaryColorHex'] ?? '#1E88E5',
      accentColorHex: json['accentColorHex'] ?? '#FFC107',
      buttonStyle: json['buttonStyle'] ?? 'rounded',
      fontSize: (json['fontSize'] is num) ? (json['fontSize'] as num).toDouble() : 14.0,
      darkMode: json['darkMode'] ?? false,
      spacing: (json['spacing'] is num) ? (json['spacing'] as num).toDouble() : 8.0,
      volume: (json['volume'] is num) ? (json['volume'] as num).toDouble() : 0.9,
      telaInicialTipo: json['telaInicialTipo'] ?? 1,
      videosTelaPrincipal: json['videosTelaPrincipal'] ?? true,
      noticias: json['videosCardGame'] ?? false,
      intro: json['intro'] ?? false,
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
      'volume': volume,
      'telaInicialTipo': telaInicialTipo,
      'videosTelaPrincipal': videosTelaPrincipal,
      'videosCardGame': noticias,
      'intro': intro,
    };
  }

  ConfigSistema copyWith({
    String? viewType,
    String? primaryColorHex,
    String? accentColorHex,
    String? buttonStyle,
    double? fontSize,
    bool? darkMode,
    double? spacing,
    double? volume,
    int? telaInicialTipo,
    bool? videosTelaPrincipal,
    bool? videosCardGame,
    bool? intro,
  }) {
    return ConfigSistema(
      viewType: viewType ?? this.viewType,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      buttonStyle: buttonStyle ?? this.buttonStyle,
      fontSize: fontSize ?? this.fontSize,
      darkMode: darkMode ?? this.darkMode,
      spacing: spacing ?? this.spacing,
      volume: volume ?? this.volume,
      telaInicialTipo: telaInicialTipo ?? this.telaInicialTipo,
      videosTelaPrincipal: videosTelaPrincipal ?? this.videosTelaPrincipal,
      noticias: videosCardGame ?? noticias,
      intro: intro ?? this.intro,
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
  static Future<ConfigSistema> load() async {
    try {
      final path = await _getFilePath();
      final file = File(path);
      if (!await file.exists()) {
        final defaults = ConfigSistema.defaults();
        await _ensureParentDir(file);
        await file.writeAsString(jsonEncode(defaults.toJson()), flush: true);
        return defaults;
      }
      final content = await file.readAsString();
      final Map<String, dynamic> data = jsonDecode(content);
      return ConfigSistema.fromJson(data);
    } catch (e) {
      // Em caso de erro, retorna padrões para não quebrar a aplicação
      return ConfigSistema.defaults();
    }
  }

  /// Salva a configuração atual no arquivo.
  Future<bool> save() async {
    try {
      final path = await ConfigSistema._getFilePath();
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
    final d = ConfigSistema.defaults();
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
      volume = d.volume;
      telaInicialTipo = d.telaInicialTipo;
      videosTelaPrincipal = d.videosTelaPrincipal;
      noticias = d.noticias;
      intro = d.intro;
    }
    return ok;
  }
}
