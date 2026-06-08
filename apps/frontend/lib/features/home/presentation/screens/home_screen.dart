import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/presentation/app_shell.dart';
import '../../../../app/theme/app_theme.dart';
import '../../../../core/time/calendar_date_utils.dart' as dates;
import '../../../anniversaries/domain/models/anniversary.dart';
import '../../../anniversaries/presentation/controllers/anniversary_controller.dart';
import '../../../anniversaries/presentation/screens/anniversary_screen.dart';
import '../../../calendar/domain/models/calendar_event.dart';
import '../../../calendar/presentation/controllers/calendar_controller.dart';
import '../../../calendar/presentation/screens/event_detail_screen.dart';
import '../controllers/home_controller.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final calendarState = ref.watch(calendarControllerProvider);
    final anniversaries = ref.watch(anniversariesProvider);
    final upcomingAnniversaries = ref.watch(
      upcomingAnniversaryOccurrencesProvider,
    );
    final homeState = ref.watch(homeControllerProvider);
    final today = dates.dateOnly(DateTime.now());
    final todayEvents = calendarState.events.where((event) {
      return _eventTouchesDate(event, today);
    }).toList()..sort(compareEventsForUi);
    final upcomingEvents = calendarState.events.where((event) {
      return !_eventVisibleEndDate(event).isBefore(today);
    }).toList()..sort(_compareUpcomingEvents);
    final reminderEvents =
        upcomingEvents
            .where(
              (event) => event.reminders.any((reminder) => reminder.enabled),
            )
            .toList()
          ..sort(_compareReminderEvents);
    final pinnedItems = _homePinnedItems(
      events: calendarState.events,
      anniversaryOccurrences: upcomingAnniversaries,
      pinnedEventIds: homeState.pinnedEventIds,
      pinnedAnniversaryIds: homeState.pinnedAnniversaryIds,
    );

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
          children: [
            _HomeHeader(
              notificationCount: reminderEvents.length,
              onOpenNotifications: () => _showNotificationSheet(
                context,
                events: reminderEvents,
                onOpenEvent: (event) => _openEvent(context, ref, event),
              ),
            ),
            const SizedBox(height: 14),
            _CoverHero(
              imageUrl: homeState.coverImageUrl,
              todayEventCount: todayEvents.length,
              onEditImage: () => _showCoverImageDialog(context, ref),
            ),
            const SizedBox(height: 24),
            _PinnedSection(
              items: pinnedItems,
              onManage: () => _showHomePinSheet(
                context,
                ref,
                events: upcomingEvents,
                anniversaries: anniversaries,
                upcomingOccurrences: upcomingAnniversaries,
              ),
              onOpenEvent: (event) => _openEvent(context, ref, event),
              onOpenAnniversary: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const AnniversaryScreen()),
              ),
              onRemoveEvent: (eventId) {
                ref
                    .read(homeControllerProvider.notifier)
                    .removeEventPin(eventId);
              },
              onRemoveAnniversary: (anniversaryId) {
                ref
                    .read(homeControllerProvider.notifier)
                    .removeAnniversaryPin(anniversaryId);
              },
            ),
            const SizedBox(height: 20),
            _SectionTitle(
              title: '다가오는 일정',
              actionIcon: Icons.calendar_month_outlined,
              onPressed: () =>
                  ref.read(selectedAppTabProvider.notifier).selectCalendar(),
            ),
            if (upcomingEvents.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...upcomingEvents.take(5).map((event) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _EventCard(
                    event: event,
                    onTap: () => _openEvent(context, ref, event),
                  ),
                );
              }),
            ],
          ],
        ),
      ),
    );
  }

  void _openEvent(BuildContext context, WidgetRef ref, CalendarEvent event) {
    ref.read(calendarControllerProvider.notifier).selectDate(event.startAt);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: event.id)),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({
    required this.notificationCount,
    required this.onOpenNotifications,
  });

  final int notificationCount;
  final VoidCallback onOpenNotifications;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(11),
            ),
            child: const Icon(
              Icons.favorite_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Couple Calendar', style: theme.textTheme.titleSmall),
                Text('우리의 하루', style: theme.textTheme.bodySmall),
              ],
            ),
          ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: '알림',
                onPressed: onOpenNotifications,
                style: IconButton.styleFrom(
                  backgroundColor: theme.colorScheme.surface,
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                icon: const Icon(Icons.notifications_none_rounded),
              ),
              if (notificationCount > 0)
                Positioned(
                  top: -2,
                  right: -2,
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 18),
                    height: 18,
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: AppPalette.rose,
                      borderRadius: BorderRadius.circular(99),
                      border: Border.all(color: theme.colorScheme.surface),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$notificationCount',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoverHero extends StatelessWidget {
  const _CoverHero({
    required this.imageUrl,
    required this.todayEventCount,
    required this.onEditImage,
  });

  final String? imageUrl;
  final int todayEventCount;
  final VoidCallback onEditImage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Material(
      color: AppPalette.paper,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: const BorderSide(color: AppPalette.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
            child: LayoutBuilder(
              builder: (context, constraints) {
                final mediaHeight = hasImage
                    ? (constraints.maxWidth > 520
                          ? 300.0
                          : constraints.maxWidth / 1.65)
                    : 132.0;
                return SizedBox(
                  height: mediaHeight,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (hasImage)
                        Image.network(
                          imageUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const _CoverPlaceholder(),
                        )
                      else
                        const _CoverPlaceholder(),
                      if (hasImage)
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.10),
                          ),
                        ),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: IconButton.filled(
                          tooltip: '대표 사진',
                          onPressed: onEditImage,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.92,
                            ),
                            foregroundColor: AppPalette.ink,
                          ),
                          icon: Icon(
                            hasImage
                                ? Icons.edit_outlined
                                : Icons.add_photo_alternate_outlined,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 11, 14, 12),
            child: Row(
              children: [
                const Icon(Icons.favorite, color: AppPalette.rose, size: 19),
                const SizedBox(width: 8),
                Text(
                  '오늘',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    dates.formatDateLabel(DateTime.now()),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                ),
                Text(
                  '$todayEventCount',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: todayEventCount == 0
                        ? AppPalette.mutedInk
                        : AppPalette.rose,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CoverPlaceholder extends StatelessWidget {
  const _CoverPlaceholder();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: AppPalette.shell),
      child: Center(
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            color: AppPalette.paper,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppPalette.line),
          ),
          child: const Icon(
            Icons.photo_camera_outlined,
            color: AppPalette.mutedInk,
            size: 24,
          ),
        ),
      ),
    );
  }
}

class _PinnedSection extends StatelessWidget {
  const _PinnedSection({
    required this.items,
    required this.onManage,
    required this.onOpenEvent,
    required this.onOpenAnniversary,
    required this.onRemoveEvent,
    required this.onRemoveAnniversary,
  });

  final List<_HomePinnedItem> items;
  final VoidCallback onManage;
  final ValueChanged<CalendarEvent> onOpenEvent;
  final VoidCallback onOpenAnniversary;
  final ValueChanged<String> onRemoveEvent;
  final ValueChanged<String> onRemoveAnniversary;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(
          title: '고정',
          actionIcon: Icons.tune_outlined,
          onPressed: onManage,
        ),
        if (items.isNotEmpty) ...[
          const SizedBox(height: 8),
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (context, index) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final item = items[index];
                return _PinnedCard(
                  item: item,
                  onTap: item.event == null
                      ? onOpenAnniversary
                      : () => onOpenEvent(item.event!),
                  onRemove: () {
                    if (item.event != null) {
                      onRemoveEvent(item.id);
                    } else {
                      onRemoveAnniversary(item.id);
                    }
                  },
                );
              },
            ),
          ),
        ],
      ],
    );
  }
}

class _PinnedCard extends StatelessWidget {
  const _PinnedCard({required this.item, required this.onRemove, this.onTap});

  final _HomePinnedItem item;
  final VoidCallback onRemove;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: 210,
      child: Material(
        color: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(item.icon, size: 18, color: item.color),
                    const Spacer(),
                    IconButton(
                      tooltip: '홈에서 제거',
                      visualDensity: VisualDensity.compact,
                      onPressed: onRemove,
                      icon: const Icon(Icons.close, size: 18),
                    ),
                  ],
                ),
                Text(
                  item.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  item.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.actionIcon,
    required this.onPressed,
  });

  final String title;
  final IconData actionIcon;
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
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w900),
          ),
        ),
        IconButton(
          tooltip: title,
          onPressed: onPressed,
          icon: Icon(actionIcon),
        ),
      ],
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({required this.event, required this.onTap});

  final CalendarEvent event;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = Color(event.colorValue);
    final theme = Theme.of(context);
    final displayDate = _eventDisplayDate(event);
    return Material(
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 66),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            child: Row(
              children: [
                SizedBox(
                  width: 42,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${displayDate.month}월',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppPalette.mutedInk,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${displayDate.day}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: color,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        event.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dates.formatEventDateRangeLabel(
                          startAt: event.startAt,
                          endAt: event.endAt,
                          isAllDay: event.isAllDay,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Icon(
                  event.kind == CalendarEventKind.date
                      ? Icons.favorite
                      : Icons.chevron_right,
                  color: event.kind == CalendarEventKind.date
                      ? AppPalette.rose
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _HomePinManagerSheet extends ConsumerWidget {
  const _HomePinManagerSheet({
    required this.events,
    required this.anniversaries,
    required this.upcomingOccurrences,
    required this.scrollController,
  });

  final List<CalendarEvent> events;
  final List<Anniversary> anniversaries;
  final List<AnniversaryOccurrence> upcomingOccurrences;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeState = ref.watch(homeControllerProvider);
    final occurrenceByAnniversaryId = {
      for (final occurrence in upcomingOccurrences)
        occurrence.anniversaryId: occurrence,
    };

    return SafeArea(
      child: ListView(
        controller: scrollController,
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text(
            '홈에 추가',
            style: Theme.of(
              context,
            ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          _SheetGroupTitle(text: '일정'),
          if (events.isEmpty)
            const _SheetEmpty(text: '없음')
          else
            ...events.take(12).map((event) {
              final selected = homeState.pinnedEventIds.contains(event.id);
              return _PinCandidateTile(
                icon: event.kind == CalendarEventKind.date
                    ? Icons.favorite
                    : Icons.event_outlined,
                title: event.title,
                subtitle: dates.formatEventDateRangeLabel(
                  startAt: event.startAt,
                  endAt: event.endAt,
                  isAllDay: event.isAllDay,
                ),
                selected: selected,
                onTap: () {
                  ref
                      .read(homeControllerProvider.notifier)
                      .toggleEventPin(event.id);
                },
              );
            }),
          const SizedBox(height: 18),
          _SheetGroupTitle(text: '기념일'),
          if (anniversaries.isEmpty)
            const _SheetEmpty(text: '없음')
          else
            ...anniversaries.map((anniversary) {
              final occurrence = occurrenceByAnniversaryId[anniversary.id];
              final selected = homeState.pinnedAnniversaryIds.contains(
                anniversary.id,
              );
              return _PinCandidateTile(
                icon: Icons.celebration_outlined,
                title: anniversary.title,
                subtitle: occurrence == null
                    ? dates.formatDateLabel(anniversary.baseDate)
                    : '${dates.formatDateLabel(occurrence.date)} · ${occurrence.label}',
                selected: selected,
                onTap: () {
                  ref
                      .read(homeControllerProvider.notifier)
                      .toggleAnniversaryPin(anniversary.id);
                },
              );
            }),
        ],
      ),
    );
  }
}

class _SheetGroupTitle extends StatelessWidget {
  const _SheetGroupTitle({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SheetEmpty extends StatelessWidget {
  const _SheetEmpty({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(
        text,
        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
      ),
    );
  }
}

class _PinCandidateTile extends StatelessWidget {
  const _PinCandidateTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: IconButton.filledTonal(
        tooltip: selected ? '홈에서 제거' : '홈에 추가',
        onPressed: onTap,
        icon: Icon(selected ? Icons.check : Icons.add),
      ),
    );
  }
}

class _HomePinnedItem {
  const _HomePinnedItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.event,
  });

  final String id;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final CalendarEvent? event;
}

List<_HomePinnedItem> _homePinnedItems({
  required List<CalendarEvent> events,
  required List<AnniversaryOccurrence> anniversaryOccurrences,
  required Set<String> pinnedEventIds,
  required Set<String> pinnedAnniversaryIds,
}) {
  final eventItems = events
      .where((event) => pinnedEventIds.contains(event.id))
      .map(
        (event) => _HomePinnedItem(
          id: event.id,
          title: event.title,
          subtitle: dates.formatEventDateRangeLabel(
            startAt: event.startAt,
            endAt: event.endAt,
            isAllDay: event.isAllDay,
          ),
          icon: event.kind == CalendarEventKind.date
              ? Icons.favorite
              : Icons.event_outlined,
          color: event.kind == CalendarEventKind.date
              ? AppPalette.rose
              : Color(event.colorValue),
          event: event,
        ),
      );

  final anniversaryItems = anniversaryOccurrences
      .where(
        (occurrence) => pinnedAnniversaryIds.contains(occurrence.anniversaryId),
      )
      .map(
        (occurrence) => _HomePinnedItem(
          id: occurrence.anniversaryId,
          title: occurrence.title,
          subtitle:
              '${dates.formatDateLabel(occurrence.date)} · ${occurrence.label}',
          icon: Icons.celebration_outlined,
          color: AppPalette.violet,
        ),
      );

  return [...eventItems, ...anniversaryItems];
}

int _compareUpcomingEvents(CalendarEvent left, CalendarEvent right) {
  final today = dates.dateOnly(DateTime.now());
  final leftDate = _eventVisibleStartDate(left).isBefore(today)
      ? today
      : _eventVisibleStartDate(left);
  final rightDate = _eventVisibleStartDate(right).isBefore(today)
      ? today
      : _eventVisibleStartDate(right);
  final dateCompare = leftDate.compareTo(rightDate);
  if (dateCompare != 0) {
    return dateCompare;
  }
  return compareEventsForUi(left, right);
}

bool _eventTouchesDate(CalendarEvent event, DateTime date) {
  final target = dates.dateOnly(date);
  return !target.isBefore(_eventVisibleStartDate(event)) &&
      !target.isAfter(_eventVisibleEndDate(event));
}

DateTime _eventVisibleStartDate(CalendarEvent event) {
  return dates.dateOnly(event.startAt);
}

DateTime _eventVisibleEndDate(CalendarEvent event) {
  if (event.isAllDay) {
    return dates.dateOnly(event.endAt).subtract(const Duration(days: 1));
  }
  return dates.dateOnly(event.endAt);
}

DateTime _eventDisplayDate(CalendarEvent event) {
  final today = dates.dateOnly(DateTime.now());
  final startDate = _eventVisibleStartDate(event);
  final endDate = _eventVisibleEndDate(event);
  if (!today.isBefore(startDate) && !today.isAfter(endDate)) {
    return today;
  }
  return startDate;
}

int _compareReminderEvents(CalendarEvent left, CalendarEvent right) {
  return _nextReminderAt(left).compareTo(_nextReminderAt(right));
}

DateTime _nextReminderAt(CalendarEvent event) {
  final reminders =
      event.reminders.where((reminder) => reminder.enabled).toList()
        ..sort((left, right) => left.remindAt.compareTo(right.remindAt));
  return reminders.first.remindAt;
}

Future<void> _showNotificationSheet(
  BuildContext context, {
  required List<CalendarEvent> events,
  required ValueChanged<CalendarEvent> onOpenEvent,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (sheetContext) {
      final theme = Theme.of(sheetContext);
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text('다가오는 알림', style: theme.textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('알림을 설정한 일정만 보여드려요.', style: theme.textTheme.bodySmall),
              const SizedBox(height: 16),
              if (events.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 28),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '예정된 알림이 없어요.',
                    style: theme.textTheme.bodyMedium,
                  ),
                )
              else
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: events.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final event = events[index];
                      final reminder = event.reminders
                          .where((item) => item.enabled)
                          .reduce(
                            (left, right) =>
                                left.remindAt.isBefore(right.remindAt)
                                ? left
                                : right,
                          );
                      return ListTile(
                        tileColor: theme.colorScheme.surface,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                          side: BorderSide(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        leading: CircleAvatar(
                          backgroundColor: Color(
                            event.colorValue,
                          ).withValues(alpha: 0.12),
                          foregroundColor: Color(event.colorValue),
                          child: const Icon(Icons.notifications_outlined),
                        ),
                        title: Text(
                          event.title,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        subtitle: Text(
                          '${dates.formatDateLabel(reminder.remindAt)} '
                          '${dates.formatTimeLabel(reminder.remindAt)}',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          onOpenEvent(event);
                        },
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _showCoverImageDialog(BuildContext context, WidgetRef ref) async {
  final currentUrl = ref.read(homeControllerProvider).coverImageUrl ?? '';
  final controller = TextEditingController(text: currentUrl);
  await showDialog<void>(
    context: context,
    builder: (context) {
      return AlertDialog(
        title: const Text('대표 사진'),
        content: TextField(
          controller: controller,
          decoration: const InputDecoration(
            labelText: '이미지 URL',
            prefixIcon: Icon(Icons.link),
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(homeControllerProvider.notifier).clearCoverImage();
              Navigator.of(context).pop();
            },
            child: const Text('제거'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(homeControllerProvider.notifier)
                  .setCoverImageUrl(controller.text);
              Navigator.of(context).pop();
            },
            child: const Text('저장'),
          ),
        ],
      );
    },
  );
  controller.dispose();
}

void _showHomePinSheet(
  BuildContext context,
  WidgetRef ref, {
  required List<CalendarEvent> events,
  required List<Anniversary> anniversaries,
  required List<AnniversaryOccurrence> upcomingOccurrences,
}) {
  showModalBottomSheet<void>(
    context: context,
    showDragHandle: false,
    isScrollControlled: true,
    builder: (context) {
      return DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.72,
        minChildSize: 0.45,
        maxChildSize: 0.92,
        builder: (context, scrollController) {
          return _HomePinManagerSheet(
            events: events,
            anniversaries: anniversaries,
            upcomingOccurrences: upcomingOccurrences,
            scrollController: scrollController,
          );
        },
      );
    },
  );
}
