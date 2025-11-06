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

  // 你的正则
  final regex = RegExp(
      r'^([\-dlspcb?])([rwxXsStT\-]{9})\s+\d+\s+(\S+)\s+(\S+)\s+(\d+)\s+(\d{4}-\d{2}-\d{2}|\w{3}\s+\d{1,2})\s+([\d:]+)\s+(.+)$'
  );

  test('match ls -l with ISO date (YYYY-MM-DD)', () {
    const line = 'drwxrws--- 18 media_rw media_rw 4096 2025-11-04 21:00 /storage/emulated/0';
    // const line = 'drwxr-x--x 4 root shell 7909 2009-01-01 08:00 /system/bin';

    final m = regex.firstMatch(line);
    expect(m, isNotNull);

    // 逐组断言
    expect(m!.group(1), 'd');                // 类型
    expect(m.group(2), 'rwxrws---');         // 权限9位
    expect(m.group(3), 'media_rw');          // owner
    expect(m.group(4), 'media_rw');          // group
    expect(m.group(5), '4096');              // size
    expect(m.group(6), '2025-11-04');        // 日期
    expect(m.group(7), '21:00');             // 时间
    expect(m.group(8), '/storage/emulated/0'); // 名称/路径

    // 如果你想要完整权限串（含类型位），可自行拼接：
    final permissionsFull = '${m.group(1)}${m.group(2)}';
    expect(permissionsFull, 'drwxrws---');
  });

  test('match ls -l with short date (Mon d)', () {
    // 有些系统会输出类似 "Nov  4 21:00"
    const line = 'drwxrws--- 18 media_rw media_rw 4096 Nov  4 21:00 /storage/emulated/0';

    final m = regex.firstMatch(line);
    expect(m, isNotNull);

    expect(m!.group(1), 'd');
    expect(m.group(2), 'rwxrws---');
    expect(m.group(3), 'media_rw');
    expect(m.group(4), 'media_rw');
    expect(m.group(5), '4096');
    expect(m.group(6), 'Nov  4');   // 注意这里是 "月+空格+日"
    expect(m.group(7), '21:00');
    expect(m.group(8), '/storage/emulated/0');
  });
}
