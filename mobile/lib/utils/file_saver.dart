import 'dart:typed_data';
import 'file_saver_stub.dart'
    if (dart.library.html) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_mobile.dart';

class FileSaver {
  static Future<bool> saveImage(Uint8List bytes, String filename) {
    return FileSaverHelper.saveImage(bytes, filename);
  }
}
