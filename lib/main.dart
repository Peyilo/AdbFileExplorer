import 'package:flutter/material.dart';
import "./adb/adb_client.dart";

void main() async {
  var devices = await AdbClient.listDevices();
  var client = AdbClient(deviceSerial: devices[0].serial);
  var files = await client.listDir("/");
  runApp(const AdbFileExplorer());
}

class AdbFileExplorer extends StatelessWidget {
  const AdbFileExplorer({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ADB 文件管理器 1',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const Padding(padding: EdgeInsets.all(8.0)),
    );
  }
}