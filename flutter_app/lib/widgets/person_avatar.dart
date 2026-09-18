import 'package:flutter/material.dart';

import '../app/theme.dart';

/// Person photo from the server, falling back to initials when the person has
/// no photo or the image cannot be loaded.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    this.imageUrl,
    required this.name,
    this.size = 40,
  });

  final String? imageUrl;
  final String name;
  final double size;

  String get _initials {
    final parts = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .map((p) => p.substring(0, 1))
        .toList();
    return parts.isEmpty ? '?' : parts.take(2).join();
  }

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();
    final fallback = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: TawasulColors.mint,
        shape: BoxShape.circle,
      ),
      child: Text(
        _initials,
        style: TextStyle(
          color: TawasulColors.forestDeep,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
        ),
      ),
    );

    if (url == null || url.isEmpty || !url.startsWith('http')) return fallback;

    return ClipOval(
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallback,
      ),
    );
  }
}
