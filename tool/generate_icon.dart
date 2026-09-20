// One-off icon rasterizer: draws a simple cloud + upload-arrow mark (matching
// the cloud_sync iconography already used on the live-transfer dashboard)
// as pure vector shapes into launcher icon PNGs.
// Run with: flutter test tool/generate_icon.dart
// No image-editing tool is available in this environment, so this reuses
// Flutter's own headless Skia renderer (available under `flutter test`).
// Deliberately avoids TextPainter/icon-font glyphs: font shaping hung
// indefinitely in this headless harness, so the mark is drawn with plain
// Canvas primitives (circles, rects, a path) instead.
import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const Color kBrandNavy = Color(0xFF1E3A8A);
const Color kBrandAccent = Color(0xFF3B82F6);
const Color kBrandWhite = Colors.white;

const Map<String, int> kLegacySizes = {
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

const Map<String, int> kAdaptiveSizes = {
  'mipmap-mdpi': 108,
  'mipmap-hdpi': 162,
  'mipmap-xhdpi': 216,
  'mipmap-xxhdpi': 324,
  'mipmap-xxxhdpi': 432,
};

/// Draws a cloud (white) with an upward "upload" arrow (accent blue) inside
/// a [0,1]x[0,1] unit box, then scales it to [size] centered with [scale].
void _paintMark(Canvas canvas, double size, double scale) {
  canvas.save();
  final inset = size * (1 - scale) / 2;
  canvas.translate(inset, inset);
  final s = size * scale;

  final cloud = Path()
    ..addOval(Rect.fromCircle(center: Offset(0.50 * s, 0.55 * s), radius: 0.28 * s))
    ..addOval(Rect.fromCircle(center: Offset(0.30 * s, 0.60 * s), radius: 0.19 * s))
    ..addOval(Rect.fromCircle(center: Offset(0.70 * s, 0.58 * s), radius: 0.21 * s))
    ..addRRect(RRect.fromRectAndRadius(
      Rect.fromLTRB(0.26 * s, 0.55 * s, 0.74 * s, 0.70 * s),
      Radius.circular(0.06 * s),
    ));
  canvas.drawPath(cloud, Paint()..color = kBrandWhite);

  final arrow = Path()
    ..moveTo(0.50 * s, 0.24 * s)
    ..lineTo(0.62 * s, 0.38 * s)
    ..lineTo(0.55 * s, 0.38 * s)
    ..lineTo(0.55 * s, 0.52 * s)
    ..lineTo(0.45 * s, 0.52 * s)
    ..lineTo(0.45 * s, 0.38 * s)
    ..lineTo(0.38 * s, 0.38 * s)
    ..close();
  canvas.drawPath(arrow, Paint()..color = kBrandAccent);

  canvas.restore();
}

Future<Uint8List> _renderIcon(int size, {required bool withBackground, required double scale}) async {
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  final s = size.toDouble();

  if (withBackground) {
    final rrect = RRect.fromRectAndRadius(Rect.fromLTWH(0, 0, s, s), Radius.circular(s * 0.22));
    canvas.drawRRect(rrect, Paint()..color = kBrandNavy);
  }

  _paintMark(canvas, s, scale);

  final picture = recorder.endRecording();
  final image = await picture.toImage(size, size);
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  return byteData!.buffer.asUint8List();
}

void main() {
  test('generate launcher icons', () async {
    final androidRes = Directory('android/app/src/main/res');

    for (final entry in kLegacySizes.entries) {
      final bytes = await _renderIcon(entry.value, withBackground: true, scale: 0.72);
      final dir = Directory('${androidRes.path}/${entry.key}')..createSync(recursive: true);
      File('${dir.path}/ic_launcher.png').writeAsBytesSync(bytes);
    }

    for (final entry in kAdaptiveSizes.entries) {
      final bytes = await _renderIcon(entry.value, withBackground: false, scale: 0.62);
      final dir = Directory('${androidRes.path}/${entry.key}')..createSync(recursive: true);
      File('${dir.path}/ic_launcher_foreground.png').writeAsBytesSync(bytes);
    }

    // A large master copy for the Play Store listing / README.
    final masterBytes = await _renderIcon(512, withBackground: true, scale: 0.72);
    final brandingDir = Directory('assets/branding')..createSync(recursive: true);
    File('${brandingDir.path}/app_icon.png').writeAsBytesSync(masterBytes);
  });
}
