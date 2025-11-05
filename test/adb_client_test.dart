import 'dart:async';
import 'dart:io';
import 'package:adb_file_explorer/adb/models/adb_device.dart';
import 'package:adb_file_explorer/adb/adb.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';


void main() {
  group('AdbClient.listDevices', () {
    test('should parse adb devices -l output correctly', () async {
      final devices = await AdbClient.listDevices();
      if (devices.isEmpty) {
        debugPrint("No devices found.");
      } else {
        for (final device in devices) {
          debugPrint(device.serial);
        }
        final client = AdbClient(deviceSerial: devices[0].serial);
        final files = await client.listDir("/");
        for (final file in files) {
          debugPrint(file.toJson().toString());
        }
      }
    });
  });
}
