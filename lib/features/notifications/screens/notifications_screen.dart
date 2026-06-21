import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notifications')),
      body: const SafeArea(
        child: EmptyState(
          icon: Icons.notifications_none_outlined,
          title: 'No notifications yet.',
        ),
      ),
    );
  }
}
