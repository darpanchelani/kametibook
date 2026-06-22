import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/app_button.dart';
import '../../auth/providers/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 36,
                      backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                      child: Icon(Icons.person, color: Theme.of(context).colorScheme.primary, size: 38),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.fullName ?? 'Kameti User',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(user?.phone ?? ''),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.location_city_outlined),
                    title: const Text('City'),
                    subtitle: Text(user?.city ?? 'Pakistan'),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('App Version'),
                    subtitle: Text('1.0.0'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.group_add_outlined),
                    title: const Text('Join Kameti'),
                    subtitle: const Text('Enter invite code shared by organizer'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.joinKameti),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Notification Preferences'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.notificationPreferences),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.security_outlined),
                    title: const Text('Security Center'),
                    subtitle: const Text('Privacy, disputes, trust score, and account requests'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.securityCenter),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            AppButton(
              label: 'Logout',
              icon: Icons.logout,
              isOutlined: true,
              onPressed: () {
                ref.read(authControllerProvider.notifier).logout();
                Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
