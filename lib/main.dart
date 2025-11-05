import 'package:flutter/material.dart';

void main() async {
  runApp(const AdbFileExplorer());
}

class AdbFileExplorer extends StatelessWidget {
  const AdbFileExplorer({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Adb File Explorer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark(useMaterial3: true),
      home: const Padding(padding: EdgeInsets.all(8.0)),
    );
  }
}