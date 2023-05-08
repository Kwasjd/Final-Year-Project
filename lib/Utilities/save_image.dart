import 'dart:io';
import 'dart:typed_data';

import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:nutrition_ai/Utilities/toast_dialog.dart';

Future saveImage(Uint8List bytes) async {
  await [Permission.storage].request();
  final time = DateTime.now()
      .toIso8601String()
      .replaceAll('.', '_')
      .replaceAll(':', '_');
  final name = "screenshot_$time";
  final result = await ImageGallerySaver.saveImage(bytes, name: name);
  toastDialog("Image is saved into gallery");
  return result['filePath'];
}

Future downloadImage(Uint8List bytes) async {
  final directory = await getApplicationDocumentsDirectory();
  final image = File('${directory.path}/flutter.png');
  image.writeAsBytesSync(bytes);
}