import 'package:adb_file_explorer/adb/adb.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  group('AdbClient.listDevices', () {
    test('should parse adb devices -l output correctly', () async {
      final devices = await AdbClient.listDevices();
      if (devices.isEmpty) {
        debugPrint("No devices found.");
      } else {
        for (final device in devices) {
          debugPrint(device.serial);
        }
        final client = AdbClient(deviceSerial: devices[0].serial);
        final files = await client.listDir("/");
        for (final file in files) {
          debugPrint(file.toJson().toString());
        }
      }
    });
    test('AdbShellSession should execute multiple commands with context', () async {
      final shell = AdbShellSession(deviceSerial: 'emulator-5554');
      await shell.start();

      expect(shell.isReady, isTrue);

      debugPrint('> Running ls...');
      final pwd1 = await shell.sendCommand('ls');
      debugPrint('PWD: $pwd1');

      expect(shell.isReady, isFalse);
    });
  });
}
