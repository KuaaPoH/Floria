import 'package:flutter/material.dart';
import 'shimmer_loading.dart';

class CustomImage extends StatelessWidget {
  final String imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadiusGeometry? borderRadius;
  final BoxShape shape;

  const CustomImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.shape = BoxShape.rectangle,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: shape == BoxShape.circle ? BorderRadius.zero : (borderRadius ?? BorderRadius.zero),
      child: Container(
        width: width,
        height: height,
        decoration: shape == BoxShape.circle ? const BoxDecoration(shape: BoxShape.circle) : null,
        clipBehavior: shape == BoxShape.circle ? Clip.antiAlias : Clip.none,
        child: Image.network(
          imageUrl,
          width: width,
          height: height,
          fit: fit,
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return ShimmerLoading(
              width: width,
              height: height,
              borderRadius: borderRadius,
              shape: shape,
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Container(
              width: width,
              height: height,
              decoration: BoxDecoration(
                color: const Color(0xFFE4E2DF),
                shape: shape,
              ),
              child: Icon(
                Icons.image_not_supported,
                color: const Color(0xFF747871),
                size: (width != null && width! < 40) ? 16 : 24,
              ),
            );
          },
        ),
      ),
    );
  }
}
