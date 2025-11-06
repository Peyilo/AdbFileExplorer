import 'package:flutter/material.dart';
import 'package:adb_file_explorer/adb/models/file_entry.dart';
import 'file_icon.dart';

/// 文件列表项组件：
/// - 单击选中
/// - 双击打开（文件/目录）
class FileItemWidget extends StatefulWidget {
  final FileEntry entry;
  final bool selected;
  final VoidCallback? onOpen;   // 双击打开
  final VoidCallback? onSelect; // 单击选中

  const FileItemWidget({
    super.key,
    required this.entry,
    this.selected = false,
    this.onOpen,
    this.onSelect,
  });

  @override
  State<FileItemWidget> createState() => _FileItemWidgetState();
}

class _FileItemWidgetState extends State<FileItemWidget> {
  late DateTime _lastTapTime;

  @override
  void initState() {
    super.initState();
    _lastTapTime = DateTime.now();
  }

  String _formatSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    const units = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size >= 1024 && i < units.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(1)} ${units[i]}';
  }

  void _handleTap() {
    final now = DateTime.now();
    final diff = now.difference(_lastTapTime);
    _lastTapTime = now;

    if (diff.inMilliseconds < 300) {
      // 双击
      widget.onOpen?.call();
    } else {
      // 单击
      widget.onSelect?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final selected = widget.selected;

    final bgColor = selected
        ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
        : Colors.transparent;

    final textColor = selected
        ? Theme.of(context).colorScheme.primary
        : Colors.white;

    return InkWell(
      onTap: _handleTap,
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          children: [
            FileIcon(entry: entry),
            const SizedBox(width: 10),
            Expanded(
              flex: 3,
              child: Text(
                entry.name,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: textColor,
                  fontWeight:
                  entry.type == 'dir' ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
            SizedBox(
              width: 140,
              child: Text(
                entry.permissions,
                style: TextStyle(color: Colors.grey[400], fontFamily: 'monospace'),
              ),
            ),
            SizedBox(
              width: 140,
              child: Text(
                entry.date,
                style: TextStyle(color: Colors.grey[400]),
              ),
            ),
            SizedBox(
              width: 80,
              child: Align(
                alignment: Alignment.centerRight,
                child: Text(
                  _formatSize(entry.size),
                  style: TextStyle(color: Colors.grey[400]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}