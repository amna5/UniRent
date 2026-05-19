// item_image.dart — displays an item image from either an asset path or a device file path
import 'dart:io';
import 'package:flutter/material.dart';
import '../theme.dart';

class ItemImage extends StatelessWidget {
  final String? imagePath;
  final BoxFit fit;
  final Widget? placeholder;

  const ItemImage({
    super.key,
    required this.imagePath,
    this.fit = BoxFit.cover,
    this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    final fallback =
        placeholder ??
        Container(
          color: AppTheme.cardBg,
          child: const Center(
            child: Icon(
              Icons.inventory_2_rounded,
              size: 40,
              color: AppTheme.textSecondary,
            ),
          ),
        );

    if (imagePath == null || imagePath!.isEmpty) return fallback;

    // Asset path — bundled with the app (e.g. 'assets/images/charger.jpg')
    if (imagePath!.startsWith('assets/')) {
      return Image.asset(
        imagePath!,
        fit: fit,
        width: double.infinity,
        errorBuilder: (_, __, ___) => fallback,
      );
    }

    // File path — saved on device by image_picker
    return Image.file(
      File(imagePath!),
      fit: fit,
      width: double.infinity,
      errorBuilder: (_, __, ___) => fallback,
    );
  }
}
