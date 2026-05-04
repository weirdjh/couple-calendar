import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/time/calendar_date_utils.dart' as dates;
import '../../../../app/presentation/app_shell.dart';
import '../../../anniversaries/presentation/controllers/anniversary_controller.dart';
import '../../../calendar/domain/models/calendar_event.dart';
import '../../../calendar/presentation/controllers/calendar_controller.dart';
import '../../../calendar/presentation/screens/event_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(calendarControllerProvider);
    final nextAnniversary = ref.watch(nextAnniversaryOccurrenceProvider);
    final today = dates.dateOnly(DateTime.now());
    final todayEvents = calendarState.events.where((event) {
      return dates.isSameDate(event.startAt, today);
    }).toList();
    final upcomingEvents = calendarState.events.where((event) {
      final eventDate = dates.dateOnly(event.startAt);
      return !eventDate.isBefore(today);
    }).toList()..sort(_compareUpcomingEvents);

    return Scaffold(
      appBar: AppBar(title: const Text('홈')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '오늘의 우리',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 16),
            _SummaryTile(
              icon: Icons.event_outlined,
              title: '오늘 일정',
              value: todayEvents.isEmpty
                  ? '등록된 일정 없음'
                  : '${todayEvents.length}개',
            ),
            const SizedBox(height: 10),
            _SummaryTile(
              icon: Icons.celebration_outlined,
              title: '다음 기념일',
              value: nextAnniversary == null
                  ? '등록된 기념일 없음'
                  : '${nextAnniversary.title} · ${nextAnniversary.label}',
              subtitle: nextAnniversary == null
                  ? null
                  : dates.formatDateLabel(nextAnniversary.date),
            ),
            const SizedBox(height: 20),
            _SectionHeader(
              title: '다가오는 일정',
              actionLabel: '캘린더에서 보기',
              onPressed: () =>
                  ref.read(selectedAppTabProvider.notifier).selectCalendar(),
            ),
            const SizedBox(height: 8),
            if (upcomingEvents.isEmpty)
              const _EmptyBlock(text: '다가오는 일정이 아직 없어요.')
            else
              ...upcomingEvents.take(3).map((event) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CompactEventRow(
                    color: Color(event.colorValue),
                    title: event.title,
                    subtitle: dates.formatDateLabel(event.startAt),
                    onTap: () {
                      ref
                          .read(calendarControllerProvider.notifier)
                          .selectDate(event.startAt);
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => EventDetailScreen(eventId: event.id),
                        ),
                      );
                    },
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile({
    required this.icon,
    required this.title,
    required this.value,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String value;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Icon(icon),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (subtitle != null) Text(subtitle!),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onPressed,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        TextButton(onPressed: onPressed, child: Text(actionLabel)),
      ],
    );
  }
}

class _CompactEventRow extends StatelessWidget {
  const _CompactEventRow({
    required this.color,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final Color color;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: onTap,
      tileColor: Theme.of(context).colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      leading: CircleAvatar(backgroundColor: color, radius: 6),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle),
    );
  }
}

int _compareUpcomingEvents(CalendarEvent left, CalendarEvent right) {
  final leftDate = dates.dateOnly(left.startAt);
  final rightDate = dates.dateOnly(right.startAt);
  final dateCompare = leftDate.compareTo(rightDate);
  if (dateCompare != 0) {
    return dateCompare;
  }
  return compareEventsForUi(left, right);
}

class _EmptyBlock extends StatelessWidget {
  const _EmptyBlock({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text),
    );
  }
}
