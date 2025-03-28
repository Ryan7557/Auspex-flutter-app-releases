import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';

class ImageSection extends StatelessWidget {
  const ImageSection({
    super.key,
    required this.imageUrl,
    this.memCacheWidth = 300,
  });

  final String imageUrl;
  final int memCacheWidth;

  static const _defaultFadeInDuration = Duration(milliseconds: 300);
  static const _loadingSize = 60.0;
  static const _errorIconSize = 32.0;
  static const _fallbackImageUrl =
      'https://artworks.thetvdb.com/banners/movies/default/movie.jpg';

  String _sanitizeImageUrl(String url) {
    if (url.isEmpty ||
        !url.startsWith('http') ||
        url.contains('placeholder.com')) {
      return _fallbackImageUrl;
    }
    return url;
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8.0),
      child: CachedNetworkImage(
        imageUrl: _sanitizeImageUrl(imageUrl),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        memCacheWidth: memCacheWidth,
        fadeInDuration: _defaultFadeInDuration,
        maxWidthDiskCache: 1024,
        placeholder:
            (context, url) => Container(
              color: Colors.grey[300],
              child: Center(
                child: LoadingAnimationWidget.beat(
                  color: Colors.deepPurple,
                  size: _loadingSize,
                ),
              ),
            ),
        errorWidget: (context, url, error) {
          debugPrint('Image error: $error for URL: $url');
          return Container(
            color: Colors.grey[300],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.red,
                  size: _errorIconSize,
                ),
                const SizedBox(height: 8),
                Text(
                  'Image not available',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
