import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/session_controller.dart';

class CoupleOnboardingScreen extends ConsumerStatefulWidget {
  const CoupleOnboardingScreen({super.key});

  @override
  ConsumerState<CoupleOnboardingScreen> createState() =>
      _CoupleOnboardingScreenState();
}

class _CoupleOnboardingScreenState
    extends ConsumerState<CoupleOnboardingScreen> {
  final _partnerController = TextEditingController();
  final _inviteController = TextEditingController();
  var _relationshipStartDate = DateTime.now().subtract(
    const Duration(days: 365),
  );

  @override
  void dispose() {
    _partnerController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(sessionControllerProvider).currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Couple Calendar')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(
              '${user?.displayName ?? '사용자'}님, 커플 공간을 연결해요',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              '일정, 기념일, 기록은 커플 공간 안에서 함께 공유돼요.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),
            _OnboardingPanel(
              title: '새 커플 공간 만들기',
              icon: Icons.favorite_outline,
              children: [
                TextField(
                  controller: _partnerController,
                  decoration: const InputDecoration(
                    labelText: '상대방 이름',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.done,
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.event_outlined),
                  title: const Text('처음 만난 날 또는 사귄 날'),
                  subtitle: Text(_dateLabel(_relationshipStartDate)),
                  trailing: const Icon(Icons.edit_calendar_outlined),
                  onTap: _pickRelationshipDate,
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      ref
                          .read(sessionControllerProvider.notifier)
                          .createDemoCouple(
                            partnerName: _partnerController.text,
                            relationshipStartDate: _relationshipStartDate,
                          );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('커플 공간 만들기'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            _OnboardingPanel(
              title: '초대 코드로 참여',
              icon: Icons.group_add_outlined,
              children: [
                TextField(
                  controller: _inviteController,
                  decoration: const InputDecoration(
                    labelText: '초대 코드',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ref
                          .read(sessionControllerProvider.notifier)
                          .joinDemoCouple(_inviteController.text);
                    },
                    icon: const Icon(Icons.login),
                    label: const Text('참여하기'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickRelationshipDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _relationshipStartDate,
      firstDate: DateTime(1990),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked == null) {
      return;
    }
    setState(() => _relationshipStartDate = picked);
  }
}

class _OnboardingPanel extends StatelessWidget {
  const _OnboardingPanel({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon),
              const SizedBox(width: 8),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

String _dateLabel(DateTime value) {
  return '${value.year}.${value.month.toString().padLeft(2, '0')}.${value.day.toString().padLeft(2, '0')}';
}
