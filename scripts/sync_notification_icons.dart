
import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final logoFile = File('assets/images/logo.png');
  if (!logoFile.existsSync()) {
    print('❌ Error: assets/images/logo.png not found');
    return;
  }

  print('🎨 SMART PROCESSING: Extracting silhouette from logo lines...');
  final bytes = await logoFile.readAsBytes();
  final original = img.decodeImage(bytes);

  if (original == null) {
    print('❌ Error: Could not decode image');
    return;
  }

  // Create a new empty transparent image
  final silhouette = img.Image(width: original.width, height: original.height, numChannels: 4);
  
  // Logic: If a pixel is "dark" (less than 200 gray), it's part of our logo lines.
  // We make it White in the silhouette.
  // Otherwise, we keep it Transparent.
  int count = 0;
  for (int y = 0; y < original.height; y++) {
    for (int x = 0; x < original.width; x++) {
      final pixel = original.getPixel(x, y);
      
      // Calculate average brightness
      final avg = (pixel.r + pixel.g + pixel.b) / 3;
      
      // If the pixel is dark enough OR has color (the pink part), it's our logo
      // Using a threshold of 240 to remove "white or near-white" backgrounds
      if (avg < 240 && pixel.a > 10) {
        // Result: White pixel with logo's original opacity
        silhouette.setPixelRgba(x, y, 255, 255, 255, pixel.a.toInt());
        count++;
      } else {
        silhouette.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }

  if (count == 0) {
    print('⚠️ Warning: No logo pixels detected. Is the image already white?');
  } else {
    print('✨ Detected $count logo pixels. Creating silhouette...');
  }

  // Trim the image to the logo size
  var cropped = silhouette;
  
  final pngBytes = img.encodePng(cropped);

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
    print('✅ Saved Silhouette to: ${file.path}');
  }

  // Also Copy the Colorful Logo for the Large Icon Fallback
  final largeIconTarget = File('android/app/src/main/res/drawable/ic_notification_large.png');
  await largeIconTarget.writeAsBytes(bytes); // Use original bytes from logo.png
  print('✅ Saved Colorful Large Icon to: ${largeIconTarget.path}');

  print('\n🚀 SUCCESS: All notification assets (Silhouette + Colorful) are synchronized.');
}
