import 'package:flutter/material.dart';

import '../../../core/widgets/empty_state.dart';

class AddMembersPlaceholderScreen extends StatelessWidget {
  const AddMembersPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Members')),
      body: const SafeArea(
        child: EmptyState(
          icon: Icons.group_add_outlined,
          title: 'Members',
          message: 'Coming in next phases.',
        ),
      ),
    );
  }
}
