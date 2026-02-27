import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  final inputPath = 'assets/images/notification.png';
  final bytes = await File(inputPath).readAsBytes();
  final image = img.decodeImage(bytes);

  if (image == null) {
      print('Error: Could not decode image');
      return;
  }

  // Create a new image for the silhouette (White on Transparent)
  final silhouette = img.Image(width: image.width, height: image.height, numChannels: 4);

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      
      // Get the transparency (alpha)
      final a = pixel.a;
      
      // We also check if the pixel is "bright" (if the image has no alpha but has a white logo on black)
      final luminance = (pixel.r + pixel.g + pixel.b) / 3;
      
      if (a > 10 || luminance > 128) {
          // Set to white with original transparency or full opacity if it was bright
          silhouette.setPixelRgba(x, y, 255, 255, 255, a > 10 ? a.toInt() : 255);
      } else {
          // Fully transparent
          silhouette.setPixelRgba(x, y, 0, 0, 0, 0);
      }
    }
  }

  final outPath = 'assets/images/notification_silhouette.png';
  await File(outPath).writeAsBytes(img.encodePng(silhouette));
  print('Successfully created silhouette at $outPath');
}
