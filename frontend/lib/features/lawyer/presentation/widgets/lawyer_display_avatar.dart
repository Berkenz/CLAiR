import 'package:flutter/material.dart';

import 'package:clair/features/lawyer/domain/entities/lawyer_entity.dart';
import 'package:clair/shared/widgets/profile_photo_image.dart';

/// Shows the lawyer's [LawyerEntity.photoUrl] when set; otherwise [initialsStyle] text.
///
/// [decoration] should match the surrounding design (gradient tile, solid pin, etc.).
/// Use [clipBehavior] so photos respect rounded / circular shapes.
class LawyerDisplayAvatar extends StatelessWidget {
  const LawyerDisplayAvatar({
    super.key,
    required this.lawyer,
    required this.size,
    required this.decoration,
    required this.initialsStyle,
    this.clipBehavior = Clip.antiAlias,
  });

  final LawyerEntity lawyer;
  final double size;
  final BoxDecoration decoration;
  final TextStyle initialsStyle;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final url = lawyer.photoUrl;
    final hasPhoto = url != null && url.isNotEmpty;

    Widget initials() => Center(
          child: Text(
            lawyer.initials,
            style: initialsStyle,
            maxLines: 1,
            overflow: TextOverflow.clip,
          ),
        );

    if (!hasPhoto) {
      return Container(
        width: size,
        height: size,
        decoration: decoration,
        clipBehavior: clipBehavior,
        child: initials(),
      );
    }

    return Container(
      width: size,
      height: size,
      decoration: decoration,
      clipBehavior: clipBehavior,
      child: Stack(
        fit: StackFit.expand,
        children: [
          initials(),
          ProfilePhotoImage(
            photoUrl: url,
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        ],
      ),
    );
  }
}
