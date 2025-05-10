import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Load SVG from assets
  final svgString = await rootBundle.loadString('assets/logo.svg');
  final pictureInfo = await vg.loadPicture(SvgStringLoader(svgString), null);
  
  // Create a recorder and canvas to draw onto
  final recorder = ui.PictureRecorder();
  final canvas = Canvas(recorder);
  
  // Calculate the size
  final size = pictureInfo.size;
  
  // Draw the SVG
  canvas.drawPicture(pictureInfo.picture);
  
  // Convert to an image
  final image = await recorder.endRecording().toImage(
    size.width.toInt(),
    size.height.toInt(),
  );
  
  // Convert to bytes
  final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
  final buffer = byteData!.buffer.asUint8List();
  
  // Save to file
  final file = File('assets/icons/logo.png');
  await file.writeAsBytes(buffer);
  
  print('SVG converted to PNG and saved at ${file.path}');
  exit(0);
} 