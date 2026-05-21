import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';

import 'package:clair/shared/utils/profile_photo_url.dart';

/// Network profile photo that busts HTTP cache when [updatedAt] or [cacheVersion] changes.
class ProfilePhotoImage extends StatefulWidget {
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
  State<ProfilePhotoImage> createState() => _ProfilePhotoImageState();
}

class _ProfilePhotoImageState extends State<ProfilePhotoImage> {
  String? _displayUrl;

  @override
  void didUpdateWidget(ProfilePhotoImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _evictUrl(_urlFor(oldWidget));
  }

  @override
  void dispose() {
    _evictUrl(_displayUrl);
    super.dispose();
  }

  String? _urlFor(ProfilePhotoImage w) => profilePhotoDisplayUrl(
        w.photoUrl,
        updatedAt: w.updatedAt,
        cacheVersion: w.cacheVersion,
      );

  void _evictUrl(String? url) {
    if (url == null) return;
    NetworkImage(url).evict();
  }

  @override
  Widget build(BuildContext context) {
    final url = _urlFor(widget);
    _displayUrl = url;
    if (url == null) return const SizedBox.shrink();

    return Image.network(
      url,
      key: ValueKey(url),
      fit: widget.fit,
      width: widget.width,
      height: widget.height,
      gaplessPlayback: false,
      headers: const {'Cache-Control': 'no-cache'},
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }
}
