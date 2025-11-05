// 解析以下内容：
// emulator-5554          device product:sdk_gphone64_x86_64 model:sdk_gphone64_x86_64 device:emu64xa transport_id:1
// emulator-5556          device product:sdk_gphone_x86_arm model:AOSP_on_IA_Emulator device:generic_x86_arm transport_id:2
class AdbDevice {
  final String serial;
  final String product;
  final String model;
  final String device;
  final int transportId;

  AdbDevice({
    required this.serial,
    required this.product,
    required this.model,
    required this.device,
    required this.transportId,
  });

  factory AdbDevice.parse(String line) {
    final parts = line.split(RegExp(r'\s+'));
    return AdbDevice(
      serial: parts[0],
      product: _extract(parts, 'product'),
      model: _extract(parts, 'model'),
      device: _extract(parts, 'device'),
      transportId: int.parse(_extract(parts, 'transport_id')),
    );
  }

  static String _extract(List<String> parts, String key) {
    final part = parts.firstWhere((p) => p.startsWith('$key:'), orElse: () => '');
    return part.isEmpty ? '' : part.split(':')[1];
  }
}
