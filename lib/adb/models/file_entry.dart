import 'dart:convert';

// 解析以下格式的内容：
// lrw-r--r--   1 root   root        30 2009-01-01 00:00 adb_keys -> /product/etc/security/adb_keys
// drwxr-xr-x 101 root   root      2040 2025-11-05 06:26 apex
// lrw-r--r--   1 root   root        11 2009-01-01 00:00 bin -> /system/bin
// drwxr-xr-x  12 root   root       260 2025-11-05 06:26 bootstrap-apex
// lrw-r--r--   1 root   root        50 2009-01-01 00:00 bugreports -> /data/user_de/0/com.android.shell/files/bugreports
// drwxrwx---   2 system cache       27 2009-01-01 00:00 cache
// drwxr-xr-x   3 root   root         0 2025-11-05 06:26 config
// lrw-r--r--   1 root   root        17 2009-01-01 00:00 d -> /sys/kernel/debug
// drwxrwx--x  51 system system    4096 2025-11-05 06:26 data
// d?????????   ? ?      ?            ?                ? data_mirror
// drwxr-xr-x   2 root   root        27 2009-01-01 00:00 debug_ramdisk
// drwxr-xr-x  19 root   root      2720 2025-11-05 06:26 dev
// lrw-r--r--   1 root   root        11 2009-01-01 00:00 etc -> /system/etc
// l?????????   ? ?      ?            ?                ? init -> ?
// -?????????   ? ?      ?            ?                ? init.environ.rc
// d?????????   ? ?      ?            ?                ? linkerconfig
// d?????????   ? ?      ?            ?                ? metadata
// drwxr-xr-x  17 root   system     360 2025-11-05 06:26 mnt
// drwxr-xr-x   2 root   root       199 2009-01-01 00:00 odm
// drwxr-xr-x   2 root   root        42 2009-01-01 00:00 odm_dlkm
// drwxr-xr-x   2 root   root        27 2009-01-01 00:00 oem
// d?????????   ? ?      ?            ?                ? postinstall
// dr-xr-xr-x 411 root   root         0 2025-11-05 06:26 proc
// drwxr-xr-x   9 root   root       151 2009-01-01 00:00 product
// lrw-r--r--   1 root   root        21 2009-01-01 00:00 sdcard -> /storage/self/primary
// drwxr-xr-x   2 root   root        27 2009-01-01 00:00 second_stage_resources
// drwx--x---   5 shell  everybody  100 2025-11-05 06:26 storage
// dr-xr-xr-x  13 root   root         0 2025-11-05 06:26 sys
// drwxr-xr-x  12 root   root       274 2009-01-01 00:00 system
// d?????????   ? ?      ?            ?                ? system_dlkm
// drwxr-xr-x   9 root   root       146 2009-01-01 00:00 system_ext
// drwxrwx--x   2 shell  shell       40 2025-11-05 06:26 tmp
// drwxr-xr-x  12 root   shell      219 2009-01-01 00:00 vendor
// drwxr-xr-x   2 root   root        42 2009-01-01 00:00 vendor_dlkm

class FileEntry {
  final String name;          // 文件名
  final String path;          // 完整路径，例如 /sdcard/Download
  final String type;          // file / dir / symlink / unknown
  final String permissions;   // 权限字符串，如 drwxr-xr-x
  final String owner;         // 所有者
  final String group;         // 所属组
  final int size;             // 文件大小
  final String date;          // 修改时间
  final String? linkTarget;   // 若为符号链接，则保存目标路径

  FileEntry({
    required this.name,
    required this.path,
    required this.type,
    required this.permissions,
    required this.owner,
    required this.group,
    required this.size,
    required this.date,
    this.linkTarget,
  });

  Map<String, dynamic> toJson() => {
    "name": name,
    "path": path,
    "type": type,
    "permissions": permissions,
    "owner": owner,
    "group": group,
    "size": size,
    "date": date,
    "link": linkTarget,
  };

  /// 解析 adb shell "ls -l" 输出为文件列表
  /// [currentPath] 当前所在目录
  /// [excludeUnknown] = true 时过滤无法访问的项
  static List<FileEntry> parseLsOutput(
      String stdout,
      String currentPath, {
        bool excludeUnknown = false,
      }) {
    final lines = const LineSplitter().convert(stdout.trim());
    final entries = <FileEntry>[];

    final regex = RegExp(
      r'^([\-dlspcb?])([rwx\-]{9})\s+\d+\s+(\S+)\s+(\S+)\s+(\d+)\s+(\d{4}-\d{2}-\d{2}|\w{3}\s+\d{1,2})\s+([\d:]+)\s+(.+)$',
    );

    for (final line in lines) {
      if (line.startsWith('total') || line.trim().isEmpty) continue;

      final match = regex.firstMatch(line);
      if (match == null) {
        // 未能匹配（通常是权限不足的情况）
        final name = line.split(' ').last;
        if (!excludeUnknown) {
          final fullPath = _joinPath(currentPath, name);
          entries.add(FileEntry(
            name: name,
            path: fullPath,
            type: 'unknown',
            permissions: '?????????',
            owner: '?',
            group: '?',
            size: 0,
            date: '',
          ));
        }
        continue;
      }

      final typeChar = match.group(1)!;
      final perms = match.group(1)! + match.group(2)!;
      final owner = match.group(3)!;
      final group = match.group(4)!;
      final size = int.tryParse(match.group(5) ?? '0') ?? 0;
      final date = '${match.group(6)} ${match.group(7)}';
      final rawName = match.group(8)!;

      String name = rawName;
      String? linkTarget;

      // 解析符号链接（格式：xxx -> yyy）
      if (typeChar == 'l' && rawName.contains('->')) {
        final parts = rawName.split('->');
        name = parts[0].trim();
        linkTarget = parts[1].trim();
      }

      final type = {
        '-': 'file',
        'd': 'dir',
        'l': 'symlink',
      }[typeChar] ?? 'unknown';

      // 过滤 unknown
      if (excludeUnknown && type == 'unknown') continue;

      final fullPath = _joinPath(currentPath, name);

      entries.add(FileEntry(
        name: name,
        path: fullPath,
        type: type,
        permissions: perms,
        owner: owner,
        group: group,
        size: size,
        date: date,
        linkTarget: linkTarget,
      ));
    }

    return entries;
  }

  /// 拼接路径，避免多余的 "//"
  static String _joinPath(String parent, String child) {
    if (parent.endsWith('/')) return "$parent$child";
    return "$parent/$child";
  }
}
