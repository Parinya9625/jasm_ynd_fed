import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// Standard network image with a shimmer placeholder.
class TheNetworkImage extends StatelessWidget {
  final String url;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const TheNetworkImage({
    super.key,
    required this.url,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.devicePixelRatioOf(context);
    final memCacheHeight = _calcCacheSize(height, dpr);
    final radius = borderRadius ?? BorderRadius.zero;

    Widget image = CachedNetworkImage(
      imageUrl: url,
      width: width,
      height: height,
      memCacheHeight: memCacheHeight?.round(),
      fit: fit,
      placeholder: (context, _) => Shimmer.fromColors(
        baseColor: Colors.grey.shade300,
        highlightColor: Colors.grey.shade100,
        child: Container(width: width, height: height, color: Colors.white),
      ),
      errorWidget: (context, _, __) => Container(
        width: width,
        height: height,
        color: Colors.grey.shade200,
        child: const Icon(Icons.image_not_supported_outlined),
      ),
    );

    if (radius != BorderRadius.zero) {
      image = ClipRRect(
        borderRadius: radius,
        child: image,
      );
    }

    return RepaintBoundary(
      child: image,
    );
  }

  int? _calcCacheSize(double? size, double dpr) {
    if (size == null || !size.isFinite || size <= 0) return null;
    return (size * dpr).round();
  }
}
