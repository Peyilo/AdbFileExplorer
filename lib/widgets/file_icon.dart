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
    if (entry.getResolvedType() == 'dir') return Icons.folder_outlined;
    return Icons.subject_sharp;
  }

  Color _getBaseColor(BuildContext context) {
    return Colors.grey.shade200;
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
            right: -size * 0.1,
            bottom: size * 0.55,
            child: Icon(
              Icons.north_east_rounded,
              size: size * 0.5,
              color: baseColor,
            ),
          ),
      ],
    );
  }
}