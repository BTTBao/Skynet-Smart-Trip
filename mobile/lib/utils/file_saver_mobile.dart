import 'dart:typed_data';

class FileSaverHelper {
  static Future<bool> saveImage(Uint8List bytes, String filename) async {
    // Fallback for native platforms. Since there's no photo gallery saver plugin
    // configured in this demo workspace, we return false here.
    return false;
  }
}
