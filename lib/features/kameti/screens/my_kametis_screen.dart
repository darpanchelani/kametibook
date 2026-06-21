import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/empty_state.dart';
import '../../member/providers/member_controller.dart';
import '../providers/kameti_controller.dart';
import '../widgets/kameti_card.dart';

class MyKametisScreen extends ConsumerWidget {
  const MyKametisScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kametis = ref.watch(kametiControllerProvider);
    ref.watch(memberControllerProvider);
    final memberController = ref.read(memberControllerProvider.notifier);
    return Scaffold(
      appBar: AppBar(title: const Text('My Kametis')),
      body: SafeArea(
        child: kametis.isEmpty
            ? EmptyState(
                icon: Icons.groups_2_outlined,
                title: 'No kameti groups yet',
                action: AppButton(
                  label: 'Create Kameti',
                  icon: Icons.add,
                  onPressed: () => Navigator.of(context).pushNamed(AppRoutes.createKameti),
                ),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final kameti = kametis[index];
                  return KametiCard(
                    kameti: kameti,
                    activeMembersCount: memberController.getActiveMembersCount(kameti.id),
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.kametiDetails, arguments: kameti.id),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: kametis.length,
              ),
      ),
      floatingActionButton: kametis.isEmpty
          ? null
          : FloatingActionButton(
              onPressed: () => Navigator.of(context).pushNamed(AppRoutes.createKameti),
              child: const Icon(Icons.add),
            ),
    );
  }
}
