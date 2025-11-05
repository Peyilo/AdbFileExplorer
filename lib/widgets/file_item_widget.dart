import 'package:flutter/material.dart';
import 'package:adb_file_explorer/adb/models/file_entry.dart';

import 'file_icon.dart';

/// 单行文件信息项（纯展示）
class FileItemWidget extends StatelessWidget {
  final FileEntry entry;

  const FileItemWidget({super.key, required this.entry});

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

  @override
  Widget build(BuildContext context) {
    final icon = entry.type == 'dir'
        ? Icons.folder
        : Icons.insert_drive_file;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
                color: Colors.white,
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
    );
  }
}