import 'package:flutter/material.dart';
import 'package:adb_file_explorer/widgets/file_item_widget.dart';
import 'package:adb_file_explorer/adb/adb.dart';

void main() async {
  final adb = Adb(adbPath: "/Users/Peyilo/Library/Android/sdk/platform-tools/adb");
  final devices = await Adb.listDevices();
  if (devices.isEmpty) {
    throw Exception("No ADB devices found.");
  }
  adb.deviceSerial = devices.first.serial;
  final files = await adb.list();
  runApp(AdbFileExplorerApp(files: files));
}

class AdbFileExplorerApp extends StatelessWidget {
  final List<FileEntry> files;

  const AdbFileExplorerApp({super.key, required this.files});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ADB File Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: FileExplorerHome(files: files),
    );
  }
}

class FileExplorerHome extends StatelessWidget {
  final List<FileEntry> files;

  const FileExplorerHome({super.key, required this.files});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('ADB File Explorer (/)')),
      body: files.isEmpty
          ? const Center(child: Text('No files found'))
          : ListView.builder(
        itemCount: files.length,
        itemBuilder: (context, index) {
          final file = files[index];
          return FileItemWidget(entry: file);
        },
      ),
    );
  }
}