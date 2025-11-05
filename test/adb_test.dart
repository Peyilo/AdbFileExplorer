import 'package:adb_file_explorer/adb/adb.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';

Future<String> exec(AdbShellSession shell, String cmd) async {
  debugPrint('> Running [$cmd]...');
  final res = await shell.run(cmd);
  debugPrint('> Result:\n$res');
  return res;
}

void main() {
  test('AdbShellSession should execute multiple commands with context', () async {
    // start adb shell session
    final shell = AdbShellSession();
    await shell.start();
    expect(shell.isReady, isTrue);

    await exec(shell, "ls -l");
    await exec(shell, "cd sdcard");
    await exec(shell, "ls -l");

    // close the shell session
    await shell.close();
    expect(shell.isReady, isFalse);
  });

  test('should parse adb devices -l output correctly', () async {
    final devices = await Adb.listDevices();
    if (devices.isEmpty) {
      debugPrint("No devices found.");
    } else {
      for (final device in devices) {
        debugPrint(device.serial);
      }
      final adb = Adb(deviceSerial: devices[0].serial);
      final files = await adb.list(path: "/");
      for (final file in files) {
        debugPrint(file.toJson().toString());
      }
    }
  });
}
