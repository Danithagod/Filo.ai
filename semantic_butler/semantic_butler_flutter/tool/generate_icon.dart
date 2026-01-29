import 'dart:io';
import 'package:image/image.dart';

void main() async {
  print('Processing icon from filo_desktop.png...');

  // Load the logo
  final file = File('assets/filo_desktop.png');
  if (!file.existsSync()) {
    print('Error: assets/filo_desktop.png not found');
    exit(1);
  }

  final bytes = await file.readAsBytes();
  final original = decodePng(bytes);

  if (original == null) {
    print('Error: Could not decode PNG');
    exit(1);
  }

  // Trim transparent edges to maximize the logo
  final trimmed = trim(original);

  // Create a 512x512 canvas (standard icon size)
  // Use a transparent background with 4 channels (RGBA)
  final size = 512;
  final icon = Image(width: size, height: size, numChannels: 4);
  // Default is transparent, so no need to fill with white.

  // Determine scaling to fit trimmed logo within the box with zero padding (Maximize)
  final padding = 0;
  final targetWidth = size - (padding * 2);
  final targetHeight = size - (padding * 2);

  // Resize trimmed image maintaining aspect ratio
  final resized = copyResize(
    trimmed,
    width: targetWidth,
    height: targetHeight,
    maintainAspect: true,
  );

  // Center the resized logo
  final x = (size - resized.width) ~/ 2;
  final y = (size - resized.height) ~/ 2;

  // Composite
  compositeImage(icon, resized, dstX: x, dstY: y);

  // Save as new asset
  final outFile = File('assets/filo_desktop_processed.png');
  await outFile.writeAsBytes(encodePng(icon));

  print('Saved processed icon to assets/filo_desktop_processed.png');
}
