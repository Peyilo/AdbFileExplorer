import 'dart:io';

import 'package:flutter/foundation.dart';
import "models/file_entry.dart";
import "models/adb_device.dart";

class AdbClient {
  static const String _defaultAdbPath = "adb";

  final String adbPath;
  String? deviceSerial;

  AdbClient({
    this.adbPath = _defaultAdbPath,
    this.deviceSerial,
  });

  /// 列出所有 ADB 设备（详细信息）
  static Future<List<AdbDevice>> listDevices({String adbPath = _defaultAdbPath}) async {
    final result = await Process.run(adbPath, ['devices', '-l']);
    final stdoutStr = result.stdout.toString().trim();

    final lines = stdoutStr.split('\n');
    final devices = <AdbDevice>[];

    for (final line in lines.skip(1)) {
      final trimmed = line.trim();
      if (trimmed.isEmpty || trimmed.startsWith('*')) continue;

      // 只解析状态为 "device" 的行
      if (!trimmed.contains(RegExp(r'\bdevice\b'))) continue;

      try {
        final device = AdbDevice.parse(trimmed);
        devices.add(device);
      } catch (e) {
        // 打印调试信息，不中断整个列表
        if (kDebugMode) {
          print('Failed to parse ADB device line: $trimmed ($e)');
        }
      }
    }

    return devices;
  }

  Future<String> shell(String cmd) async {
    final args = [
      if (deviceSerial != null) '-s',
      if (deviceSerial != null) deviceSerial!,
      'shell',
      cmd
    ];
    final result = await Process.run(adbPath, args);
    if (result.exitCode != 0) throw Exception(result.stderr);
    return result.stdout.toString();
  }

  /// 列出指定目录下的文件（使用 adb shell ls -l）
  /// 自动忽略权限错误，返回结构化的 [FileEntry] 列表。
  Future<List<FileEntry>> listDir(String path) async {
    try {
      final out = await shell('ls -l "$path" 2>/dev/null || true');
      final files = FileEntry.parseLsOutput(
        out,
        path,
        excludeUnknown: true, // 过滤掉权限不足、解析失败的项
      );

      // 排序：目录优先，再按名称排序
      files.sort((a, b) {
        if (a.type == b.type) {
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        }
        if (a.type == 'dir') return -1;
        if (b.type == 'dir') return 1;
        return 0;
      });

      return files;
    } catch (e) {
      debugPrint("listDir 出错: $e");
      return [];
    }
  }

  Future<void> pull(String remote, String local) async {
    final args = [
      if (deviceSerial != null) '-s',
      if (deviceSerial != null) deviceSerial!,
      'pull',
      remote,
      local
    ];
    final proc = await Process.start(adbPath, args);
    await stdout.addStream(proc.stdout);
    await stderr.addStream(proc.stderr);
    await proc.exitCode;
  }

  Future<void> push(String local, String remote) async {
    final args = [
      if (deviceSerial != null) '-s',
      if (deviceSerial != null) deviceSerial!,
      'push',
      local,
      remote
    ];
    final proc = await Process.start(adbPath, args);
    await stdout.addStream(proc.stdout);
    await stderr.addStream(proc.stderr);
    await proc.exitCode;
  }

  Future<void> mkdir(String path) async => await shell('mkdir -p "$path"');

  Future<void> rm(String path, {bool recursive = false}) async =>
      await shell('rm ${recursive ? "-rf" : "-f"} "$path"');
}
