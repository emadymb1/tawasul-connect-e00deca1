import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../core/providers.dart';
import '../l10n/strings.dart';

/// Standard page body: pull down to reload, with a banner when the phone is
/// showing the last data it stored because the server could not be reached.
class RefreshableBody extends ConsumerWidget {
  const RefreshableBody({
    super.key,
    required this.children,
    required this.onRefresh,
    this.padding = const EdgeInsets.fromLTRB(16, 16, 16, 28),
  });

  /// Reloads the screen's data; usually invalidates the page's providers.
  final Future<void> Function() onRefresh;
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final offline = ref.watch(servingFromCacheProvider);
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: TawasulColors.forest,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        children: [
          if (offline) const OfflineBanner(),
          ...children,
        ],
      ),
    );
  }
}

class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: TawasulColors.gold.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 18, color: TawasulColors.forest),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              '${strings.offline} — ${strings.showingSavedData}',
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: TawasulColors.forest),
            ),
          ),
        ],
      ),
    );
  }
}
