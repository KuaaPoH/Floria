import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
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
    final formattedUrl = AppConstants.formatImageUrl(imageUrl);

    Widget buildFallback() {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: const Color(0xFFF1F5F0),
          shape: shape,
        ),
        child: Center(
          child: Icon(
            Icons.eco_rounded,
            color: const Color(0xFF4B6350).withOpacity(0.5),
            size: (width != null && width! < 50) ? 18 : 36,
          ),
        ),
      );
    }

    if (formattedUrl.isEmpty) {
      return ClipRRect(
        borderRadius: shape == BoxShape.circle ? BorderRadius.zero : (borderRadius ?? BorderRadius.zero),
        child: buildFallback(),
      );
    }

    return ClipRRect(
      borderRadius: shape == BoxShape.circle ? BorderRadius.zero : (borderRadius ?? BorderRadius.zero),
      child: Container(
        width: width,
        height: height,
        decoration: shape == BoxShape.circle ? const BoxDecoration(shape: BoxShape.circle) : null,
        clipBehavior: shape == BoxShape.circle ? Clip.antiAlias : Clip.none,
        child: Image.network(
          formattedUrl,
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
            return buildFallback();
          },
        ),
      ),
    );
  }
}
