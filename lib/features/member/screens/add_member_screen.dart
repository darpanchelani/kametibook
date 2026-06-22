import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../../auth/providers/auth_controller.dart';
import '../../kameti/models/kameti_model.dart';
import '../../kameti/providers/kameti_controller.dart';
import '../../notifications/providers/notification_controller.dart';
import '../models/member_model.dart';
import '../providers/member_controller.dart';
import '../widgets/add_member_form.dart';

class AddMemberScreen extends ConsumerWidget {
  const AddMemberScreen({required this.kametiId, super.key});

  final String kametiId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kameti = _findKameti(ref.watch(kametiControllerProvider), kametiId);
    if (kameti == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Member')),
        body: const Center(child: Text('Kameti not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Member')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AddMemberForm(
              submitLabel: 'Add Member',
              onSubmit: (data) {
                final now = DateTime.now();
                final member = MemberModel(
                  id: now.microsecondsSinceEpoch.toString(),
                  kametiId: kameti.id,
                  fullName: data.fullName,
                  phone: data.phone,
                  city: data.city,
                  cnic: data.cnic,
                  whatsappNumber: data.whatsappNumber,
                  email: data.email,
                  notes: data.notes,
                  role: MemberRole.member,
                  status: MemberStatus.active,
                  hasReceivedKameti: false,
                  joinedAt: now,
                  createdAt: now,
                  updatedAt: now,
                );
                final error = ref.read(memberControllerProvider.notifier).addMemberForKameti(
                      kameti: kameti,
                      member: member,
                    );
                if (error != null) return error;
                ref.read(notificationControllerProvider.notifier).createMemberAddedNotification(
                      userId: ref.read(authControllerProvider).user?.id ?? 'mock-user',
                      kameti: kameti,
                      member: member,
                    );
                SnackbarHelper.showSuccess(context, 'Member added successfully.');
                Navigator.of(context).pop();
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  KametiModel? _findKameti(List<KametiModel> kametis, String id) {
    for (final kameti in kametis) {
      if (kameti.id == id) return kameti;
    }
    return null;
  }
}
