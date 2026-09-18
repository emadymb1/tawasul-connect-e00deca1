import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/theme.dart';
import '../../core/providers.dart';
import '../../core/server_capabilities.dart';
import '../../l10n/strings.dart';
import '../../widgets/async_card.dart';
import '../../widgets/common.dart';

/// Live webhook subscriptions on the server.
final webhookSubscriptionsProvider =
    FutureProvider<List<Map<String, dynamic>>>((ref) async {
  return ref.watch(apiClientProvider).getList('/webhooks', pageSize: 100);
});

/// Admin → System: everything the API v2 meta endpoints expose.
class AdminSystemPage extends ConsumerWidget {
  const AdminSystemPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final health = ref.watch(serverHealthProvider);
    final stats = ref.watch(serverStatsProvider);
    final analytics = ref.watch(serverAnalyticsProvider(7));
    final permissions = ref.watch(serverPermissionsProvider);
    final credential = ref.watch(currentCredentialProvider);
    final resources = ref.watch(liveResourcesProvider);
    final webhooks = ref.watch(webhookSubscriptionsProvider);

    return RefreshIndicator(
      onRefresh: () async {
        ref.invalidate(serverHealthProvider);
        ref.invalidate(serverStatsProvider);
        ref.invalidate(serverAnalyticsProvider(7));
        ref.invalidate(serverPermissionsProvider);
        ref.invalidate(currentCredentialProvider);
        ref.invalidate(liveResourcesProvider);
        ref.invalidate(webhookSubscriptionsProvider);
      },
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          AsyncCard<Map<String, dynamic>>(
            title: strings.serverHealth,
            value: health,
            onRetry: () => ref.invalidate(serverHealthProvider),
            builder: (data) => _rows(data),
          ),
          const SizedBox(height: 12),
          AsyncCard<Map<String, dynamic>>(
            title: strings.serverStats,
            value: stats,
            onRetry: () => ref.invalidate(serverStatsProvider),
            builder: (data) => _rows(data),
          ),
          const SizedBox(height: 12),
          AsyncCard<Map<String, dynamic>>(
            title: strings.apiAnalytics,
            value: analytics,
            onRetry: () => ref.invalidate(serverAnalyticsProvider(7)),
            builder: (data) => _rows(data),
          ),
          const SizedBox(height: 12),
          AsyncCard<List<LiveResource>>(
            title: strings.resourceRegistry,
            value: resources,
            onRetry: () => ref.invalidate(liveResourcesProvider),
            builder: (list) {
              final writable = list.where((r) => !r.readOnly).length;
              final modules = list.map((r) => r.module).toSet()
                ..removeWhere((m) => m.isEmpty);
              return [
                DetailRow(
                    title: strings.resourcesAvailable, subtitle: '${list.length}'),
                DetailRow(title: strings.writableResources, subtitle: '$writable'),
                DetailRow(title: strings.modules, subtitle: '${modules.length}'),
              ];
            },
          ),
          const SizedBox(height: 12),
          AsyncCard<Map<String, dynamic>>(
            title: strings.myPermissions,
            value: permissions,
            onRetry: () => ref.invalidate(serverPermissionsProvider),
            builder: (data) => _rows(data, limit: 40),
          ),
          const SizedBox(height: 12),
          AsyncCard<Map<String, dynamic>>(
            title: strings.credential,
            value: credential,
            onRetry: () => ref.invalidate(currentCredentialProvider),
            builder: (data) => _rows(data, limit: 20),
          ),
          const SizedBox(height: 12),
          AsyncCard<List<Map<String, dynamic>>>(
            title: strings.webhooks,
            value: webhooks,
            onRetry: () => ref.invalidate(webhookSubscriptionsProvider),
            builder: (list) => [
              if (list.isEmpty) Text(strings.nothingHere),
              for (final hook in list)
                DetailRow(
                  title: '${hook['name'] ?? hook['url'] ?? ''}',
                  subtitle: '${hook['events'] ?? ''}',
                  trailing: IconButton(
                    icon: const Icon(Icons.delete_outline_rounded,
                        color: TawasulColors.red),
                    onPressed: () async {
                      final id = (hook['gibbonRestWebhookID'] ??
                              hook['id'] ??
                              hook['webhookID'])
                          ?.toString();
                      if (id == null) return;
                      await ref
                          .read(apiClientProvider)
                          .delete('/webhooks/$id');
                      ref.invalidate(webhookSubscriptionsProvider);
                    },
                  ),
                ),
              const SizedBox(height: 8),
              FilledButton.icon(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  builder: (_) => const _WebhookSheet(),
                ).then((_) => ref.invalidate(webhookSubscriptionsProvider)),
                icon: const Icon(Icons.add_rounded),
                label: Text(strings.addWebhook),
              ),
            ],
          ),
        ],
      ),
    );
  }

  List<Widget> _rows(Map<String, dynamic> data, {int limit = 30}) {
    final entries = data.entries.take(limit).toList();
    if (entries.isEmpty) return const [Text('—')];
    return [
      for (final entry in entries)
        DetailRow(title: entry.key, subtitle: _format(entry.value)),
    ];
  }

  static String _format(dynamic value) {
    if (value is Map) {
      return value.entries.map((e) => '${e.key}: ${e.value}').join(' · ');
    }
    if (value is List) {
      if (value.isEmpty) return '—';
      return value.map((e) => e is Map ? e.values.join(' ') : '$e').join(', ');
    }
    return '$value';
  }
}

class _WebhookSheet extends ConsumerStatefulWidget {
  const _WebhookSheet();

  @override
  ConsumerState<_WebhookSheet> createState() => _WebhookSheetState();
}

class _WebhookSheetState extends ConsumerState<_WebhookSheet> {
  final _name = TextEditingController();
  final _url = TextEditingController();
  final _events = TextEditingController();
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _name.dispose();
    _url.dispose();
    _events.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref.read(apiClientProvider).post('/webhooks', {
        'name': _name.text.trim(),
        'url': _url.text.trim(),
        'events': _events.text.trim(),
      });
      if (mounted) Navigator.of(context).pop();
    } catch (error) {
      setState(() => _error = '$error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = S.of(context);
    final events = ref.watch(webhookEventsProvider);
    return Padding(
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).viewInsets.bottom + 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(strings.addWebhook,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 12),
            TextField(
              controller: _name,
              decoration: InputDecoration(labelText: strings.name),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _url,
              keyboardType: TextInputType.url,
              decoration: InputDecoration(labelText: strings.webhookUrl),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _events,
              decoration: InputDecoration(
                labelText: strings.webhookEvents,
                hintText: 'attendance.created, attendance.updated',
              ),
            ),
            const SizedBox(height: 10),
            events.maybeWhen(
              data: (list) => Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final event in list.take(24))
                    ActionChip(
                      label: Text(event, style: const TextStyle(fontSize: 11)),
                      onPressed: () {
                        final current = _events.text.trim();
                        _events.text =
                            current.isEmpty ? event : '$current,$event';
                        _events.selection = TextSelection.collapsed(
                            offset: _events.text.length);
                      },
                    ),
                ],
              ),
              orElse: () => const SizedBox.shrink(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: const TextStyle(color: TawasulColors.red)),
            ],
            const SizedBox(height: 14),
            FilledButton(
              onPressed: _saving ? null : _save,
              child: Text(_saving ? strings.loading : strings.save),
            ),
          ],
        ),
      ),
    );
  }
}

/// Copy a CSV export to the clipboard / share sheet from any resource list.
Future<void> exportResourceCsv(
  BuildContext context,
  WidgetRef ref,
  String resourcePath, {
  Map<String, dynamic> filters = const {},
}) async {
  final strings = S.of(context);
  final messenger = ScaffoldMessenger.of(context);
  try {
    final resource = resourcePath.startsWith('/')
        ? resourcePath.substring(1)
        : resourcePath;
    final csv = await ref
        .read(apiClientProvider)
        .exportCsv(resource, filters: filters);
    await Clipboard.setData(ClipboardData(text: csv));
    final lines = csv.split('\n').where((l) => l.trim().isNotEmpty).length;
    messenger.showSnackBar(
      SnackBar(content: Text('${strings.exportedRows}: ${lines - 1}')),
    );
  } catch (error) {
    messenger.showSnackBar(SnackBar(content: Text('$error')));
  }
}
