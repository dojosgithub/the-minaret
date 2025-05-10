import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'dart:ui' as ui;

// Run this file with: flutter run -t lib/tools/create_icon.dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  runApp(const MaterialApp(home: IconGenerator()));
}

class IconGenerator extends StatefulWidget {
  const IconGenerator({super.key});

  @override
  State<IconGenerator> createState() => _IconGeneratorState();
}

class _IconGeneratorState extends State<IconGenerator> {
  bool _isConverting = false;
  String _status = 'Ready to convert logo.svg to PNG';
  
  Future<void> _convertSvgToPng() async {
    setState(() {
      _isConverting = true;
      _status = 'Converting...';
    });
    
    try {
      // Load the SVG file
      final String svgString = await rootBundle.loadString('assets/logo.svg');
      
      // Define the size of the PNG (512x512 is good for app icons)
      const size = Size(512, 512);
      
      // Create a PictureInfo from the SVG
      final PictureInfo pictureInfo = await vg.loadPicture(SvgStringLoader(svgString), null);
      
      // This step uses a PictureRecorder to capture the SVG drawing commands
      final ui.PictureRecorder recorder = ui.PictureRecorder();
      final Canvas canvas = Canvas(recorder);
      
      // Draw a background
      canvas.drawColor(const Color(0xFF4F245A), BlendMode.src);
      
      // Calculate the scaling to center the SVG in our target size
      final Size svgSize = pictureInfo.size;
      final double scale = size.width / svgSize.width;
      final double horizontalOffset = (size.width - (svgSize.width * scale)) / 2;
      final double verticalOffset = (size.height - (svgSize.height * scale)) / 2;
      
      // Draw the SVG centered
      canvas.save();
      canvas.translate(horizontalOffset, verticalOffset);
      canvas.scale(scale);
      canvas.drawPicture(pictureInfo.picture);
      canvas.restore();
      
      // Convert to an image
      final ui.Image image = await recorder.endRecording().toImage(
        size.width.toInt(),
        size.height.toInt(),
      );
      
      // Convert to bytes
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw Exception('Failed to convert to PNG');
      }
      
      // Write to file
      final Uint8List pngBytes = byteData.buffer.asUint8List();
      final File file = File('assets/logo_512.png');
      await file.writeAsBytes(pngBytes);
      
      setState(() {
        _status = 'Successfully saved PNG to ${file.path}';
      });
    } catch (e) {
      setState(() {
        _status = 'Error: $e';
      });
    } finally {
      setState(() {
        _isConverting = false;
      });
    }
  }
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('SVG to PNG Converter'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('This tool converts the logo.svg to PNG for app icons'),
            const SizedBox(height: 20),
            SvgPicture.asset(
              'assets/logo.svg',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 20),
            Text(_status),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _isConverting ? null : _convertSvgToPng,
              child: _isConverting
                  ? const CircularProgressIndicator()
                  : const Text('Convert to PNG'),
            ),
          ],
        ),
      ),
    );
  }
} 