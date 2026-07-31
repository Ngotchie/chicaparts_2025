import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

class OptimizedNetworkImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final int memCacheWidth;
  final int? memCacheHeight;
  final int maxWidthDiskCache;
  final int? maxHeightDiskCache;
  final Widget? errorWidget;

  const OptimizedNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    required this.memCacheWidth,
    this.memCacheHeight,
    required this.maxWidthDiskCache,
    this.maxHeightDiskCache,
    this.errorWidget,
  });

  static CachedNetworkImageProvider provider(
    String imageUrl, {
    int maxWidth = 1200,
    int? maxHeight,
  }) {
    return CachedNetworkImageProvider(
      imageUrl,
      maxWidth: maxWidth,
      maxHeight: maxHeight,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imageUrl.trim().isEmpty) {
      return _fallback();
    }

    return CachedNetworkImage(
      imageUrl: imageUrl,
      width: width,
      height: height,
      fit: fit,
      fadeInDuration: const Duration(milliseconds: 180),
      fadeOutDuration: const Duration(milliseconds: 90),
      memCacheWidth: memCacheWidth,
      memCacheHeight: memCacheHeight,
      maxWidthDiskCache: maxWidthDiskCache,
      maxHeightDiskCache: maxHeightDiskCache,
      placeholder: (context, url) => _placeholder(),
      errorWidget: (context, url, error) => _fallback(),
    );
  }

  Widget _placeholder() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: width,
        height: height,
        color: Colors.white,
      ),
    );
  }

  Widget _fallback() {
    return SizedBox(
      width: width,
      height: height,
      child: Center(
        child: errorWidget ??
            const Icon(
              Icons.broken_image,
              size: 42,
              color: Colors.grey,
            ),
      ),
    );
  }
}
