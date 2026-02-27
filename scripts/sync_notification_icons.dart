
import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final logoFile = File('assets/images/noti.png');
  if (!logoFile.existsSync()) {
    print('❌ Error: assets/images/noti.png not found');
    return;
  }

  print('🎨 Processing logo to create a perfect silhouette...');
  final bytes = await logoFile.readAsBytes();
  final image = img.decodeImage(bytes);

  if (image == null) {
    print('❌ Error: Could not decode image');
    return;
  }

  // Create white silhouette: every non-transparent pixel becomes white
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      if (pixel.a > 0) {
        // Keep transparency, make color white
        image.setPixelRgba(x, y, 255, 255, 255, pixel.a.toInt());
      }
    }
  }

  final pngBytes = img.encodePng(image);

  final resPath = 'android/app/src/main/res';
  final targets = [
    'drawable',
    'mipmap-mdpi',
    'mipmap-hdpi',
    'mipmap-xhdpi',
    'mipmap-xxhdpi',
    'mipmap-xxxhdpi',
  ];

  for (final target in targets) {
    final dir = Directory('$resPath/$target');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    
    final file = File('${dir.path}/ic_notification.png');
    await file.writeAsBytes(pngBytes);
    print('✅ Saved to: ${file.path}');
  }

  print('\n🚀 SUCCESS: Notification icon synchronized across all folders.');
}
