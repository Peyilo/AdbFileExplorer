import 'package:flutter/material.dart';
import 'package:adb_file_explorer/adb/adb.dart';
import 'package:adb_file_explorer/widgets/file_item_widget.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final adb = Adb();
  final devices = await Adb.listDevices();
  if (devices.isEmpty) {
    throw Exception("No ADB devices found.");
  }
  adb.deviceSerial = devices.first.serial;

  runApp(AdbFileExplorerApp(adb: adb));
}

class AdbFileExplorerApp extends StatelessWidget {
  final Adb adb;

  const AdbFileExplorerApp({super.key, required this.adb});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ADB File Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: FileExplorerHome(adb: adb),
    );
  }
}

class FileExplorerHome extends StatefulWidget {
  final Adb adb;

  const FileExplorerHome({super.key, required this.adb});

  @override
  State<FileExplorerHome> createState() => _FileExplorerHomeState();
}

class _FileExplorerHomeState extends State<FileExplorerHome> {
  List<FileEntry> _files = [];
  String _currentPath = "/storage/emulated/0";
  int? _selectedIndex;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadDirectory(_currentPath);
  }

  Future<void> _loadDirectory(String path) async {
    setState(() {
      _loading = true;
      _selectedIndex = null;
    });

    try {
      final files = await widget.adb.list(path: path);
      setState(() {
        _files = files;
        _currentPath = path;
      });
    } catch (e) {
      debugPrint("❌ 加载目录失败: $e");
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _enterDirectory(String path) async {
    await _loadDirectory(path);
  }

  void _openFile(String path) {
    // TODO：将文件传到本地临时文件夹内，并使用系统默认程序打开
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('打开文件: $path')),
    );
  }

  void _goParentDirectory() {
    if (_currentPath == '/' || _currentPath == '') return;
    final parent = _currentPath.substring(0, _currentPath.lastIndexOf('/'));
    _loadDirectory(parent.isEmpty ? '/' : parent);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('ADB File Explorer ($_currentPath)'),
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_upward),
            tooltip: '返回上级目录',
            onPressed: _goParentDirectory,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _files.isEmpty
          ? const Center(child: Text('No files found'))
          : ListView.builder(
        itemCount: _files.length,
        itemBuilder: (context, index) {
          final file = _files[index];
          return FileItemWidget(
            entry: file,
            selected: _selectedIndex == index,
            onSelect: () {
              setState(() => _selectedIndex = index);
            },
            onOpen: () {
              if (file.type == 'dir') {
                _enterDirectory(file.path);
              } else if (file.getResolvedType() == 'dir') {
                _enterDirectory(file.linkTarget!.path);
              } else {
                _openFile(file.path);
              }
            },
          );
        },
      ),
    );
  }
}