import 'dart:convert';

import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    required this.name,
    required this.photoUrl,
    this.radius = 24,
    super.key,
  });

  final String name;
  final String photoUrl;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final imageProvider = _imageProvider(photoUrl);
    return CircleAvatar(
      radius: radius,
      backgroundColor:
          Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
      backgroundImage: imageProvider,
      child: imageProvider == null
          ? Text(
              name.isEmpty ? '?' : name[0].toUpperCase(),
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w900,
                fontSize: radius * 0.62,
              ),
            )
          : null,
    );
  }

  ImageProvider? _imageProvider(String value) {
    final photo = value.trim();
    if (photo.isEmpty) return null;
    if (photo.startsWith('data:image')) {
      final commaIndex = photo.indexOf(',');
      if (commaIndex == -1) return null;
      try {
        return MemoryImage(base64Decode(photo.substring(commaIndex + 1)));
      } catch (_) {
        return null;
      }
    }
    return NetworkImage(photo);
  }
}
