import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/utils/currency_formatter.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../auth/providers/auth_controller.dart';
import '../../kameti/providers/kameti_controller.dart';
import '../../member/models/member_model.dart';
import '../providers/invite_controller.dart';

class InviteMemberScreen extends ConsumerStatefulWidget {
  const InviteMemberScreen({required this.kametiId, super.key});

  final String kametiId;

  @override
  ConsumerState<InviteMemberScreen> createState() => _InviteMemberScreenState();
}

class _InviteMemberScreenState extends ConsumerState<InviteMemberScreen> {
  final _phoneController = TextEditingController();
  MemberRole _role = MemberRole.member;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final kameti = ref
        .watch(kametiControllerProvider)
        .where((item) => item.id == widget.kametiId)
        .firstOrNull;
    return Scaffold(
      appBar: AppBar(title: const Text('Invite Member')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(kameti?.name ?? 'Kameti',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w900)),
            const SizedBox(height: 12),
            TextField(
                enableSuggestions: false,
                autocorrect: false,
                autofillHints: const <String>[],
                smartDashesType: SmartDashesType.disabled,
                smartQuotesType: SmartQuotesType.disabled,
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Phone number')),
            const SizedBox(height: 12),
            DropdownButtonFormField<MemberRole>(
              initialValue: _role,
              decoration: const InputDecoration(labelText: 'Role'),
              items: const [
                DropdownMenuItem(
                    value: MemberRole.member, child: Text('Member')),
                DropdownMenuItem(
                    value: MemberRole.coOrganizer, child: Text('Co-Organizer')),
              ],
              onChanged: (value) =>
                  setState(() => _role = value ?? MemberRole.member),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: kameti == null ? null : () => _createInvite(kameti),
              icon: const Icon(Icons.ios_share_outlined),
              label: const Text('Create & Share Invite'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _createInvite(dynamic kameti) async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      SnackbarHelper.showError(context, 'Phone number is required.');
      return;
    }
    final invite = ref.read(inviteControllerProvider.notifier).createInvite(
          kameti: kameti,
          invitedPhone: phone,
          role: _role,
          invitedBy: ref.read(authControllerProvider).user?.id ?? '',
        );
    final message =
        'You are invited to join ${kameti.name} on KametiBook.\nInvite Code: ${invite.inviteCode}\nMonthly Amount: ${CurrencyFormatter.pkr(kameti.monthlyAmount)}\nOpen KametiBook and enter this code to join.';
    await SharePlus.instance.share(ShareParams(text: message));
    if (mounted) {
      SnackbarHelper.showSuccess(context, 'Invite created successfully.');
    }
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
