import 'dart:io';
import 'dart:math';
import 'package:path/path.dart' as p;

/// Dados privados do usuário; nunca escreve ao lado do executável instalado.
class AppStorage {
  static Directory get root {
    final environment = Platform.environment;
    final base = Platform.isWindows
        ? environment['LOCALAPPDATA'] ??
            (environment['USERPROFILE'] == null
                ? null
                : p.join(environment['USERPROFILE']!, 'AppData', 'Local'))
        : environment['XDG_DATA_HOME'] ??
            (environment['HOME'] == null
                ? null
                : p.join(environment['HOME']!, '.local', 'share'));
    if (base == null || base.isEmpty) {
      throw StateError(
          'Não foi possível localizar a pasta de dados do usuário.');
    }
    return Directory(p.join(base, 'V1 Launcher'));
  }

  static File dataFile(String name) {
    if (name.isEmpty ||
        p.basename(name) != name ||
        name == '.' ||
        name == '..') {
      throw ArgumentError.value(name, 'name', 'Nome de arquivo inválido.');
    }
    final legacy = Platform.isWindows
        ? p.join(Platform.environment['PUBLIC'] ?? r'C:\Users\Public',
            'Documents', name)
        : p.join(Platform.environment['HOME'] ?? '', 'Documents', name);
    return migrateFile(File(p.join(root.path, name)), File(legacy));
  }

  /// Cópia única, sem substituir os novos dados nem apagar o arquivo antigo.
  static File migrateFile(File target, File legacy) {
    target.parent.createSync(recursive: true);
    if (!target.existsSync() && legacy.existsSync()) {
      // Grava em arquivo exclusivo e publica somente após concluir a cópia.
      final temporary = File('${target.path}.migration-$pid-'
          '${Random.secure().nextInt(1 << 32)}');
      try {
        legacy.copySync(temporary.path);
        if (!target.existsSync()) temporary.renameSync(target.path);
      } finally {
        if (temporary.existsSync()) temporary.deleteSync();
      }
    }
    return target;
  }
}

class FolderAccessException implements Exception {
  final String path;
  final Object cause;
  const FolderAccessException(this.path, this.cause);
  @override
  String toString() => 'Não foi possível gravar em "$path". '
      'Escolha outra pasta/disco ou libere o acesso dessa pasta para o V1 Launcher '
      'nas configurações do Windows. Detalhe: $cause';
}

/// Testa criar, escrever, ler e remover um arquivo próprio, sem alterar ACLs.
Future<void> ensureWritableDirectory(Directory directory) async {
  File? probe;
  try {
    await directory.create(recursive: true);
    for (var attempt = 0; attempt < 5; attempt++) {
      final candidate = File(p.join(directory.path,
          '.v1-write-check-$pid-${Random.secure().nextInt(1 << 32)}'));
      try {
        await candidate.create(exclusive: true);
        probe = candidate;
        break;
      } on FileSystemException {
        if (!await candidate.exists()) rethrow;
      }
    }
    if (probe == null) {
      throw StateError('Não foi possível criar o teste de acesso.');
    }
    await probe.writeAsString('V1', flush: true);
    if (await probe.readAsString() != 'V1') {
      throw StateError('A verificação de escrita falhou.');
    }
    await probe.delete();
    probe = null;
  } catch (error) {
    throw FolderAccessException(directory.path, error);
  } finally {
    if (probe != null) {
      try {
        await probe.delete();
      } catch (_) {/* Não oculta a causa original de uma falha de acesso. */}
    }
  }
}
