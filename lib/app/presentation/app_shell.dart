import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/presentation/controllers/session_controller.dart';
import '../../features/auth/presentation/screens/couple_onboarding_screen.dart';
import '../../features/calendar/presentation/screens/calendar_screen.dart';
import '../../features/home/presentation/screens/home_screen.dart';
import '../../features/records/presentation/screens/records_screen.dart';
import '../../features/settings/presentation/screens/settings_screen.dart';

class AppShell extends ConsumerStatefulWidget {
  const AppShell({super.key});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

final selectedAppTabProvider = NotifierProvider<AppTabController, int>(
  AppTabController.new,
);

class AppTabController extends Notifier<int> {
  @override
  int build() => 1;

  void selectCalendar() {
    state = 1;
  }

  void selectIndex(int index) {
    state = index;
  }
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    if (!session.isSignedIn || !session.hasCouple) {
      return const CoupleOnboardingScreen();
    }
    final selectedIndex = ref.watch(selectedAppTabProvider);

    final destinations = [
      _Destination(
        label: '홈',
        icon: Icons.home_outlined,
        selectedIcon: Icons.home,
        screen: const HomeScreen(),
      ),
      _Destination(
        label: '캘린더',
        icon: Icons.calendar_month_outlined,
        selectedIcon: Icons.calendar_month,
        screen: const CalendarScreen(),
      ),
      _Destination(
        label: '기록',
        icon: Icons.collections_bookmark_outlined,
        selectedIcon: Icons.collections_bookmark,
        screen: const RecordsScreen(),
      ),
      _Destination(
        label: '설정',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        screen: const SettingsScreen(),
      ),
    ];

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: destinations
            .map((destination) => destination.screen)
            .toList(),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: selectedIndex,
        onDestinationSelected: (index) {
          ref.read(selectedAppTabProvider.notifier).selectIndex(index);
        },
        destinations: destinations.map((destination) {
          return NavigationDestination(
            icon: Icon(destination.icon),
            selectedIcon: Icon(destination.selectedIcon),
            label: destination.label,
          );
        }).toList(),
      ),
    );
  }
}

class _Destination {
  const _Destination({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.screen,
  });

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final Widget screen;
}
