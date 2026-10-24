// ignore_for_file: file_names

import 'dart:convert';
import 'dart:io';
import '../System/app_storage.dart';

/// Modelo de configuração do sistema (UI / tema / estilos)
/// Salva/Carrega como JSON na pasta privada de dados do usuário.
class ConfigSistema {
  // Exemplo de propriedades de interface
  String viewType; // 'list' | 'moderno' | 'retro' | 'futurista' (grid: atalho legado)
  int uiFps; // 0 = Livre (monitor), 30 ou 60 = cadência da UI
  String primaryColorHex; // Ex: '#FF4081'
  String accentColorHex; // Ex: '#FFC107'
  String buttonStyle; // 'rounded' | 'flat' | 'outline'
  double fontSize; // valor base de fonte
  bool darkMode; // tema escuro
  double spacing; // espaçamento geral
  
  // Propriedades de ConfigSistema
  double volume; // Volume do sistema (0.0 - 1.0)
  double volumeMusicaFuturista; // Volume da música ambiente futurista (0.0 - 1.0)
  double volumeSomInicioFuturista; // Volume do som ao iniciar um jogo (0.0 - 1.0)
  int telaInicialTipo; // Tipo de tela inicial
  bool videosTelaPrincipal; // Exibir vídeos na tela principal
  bool cinemaCatalogo; // Aba Cinema: catálogo TMDB (true) ou grade de canais
  bool noticias; // Exibir vídeos no card do game
  bool intro; // Tocar som de introdução
  
  // Sequências de comandos do controle (configuráveis)
  List<String> sequenciaEnter; // SELECT + SELECT + A + A + A
  List<String> sequenciaEspaco; // SELECT + SELECT + Y + Y + Y
  
  // Múltiplas opções para voltar à tela (SELECT ou START)
  List<String> sequenciaVoltarTela1; // SELECT + SELECT + LB + RB + A  
  List<String> sequenciaVoltarTela2; // START + START + LB + RB + A
  
  // Múltiplas opções para ativar mouse (SELECT ou START ou custom)
  List<String> sequenciaAtivaMouse1; // START + START + LB + RB + Y  
  List<String> sequenciaAtivaMouse2; // SELECT + SELECT + LB + RB + Y  
  List<String> sequenciaAtivaMouseCustom; // [configurável]

  ConfigSistema({
    required this.viewType,
    this.uiFps = 0,
    required this.primaryColorHex,
    required this.accentColorHex,
    required this.buttonStyle,
    required this.fontSize,
    required this.darkMode,
    required this.spacing,
    required this.volume,
    required this.volumeMusicaFuturista,
    required this.volumeSomInicioFuturista,
    required this.telaInicialTipo,
    required this.videosTelaPrincipal,
    this.cinemaCatalogo = true,
    required this.noticias,
    required this.intro,
    required this.sequenciaEnter,
    required this.sequenciaEspaco,
    required this.sequenciaVoltarTela1,
    required this.sequenciaVoltarTela2,
    required this.sequenciaAtivaMouse1,
    required this.sequenciaAtivaMouse2,
    required this.sequenciaAtivaMouseCustom,
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
      volumeMusicaFuturista: 0.22,
      volumeSomInicioFuturista: 1.0,
      telaInicialTipo: 1,
      videosTelaPrincipal: true,
      cinemaCatalogo: true,
      noticias: false,
      intro: false,
      sequenciaEnter: ["SELECT", "SELECT", "2", "2", "2"],
      sequenciaEspaco: ["SELECT", "SELECT", "4", "4", "4"],
      sequenciaVoltarTela1: ["SELECT", "SELECT", "LB", "RB", "2"],
      sequenciaVoltarTela2: ["START", "START", "LB", "RB", "2"],
      sequenciaAtivaMouse1: ["START", "START", "LB", "RB", "4"],
      sequenciaAtivaMouse2: ["SELECT", "SELECT", "LB", "RB", "4"],
      sequenciaAtivaMouseCustom: ["L3", "R3", "LB", "RB", "4"],
    );
  }

  factory ConfigSistema.fromJson(Map<String, dynamic> json) {
    return ConfigSistema(
      viewType: json['viewType'] ?? 'list',
      uiFps: json['uiFps'] == 30 ? 30 : (json['uiFps'] == 60 ? 60 : 0),
      primaryColorHex: json['primaryColorHex'] ?? '#1E88E5',
      accentColorHex: json['accentColorHex'] ?? '#FFC107',
      buttonStyle: json['buttonStyle'] ?? 'rounded',
      fontSize: (json['fontSize'] is num) ? (json['fontSize'] as num).toDouble() : 14.0,
      darkMode: json['darkMode'] ?? false,
      spacing: (json['spacing'] is num) ? (json['spacing'] as num).toDouble() : 8.0,
      volume: (json['volume'] is num) ? (json['volume'] as num).toDouble() : 0.9,
      volumeMusicaFuturista: (json['volumeMusicaFuturista'] is num)
          ? (json['volumeMusicaFuturista'] as num)
              .toDouble()
              .clamp(0.0, 1.0)
              .toDouble()
          : 0.22,
      volumeSomInicioFuturista: (json['volumeSomInicioFuturista'] is num)
          ? (json['volumeSomInicioFuturista'] as num)
              .toDouble()
              .clamp(0.0, 1.0)
              .toDouble()
          : 1.0,
      telaInicialTipo: json['telaInicialTipo'] ?? 1,
      videosTelaPrincipal: json['videosTelaPrincipal'] ?? true,
      cinemaCatalogo: json['cinemaCatalogo'] ?? true,
      noticias: json['videosCardGame'] ?? true,
      intro: json['intro'] ?? true,
      sequenciaEnter: json['sequenciaEnter'] != null 
          ? List<String>.from(json['sequenciaEnter']) 
          : ["SELECT", "SELECT", "2", "2", "2"],
      sequenciaEspaco: json['sequenciaEspaco'] != null 
          ? List<String>.from(json['sequenciaEspaco']) 
          : ["SELECT", "SELECT", "4", "4", "4"],
      sequenciaVoltarTela1: json['sequenciaVoltarTela1'] != null 
          ? List<String>.from(json['sequenciaVoltarTela1']) 
          : ["SELECT", "SELECT", "LB", "RB", "2"],
      sequenciaVoltarTela2: json['sequenciaVoltarTela2'] != null 
          ? List<String>.from(json['sequenciaVoltarTela2']) 
          : ["START", "START", "LB", "RB", "2"],
      sequenciaAtivaMouse1: json['sequenciaAtivaMouse1'] != null 
          ? List<String>.from(json['sequenciaAtivaMouse1']) 
          : ["START", "START", "LB", "RB", "4"],
      sequenciaAtivaMouse2: json['sequenciaAtivaMouse2'] != null 
          ? List<String>.from(json['sequenciaAtivaMouse2']) 
          : ["SELECT", "SELECT", "LB", "RB", "4"],
      sequenciaAtivaMouseCustom: json['sequenciaAtivaMouseCustom'] != null 
          ? List<String>.from(json['sequenciaAtivaMouseCustom']) 
          : ["L3", "R3", "LB", "RB", "4"],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'viewType': viewType,
      'uiFps': uiFps,
      'primaryColorHex': primaryColorHex,
      'accentColorHex': accentColorHex,
      'buttonStyle': buttonStyle,
      'fontSize': fontSize,
      'darkMode': darkMode,
      'spacing': spacing,
      'volume': volume,
      'volumeMusicaFuturista': volumeMusicaFuturista,
      'volumeSomInicioFuturista': volumeSomInicioFuturista,
      'telaInicialTipo': telaInicialTipo,
      'videosTelaPrincipal': videosTelaPrincipal,
      'cinemaCatalogo': cinemaCatalogo,
      'videosCardGame': noticias,
      'intro': intro,
      'sequenciaEnter': sequenciaEnter,
      'sequenciaEspaco': sequenciaEspaco,
      'sequenciaVoltarTela1': sequenciaVoltarTela1,
      'sequenciaVoltarTela2': sequenciaVoltarTela2,
      'sequenciaAtivaMouse1': sequenciaAtivaMouse1,
      'sequenciaAtivaMouse2': sequenciaAtivaMouse2,
      'sequenciaAtivaMouseCustom': sequenciaAtivaMouseCustom,
    };
  }

  ConfigSistema copyWith({
    String? viewType,
    int? uiFps,
    String? primaryColorHex,
    String? accentColorHex,
    String? buttonStyle,
    double? fontSize,
    bool? darkMode,
    double? spacing,
    double? volume,
    double? volumeMusicaFuturista,
    double? volumeSomInicioFuturista,
    int? telaInicialTipo,
    bool? videosTelaPrincipal,
    bool? cinemaCatalogo,
    bool? videosCardGame,
    bool? intro,
    List<String>? sequenciaEnter,
    List<String>? sequenciaEspaco,
    List<String>? sequenciaVoltarTela1,
    List<String>? sequenciaVoltarTela2,
    List<String>? sequenciaAtivaMouse1,
    List<String>? sequenciaAtivaMouse2,
    List<String>? sequenciaAtivaMouseCustom,
  }) {
    return ConfigSistema(
      viewType: viewType ?? this.viewType,
      uiFps: uiFps ?? this.uiFps,
      primaryColorHex: primaryColorHex ?? this.primaryColorHex,
      accentColorHex: accentColorHex ?? this.accentColorHex,
      buttonStyle: buttonStyle ?? this.buttonStyle,
      fontSize: fontSize ?? this.fontSize,
      darkMode: darkMode ?? this.darkMode,
      spacing: spacing ?? this.spacing,
      volume: volume ?? this.volume,
      volumeMusicaFuturista:
          volumeMusicaFuturista ?? this.volumeMusicaFuturista,
      volumeSomInicioFuturista:
          volumeSomInicioFuturista ?? this.volumeSomInicioFuturista,
      telaInicialTipo: telaInicialTipo ?? this.telaInicialTipo,
      videosTelaPrincipal: videosTelaPrincipal ?? this.videosTelaPrincipal,
      cinemaCatalogo: cinemaCatalogo ?? this.cinemaCatalogo,
      noticias: videosCardGame ?? noticias,
      intro: intro ?? this.intro,
      sequenciaEnter: sequenciaEnter ?? this.sequenciaEnter,
      sequenciaEspaco: sequenciaEspaco ?? this.sequenciaEspaco,
      sequenciaVoltarTela1: sequenciaVoltarTela1 ?? this.sequenciaVoltarTela1,
      sequenciaVoltarTela2: sequenciaVoltarTela2 ?? this.sequenciaVoltarTela2,
      sequenciaAtivaMouse1: sequenciaAtivaMouse1 ?? this.sequenciaAtivaMouse1,
      sequenciaAtivaMouse2: sequenciaAtivaMouse2 ?? this.sequenciaAtivaMouse2,
      sequenciaAtivaMouseCustom: sequenciaAtivaMouseCustom ?? this.sequenciaAtivaMouseCustom,
    );
  }

  static const _fileName = 'v1_game_config.json';

  /// Retorna o caminho completo do arquivo de configuração.
  /// Migra a configuração antiga para a pasta privada do usuário.
  static Future<String> _getFilePath() async {
    return AppStorage.dataFile(_fileName).path;
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
      uiFps = d.uiFps;
      primaryColorHex = d.primaryColorHex;
      accentColorHex = d.accentColorHex;
      buttonStyle = d.buttonStyle;
      fontSize = d.fontSize;
      darkMode = d.darkMode;
      spacing = d.spacing;
      volume = d.volume;
      volumeMusicaFuturista = d.volumeMusicaFuturista;
      volumeSomInicioFuturista = d.volumeSomInicioFuturista;
      telaInicialTipo = d.telaInicialTipo;
      videosTelaPrincipal = d.videosTelaPrincipal;
      cinemaCatalogo = d.cinemaCatalogo;
      noticias = d.noticias;
      intro = d.intro;
    }
    return ok;
  }
}
