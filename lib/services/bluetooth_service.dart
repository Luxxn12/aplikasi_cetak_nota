import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService extends ChangeNotifier {
  BluetoothService._();
  static final instance = BluetoothService._();

  final BluetoothPrint _printer = BluetoothPrint.instance;
  List<BluetoothDevice> devices = [];
  BluetoothDevice? connectedDevice;
  bool isScanning = false;

  Future<void> ensurePermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.locationWhenInUse,
    ].request();
  }

  Future<void> refreshDevices() async {
    await ensurePermissions();
    isScanning = true;
    notifyListeners();
    // Start scan for a short time and collect results
    await _printer.startScan(timeout: const Duration(seconds: 4));
    final sub = _printer.scanResults.listen((result) {
      devices = result;
      notifyListeners();
    });
    await Future.delayed(const Duration(seconds: 4));
    await _printer.stopScan();
    await sub.cancel();
    isScanning = false;
    notifyListeners();
  }

  Future<bool> connect(BluetoothDevice device) async {
    try {
      await _printer.connect(device);
      connectedDevice = device;
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> disconnect() async {
    await _printer.disconnect();
    connectedDevice = null;
    notifyListeners();
  }

  Future<void> printImageBytes(Uint8List pngBytes) async {
    if (connectedDevice == null) throw Exception('Printer belum terhubung');
    final labelConfig = await _buildLabelConfig(pngBytes);
    final base64Img = base64Encode(pngBytes);
    final List<LineText> lines = [
      LineText(
        type: LineText.TYPE_IMAGE,
        content: base64Img,
        align: LineText.ALIGN_CENTER,
        linefeed: 1,
        x: 0,
        y: 0,
      ),
    ];
    await _printer.printLabel(labelConfig, lines);
  }

  Future<Map<String, dynamic>> _buildLabelConfig(Uint8List pngBytes) async {
    const dotsPerMillimeter = 8; // 203 dpi printers => 8 dots ≈ 1mm
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    final image = frame.image;
    final widthPx = image.width;
    final heightPx = image.height;
    image.dispose();
    codec.dispose();

    final widthMm = (widthPx / dotsPerMillimeter).ceil();
    final heightMm = (heightPx / dotsPerMillimeter).ceil();

    return <String, dynamic>{'width': widthMm, 'height': heightMm, 'gap': 0};
  }
}
