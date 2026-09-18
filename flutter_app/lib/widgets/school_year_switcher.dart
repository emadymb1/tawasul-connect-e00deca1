import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../app/theme.dart';
import '../core/school_year.dart';
import '../l10n/strings.dart';

/// Top-bar button that lets an administrator work in another school year.
///
/// Every screen reloads with `gibbonSchoolYearID` set to the chosen year.
class SchoolYearSwitcher extends ConsumerWidget {
  const SchoolYearSwitcher({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final selected = ref.watch(selectedSchoolYearProvider);

    return IconButton(
      tooltip: strings.schoolYear,
      icon: Icon(
        Icons.event_note_outlined,
        color: selected == null ? null : TawasulColors.red,
      ),
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => const _SchoolYearDialog(),
      ),
    );
  }
}

class _SchoolYearDialog extends ConsumerWidget {
  const _SchoolYearDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final strings = S.of(context);
    final years = ref.watch(apiSchoolYearsProvider);
    final selected = ref.watch(selectedSchoolYearProvider);

    void choose(String? id) {
      setSchoolYear(ref, id);
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(strings.yearChanged)));
    }

    return AlertDialog(
      title: Text(strings.schoolYear),
      content: SizedBox(
        width: 360,
        child: years.when(
          loading: () => const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Text(strings.noPermission),
          data: (list) => ListView(
            shrinkWrap: true,
            children: [
              RadioListTile<String?>(
                value: null,
                groupValue: selected,
                onChanged: (_) => choose(null),
                title: Text(strings.myOwnYear),
              ),
              for (final year in list)
                RadioListTile<String?>(
                  value: year.id,
                  groupValue: selected,
                  onChanged: (_) => choose(year.id),
                  title: Text(year.name),
                  subtitle: year.isCurrent
                      ? Text(strings.currentYear)
                      : (year.firstDay == null
                          ? null
                          : Text('${year.firstDay} → ${year.lastDay ?? ''}')),
                ),
              if (list.isEmpty) Text(strings.nothingHere),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(strings.cancel),
        ),
      ],
    );
  }
}
