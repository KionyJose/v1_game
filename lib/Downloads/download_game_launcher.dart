import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import '../Interface/launcher_pad_scope.dart';

Future<void> openDownloadedFolder(String directory) async {
  if (directory.isEmpty || !await Directory(directory).exists()) {
    throw const FileSystemException('Pasta do download não encontrada');
  }
  await Process.start(
      'explorer.exe', [p.normalize(Directory(directory).absolute.path)],
      mode: ProcessStartMode.detached);
}

bool isGameExecutable(String path) {
  if (p.extension(path).toLowerCase() != '.exe') return false;
  final name = p.basenameWithoutExtension(path).toLowerCase();
  return !RegExp(
          r'^(setup|install|unins|uninstall|quicksfv|verify|unarc|v1unarc|cls-|precomp|rzw|rz-|flushfilecache|hosts|vcredist|vc_redist|dxsetup|dxwebsetup|directx|crashreport|crashhandler|crashpad|unitycrash|gamelaunchhelper|gamingrepair|ue[45]prereq)')
      .hasMatch(name);
}

/// Prefer a unique root launcher over engine binaries. Ambiguous collections
/// still use the Pad file picker rather than guessing an executable.
String? chooseInstalledExecutable(List<String> candidates, String root) {
  final games = candidates.where(isGameExecutable).toList();
  final launchers =
      games.where((path) => p.equals(p.dirname(path), root)).toList();
  if (launchers.length == 1) return launchers.single;
  return games.length == 1 ? games.single : null;
}

/// Busca somente na pasta do download, sem seguir links de diretórios.
Future<List<String>> findDownloadedGames(String directory) async {
  final results = <String>[];
  var visited = 0;
  Future<void> scan(Directory folder, int depth) async {
    if (depth > 6 || visited >= 3000) return;
    try {
      await for (final entry in folder.list(followLinks: false)) {
        if (++visited > 3000) break;
        if (entry is File && isGameExecutable(entry.path)) {
          results.add(entry.path);
        }
        if (entry is Directory &&
            !RegExp(r'^(md5|_?redist|_commonredist|support|directx|\.v1-tools)$',
                    caseSensitive: false)
                .hasMatch(p.basename(entry.path))) {
          await scan(entry, depth + 1);
        }
      }
    } on FileSystemException {
      /* Pastas inacessíveis não impedem a seleção manual. */
    }
  }

  if (directory.isNotEmpty) await scan(Directory(directory), 0);
  results.sort();
  return results;
}

Future<String?> selectDownloadedGame(BuildContext context, String directory,
        {bool enablePad = true}) =>
    showDialog<String>(
        context: context,
        builder: (_) =>
            _GameExecutablePicker(directory: directory, enablePad: enablePad));

/// Seletor interno, navegável pelo mesmo Pad, para jogos portáteis ou instalados.
class _GameExecutablePicker extends StatefulWidget {
  final String directory;
  final bool enablePad;
  const _GameExecutablePicker(
      {required this.directory, required this.enablePad});
  @override
  State<_GameExecutablePicker> createState() => _GameExecutablePickerState();
}

class _GameExecutablePickerState extends State<_GameExecutablePicker> {
  String? _directory;
  late Future<List<FileSystemEntity>> _entries;
  @override
  void initState() {
    super.initState();
    _directory = widget.directory.isEmpty ? null : widget.directory;
    _entries = _load();
  }

  Future<List<FileSystemEntity>> _load() async {
    if (_directory == null) {
      final drives = <Directory>[];
      for (var code = 65; code <= 90; code++) {
        final drive = Directory('${String.fromCharCode(code)}:/');
        if (await drive.exists()) drives.add(drive);
      }
      return drives;
    }
    final entries =
        await Directory(_directory!).list(followLinks: false).toList();
    entries.sort((a, b) {
      if ((a is Directory) != (b is Directory)) return a is Directory ? -1 : 1;
      return p
          .basename(a.path)
          .toLowerCase()
          .compareTo(p.basename(b.path).toLowerCase());
    });
    return entries;
  }

  void _navigate(String? directory) => setState(() {
        _directory = directory;
        _entries = _load();
      });

  @override
  Widget build(BuildContext context) => LauncherPadScope(
      menu: false,
      enabled: widget.enablePad,
      child: AlertDialog(
        title: const Text('Selecionar executável do jogo'),
        content: SizedBox(
            width: 700,
            height: (MediaQuery.sizeOf(context).height * .55).clamp(180, 500),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                      'Navegue pela pasta do jogo e selecione seu executável .exe. A escolha será salva e o jogo será cadastrado na biblioteca.'),
                  const SizedBox(height: 12),
                  Text(_directory ?? 'Unidades do computador',
                      maxLines: 2, overflow: TextOverflow.ellipsis),
                  Wrap(spacing: 8, children: [
                    TextButton.icon(
                        onPressed: _directory == null
                            ? null
                            : () {
                                final parent = p.dirname(_directory!);
                                _navigate(parent == _directory ? null : parent);
                              },
                        icon: const Icon(Icons.arrow_upward),
                        label: const Text('Pasta anterior')),
                    TextButton.icon(
                        onPressed: () => _navigate(null),
                        icon: const Icon(Icons.storage),
                        label: const Text('Unidades')),
                  ]),
                  Expanded(
                      child: FutureBuilder<List<FileSystemEntity>>(
                          future: _entries,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const Center(
                                  child: CircularProgressIndicator());
                            }
                            if (snapshot.hasError) {
                              return const Center(
                                  child: Text(
                                      'Não foi possível acessar esta pasta. Escolha outra pasta.'));
                            }
                            final entries = snapshot.data ?? [];
                            if (entries.isEmpty) {
                              return const Center(
                                  child: Text(
                                      'Nenhum executável do jogo nesta pasta.'));
                            }
                            return SingleChildScrollView(
                                key: ValueKey(_directory),
                                child: Column(children: [
                                  for (var index = 0;
                                      index < entries.length;
                                      index++)
                                    Padding(
                                        padding:
                                            const EdgeInsets.only(bottom: 6),
                                        child: OutlinedButton.icon(
                                          autofocus: index == 0,
                                          onPressed: () => entries[index]
                                                  is Directory
                                              ? _navigate(entries[index].path)
                                              : isGameExecutable(
                                                      entries[index].path)
                                                  ? Navigator.pop(context,
                                                      entries[index].path)
                                                  : ScaffoldMessenger.of(
                                                          context)
                                                      .showSnackBar(const SnackBar(
                                                          content: Text(
                                                              'Este arquivo não é um executável do jogo. Selecione o arquivo .exe correto.'))),
                                          icon: Icon(entries[index] is Directory
                                              ? Icons.folder_outlined
                                              : isGameExecutable(
                                                      entries[index].path)
                                                  ? Icons.sports_esports
                                                  : Icons
                                                      .insert_drive_file_outlined),
                                          label: SizedBox(
                                              width: double.infinity,
                                              child: Text(
                                                  p
                                                          .basename(
                                                              entries[index]
                                                                  .path)
                                                          .isEmpty
                                                      ? entries[index].path
                                                      : p.basename(
                                                          entries[index].path),
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis)),
                                        )),
                                ]));
                          })),
                ])),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Voltar'))
        ],
      ));
}
