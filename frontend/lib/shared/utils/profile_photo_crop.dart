import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';

import 'package:clair/shared/widgets/profile_photo_crop_page.dart';

/// Picks an image from the gallery and opens an in-app crop screen.
/// Returns a square JPEG [XFile], or null if the user cancels.
Future<XFile?> pickAndCropProfilePhoto(
  BuildContext context, {
  ImageSource source = ImageSource.gallery,
}) async {
  final picker = ImagePicker();
  final picked = await picker.pickImage(source: source, imageQuality: 95);
  if (picked == null) return null;

  if (!context.mounted) return null;
  final bytes = await picked.readAsBytes();
  if (!context.mounted) return null;

  final cropped = await Navigator.of(context).push<Uint8List>(
    MaterialPageRoute<Uint8List>(
      fullscreenDialog: true,
      builder: (_) => ProfilePhotoCropPage(imageBytes: bytes),
    ),
  );
  if (cropped == null) return null;

  final dir = await getTemporaryDirectory();
  final path =
      '${dir.path}/profile_${DateTime.now().millisecondsSinceEpoch}.jpg';
  await File(path).writeAsBytes(cropped);
  return XFile(path);
}
