import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../models/member_model.dart';
import '../providers/member_controller.dart';
import '../widgets/add_member_form.dart';

class EditMemberScreen extends ConsumerWidget {
  const EditMemberScreen({
    required this.kametiId,
    required this.memberId,
    super.key,
  });

  final String kametiId;
  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    MemberModel? member;
    for (final item in ref.watch(memberControllerProvider)) {
      if (item.id == memberId) {
        member = item;
        break;
      }
    }
    final selectedMember = member;
    if (selectedMember == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Member')),
        body: const Center(child: Text('Member not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Member')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AddMemberForm(
              initialMember: selectedMember,
              allowStatusEditing: true,
              submitLabel: 'Update Member',
              onSubmit: (data) {
                final error = ref.read(memberControllerProvider.notifier).updateMember(
                      kametiId: kametiId,
                      memberId: memberId,
                      updatedMember: selectedMember.copyWith(
                        fullName: data.fullName,
                        phone: data.phone,
                        city: data.city,
                        cnic: data.cnic,
                        whatsappNumber: data.whatsappNumber,
                        email: data.email,
                        notes: data.notes,
                        status: selectedMember.role == MemberRole.organizer ? MemberStatus.active : data.status,
                      ),
                    );
                if (error != null) return error;
                SnackbarHelper.showSuccess(context, 'Member updated successfully.');
                Navigator.of(context).pop();
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }
}
