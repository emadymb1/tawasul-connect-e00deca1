import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../core/api_exception.dart';
import '../l10n/strings.dart';
import 'common.dart';

/// A SectionCard fed by a Riverpod async value, with loading / error / empty
/// states and a retry that re-runs the request.
///
/// When the server refuses the request (403) the card disappears completely,
/// so each portal only shows what the signed-in role is allowed to see.
class AsyncCard<T> extends ConsumerWidget {
  const AsyncCard({
    super.key,
    required this.title,
    required this.value,
    required this.builder,
    this.onRetry,
    this.hideWhenForbidden = true,
  });

  final String title;
  final AsyncValue<T> value;
  final List<Widget> Function(T data) builder;
  final VoidCallback? onRetry;

  /// Hide the whole card when the user has no permission for its data.
  final bool hideWhenForbidden;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    return value.when(
      loading: () => SectionCard(title: title, children: const [
        Padding(
          padding: EdgeInsets.symmetric(vertical: 18),
          child: Center(child: CircularProgressIndicator()),
        ),
      ]),
      error: (error, _) {
        final forbidden = error is ApiException && error.isForbidden;
        if (forbidden && hideWhenForbidden) return const SizedBox.shrink();
        final offline = error is ApiException && error.isOffline;
        return SectionCard(title: title, children: [
          Text(
            forbidden
                ? strings.noPermission
                : offline
                    ? strings.offlineNoSavedData
                    : (error is ApiException ? error.message : '$error'),
            style: const TextStyle(color: TawasulColors.red),
          ),
          if (!forbidden && onRetry != null) ...[
            const SizedBox(height: 6),
            TextButton(onPressed: onRetry, child: Text(strings.retry)),
          ],
        ]);
      },
      data: (data) => SectionCard(title: title, children: builder(data)),
    );
  }
}

/// A simple two-line row used across the portals.
class DetailRow extends StatelessWidget {
  const DetailRow({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.trailing,
    this.onTap,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            if (leading != null) ...[leading!, const SizedBox(width: 12)],
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, fontSize: 15),
                  ),
                  if (subtitle != null && subtitle!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 2),
                      child: Text(
                        subtitle!,
                        style: const TextStyle(
                            color: TawasulColors.muted, fontSize: 13),
                      ),
                    ),
                ],
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}

class StatusPill extends StatelessWidget {
  const StatusPill({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          label,
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
        ),
      );
}
