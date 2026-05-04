import 'package:flutter/material.dart';

import '../../../anniversaries/presentation/screens/anniversary_screen.dart';
import '../../../date_records/presentation/screens/date_record_screen.dart';
import '../../../todos/presentation/screens/todo_screen.dart';
import 'record_placeholder_screen.dart';

class RecordsScreen extends StatelessWidget {
  const RecordsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final modules = [
      _RecordModule(
        title: '기념일',
        subtitle: '처음 만난 날, 100일, 1주년',
        icon: Icons.celebration_outlined,
        color: const Color(0xFFC67C4E),
        screen: const AnniversaryScreen(),
      ),
      _RecordModule(
        title: 'Todo',
        subtitle: '데이트 아이디어와 함께 할 일',
        icon: Icons.check_circle_outline,
        color: const Color(0xFF4D7C8A),
        screen: const TodoScreen(),
      ),
      _RecordModule(
        title: '데이트 기록',
        subtitle: '장소, 사진, 메모',
        icon: Icons.place_outlined,
        color: const Color(0xFF5D8C61),
        screen: const DateRecordScreen(),
      ),
      _RecordModule(
        title: '싸움 기록',
        subtitle: '내용, 원인, 화해 여부',
        icon: Icons.favorite_border,
        color: const Color(0xFF9B5C64),
        screen: const RecordPlaceholderScreen(
          title: '싸움 기록',
          body: '민감한 기록이라 캘린더에는 요약만 연결하고, 자세한 내용은 이 화면 안에서 열도록 만들 예정이에요.',
        ),
      ),
      _RecordModule(
        title: '리뷰',
        subtitle: '영화, 드라마, 와인, 식당',
        icon: Icons.star_border,
        color: const Color(0xFF7C6A9E),
        screen: const RecordPlaceholderScreen(
          title: '리뷰',
          body: '함께 본 콘텐츠나 먹어본 와인, 다녀온 식당을 별점과 감상으로 기록할 예정이에요.',
        ),
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('기록')),
      body: SafeArea(
        child: ListView.separated(
          padding: const EdgeInsets.all(20),
          itemCount: modules.length,
          separatorBuilder: (_, _) => const SizedBox(height: 10),
          itemBuilder: (context, index) {
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
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.screen,
  });

  final String title;
  final String subtitle;
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
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: module.color.withValues(alpha: 0.14),
          foregroundColor: module.color,
          child: Icon(module.icon),
        ),
        title: Text(
          module.title,
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
        subtitle: Text(module.subtitle),
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
