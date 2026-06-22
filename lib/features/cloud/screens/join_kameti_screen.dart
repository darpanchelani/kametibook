import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../auth/providers/auth_controller.dart';
import '../../kameti/providers/kameti_controller.dart';
import '../../member/models/member_model.dart';
import '../../member/providers/member_controller.dart';
import '../models/kameti_invite_model.dart';
import '../providers/invite_controller.dart';

class JoinKametiScreen extends ConsumerStatefulWidget {
  const JoinKametiScreen({super.key});

  @override
  ConsumerState<JoinKametiScreen> createState() => _JoinKametiScreenState();
}

class _JoinKametiScreenState extends ConsumerState<JoinKametiScreen> {
  final _codeController = TextEditingController();
  KametiInviteModel? _invite;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kameti = _invite == null ? null : ref.watch(kametiControllerProvider).where((item) => item.id == _invite!.kametiId).firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Join Kameti')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: _codeController,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(labelText: 'Invite code'),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(onPressed: _validateInvite, icon: const Icon(Icons.search), label: const Text('Find Kameti')),
            if (_invite != null && kameti != null) ...[
              const SizedBox(height: 18),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(kameti.name, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900)),
                      Text('Organizer: ${kameti.organizerName}'),
                      Text('Type: ${kameti.type.label}'),
                      Text('Monthly: ${CurrencyFormatter.pkr(kameti.monthlyAmount)}'),
                      Text('Duration: ${kameti.durationMonths} months'),
                      Text('Members: ${kameti.totalMembers}'),
                      Text('Start: ${DateFormatter.display(kameti.startDate)}'),
                      if (kameti.description.isNotEmpty) Text(kameti.description),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: OutlinedButton(onPressed: _decline, child: const Text('Decline'))),
                  const SizedBox(width: 10),
                  Expanded(child: FilledButton(onPressed: () => _accept(kameti), child: const Text('Accept'))),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _validateInvite() {
    final invite = ref.read(inviteControllerProvider.notifier).byCode(_codeController.text);
    if (invite == null) {
      SnackbarHelper.showError(context, 'Invalid invite code.');
      return;
    }
    if (invite.status != KametiInviteStatus.pending || invite.isExpired) {
      SnackbarHelper.showError(context, 'Invite expired or already used.');
      return;
    }
    setState(() => _invite = invite);
  }

  void _accept(dynamic kameti) {
    final invite = _invite;
    if (invite == null) return;
    final user = ref.read(authControllerProvider).user;
    final now = DateTime.now();
    final existing = ref.read(memberControllerProvider.notifier).getMembersByKametiId(kameti.id).where((member) {
      return member.phone.replaceAll(RegExp(r'\D'), '') == invite.invitedPhone.replaceAll(RegExp(r'\D'), '');
    }).firstOrNull;
    if (existing == null) {
      ref.read(memberControllerProvider.notifier).addMember(
            MemberModel(
              id: 'member-${now.microsecondsSinceEpoch}',
              kametiId: kameti.id,
              fullName: user?.fullName ?? 'Member',
              phone: invite.invitedPhone,
              city: user?.city ?? 'Pakistan',
              cnic: '',
              whatsappNumber: invite.invitedPhone,
              email: '',
              notes: 'Joined through invite code',
              role: invite.role,
              status: MemberStatus.active,
              hasReceivedKameti: false,
              joinedAt: now,
              createdAt: now,
              updatedAt: now,
              userId: user?.id ?? '',
              invitedBy: invite.invitedBy,
              inviteStatus: MemberInviteStatus.accepted,
              joinedByApp: true,
              linkedAt: now,
            ),
          );
    } else {
      ref.read(memberControllerProvider.notifier).updateMember(
            kametiId: kameti.id,
            memberId: existing.id,
            updatedMember: existing.copyWith(
              userId: user?.id ?? '',
              inviteStatus: MemberInviteStatus.accepted,
              joinedByApp: true,
              linkedAt: now,
              status: MemberStatus.active,
            ),
          );
    }
    ref.read(kametiControllerProvider.notifier).addMemberUser(kameti.id, user?.id ?? '');
    ref.read(inviteControllerProvider.notifier).acceptInvite(invite.id, user?.id ?? '');
    SnackbarHelper.showSuccess(context, 'You have joined this kameti.');
    Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.main, (_) => false);
  }

  void _decline() {
    final invite = _invite;
    if (invite == null) return;
    ref.read(inviteControllerProvider.notifier).rejectInvite(invite.id);
    SnackbarHelper.showInfo(context, 'Invite declined.');
    setState(() => _invite = null);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
