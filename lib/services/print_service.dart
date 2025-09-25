import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class PrintService {
  static Future<Uint8List> captureToPng(
    GlobalKey key, {
    double pixelRatio = 3,
    bool rotateClockwise = false,
  }) async {
    final boundary =
        key.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final ui.Image image = await boundary.toImage(pixelRatio: pixelRatio);
    final ui.Image finalImage =
        rotateClockwise ? await _rotate90(image) : image;
    final byteData = await finalImage.toByteData(
      format: ui.ImageByteFormat.png,
    );
    return byteData!.buffer.asUint8List();
  }

  static Future<ui.Image> _rotate90(ui.Image image) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);

    // Rotate canvas 90 degrees clockwise around origin so portrait tampil benar.
    canvas.translate(image.height.toDouble(), 0);
    canvas.rotate(math.pi / 2);
    canvas.drawImage(image, Offset.zero, Paint());

    final picture = recorder.endRecording();
    return picture.toImage(image.height, image.width);
  }
}
