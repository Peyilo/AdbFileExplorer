import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import "models/file_entry.dart";
import "models/adb_device.dart";

export 'models/file_entry.dart';
export "models/adb_device.dart";

class Adb {
  static const String _defaultAdbPath = "adb";

  final String adbPath;
  String? deviceSerial;

  late final AdbShellExecutor _shellExecutor;

  Adb({
    this.adbPath = _defaultAdbPath,
    this.deviceSerial,
  }) {
    _shellExecutor = AdbShellExecutor(
      adbPath: adbPath,
      deviceSerial: deviceSerial,
    );
  }

  Future<String> run(String cmd) async {
    return _shellExecutor.run(cmd);
  }

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

  /// 列出指定目录下的文件（使用 adb shell ls -l）
  /// 自动忽略权限错误，返回结构化的 [FileEntry] 列表。
  Future<List<FileEntry>> list({String path = "/"}) async {
    final out = await run('ls -l "$path" 2>/dev/null || true');
    final files = FileEntry.parseLsOutput(
      out,
      path,
      excludeUnknown: true, // 过滤掉权限不足、解析失败的项
    );

    // 确定files中type为symlink的项的linkTarget
    final symlinks = files.where((f) => f.type == 'symlink' && f.linkTarget != null);
    for (final link in symlinks) {
      final targetPath = link.linkTarget!.path;

      // 用 ls -ld 查询目标类型（不跟随链接）
      final targetOut = await run('ls -ld "$targetPath" 2>/dev/null || true');
      final targetList = FileEntry.parseLsOutput(targetOut, path);
      if (targetList.isNotEmpty) {
        final targetEntry = targetList.first;
        link.linkTarget = targetEntry;
      }
    }

    // 排序
    int typeOrder(String type) {
      if (type == 'dir') return 0;
      if (type == 'file') return 1;
      return 3;             // unknown 或坏链接
    }
    files.sort((a, b) {
      final orderA = typeOrder(a.getResolvedType());
      final orderB = typeOrder(b.getResolvedType());
      if (orderA != orderB) return orderA.compareTo(orderB);
      return a.name.toLowerCase().compareTo(b.name.toLowerCase());
    });

    return files;
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

  Future<void> mkdir(String path) async => await run('mkdir -p "$path"');

  Future<void> rm(String path, {bool recursive = false}) async =>
      await run('rm ${recursive ? "-rf" : "-f"} "$path"');
}

// 一个保持上下文的 ADB shell 会话类
class AdbShellSession {
  final String adbPath;
  final String? deviceSerial;
  late Process _process;
  final _outputController = StreamController<String>.broadcast();

  bool _isReady = false;
  bool get isReady => _isReady;

  AdbShellSession({this.adbPath = 'adb', this.deviceSerial});

  /// 启动 adb shell 并保持连接
  /// 实际上做的是：启动一个可持续交互的 ADB shell 子进程，并建立 Dart 与 shell 之间的输入输出通道。
  Future<void> start() async {
    final args = [
      if (deviceSerial != null) '-s',
      if (deviceSerial != null) deviceSerial!,
      'shell'
    ];

    _process = await Process.start(adbPath, args, mode: ProcessStartMode.normal);

    // 监听输出
    _process.stdout
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      _outputController.add(line);
    });

    _process.stderr
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .listen((line) {
      _outputController.add('ERR: $line');
    });

    _isReady = true;
  }

  /// 执行命令（保持上下文）
  Future<String> run(String cmd) async {
    if (!_isReady) throw Exception("ADB shell not started.");

    final completer = Completer<String>();
    final buffer = StringBuffer();

    // 生成唯一标记，避免与普通文本冲突
    final marker = '__CMD_DONE_${DateTime.now().millisecondsSinceEpoch}__';

    StreamSubscription<String>? sub;
    sub = _outputController.stream.listen((line) {
      if (line.contains(marker)) {
        // 收到标记 -> 命令执行结束
        sub?.cancel();
        completer.complete(buffer.toString().trim());
        return;
      }
      buffer.writeln(line);
    });

    // 向 shell 写入命令并附带结束标记
    // 注意：需要加分号和换行
    _process.stdin.writeln('$cmd; echo $marker');
    _process.stdin.writeln(); // 保证 flush

    return completer.future;
  }

  /// 关闭 adb shell 连接
  Future<void> close() async {
    _process.stdin.writeln('exit');
    _process.kill(ProcessSignal.sigterm);
    await _outputController.close();
    _isReady = false;
  }
}

/// 执行单次 ADB shell 命令的轻量级工具类
///
/// 每次调用都会启动一次新的 adb shell 进程执行命令，
/// 命令执行完立即退出，不保持上下文。
class AdbShellExecutor {
  final String adbPath;
  final String? deviceSerial;

  const AdbShellExecutor({
    this.adbPath = 'adb',
    this.deviceSerial,
  });

  /// 执行一次性 shell 命令（执行后立即退出）
  ///
  /// 相当于：`adb [-s <serial>] shell "<cmd>"`
  /// 返回命令标准输出（去除多余空白）
  Future<String> run(String cmd) async {
    final args = [
      if (deviceSerial != null) '-s',
      if (deviceSerial != null) deviceSerial!,
      'shell',
      cmd,
    ];

    // 启动 adb 子进程并等待执行完毕
    final result = await Process.run(adbPath, args);

    if (result.exitCode != 0) {
      final err = result.stderr.toString().trim();
      throw Exception('ADB shell failed (code=${result.exitCode}): $err');
    }

    return result.stdout.toString().trim();
  }
}
