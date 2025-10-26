import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:bluetooth_print/bluetooth_print.dart';
import 'package:bluetooth_print/bluetooth_print_model.dart';
import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

class BluetoothService extends ChangeNotifier {
  BluetoothService._() {
    _applyBy482btDefaults();
  }

  static final instance = BluetoothService._();

  static const double _hardwareMarginMm = 0.5;

  final BluetoothPrint _printer = BluetoothPrint.instance;
  List<BluetoothDevice> devices = [];
  BluetoothDevice? connectedDevice;
  bool isScanning = false;

  double _dotsPerMillimeter = 8.0; // 203 dpi default
  double _targetWidthMm = 90.0;
  double _targetHeightMm = 115.0;
  bool _autoRotate = false;

  double _binarizationThreshold = 170.0;
  int _tscDensityIndex = 9;
  int _tscSpeedIndex = 3;
  double _offsetXMm = 0;
  double _offsetYMm = 0;
  double _outerMarginMm = 1.5;
  double _trailingFeedReductionMm = 0;
  bool _autoTear = false;

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

  void setMaxPrintWidthDots(int dots) {
    if (dots <= 0) return;
    _targetWidthMm = dots / _dotsPerMillimeter;
    notifyListeners();
  }

  void setPrintWidthMillimeters(double mm) {
    if (mm <= 0) return;
    _targetWidthMm = mm;
    _targetHeightMm = 0;
    notifyListeners();
  }

  void setPrintSize({required double widthMm, required double heightMm}) {
    if (widthMm <= 0) return;
    _targetWidthMm = widthMm;
    _targetHeightMm = heightMm > 0 ? heightMm : 0;
    notifyListeners();
  }

  void setDotsPerMillimeter(double value) {
    if (value <= 0) return;
    _dotsPerMillimeter = value;
    notifyListeners();
  }

  void setAutoRotate(bool value) {
    _autoRotate = value;
    notifyListeners();
  }

  void setBinarizationThreshold(double threshold) {
    final sanitized = threshold.clamp(0.0, 255.0);
    if ((sanitized - _binarizationThreshold).abs() < 0.5) return;
    _binarizationThreshold = sanitized;
    notifyListeners();
  }

  void setPrintDensity(int index) {
    final sanitized = index < 0 ? 0 : (index > 15 ? 15 : index);
    if (sanitized == _tscDensityIndex) return;
    _tscDensityIndex = sanitized;
    notifyListeners();
  }

  void setPrintSpeed(int index) {
    final sanitized = index < 0 ? 0 : (index > 9 ? 9 : index);
    if (sanitized == _tscSpeedIndex) return;
    _tscSpeedIndex = sanitized;
    notifyListeners();
  }

  void setLabelOffset({double? xMm, double? yMm}) {
    var changed = false;
    if (xMm != null && (xMm - _offsetXMm).abs() > 0.001) {
      _offsetXMm = xMm;
      changed = true;
    }
    if (yMm != null && (yMm - _offsetYMm).abs() > 0.001) {
      _offsetYMm = yMm;
      changed = true;
    }
    if (changed) notifyListeners();
  }

  void setAutoTear(bool value) {
    if (_autoTear == value) return;
    _autoTear = value;
    notifyListeners();
  }

  void setOuterMargin(double mm) {
    final sanitized = math.max(0.0, mm);
    if ((sanitized - _outerMarginMm).abs() < 0.001) return;
    _outerMarginMm = sanitized;
    notifyListeners();
  }

  void setTrailingFeedReduction(double mm) {
    final sanitized = math.max(0.0, mm);
    if ((sanitized - _trailingFeedReductionMm).abs() < 0.01) return;
    _trailingFeedReductionMm = sanitized;
    notifyListeners();
  }

  void applyBy482btPreset() {
    _applyBy482btDefaults();
    notifyListeners();
  }

  Future<void> printImageBytes(Uint8List pngBytes) async {
    if (connectedDevice == null) throw Exception('Printer belum terhubung');
    final isConnected = await _printer.isConnected ?? false;
    if (!isConnected) throw Exception('Printer belum siap menerima data');

    final printable = await _preparePrintableImage(pngBytes);
    final base64Img = base64Encode(printable.bytes);
    final config = _buildLabelConfig(printable);
    final configWidthMm = (config['width'] as int).toDouble();
    final configHeightMm = (config['height'] as int).toDouble();
    final labelWidthDots = (configWidthMm * _dotsPerMillimeter).round();
    final labelHeightDots = (configHeightMm * _dotsPerMillimeter).round();
    final widthScale = labelWidthDots / printable.widthPx;
    final heightScale = labelHeightDots / printable.heightPx;
    final scale = math.min(1.0, math.min(widthScale, heightScale));
    final displayWidth = (printable.widthPx * scale).round().clamp(
      1,
      labelWidthDots,
    );
    final displayHeight = (printable.heightPx * scale).round().clamp(
      1,
      labelHeightDots,
    );
    final maxX = math.max(0, labelWidthDots - displayWidth);
    final maxY = math.max(0, labelHeightDots - displayHeight);
    final baseX = (labelWidthDots - displayWidth) ~/ 2;
    final baseY = 0; // Align to top; leftover height stays as trailing feed.
    final offsetXDots = (_offsetXMm * _dotsPerMillimeter).round();
    final offsetYDots = (_offsetYMm * _dotsPerMillimeter).round();
    final startX = math.min(math.max(baseX + offsetXDots, 0), maxX);
    final startY = math.min(math.max(baseY + offsetYDots, 0), maxY);

    final lines = [
      LineText(
        type: LineText.TYPE_IMAGE,
        content: base64Img,
        width: displayWidth,
        height: displayHeight,
        x: startX,
        y: startY,
        linefeed: 0,
        align: LineText.ALIGN_LEFT,
      ),
    ];

    await _printer.printLabel(config, lines);
  }

  Future<_PrintableImage> _preparePrintableImage(Uint8List pngBytes) async {
    final codec = await ui.instantiateImageCodec(pngBytes);
    final frame = await codec.getNextFrame();
    final original = frame.image;

    ui.Image working = original;
    ui.Image? rotated;
    ui.Image? scaled;

    final hasHeightTarget = _targetHeightMm > 0;
    final targetLandscape =
        hasHeightTarget ? _targetWidthMm >= _targetHeightMm : true;
    final imageLandscape = working.width >= working.height;
    final shouldRotate = _autoRotate && targetLandscape != imageLandscape;

    if (shouldRotate) {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      canvas.translate(working.height.toDouble(), 0);
      canvas.rotate(math.pi / 2);
      canvas.drawImage(working, ui.Offset.zero, ui.Paint());
      final picture = recorder.endRecording();
      rotated = await picture.toImage(working.height, working.width);
      picture.dispose();
      working = rotated;
    }

    final targetWidthMm =
        _targetWidthMm > 0
            ? _targetWidthMm
            : working.width / _dotsPerMillimeter;
    final contentWidthMm = math.max(
      1.0,
      targetWidthMm - (_outerMarginMm * 2) - (_hardwareMarginMm * 2),
    );
    final maxWidthDots = (contentWidthMm * _dotsPerMillimeter).round().clamp(
      1,
      9999,
    );

    double scale;
    if (hasHeightTarget) {
      final targetHeightMm =
          _targetHeightMm > 0
              ? _targetHeightMm
              : working.height / _dotsPerMillimeter;
      final contentHeightMm = math.max(
        1.0,
        targetHeightMm - (_outerMarginMm * 2) - (_hardwareMarginMm * 2),
      );
      final maxHeightDots = (contentHeightMm * _dotsPerMillimeter)
          .round()
          .clamp(1, 9999);
      scale = math.min(
        maxWidthDots / working.width,
        maxHeightDots / working.height,
      );
    } else {
      scale = maxWidthDots / working.width;
    }
    if (scale > 1) scale = 1;

    ui.Image output = working;
    if ((scale - 1).abs() > 0.01) {
      final recorder = ui.PictureRecorder();
      final canvas = ui.Canvas(recorder);
      final paint = ui.Paint()..filterQuality = ui.FilterQuality.high;
      canvas.scale(scale, scale);
      canvas.drawImage(working, ui.Offset.zero, paint);
      final picture = recorder.endRecording();
      final targetWidth = (working.width * scale).round();
      final targetHeight = (working.height * scale).round();
      scaled = await picture.toImage(targetWidth, targetHeight);
      picture.dispose();
      output = scaled;
    }

    final padded = await _padWithMargin(output);
    final expanded = await _expandToTargetCanvas(padded);

    final monochrome = await _ditherToMonochrome(expanded);
    final normalized = await _enforceWidthMultipleOf8(monochrome);

    final byteData = await normalized.toByteData(
      format: ui.ImageByteFormat.png,
    );
    final bytes = byteData!.buffer.asUint8List();
    final width = normalized.width;
    final height = normalized.height;

    final widthMm = width / _dotsPerMillimeter;
    final heightMm = height / _dotsPerMillimeter;

    _disposeUnique([
      normalized,
      monochrome,
      padded,
      output,
      expanded,
      scaled,
      rotated,
      original,
    ]);
    codec.dispose();

    return _PrintableImage(
      bytes: bytes,
      widthPx: width,
      heightPx: height,
      widthMm: widthMm,
      heightMm: heightMm,
    );
  }

  Map<String, dynamic> _buildLabelConfig(_PrintableImage image) {
    int widthMm;
    int heightMm;
    if (_targetHeightMm > 0) {
      widthMm = _targetWidthMm.round();
      heightMm = _targetHeightMm.round();
    } else {
      widthMm = _targetWidthMm.round();
      final aspect = image.heightPx / image.widthPx;
      heightMm = math.max(1, (widthMm * aspect).round());
    }
    if (widthMm < 1) widthMm = 1;
    if (widthMm > 999) widthMm = 999;
    if (heightMm < 1) heightMm = 1;
    if (heightMm > 999) heightMm = 999;
    final offsetXDots = (_offsetXMm * _dotsPerMillimeter).round();
    final offsetYDots = (_offsetYMm * _dotsPerMillimeter).round();
    return <String, dynamic>{
      'width': widthMm,
      'height': heightMm,
      'gap': 0,
      'offsetX': offsetXDots,
      'offsetY': offsetYDots,
      'density': _tscDensityIndex,
      'speed': _tscSpeedIndex,
      'tear': _autoTear ? 1 : 0,
    };
  }

  Future<ui.Image> _ditherToMonochrome(ui.Image image) async {
    final byteData = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    final data = byteData!.buffer.asUint8List();
    final width = image.width;
    final height = image.height;
    final errors = Float32List(width * height);
    final threshold = _binarizationThreshold;

    for (var y = 0; y < height; y++) {
      final leftToRight = y.isEven;
      final start = leftToRight ? 0 : width - 1;
      final end = leftToRight ? width : -1;
      final step = leftToRight ? 1 : -1;

      for (var x = start; x != end; x += step) {
        final index = y * width + x;
        final dataIndex = index * 4;
        final r = data[dataIndex];
        final g = data[dataIndex + 1];
        final b = data[dataIndex + 2];
        final luminance = 0.299 * r + 0.587 * g + 0.114 * b + errors[index];
        final newValue = luminance < threshold ? 0 : 255;
        final err = luminance - newValue;

        data[dataIndex] = newValue;
        data[dataIndex + 1] = newValue;
        data[dataIndex + 2] = newValue;
        data[dataIndex + 3] = 255;

        final nextRow = y + 1;
        if (leftToRight) {
          if (x + 1 < width) {
            errors[index + 1] += err * 7 / 16;
          }
          if (nextRow < height) {
            final base = nextRow * width;
            if (x > 0) errors[base + x - 1] += err * 3 / 16;
            errors[base + x] += err * 5 / 16;
            if (x + 1 < width) errors[base + x + 1] += err * 1 / 16;
          }
        } else {
          if (x - 1 >= 0) {
            errors[index - 1] += err * 7 / 16;
          }
          if (nextRow < height) {
            final base = nextRow * width;
            if (x + 1 < width) errors[base + x + 1] += err * 3 / 16;
            errors[base + x] += err * 5 / 16;
            if (x - 1 >= 0) errors[base + x - 1] += err * 1 / 16;
          }
        }
      }
    }

    final monochrome = await _imageFromPixels(data, image.width, image.height);
    return monochrome;
  }

  Future<ui.Image> _enforceWidthMultipleOf8(ui.Image image) async {
    final remainder = image.width % 8;
    if (remainder == 0) return image;
    final newWidth = image.width + (8 - remainder);
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final bgPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, newWidth.toDouble(), image.height.toDouble()),
      bgPaint,
    );
    canvas.drawImage(image, ui.Offset.zero, ui.Paint());
    final picture = recorder.endRecording();
    final padded = await picture.toImage(newWidth, image.height);
    picture.dispose();
    return padded;
  }

  Future<ui.Image> _expandToTargetCanvas(ui.Image image) async {
    final hasHeightTarget = _targetHeightMm > 0;
    final targetWidthDots =
        (_targetWidthMm * _dotsPerMillimeter).round().clamp(1, 9999);
    final targetHeightDots =
        hasHeightTarget
            ? (_targetHeightMm * _dotsPerMillimeter).round().clamp(1, 9999)
            : image.height;

    final reductionDots =
        hasHeightTarget
            ? (_trailingFeedReductionMm * _dotsPerMillimeter).round().clamp(
              0,
              9999,
            )
            : 0;
    final effectiveTargetHeightDots = hasHeightTarget
        ? math.max(1, targetHeightDots - reductionDots)
        : targetHeightDots;

    final desiredWidth = math.max(image.width, targetWidthDots);
    final desiredHeight = math.max(image.height, effectiveTargetHeightDots);

    if (desiredWidth == image.width && desiredHeight == image.height) {
      return image;
    }

    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final bgPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawRect(
      ui.Rect.fromLTWH(
        0,
        0,
        desiredWidth.toDouble(),
        desiredHeight.toDouble(),
      ),
      bgPaint,
    );

    final offsetX = ((desiredWidth - image.width) / 2).floorToDouble();
    const offsetY = 0.0; // simpan konten di atas, sisa putih di bawah

    canvas.drawImage(
      image,
      ui.Offset(offsetX, offsetY),
      ui.Paint(),
    );

    final picture = recorder.endRecording();
    final expanded = await picture.toImage(desiredWidth, desiredHeight);
    picture.dispose();
    return expanded;
  }

  Future<ui.Image> _padWithMargin(ui.Image image) async {
    final padDots = (_outerMarginMm * _dotsPerMillimeter).round();
    if (padDots <= 0) return image;
    final newWidth = image.width + padDots * 2;
    final newHeight = image.height + padDots * 2;
    final recorder = ui.PictureRecorder();
    final canvas = ui.Canvas(recorder);
    final bgPaint = ui.Paint()..color = const ui.Color(0xFFFFFFFF);
    canvas.drawRect(
      ui.Rect.fromLTWH(0, 0, newWidth.toDouble(), newHeight.toDouble()),
      bgPaint,
    );
    canvas.drawImage(
      image,
      ui.Offset(padDots.toDouble(), padDots.toDouble()),
      ui.Paint(),
    );
    final picture = recorder.endRecording();
    final padded = await picture.toImage(newWidth, newHeight);
    picture.dispose();
    return padded;
  }

  Future<ui.Image> _imageFromPixels(Uint8List rgba, int width, int height) {
    final completer = Completer<ui.Image>();
    ui.decodeImageFromPixels(
      rgba,
      width,
      height,
      ui.PixelFormat.rgba8888,
      completer.complete,
    );
    return completer.future;
  }

  void _disposeUnique(List<ui.Image?> images) {
    final seen = <ui.Image>[];
    for (final img in images) {
      if (img == null) continue;
      if (seen.any((e) => identical(e, img))) continue;
      seen.add(img);
    }
    for (final img in seen) {
      img.dispose();
    }
  }

  void _applyBy482btDefaults() {
    _dotsPerMillimeter = 8.0; // 203 dpi
    _targetWidthMm = 90; // lebar head
    _targetHeightMm = 200; // panjang kertas roll
    _autoRotate = true; // biar service yang putar bila perlu
    _outerMarginMm = 0.5; // tipis agar aman dr hardware margin
    _trailingFeedReductionMm = 0;
    _binarizationThreshold = 170;
    _tscDensityIndex = 9;
    _tscSpeedIndex = 3;
    _offsetXMm = 0;
    _offsetYMm = 0;
    _autoTear = false;
  }
}

class _PrintableImage {
  const _PrintableImage({
    required this.bytes,
    required this.widthPx,
    required this.heightPx,
    required this.widthMm,
    required this.heightMm,
  });

  final Uint8List bytes;
  final int widthPx;
  final int heightPx;
  final double widthMm;
  final double heightMm;
}
