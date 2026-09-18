import 'package:flutter/material.dart';

import '../app/theme.dart';
import '../l10n/strings.dart';

/// Rounded brand header used at the top of every portal dashboard.
class BrandHero extends StatelessWidget {
  const BrandHero({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    this.initials,
  });

  final String eyebrow;
  final String title;
  final String? subtitle;
  final String? initials;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(32),
      child: Container(
        height: 168,
        color: TawasulColors.forest,
        child: Stack(
          children: [
            const Positioned(
              top: -50,
              right: -40,
              child: _Blob(size: 150, color: TawasulColors.red),
            ),
            const Positioned(
              bottom: -30,
              right: 40,
              child: _Blob(size: 96, color: TawasulColors.gold),
            ),
            Padding(
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    style: const TextStyle(
                      color: Color(0xCCF6F1E7),
                      fontSize: 11,
                      letterSpacing: 1.4,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: TawasulColors.gold,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        color: Color(0xDDF6F1E7),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});
  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        width: size,
        height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      );
}

class StatCard extends StatelessWidget {
  const StatCard({
    super.key,
    required this.label,
    required this.value,
    this.background = TawasulColors.mint,
    this.foreground = TawasulColors.forestDeep,
    this.onTap,
  });

  final String label;
  final String value;
  final Color background;
  final Color foreground;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(28),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                color: foreground.withValues(alpha: 0.75),
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                color: foreground,
                fontSize: 32,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SectionCard extends StatelessWidget {
  const SectionCard({super.key, required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: TawasulColors.forest,
              ),
            ),
            const SizedBox(height: 10),
            if (children.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  S.of(context).nothingHere,
                  style: const TextStyle(color: TawasulColors.muted),
                ),
              )
            else
              ...children,
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class TimePill extends StatelessWidget {
  const TimePill({super.key, required this.time, this.color});
  final String time;
  final Color? color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: color ?? TawasulColors.mint,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          time,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 13,
            color: TawasulColors.forestDeep,
          ),
        ),
      );
}

/// Renders loading / error / empty states for an async value.
class AsyncSection<T> extends StatelessWidget {
  const AsyncSection({
    super.key,
    required this.value,
    required this.title,
    required this.builder,
  });

  final AsyncValueLike<T> value;
  final String title;
  final List<Widget> Function(T data) builder;

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    if (value.isLoading) {
      return SectionCard(title: title, children: const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Center(child: CircularProgressIndicator()),
        ),
      ]);
    }
    if (value.error != null) {
      return SectionCard(title: title, children: [
        Text(value.error!,
            style: const TextStyle(color: TawasulColors.red)),
        const SizedBox(height: 8),
        TextButton(onPressed: value.retry, child: Text(strings.retry)),
      ]);
    }
    return SectionCard(title: title, children: builder(value.data as T));
  }
}

class AsyncValueLike<T> {
  AsyncValueLike({this.data, this.error, this.isLoading = false, this.retry});
  final T? data;
  final String? error;
  final bool isLoading;
  final VoidCallback? retry;
}
