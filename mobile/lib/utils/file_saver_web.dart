import 'dart:html' as html;
import 'dart:typed_data';

class FileSaverHelper {
  static Future<bool> saveImage(Uint8List bytes, String filename) async {
    try {
      final blob = html.Blob([bytes], 'image/png');
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute('download', filename)
        ..click();
      html.Url.revokeObjectUrl(url);
      return true;
    } catch (_) {
      return false;
    }
  }
}
