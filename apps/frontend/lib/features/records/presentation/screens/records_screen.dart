import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../../core/time/calendar_date_utils.dart' as dates;
import '../../../anniversaries/domain/models/anniversary.dart';
import '../../../anniversaries/presentation/controllers/anniversary_controller.dart';
import '../../../anniversaries/presentation/screens/anniversary_screen.dart';
import '../../../date_records/domain/models/date_record.dart';
import '../../../date_records/presentation/controllers/date_record_controller.dart';
import '../../../date_records/presentation/screens/date_record_screen.dart';
import '../../../reviews/domain/models/review.dart';
import '../../../reviews/presentation/controllers/review_controller.dart';
import '../../../reviews/presentation/screens/review_screen.dart';
import '../../../todos/presentation/controllers/todo_controller.dart';
import '../../../todos/presentation/screens/todo_screen.dart';

class RecordsScreen extends ConsumerWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final nextAnniversary = ref.watch(nextAnniversaryOccurrenceProvider);
    final todoState = ref.watch(todoControllerProvider);
    final dateRecordState = ref.watch(dateRecordControllerProvider);
    final reviewState = ref.watch(reviewControllerProvider);
    final modules = [
      _RecordModule(
        title: '기념일',
        eyebrow: _anniversaryEyebrow(nextAnniversary),
        summary: nextAnniversary?.title ?? '소중한 날을 기록해요',
        icon: Icons.celebration_outlined,
        color: AppPalette.amber,
        screen: const AnniversaryScreen(),
      ),
      _RecordModule(
        title: '버킷리스트',
        eyebrow: '${todoState.items.length}개의 바람',
        summary: todoState.completions.isEmpty
            ? '함께 이루고 싶은 일'
            : '${todoState.completions.length}번 함께 완료',
        icon: Icons.check_circle_outline,
        color: AppPalette.teal,
        screen: const TodoScreen(),
      ),
      _RecordModule(
        title: '데이트 기록',
        eyebrow: '${dateRecordState.records.length}개의 추억',
        summary: _latestDateRecordSummary(dateRecordState.records),
        icon: Icons.place_outlined,
        color: AppPalette.sage,
        screen: const DateRecordScreen(),
      ),
      _RecordModule(
        title: '리뷰',
        eyebrow: '${reviewState.reviews.length}개의 리뷰',
        summary: _reviewSummary(reviewState.reviews),
        icon: Icons.star_border,
        color: AppPalette.rose,
        screen: const ReviewScreen(),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          children: [
            Text('기록', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 4),
            Text(
              '함께 만든 순간들을 모아보세요.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final columns = constraints.maxWidth >= 720 ? 4 : 2;
                const spacing = 10.0;
                final cardWidth =
                    (constraints.maxWidth - spacing * (columns - 1)) / columns;
                return Wrap(
                  spacing: spacing,
                  runSpacing: spacing,
                  children: modules
                      .map(
                        (module) => SizedBox(
                          width: cardWidth,
                          height: 172,
                          child: _RecordModuleCard(module: module),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _RecordModule {
  const _RecordModule({
    required this.title,
    required this.eyebrow,
    required this.summary,
    required this.icon,
    required this.color,
    required this.screen,
  });

  final String title;
  final String eyebrow;
  final String summary;
  final IconData icon;
  final Color color;
  final Widget screen;
}

class _RecordModuleCard extends StatelessWidget {
  const _RecordModuleCard({required this.module});

  final _RecordModule module;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: module.color.withValues(alpha: 0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(color: module.color.withValues(alpha: 0.24)),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => module.screen));
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: AppPalette.paper,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: module.color.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Icon(module.icon, color: module.color, size: 21),
                  ),
                  const Spacer(),
                  Icon(Icons.arrow_outward, size: 17, color: module.color),
                ],
              ),
              const Spacer(),
              Text(
                module.eyebrow,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: module.color,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                module.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium,
              ),
              const SizedBox(height: 3),
              Text(
                module.summary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _anniversaryEyebrow(AnniversaryOccurrence? occurrence) {
  if (occurrence == null) {
    return '다가오는 기념일';
  }
  final remaining = dates
      .dateOnly(occurrence.date)
      .difference(dates.dateOnly(DateTime.now()))
      .inDays;
  return remaining == 0 ? '오늘' : 'D-$remaining';
}

String _latestDateRecordSummary(List<DateRecord> records) {
  if (records.isEmpty) {
    return '우리의 데이트를 남겨요';
  }
  final latest = [...records]
    ..sort((left, right) => right.date.compareTo(left.date));
  return latest.first.title;
}

String _reviewSummary(List<Review> reviews) {
  if (reviews.isEmpty) {
    return '함께 본 것들을 평가해요';
  }
  final average =
      reviews.fold<double>(0, (sum, review) => sum + review.rating) /
      reviews.length;
  return '평균 ${average.toStringAsFixed(1)}점';
}
