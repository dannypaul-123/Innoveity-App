import 'dart:io';
import 'package:flutter/material.dart';

/// Returns an [ImageProvider] for the given [avatar] string, supporting
/// network URLs (http/https), assets (assets/...), and local file system paths.
ImageProvider? getAvatarImageProvider(String? avatar) {
  if (avatar == null || avatar.trim().isEmpty) return null;
  var clean = avatar.trim();
  if (clean.startsWith('http://') || clean.startsWith('https://')) {
    return NetworkImage(clean);
  }
  if (clean.startsWith('assets/')) {
    return AssetImage(clean);
  }
  if (clean.startsWith('file://')) {
    try {
      clean = Uri.parse(clean).toFilePath();
    } catch (_) {
      clean = clean.replaceFirst(RegExp(r'^file://+'), '');
    }
  }
  try {
    final file = File(clean);
    if (file.existsSync()) {
      return FileImage(file);
    }
  } catch (_) {}
  return null;
}

/// Standardized circular user avatar used across the app that properly
/// renders local files, network images, assets, or falls back to initials.
Widget buildUserAvatar({
  required String? avatar,
  required String name,
  double size = 36,
  Color backgroundColor = const Color(0xFFEA580C),
  Border? border,
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.bold,
  Color textColor = Colors.white,
}) {
  final provider = getAvatarImageProvider(avatar);
  final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : 'U';

  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: backgroundColor,
      border: border,
      image: provider != null
          ? DecorationImage(
              image: provider,
              fit: BoxFit.cover,
              onError: (exception, stackTrace) {},
            )
          : null,
    ),
    child: provider == null
        ? Center(
            child: Text(
              initial,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: textColor,
              ),
            ),
          )
        : null,
  );
}
