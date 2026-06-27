import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../providers/friends_controller.dart';

class FriendProfileScreen extends ConsumerWidget {
  const FriendProfileScreen({required this.userId, super.key});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(friendsControllerProvider);
    final friend =
        ref.read(friendsControllerProvider.notifier).friendById(userId);
    final result = state.searchResults
        .where((item) => item.profile.id == userId)
        .firstOrNull;

    final name = friend?.friendName ?? result?.profile.fullName ?? 'Profile';
    final username = friend?.friendUsername ?? result?.profile.username ?? '';
    final phone = friend?.friendPhone ?? result?.profile.phone ?? '';
    final city = friend?.friendCity ?? result?.profile.city ?? '';
    final photo =
        friend?.friendPhotoUrl ?? result?.profile.profilePhotoUrl ?? '';

    if (friend == null && result == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Profile')),
        body: const EmptyState(
          icon: Icons.person_search_outlined,
          title: 'Profile not found. Search the user again.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFE7EFEB)),
              ),
              child: Column(
                children: [
                  ProfileAvatar(name: name, photoUrl: photo, radius: 42),
                  const SizedBox(height: 14),
                  Text(
                    name,
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w900),
                  ),
                  if (username.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text('@$username',
                        style: Theme.of(context).textTheme.bodyMedium),
                  ],
                  const SizedBox(height: 18),
                  _ProfileLine(
                      icon: Icons.phone_outlined, label: 'Phone', value: phone),
                  _ProfileLine(
                      icon: Icons.location_city_outlined,
                      label: 'City',
                      value: city),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (friend == null && result != null)
              AppButton(
                label: 'Add Friend',
                icon: Icons.person_add_alt_1_outlined,
                onPressed: () async {
                  final error = await ref
                      .read(friendsControllerProvider.notifier)
                      .addFriend(result.profile);
                  if (!context.mounted) return;
                  if (error != null) {
                    SnackbarHelper.showError(context, error);
                  } else {
                    SnackbarHelper.showSuccess(
                        context, 'Friend request sent to $name.');
                    Navigator.of(context).pop();
                  }
                },
              )
            else
              AppButton(
                label: 'Chat',
                icon: Icons.chat_bubble_outline,
                onPressed: () => Navigator.of(context)
                    .pushNamed(AppRoutes.chat, arguments: friend!.chatId),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileLine extends StatelessWidget {
  const _ProfileLine({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        children: [
          Icon(icon, color: const Color(0xFF087F5B)),
          const SizedBox(width: 10),
          Text('$label: ', style: const TextStyle(fontWeight: FontWeight.w800)),
          Expanded(child: Text(value.isEmpty ? 'Not provided' : value)),
        ],
      ),
    );
  }
}
