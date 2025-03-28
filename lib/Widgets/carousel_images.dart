import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class CarouselImages extends StatelessWidget {
  const CarouselImages({
    super.key,
    required this.imageUrl,
    this.memCacheWidth = 800,
  });

  final String imageUrl;
  final int memCacheWidth;

  static const _shimmerGradient = LinearGradient(
    colors: [Color(0xFFEBEBF4), Color(0xFFF4F4F4), Color(0xFFEBEBF4)],
    stops: [0.1, 0.3, 0.4],
    begin: Alignment(-1.0, -0.3),
    end: Alignment(1.0, 0.3),
  );

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: imageUrl,
          fit: BoxFit.cover,
          memCacheWidth: memCacheWidth,
          fadeInDuration: const Duration(milliseconds: 200),
          placeholderFadeInDuration: const Duration(milliseconds: 200),
          placeholder:
              (context, url) => ShaderMask(
                shaderCallback: (bounds) {
                  return _shimmerGradient.createShader(bounds);
                },
                child: Container(color: Colors.grey[900]),
              ),
          errorWidget:
              (context, url, error) => Container(
                color: Colors.grey[900],
                child: const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 32,
                ),
              ),
        ),
        const ColorFiltered(
          colorFilter: ColorFilter.mode(Colors.black54, BlendMode.darken),
          child: SizedBox.expand(),
        ),
      ],
    );
  }
}
