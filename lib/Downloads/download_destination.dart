import 'dart:io';
import 'dart:ffi';
import 'package:ffi/ffi.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:win32/win32.dart';
import '../Interface/launcher_pad_scope.dart';

/// Espaço disponível ao usuário atual, incluindo eventuais cotas do Windows.
int? freeDownloadDriveBytes(String drive) {
  if (!Platform.isWindows || !RegExp(r'^[a-zA-Z]:[\\/]$').hasMatch(drive)) {
    return null;
  }
  final path = drive.toNativeUtf16();
  final available = calloc<Uint64>();
  try {
    return GetDiskFreeSpaceEx(path, available, nullptr, nullptr) != 0
        ? available.value
        : null;
  } finally {
    calloc.free(available);
    calloc.free(path);
  }
}

Future<List<String>> availableDownloadDrives() async {
  final drives = <String>[];
  for (var code = 65; code <= 90; code++) {
    final root = '${String.fromCharCode(code)}:\\';
    try {
      if (await Directory(root).exists()) drives.add(root);
    } on FileSystemException {
      // Unidades desconectadas não impedem a escolha dos outros discos.
    }
  }
  return drives;
}

String gameDownloadDirectory(String drive, String gameName, String gameId) {
  if (!RegExp(r'^[a-zA-Z]:[\\/]$').hasMatch(drive)) {
    throw StateError('Selecione a raiz de um disco disponível.');
  }
  var name = gameName
      .replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1f]'), '_')
      .replaceAll(RegExp(r'[. ]+$'), '')
      .trim();
  if (name.isEmpty) name = 'Jogo';
  if (name.length > 100) name = name.substring(0, 100).trim();
  // O identificador distingue edições e evita misturar downloads do mesmo jogo.
  return p.windows.join(drive, 'V1 Jogos', '$name - ${gameId.substring(0, 8)}');
}

Future<String?> selectDownloadDrive(BuildContext context, String gameName,
        {Future<List<String>> Function()? loadDrives, bool enablePad = true}) =>
    showDialog<String>(
        context: context,
        builder: (_) => _DrivePicker(
            gameName: gameName,
            loadDrives: loadDrives ?? availableDownloadDrives,
            enablePad: enablePad));

class _DrivePicker extends StatefulWidget {
  final String gameName;
  final Future<List<String>> Function() loadDrives;
  final bool enablePad;
  const _DrivePicker(
      {required this.gameName,
      required this.loadDrives,
      required this.enablePad});
  @override
  State<_DrivePicker> createState() => _DrivePickerState();
}

class _DrivePickerState extends State<_DrivePicker> {
  late Future<List<String>> _drives;
  final _freeBytes = <String, int?>{};

  Future<List<String>> _loadDrives() async {
    final drives = await widget.loadDrives();
    _freeBytes.clear();
    for (final drive in drives) {
      _freeBytes[drive] = freeDownloadDriveBytes(drive);
    }
    return drives;
  }

  @override
  void initState() {
    super.initState();
    _drives = _loadDrives();
  }

  @override
  Widget build(BuildContext context) => LauncherPadScope(
      menu: false,
      enabled: widget.enablePad,
      child: AlertDialog(
        title: const Text('Onde baixar o jogo?'),
        content: SizedBox(
            width: 520,
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(widget.gameName),
                  const SizedBox(height: 8),
                  const Text(
                      'Escolha um disco. O jogo será salvo em V1 Jogos, dentro de uma pasta própria.'),
                  const SizedBox(height: 20),
                  Flexible(
                      child: FutureBuilder<List<String>>(
                          future: _drives,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState !=
                                ConnectionState.done) {
                              return const Padding(
                                  padding: EdgeInsets.all(24),
                                  child: Center(
                                      child: CircularProgressIndicator()));
                            }
                            if (snapshot.hasError ||
                                (snapshot.data?.isEmpty ?? true)) {
                              return Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Text(
                                        'Nenhum disco acessível. Verifique as unidades e tente novamente.'),
                                    TextButton(
                                        autofocus: true,
                                        onPressed: () => setState(() {
                                              _drives = _loadDrives();
                                            }),
                                        child: const Text('Atualizar discos')),
                                  ]);
                            }
                            final drives = snapshot.data!;
                            return SingleChildScrollView(
                                child: Column(children: [
                              for (var index = 0;
                                  index < drives.length;
                                  index++)
                                Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: OutlinedButton.icon(
                                        key: ValueKey(
                                            'download-drive-${drives[index]}'),
                                        autofocus: index == 0,
                                        onPressed: () => Navigator.pop(
                                            context, drives[index]),
                                        icon: const Icon(Icons.storage_rounded),
                                        label: SizedBox(
                                            width: double.infinity,
                                            child: Wrap(
                                              spacing: 8,
                                              runSpacing: 4,
                                              crossAxisAlignment:
                                                  WrapCrossAlignment.center,
                                              children: [
                                                Text(
                                                    'Disco ${drives[index].substring(0, 2)}'),
                                                Text(
                                                  _freeBytes[drives[index]] ==
                                                          null
                                                      ? 'Espaço livre indisponível'
                                                      : '${(_freeBytes[drives[index]]! / (1024 * 1024 * 1024)).toStringAsFixed(1).replaceAll('.', ',')} GB livres',
                                                  style: const TextStyle(
                                                      color: Colors.yellow),
                                                ),
                                                const Text('• V1 Jogos'),
                                              ],
                                            )))),
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
