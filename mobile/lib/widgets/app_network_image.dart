import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class AppNetworkImage extends StatelessWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit,
    this.width,
    this.height,
    this.alignment = Alignment.center,
    this.errorBuilder,
    this.loadingBuilder,
    this.filterQuality = FilterQuality.low,
  });

  final String imageUrl;
  final BoxFit? fit;
  final double? width;
  final double? height;
  final AlignmentGeometry alignment;
  final Widget Function(BuildContext, Object, StackTrace?)? errorBuilder;
  final ImageLoadingBuilder? loadingBuilder;
  final FilterQuality filterQuality;

  @override
  Widget build(BuildContext context) {
    final uri = Uri.tryParse(imageUrl);
    final isFirebaseStorageImage = kIsWeb &&
        uri != null &&
        uri.scheme == 'https' &&
        (uri.host.contains('firebasestorage.googleapis.com') ||
            uri.host.contains('firebasestorage.app'));

    final image = isFirebaseStorageImage
        ? Image.network(
            imageUrl,
            width: width,
            height: height,
            fit: fit,
            alignment: alignment,
            filterQuality: filterQuality,
            loadingBuilder: loadingBuilder,
            errorBuilder: errorBuilder,
            webHtmlElementStrategy: WebHtmlElementStrategy.prefer,
          )
        : Image.network(
            imageUrl,
            width: width,
            height: height,
            fit: fit,
            alignment: alignment,
            filterQuality: filterQuality,
            loadingBuilder: loadingBuilder,
            errorBuilder: errorBuilder,
          );

    return image;
  }
}
