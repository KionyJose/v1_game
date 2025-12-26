// ignore_for_file: avoid_print, deprecated_member_use, prefer_const_constructors

import 'dart:io';
import 'dart:ffi';
import 'package:win32/win32.dart';
import 'package:ffi/ffi.dart';

/// Modelo para representar um jogo encontrado no sistema
class JogoEncontrado {
  final String nome;
  final String caminho;
  final String executavel;
  final String? icone;
  final String origem; // Steam, Epic, Instalado, etc.
  final DateTime? dataInstalacao;
  final int? tamanhoMB;

  JogoEncontrado({
    required this.nome,
    required this.caminho,
    required this.executavel,
    this.icone,
    required this.origem,
    this.dataInstalacao,
    this.tamanhoMB,
  });

  Map<String, dynamic> toMap() {
    return {
      'nome': nome,
      'caminho': caminho,
      'executavel': executavel,
      'icone': icone,
      'origem': origem,
      'dataInstalacao': dataInstalacao?.toIso8601String(),
      'tamanhoMB': tamanhoMB,
    };
  }

  @override
  String toString() {
    return 'JogoEncontrado(nome: $nome, origem: $origem, caminho: $caminho)';
  }
}

class JogosExistentes {
  /// Lista de extensões de arquivos executáveis de jogos
  static const List<String> extensoesJogos = ['.exe', '.bat', '.lnk'];

  /// Profundidade máxima para busca em subpastas
  static const int profundidadeMaxima = 2;

  /// Timeout para operações de busca (em segundos)
  static const int timeoutBusca = 30;

  /// Nomes comuns de pastas de jogos
  static const List<String> pastasComuns = [
    'Games',
    'Jogos',
    'Steam',
    'Epic Games',
    'GOG Galaxy',
    'EA Games',
    'Riot Games',
    'Ubisoft',
    'Battle.net',
    'Origin',
    'Activision',
    'Rockstar Games',
  ];

  /// Busca todos os jogos instalados no computador
  Future<List<JogoEncontrado>> buscarJogosInstalados() async {
    List<JogoEncontrado> jogosEncontrados = [];

    try {
      // Buscar jogos do Steam
      print('Buscando jogos Steam...');
      jogosEncontrados.addAll(await _buscarJogosSteam());

      // Buscar jogos da Epic Games
      print('Buscando jogos Epic Games...');
      jogosEncontrados.addAll(await _buscarJogosEpicGames());

      // Buscar em pastas comuns de jogos (mais flexível)
      print('Buscando em pastas comuns...');
      jogosEncontrados.addAll(await _buscarEmPastasComuns());

      // Buscar em raiz dos drives (jogos piratas soltos)
      print('Buscando em raiz dos drives...');
      jogosEncontrados.addAll(await _buscarEmRaizDrives());

      // Buscar em Program Files (última opção - mais restritivo)
      print('Buscando em Program Files...');
      jogosEncontrados.addAll(await _buscarEmProgramFiles());
    } catch (e) {
      print('Erro ao buscar jogos: $e');
    }

    // Remover duplicados baseado no caminho
    final Map<String, JogoEncontrado> jogosUnicos = {};
    for (var jogo in jogosEncontrados) {
      jogosUnicos[jogo.caminho.toLowerCase()] = jogo;
    }

    print('Total de jogos encontrados: ${jogosUnicos.length}');
    return jogosUnicos.values.toList();
  }

  /// Busca jogos instalados via Steam
  Future<List<JogoEncontrado>> _buscarJogosSteam() async {
    List<JogoEncontrado> jogos = [];

    try {
      // Obter todos os drives disponíveis
      final drives = await _obterDrivesDisponiveis();

      // Lista de possíveis localizações do Steam
      List<String> steamPaths = [];

      // Tentar ler do registro primeiro
      final steamPathRegistro = _lerRegistroSteam();
      if (steamPathRegistro != null && steamPathRegistro.isNotEmpty) {
        steamPaths.add(steamPathRegistro);
        print('Steam encontrado no registro: $steamPathRegistro');
      }

      // Buscar em TODOS os drives disponíveis
      for (var drive in drives) {
        steamPaths.addAll([
          '$drive\\Program Files (x86)\\Steam',
          '$drive\\Program Files\\Steam',
          '$drive\\Steam',
          '$drive\\SteamLibrary',
          '$drive\\Games\\Steam',
          '$drive\\Jogos\\Steam',
        ]);
      }

      // Verificar cada caminho possível
      for (final steamPath in steamPaths) {
        try {
          final steamAppsDir = Directory('$steamPath\\steamapps\\common');

          if (await steamAppsDir.exists()) {
            print('✓ Pasta Steam encontrada: ${steamAppsDir.path}');
            try {
              final entities = steamAppsDir.list().timeout(
                    Duration(seconds: timeoutBusca),
                    onTimeout: (sink) => sink.close(),
                  );

              await for (var entity in entities) {
                try {
                  if (entity is Directory) {
                    final nomeJogo = entity.path.split('\\').last;
                    final executavel = await _encontrarExecutavel(entity.path);

                    if (executavel != null) {
                      print('  ✓ Jogo Steam: $nomeJogo');
                      jogos.add(JogoEncontrado(
                        nome: nomeJogo,
                        caminho: entity.path,
                        executavel: executavel,
                        origem: 'Steam',
                      ));
                    }
                  }
                } catch (e) {
                  continue;
                }
              }
            } catch (e) {
              print('Erro ao listar jogos Steam em $steamPath: $e');
            }
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      print('Erro ao buscar jogos Steam: $e');
    }

    print('Total de jogos Steam encontrados: ${jogos.length}');
    return jogos;
  }

  /// Busca jogos instalados via Epic Games Store
  Future<List<JogoEncontrado>> _buscarJogosEpicGames() async {
    List<JogoEncontrado> jogos = [];

    try {
      // Obter todos os drives disponíveis
      final drives = await _obterDrivesDisponiveis();

      // Lista de possíveis localizações da Epic Games
      List<String> epicPaths = [];

      // Buscar em TODOS os drives disponíveis
      for (var drive in drives) {
        epicPaths.addAll([
          '$drive\\Program Files\\Epic Games',
          '$drive\\Program Files (x86)\\Epic Games',
          '$drive\\Epic Games',
          '$drive\\EpicGames',
          '$drive\\Games\\Epic Games',
          '$drive\\Jogos\\Epic Games',
        ]);
      }

      for (final epicPath in epicPaths) {
        final epicDir = Directory(epicPath);

        if (await epicDir.exists()) {
          print('✓ Pasta Epic Games encontrada: $epicPath');
          try {
            final entities = epicDir.list().timeout(
                  Duration(seconds: timeoutBusca ~/ 2),
                  onTimeout: (sink) => sink.close(),
                );

            await for (var entity in entities) {
              try {
                if (entity is Directory) {
                  final nomeJogo = entity.path.split('\\').last;
                  if (nomeJogo != 'Launcher' && !nomeJogo.startsWith('.')) {
                    final executavel = await _encontrarExecutavel(entity.path);

                    if (executavel != null) {
                      print('  ✓ Jogo Epic Games: $nomeJogo');
                      jogos.add(JogoEncontrado(
                        nome: nomeJogo,
                        caminho: entity.path,
                        executavel: executavel,
                        origem: 'Epic Games',
                      ));
                    }
                  }
                }
              } catch (e) {
                continue;
              }
            }
          } catch (e) {
            continue;
          }
        }
      }
    } catch (e) {
      print('Erro ao buscar jogos Epic Games: $e');
    }

    print('Total de jogos Epic Games encontrados: ${jogos.length}');
    return jogos;
  }

  /// Busca jogos em Program Files e Program Files (x86)
  Future<List<JogoEncontrado>> _buscarEmProgramFiles() async {
    List<JogoEncontrado> jogos = [];

    final pastas = [
      'C:\\Program Files',
      'C:\\Program Files (x86)',
    ];

    for (var pasta in pastas) {
      try {
        final dir = Directory(pasta);
        if (await dir.exists()) {
          final entities = dir.list(followLinks: false).timeout(
                Duration(seconds: timeoutBusca ~/ 2),
                onTimeout: (sink) => sink.close(),
              );

          await for (var entity in entities) {
            try {
              if (entity is Directory) {
                final nomePasta = entity.path.split('\\').last;

                // Ignorar pastas do sistema Windows
                if (_ehPastaSistema(nomePasta)) continue;

                // Verificar se é uma pasta de jogo conhecida
                if (_ehPastaDeJogo(nomePasta)) {
                  final executavel = await _encontrarExecutavel(entity.path);

                  if (executavel != null) {
                    jogos.add(JogoEncontrado(
                      nome: nomePasta,
                      caminho: entity.path,
                      executavel: executavel,
                      origem: 'Instalado',
                    ));
                  }
                }
              }
            } catch (e) {
              continue;
            }
          }
        }
      } catch (e) {
        print('Erro ao buscar em $pasta: $e');
      }
    }

    return jogos;
  }

  /// Busca em pastas comuns onde jogos costumam ser instalados
  Future<List<JogoEncontrado>> _buscarEmPastasComuns() async {
    List<JogoEncontrado> jogos = [];

    // Buscar apenas em drives que existem
    final drives = await _obterDrivesDisponiveis();

    for (var drive in drives) {
      for (var pastaComum in pastasComuns) {
        try {
          final caminho = '$drive\\$pastaComum';
          final dir = Directory(caminho);

          if (await dir.exists()) {
            print('Verificando pasta: $caminho');
            try {
              final entities = dir.list(followLinks: false).timeout(
                    Duration(seconds: 10),
                    onTimeout: (sink) => sink.close(),
                  );

              await for (var entity in entities) {
                try {
                  if (entity is Directory) {
                    final nomeJogo = entity.path.split('\\').last;
                    if (!_ehPastaSistema(nomeJogo)) {
                      final executavel =
                          await _encontrarExecutavel(entity.path);

                      if (executavel != null) {
                        print('✓ Jogo encontrado: $nomeJogo em $pastaComum');
                        jogos.add(JogoEncontrado(
                          nome: nomeJogo,
                          caminho: entity.path,
                          executavel: executavel,
                          origem: pastaComum,
                        ));
                      }
                    }
                  }
                } catch (e) {
                  continue;
                }
              }
            } catch (e) {
              continue;
            }
          }
        } catch (e) {
          // Drive ou pasta não existe, continuar
        }
      }
    }

    return jogos;
  }

  /// Busca jogos em raiz dos drives (para jogos piratas soltos)
  Future<List<JogoEncontrado>> _buscarEmRaizDrives() async {
    List<JogoEncontrado> jogos = [];

    final drives = await _obterDrivesDisponiveis();

    for (var drive in drives) {
      try {
        final dir = Directory(drive);

        if (await dir.exists()) {
          print('Buscando jogos na raiz de $drive...');
          try {
            final entities = dir.list(followLinks: false).timeout(
                  Duration(seconds: 15),
                  onTimeout: (sink) => sink.close(),
                );

            await for (var entity in entities) {
              try {
                if (entity is Directory) {
                  final nomePasta = entity.path.split('\\').last;

                  // Ignorar pastas do sistema
                  if (_ehPastaSistema(nomePasta)) continue;

                  // Verificar se parece ser um jogo (mais flexível)
                  if (_pareceSerJogo(nomePasta)) {
                    final executavel = await _encontrarExecutavel(entity.path);

                    if (executavel != null) {
                      print('✓ Jogo encontrado na raiz: $nomePasta');
                      jogos.add(JogoEncontrado(
                        nome: nomePasta,
                        caminho: entity.path,
                        executavel: executavel,
                        origem: 'Raiz $drive',
                      ));
                    }
                  }
                }
              } catch (e) {
                continue;
              }
            }
          } catch (e) {
            print('Erro ao buscar na raiz de $drive: $e');
          }
        }
      } catch (e) {
        continue;
      }
    }

    return jogos;
  }

  /// Obtém lista de drives disponíveis no sistema
  Future<List<String>> _obterDrivesDisponiveis() async {
    List<String> drivesDisponiveis = [];
    final drives = ['C:', 'D:', 'E:', 'F:', 'G:'];

    for (var drive in drives) {
      try {
        final dir = Directory(drive);
        if (await dir.exists()) {
          drivesDisponiveis.add(drive);
        }
      } catch (e) {
        // Drive não acessível
      }
    }

    return drivesDisponiveis;
  }

  /// Encontra o arquivo executável principal em uma pasta
  Future<String?> _encontrarExecutavel(String caminhoPasta) async {
    try {
      final dir = Directory(caminhoPasta);

      if (!await dir.exists()) return null;

      List<String> executaveisEncontrados = [];

      // Procurar por .exe na raiz primeiro
      try {
        final entities = dir.list(followLinks: false).timeout(
              Duration(seconds: 5),
              onTimeout: (sink) => sink.close(),
            );

        await for (var entity in entities) {
          try {
            if (entity is File && entity.path.toLowerCase().endsWith('.exe')) {
              final nome = entity.path.split('\\').last.toLowerCase();

              // Evitar executáveis de sistema comuns
              if (!_ehExecutavelSistema(nome)) {
                final file = File(entity.path);
                if (await file.exists()) {
                  executaveisEncontrados.add(entity.path);
                }
              }
            }
          } catch (e) {
            continue;
          }
        }
      } catch (e) {
        // Timeout ou erro de permissão
      }

      // Se encontrou executáveis na raiz, retornar o primeiro
      if (executaveisEncontrados.isNotEmpty) {
        return executaveisEncontrados.first;
      }

      // Se não encontrar na raiz, procurar em subpastas comuns
      final subpastas = [
        'bin',
        'Binaries',
        'Win64',
        'Win32',
        'Game',
        'x64',
        'x86'
      ];
      for (var subpasta in subpastas) {
        try {
          final subDir = Directory('$caminhoPasta\\$subpasta');
          if (await subDir.exists()) {
            final entities = subDir.list(followLinks: false).timeout(
                  Duration(seconds: 3),
                  onTimeout: (sink) => sink.close(),
                );

            await for (var entity in entities) {
              try {
                if (entity is File &&
                    entity.path.toLowerCase().endsWith('.exe')) {
                  final nome = entity.path.split('\\').last.toLowerCase();
                  if (!_ehExecutavelSistema(nome)) {
                    final file = File(entity.path);
                    if (await file.exists()) {
                      return entity.path;
                    }
                  }
                }
              } catch (e) {
                continue;
              }
            }
          }
        } catch (e) {
          continue;
        }
      }
    } catch (e) {
      // Erro geral
    }

    return null;
  }

  /// Verifica se é uma pasta do sistema que deve ser ignorada
  bool _ehPastaSistema(String nomePasta) {
    final nomeLower = nomePasta.toLowerCase();

    final pastasIgnoradas = [
      'windows',
      'system32',
      'program data',
      'programdata',
      '\$recycle.bin',
      'system volume information',
      'msocache',
      'perflogs',
      'recovery',
      'boot',
      'intel',
      'amd',
      'nvidia',
      'microsoft',
      'common files',
      'windows defender',
      'windowsapps',
      'users',
      'usuarios',
      'temp',
      'tmp',
    ];

    return pastasIgnoradas
        .any((pasta) => nomeLower == pasta || nomeLower.contains(pasta));
  }

  /// Verifica se a pasta parece ser um jogo (critério mais flexível)
  bool _pareceSerJogo(String nomePasta) {
    final nomeLower = nomePasta.toLowerCase();

    // Ignora pastas do sistema
    if (_ehPastaSistema(nomeLower)) return false;

    // Ignora pastas muito curtas (ex: "tmp", "bin", "src")
    if (nomePasta.length < 4) return false;

    // Aceita qualquer pasta que não seja do sistema
    // (mais flexível para jogos piratas)
    return true;
  }

  /// Verifica se é uma pasta conhecida de jogos
  bool _ehPastaDeJogo(String nomePasta) {
    final nomeLower = nomePasta.toLowerCase();

    // Lista de palavras-chave que indicam jogos
    final palavrasChave = [
      'game',
      'games',
      'steam',
      'epic',
      'riot',
      'ubisoft',
      'ea',
      'electronic arts',
      'activision',
      'blizzard',
      'square enix',
      'rockstar',
      'bethesda',
      'cd projekt',
    ];

    return palavrasChave.any((palavra) => nomeLower.contains(palavra));
  }

  /// Verifica se é um executável de sistema que deve ser ignorado
  bool _ehExecutavelSistema(String nomeExecutavel) {
    final ignorados = [
      'unins',
      'uninst',
      'uninstall',
      'setup',
      'install',
      'update',
      'updater',
      'patch',
      'patcher',
      'crash',
      'crashreport',
      'report',
      'register',
      'config',
      'settings',
      'redist',
      'vcredist',
      'directx',
      'easyanticheat',
      'battleye',
      'dxsetup',
      'ue4prerequisites',
      'activision',
      'steam_api',
    ];

    final nomeLower = nomeExecutavel.toLowerCase();

    // Ignora executáveis muito pequenos (provavelmente sistema)
    if (nomeExecutavel.length < 4) return true;

    return ignorados.any((ignorado) => nomeLower.contains(ignorado));
  }

  /// Lê o caminho do Steam do registro do Windows
  String? _lerRegistroSteam() {
    try {
      final hKey = calloc<HKEY>();

      // Tentar na chave de 64-bit primeiro
      var result = RegOpenKeyEx(
        HKEY_LOCAL_MACHINE,
        'SOFTWARE\\WOW6432Node\\Valve\\Steam'.toNativeUtf16(),
        0,
        KEY_READ,
        hKey,
      );

      // Se falhar, tentar na chave de 32-bit
      if (result != ERROR_SUCCESS) {
        result = RegOpenKeyEx(
          HKEY_LOCAL_MACHINE,
          'SOFTWARE\\Valve\\Steam'.toNativeUtf16(),
          0,
          KEY_READ,
          hKey,
        );
      }

      if (result == ERROR_SUCCESS) {
        final dataPtr = calloc<Uint8>(256);
        final dataSize = calloc<DWORD>();
        dataSize.value = 256;

        result = RegQueryValueEx(
          hKey.value,
          'InstallPath'.toNativeUtf16(),
          nullptr,
          nullptr,
          dataPtr,
          dataSize,
        );

        if (result == ERROR_SUCCESS) {
          final path = dataPtr.cast<Utf16>().toDartString();
          malloc.free(dataPtr);
          malloc.free(dataSize);
          RegCloseKey(hKey.value);
          malloc.free(hKey);
          return path.isNotEmpty ? path : null;
        }

        malloc.free(dataPtr);
        malloc.free(dataSize);
        RegCloseKey(hKey.value);
      }

      malloc.free(hKey);
    } catch (e) {
      print('Erro ao ler registro Steam: $e');
    }

    // Fallback: tentar caminhos padrão do Steam
    final caminhosPadrao = [
      'C:\\Program Files (x86)\\Steam',
      'C:\\Program Files\\Steam',
    ];

    for (var caminho in caminhosPadrao) {
      try {
        if (Directory(caminho).existsSync()) {
          return caminho;
        }
      } catch (e) {
        continue;
      }
    }

    return null;
  }

  /// Busca jogos por nome ou caminho específico
  Future<List<JogoEncontrado>> buscarJogoPorNome(String query) async {
    final todosJogos = await buscarJogosInstalados();

    final queryLower = query.toLowerCase();
    return todosJogos.where((jogo) {
      return jogo.nome.toLowerCase().contains(queryLower) ||
          jogo.caminho.toLowerCase().contains(queryLower);
    }).toList();
  }

  /// Obtém informações adicionais de um jogo específico
  Future<JogoEncontrado?> obterInfoJogo(String caminhoExecutavel) async {
    try {
      final file = File(caminhoExecutavel);
      if (!await file.exists()) return null;

      final stat = await file.stat();
      final caminho = file.parent.path;
      final nome = file.path.split('\\').last.replaceAll('.exe', '');

      return JogoEncontrado(
        nome: nome,
        caminho: caminho,
        executavel: caminhoExecutavel,
        origem: 'Manual',
        dataInstalacao: stat.modified,
        tamanhoMB: (stat.size / (1024 * 1024)).round(),
      );
    } catch (e) {
      print('Erro ao obter info do jogo: $e');
      return null;
    }
  }
}
