import 'package:flutter/material.dart';

import 'package:clair/shared/utils/profile_photo_url.dart';

/// Network profile photo that busts HTTP cache when [updatedAt] or [cacheVersion] changes.
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

    return Image.network(
      url,
      key: ValueKey(url),
      fit: fit,
      width: width,
      height: height,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}
