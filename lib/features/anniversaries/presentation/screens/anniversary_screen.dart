import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/calendar_date_utils.dart' as dates;
import '../controllers/anniversary_controller.dart';

class AnniversaryScreen extends ConsumerWidget {
  const AnniversaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final anniversaries = ref.watch(anniversariesProvider);
    final upcoming = ref.watch(upcomingAnniversaryOccurrencesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('기념일')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '등록된 기념일',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (anniversaries.isEmpty)
              const _EmptyPanel(text: '등록된 기념일이 없어요.')
            else
              ...anniversaries.map((anniversary) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _AnniversaryBaseTile(
                    title: anniversary.title,
                    dateLabel: dates.formatDateLabel(anniversary.baseDate),
                  ),
                );
              }),
            const SizedBox(height: 20),
            Text(
              '다가오는 마일스톤',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            if (upcoming.isEmpty)
              const _EmptyPanel(text: '다가오는 기념일이 없어요.')
            else
              ...upcoming.map((occurrence) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _MilestoneTile(
                    title: occurrence.title,
                    label: occurrence.label,
                    dateLabel: dates.formatDateLabel(occurrence.date),
                    daysLeft: occurrence.date
                        .difference(dates.dateOnly(DateTime.now()))
                        .inDays,
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _AnniversaryBaseTile extends StatelessWidget {
  const _AnniversaryBaseTile({required this.title, required this.dateLabel});

  final String title;
  final String dateLabel;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      tileColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: const Icon(Icons.favorite_outline),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      subtitle: Text(dateLabel),
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({
    required this.title,
    required this.label,
    required this.dateLabel,
    required this.daysLeft,
  });

  final String title;
  final String label;
  final String dateLabel;
  final int daysLeft;

  @override
  Widget build(BuildContext context) {
    final subtitle = daysLeft == 0 ? '오늘' : '$daysLeft일 남음';
    return ListTile(
      tileColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.tertiaryContainer,
        foregroundColor: Theme.of(context).colorScheme.onTertiaryContainer,
        child: const Icon(Icons.celebration_outlined),
      ),
      title: Text(
        '$title $label',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
      subtitle: Text('$dateLabel · $subtitle'),
    );
  }
}

class _EmptyPanel extends StatelessWidget {
  const _EmptyPanel({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text),
    );
  }
}
