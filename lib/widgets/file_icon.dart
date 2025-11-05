import 'package:flutter/material.dart';
import 'package:adb_file_explorer/adb/models/file_entry.dart';

/// 文件图标组件：根据 FileEntry 类型自动选择主图标与颜色，
/// 并在符号链接上叠加箭头标识。
class FileIcon extends StatelessWidget {
  final FileEntry entry;
  final double size;

  const FileIcon({
    super.key,
    required this.entry,
    this.size = 22,
  });

  IconData _getBaseIcon() {
    if (entry.type == 'dir') return Icons.folder_rounded;
    if (entry.type == 'symlink') return Icons.folder_rounded; // 链接仍显示原文件类型
    final name = entry.name.toLowerCase();
    if (name.endsWith('.apk')) return Icons.android_rounded;
    if (name.endsWith('.so')) return Icons.memory_rounded;
    if (name.endsWith('.txt') || name.endsWith('.log')) return Icons.description_rounded;
    if (name.endsWith('.xml')) return Icons.code_rounded;
    if (name.endsWith('.png') || name.endsWith('.jpg') || name.endsWith('.jpeg')) {
      return Icons.image_rounded;
    }
    if (name.endsWith('.zip') || name.endsWith('.tar') || name.endsWith('.gz')) {
      return Icons.archive_rounded;
    }
    return Icons.insert_drive_file_rounded;
  }

  Color _getBaseColor(BuildContext context) {
    if (entry.type == 'dir') return Colors.amberAccent.shade200;
    if (entry.type == 'symlink') return Colors.cyanAccent.shade200;

    final name = entry.name.toLowerCase();
    if (name.endsWith('.apk')) return Colors.greenAccent.shade400;
    if (name.endsWith('.so')) return Colors.orangeAccent.shade200;
    if (name.endsWith('.png') || name.endsWith('.jpg') || name.endsWith('.jpeg')) {
      return Colors.lightBlueAccent.shade100;
    }
    if (name.endsWith('.xml')) return Colors.purpleAccent.shade100;
    if (name.endsWith('.txt') || name.endsWith('.log')) return Colors.grey.shade300;
    if (name.endsWith('.zip') || name.endsWith('.tar') || name.endsWith('.gz')) {
      return Colors.blueGrey.shade300;
    }
    return Colors.grey.shade400;
  }

  @override
  Widget build(BuildContext context) {
    final baseIcon = _getBaseIcon();
    final baseColor = _getBaseColor(context);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(baseIcon, size: size, color: baseColor),
        if (entry.type == 'symlink')
          Positioned(
            right: -1,
            bottom: -1,
            child: Icon(
              Icons.north_east_rounded,
              size: size * 0.5,
              color: Colors.cyanAccent.shade100,
            ),
          ),
      ],
    );
  }
}