import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/providers/auth_controller.dart';
import '../../kameti/screens/my_kametis_screen.dart';
import '../../notifications/providers/notification_controller.dart';
import '../../notifications/screens/notifications_screen.dart';
import '../../notifications/widgets/unread_badge.dart';
import '../../profile/screens/profile_screen.dart';
import 'home_screen.dart';

class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({this.initialTab = 0, super.key});

  final int initialTab;

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  late int _currentIndex = widget.initialTab;

  late final List<Widget> _screens = [
    const HomeScreen(),
    const MyKametisScreen(),
    const NotificationsScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(authControllerProvider).user?.id ?? 'mock-user';
    final unreadCount = ref.watch(notificationControllerProvider).where((item) => item.userId == userId && item.isUnread).length;
    return Scaffold(
      body: IndexedStack(index: _currentIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) => setState(() => _currentIndex = index),
        destinations: [
          const NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          const NavigationDestination(
            icon: Icon(Icons.groups_2_outlined),
            selectedIcon: Icon(Icons.groups_2),
            label: 'My Kametis',
          ),
          NavigationDestination(
            icon: UnreadBadge(count: unreadCount, child: const Icon(Icons.notifications_outlined)),
            selectedIcon: UnreadBadge(count: unreadCount, child: const Icon(Icons.notifications)),
            label: 'Notifications',
          ),
          const NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
