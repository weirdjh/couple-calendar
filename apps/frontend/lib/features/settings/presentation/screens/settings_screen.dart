import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/firebase/firebase_bootstrap.dart';
import '../../../auth/presentation/controllers/session_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionControllerProvider);
    final user = session.currentUser;
    final couple = session.currentCouple;

    return Scaffold(
      appBar: AppBar(title: const Text('설정')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            _SettingsSection(
              title: '사용자',
              children: [
                _InfoRow(label: '현재 사용자', value: user?.displayName ?? '-'),
                _InfoRow(label: '사용자 ID', value: user?.id ?? '-'),
                _InfoRow(
                  label: '상대방',
                  value: couple?.partnerDisplayName ?? '-',
                ),
                _InfoRow(label: '커플 공간', value: couple?.id ?? '-'),
                _InfoRow(label: '초대 코드', value: couple?.inviteCode ?? '-'),
              ],
            ),
            const SizedBox(height: 12),
            _SettingsSection(
              title: '데이터',
              children: [
                _InfoRow(
                  label: '저장소',
                  value: switch (appDataMode) {
                    AppDataMode.api => 'API server',
                    AppDataMode.mock => 'Mock repository',
                    AppDataMode.firebase =>
                      useFirebaseEmulator ? 'Firebase emulator' : 'Firebase',
                  },
                ),
                _InfoRow(label: 'Firebase 설정', value: '대기 중'),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () {
                ref.read(sessionControllerProvider.notifier).resetCouple();
              },
              icon: const Icon(Icons.logout),
              label: const Text('커플 연결 다시 설정'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SettingsSection extends StatelessWidget {
  const _SettingsSection({required this.title, required this.children});

  final String title;
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
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}
