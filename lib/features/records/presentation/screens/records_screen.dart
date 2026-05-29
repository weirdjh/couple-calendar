import 'package:flutter/material.dart';

import '../../../../app/theme/app_theme.dart';
import '../../../anniversaries/presentation/screens/anniversary_screen.dart';
import '../../../date_records/presentation/screens/date_record_screen.dart';
import '../../../reviews/presentation/screens/review_screen.dart';
import '../../../todos/presentation/screens/todo_screen.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = [
      _RecordModule(
        title: '기념일',
        icon: Icons.celebration_outlined,
        color: AppPalette.amber,
        screen: const AnniversaryScreen(),
      ),
      _RecordModule(
        title: '버킷리스트',
        icon: Icons.check_circle_outline,
        color: AppPalette.teal,
        screen: const TodoScreen(),
      ),
      _RecordModule(
        title: '데이트 기록',
        icon: Icons.place_outlined,
        color: AppPalette.sage,
        screen: const DateRecordScreen(),
      ),
      _RecordModule(
        title: '리뷰',
        icon: Icons.star_border,
        color: AppPalette.rose,
        screen: const ReviewScreen(),
      ),
    ];

    return Scaffold(
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
          itemCount: modules.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '기록',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _RecordModuleTile(module: modules[index]),
                ],
              );
            }
            return _RecordModuleTile(module: modules[index]);
          },
        ),
      ),
    );
  }
}

class _RecordModule {
  const _RecordModule({
    required this.title,
    required this.icon,
    required this.color,
    required this.screen,
  });

  final String title;
  final IconData icon;
  final Color color;
  final Widget screen;
}

class _RecordModuleTile extends StatelessWidget {
  const _RecordModuleTile({required this.module});

  final _RecordModule module;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: module.color.withValues(alpha: 0.10),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(module.icon, color: module.color),
        ),
        title: Text(
          module.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: () {
          Navigator.of(
            context,
          ).push(MaterialPageRoute(builder: (_) => module.screen));
        },
      ),
    );
  }
}
