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

  @override
  void dispose() {
    _partnerController.dispose();
    _inviteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final user = session.currentUser;

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
            if (session.errorMessage != null) ...[
              const SizedBox(height: 16),
              _ErrorBanner(message: session.errorMessage!),
            ],
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
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      ref
                          .read(sessionControllerProvider.notifier)
                          .createDemoCouple(
                            partnerName: _partnerController.text,
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
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        message,
        style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
      ),
    );
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
