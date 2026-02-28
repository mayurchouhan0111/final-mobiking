import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final filesToCrop = [
    'android/app/src/main/res/drawable/ic_notification.png',
  ];

  for (String path in filesToCrop) {
    final file = File(path);
    if (!file.existsSync()) {
      print('File not found: $path');
      continue;
    }

    final bytes = file.readAsBytesSync();
    var defaultImage = img.decodeImage(bytes);
    
    if (defaultImage == null) continue;
    
    int minX = defaultImage.width;
    int minY = defaultImage.height;
    int maxX = 0;
    int maxY = 0;
    
    for (int y = 0; y < defaultImage.height; y++) {
      for (int x = 0; x < defaultImage.width; x++) {
        if (defaultImage.getPixel(x, y).a > 0) {
          if (x < minX) minX = x;
          if (x > maxX) maxX = x;
          if (y < minY) minY = y;
          if (y > maxY) maxY = y;
        }
      }
    }
    
    if (minX <= maxX && minY <= maxY) {
      int w = maxX - minX + 1;
      int h = maxY - minY + 1;
      var cropped = img.copyCrop(defaultImage, x: minX, y: minY, width: w, height: h);
      
      int maxDim = w > h ? w : h;
      var square = img.Image(width: maxDim, height: maxDim, numChannels: 4);
      
      int offsetX = (maxDim - w) ~/ 2;
      int offsetY = (maxDim - h) ~/ 2;
      
      img.compositeImage(square, cropped, dstX: offsetX, dstY: offsetY);
      
      file.writeAsBytesSync(img.encodePng(square));
      print('Cropped successfully: $path (New size: ${square.width}x${square.height}) from ${defaultImage.width}x${defaultImage.height}');
    } else {
      print('Image is completely transparent or invalid.');
    }
  }
}
