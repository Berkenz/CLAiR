import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:clair/shared/utils/profile_photo_url.dart';

/// Network profile photo with explicit cache keys so re-uploads at the same path
/// do not show a previous image.
class ProfilePhotoImage extends StatelessWidget {
  const ProfilePhotoImage({
    super.key,
    required this.photoUrl,
    this.updatedAt,
    this.cacheVersion,
    this.fit = BoxFit.cover,
    this.width,
    this.height,
  });

  final String photoUrl;
  final DateTime? updatedAt;
  final int? cacheVersion;
  final BoxFit fit;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    final url = profilePhotoDisplayUrl(
      photoUrl,
      updatedAt: updatedAt,
      cacheVersion: cacheVersion,
    );
    if (url == null) return const SizedBox.shrink();

    final pixelWidth = width != null ? (width! * MediaQuery.devicePixelRatioOf(context)).round() : null;

    return CachedNetworkImage(
      imageUrl: url,
      cacheKey: url,
      fit: fit,
      width: width,
      height: height,
      memCacheWidth: pixelWidth,
      placeholder: (_, __) => const SizedBox.shrink(),
      errorWidget: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  /// Drop cached bytes for this avatar (call before changing [cacheVersion]).
  static Future<void> evictUrl({
    required String photoUrl,
    DateTime? updatedAt,
    int? cacheVersion,
  }) async {
    final url = profilePhotoDisplayUrl(
      photoUrl,
      updatedAt: updatedAt,
      cacheVersion: cacheVersion,
    );
    if (url == null) return;
    await CachedNetworkImage.evictFromCache(url);
  }
}
