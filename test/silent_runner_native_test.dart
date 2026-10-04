import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final enabled = Platform.isWindows &&
      Platform.environment['RUN_SILENT_RUNNER_NATIVE_TEST'] == '1';
  final runner = File('assets/Repack/V1SilentInstall.exe').absolute.path;
  final probe = File('build/repack-analysis/installer_probe.exe').absolute.path;
  test('Runner passa flags silent e encerra somente auxiliares próprios',
      () async {
    final root = await Directory('test').createTemp('silent-runner-');
    try {
      final process = await Process.start(runner, [
        '--worker',
        '$pid',
        probe,
        root.absolute.path,
        p.join(root.absolute.path, 'install.log')
      ]);
      final stdoutDone = process.stdout.drain<void>();
      final stderrDone = process.stderr.drain<void>();
      expect(await process.exitCode, 0);
      await stdoutDone;
      await stderrDone;
      expect(await File(p.join(root.path, 'complete.txt')).exists(), isTrue);
      final args =
          await File(p.join(root.path, 'arguments.txt')).readAsString();
      for (final flag in [
        '/VERYSILENT',
        '/SUPPRESSMSGBOXES',
        '/NORESTART',
        '/NOICONS',
        '/TASKS='
      ]) {
        expect(args, contains(flag));
      }
      expect(args, contains('/DIR=${root.absolute.path}'));
    } finally {
      await root.delete(recursive: true);
    }
  }, skip: !enabled, timeout: const Timeout(Duration(seconds: 30)));

  test('Cancelar o parent encerra o instalador e seu processo filho', () async {
    final root = await Directory('test').createTemp('silent-cancel-');
    Process? owner;
    try {
      await File(p.join(root.path, 'cancel-case')).writeAsString('fixture');
      owner = await Process.start(probe, ['--wait']);
      final ownerOut = owner.stdout.drain<void>();
      final ownerErr = owner.stderr.drain<void>();
      final process = await Process.start(runner, [
        '--worker',
        '${owner.pid}',
        probe,
        root.absolute.path,
        p.join(root.absolute.path, 'install.log')
      ]);
      final out = process.stdout.drain<void>();
      final err = process.stderr.drain<void>();
      final childFile = File(p.join(root.path, 'child.pid'));
      for (var i = 0; i < 100 && !await childFile.exists(); i++) {
        await Future<void>.delayed(const Duration(milliseconds: 20));
      }
      expect(await childFile.exists(), isTrue);
      final child = int.parse(await childFile.readAsString());
      owner.kill();
      await owner.exitCode;
      await ownerOut;
      await ownerErr;
      expect(await process.exitCode, 3);
      await out;
      await err;
      expect(Process.killPid(child), isFalse,
          reason: 'The child must already have exited with its job.');
      expect(await File(p.join(root.path, 'complete.txt')).exists(), isFalse);
    } finally {
      owner?.kill();
      await root.delete(recursive: true);
    }
  }, skip: !enabled, timeout: const Timeout(Duration(seconds: 30)));
}
