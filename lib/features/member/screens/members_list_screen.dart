import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/empty_state.dart';
import '../../auth/providers/auth_controller.dart';
import '../../kameti/models/kameti_model.dart';
import '../../kameti/providers/kameti_controller.dart';
import '../models/member_model.dart';
import '../providers/member_controller.dart';
import '../widgets/member_card.dart';
import '../widgets/member_count_summary_card.dart';

class MembersListScreen extends ConsumerStatefulWidget {
  const MembersListScreen({required this.kametiId, super.key});

  final String kametiId;

  @override
  ConsumerState<MembersListScreen> createState() => _MembersListScreenState();
}

class _MembersListScreenState extends ConsumerState<MembersListScreen> {
  final _searchController = TextEditingController();
  MemberStatus? _filter;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureOrganizer());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _ensureOrganizer() {
    final kameti = _findKameti(ref.read(kametiControllerProvider), widget.kametiId);
    if (kameti == null) return;
    ref.read(memberControllerProvider.notifier).ensureOrganizerMember(
          kameti: kameti,
          currentUser: ref.read(authControllerProvider).user,
        );
  }

  @override
  Widget build(BuildContext context) {
    final kameti = _findKameti(ref.watch(kametiControllerProvider), widget.kametiId);
    if (kameti == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Members')),
        body: const Center(child: Text('Kameti not found')),
      );
    }

    ref.watch(memberControllerProvider);
    final controller = ref.read(memberControllerProvider.notifier);
    final activeCount = controller.getActiveMembersCount(kameti.id);
    final allMembers = controller.getMembersByKametiId(kameti.id);
    final query = _searchController.text.trim().toLowerCase();
    final filteredMembers = allMembers.where((member) {
      final matchesFilter = _filter == null || member.status == _filter;
      final matchesSearch = query.isEmpty ||
          member.fullName.toLowerCase().contains(query) ||
          member.phone.toLowerCase().contains(query) ||
          member.city.toLowerCase().contains(query);
      return matchesFilter && matchesSearch;
    }).toList();
    final slotsFilled = activeCount >= kameti.totalMembers;
    final nonOrganizerActiveMembers =
        allMembers.where((member) => member.role != MemberRole.organizer && member.status != MemberStatus.removed).length;

    return Scaffold(
      appBar: AppBar(title: const Text('Members')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            MemberCountSummaryCard(addedCount: activeCount, totalCount: kameti.totalMembers),
            if (slotsFilled)
              const Padding(
                padding: EdgeInsets.only(top: 8, bottom: 8),
                child: Text('All member slots are filled.', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                labelText: 'Search members',
                prefixIcon: Icon(Icons.search),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _FilterChip(label: 'All', selected: _filter == null, onTap: () => setState(() => _filter = null)),
                _FilterChip(
                  label: 'Active',
                  selected: _filter == MemberStatus.active,
                  onTap: () => setState(() => _filter = MemberStatus.active),
                ),
                _FilterChip(
                  label: 'Pending',
                  selected: _filter == MemberStatus.pending,
                  onTap: () => setState(() => _filter = MemberStatus.pending),
                ),
                _FilterChip(
                  label: 'Removed',
                  selected: _filter == MemberStatus.removed,
                  onTap: () => setState(() => _filter = MemberStatus.removed),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppButton(
              label: slotsFilled ? 'All member slots are filled' : 'Add Member',
              icon: Icons.group_add_outlined,
              onPressed: slotsFilled ? null : () => Navigator.of(context).pushNamed(AppRoutes.addMember, arguments: kameti.id),
            ),
            const SizedBox(height: 14),
            if (nonOrganizerActiveMembers == 0)
              const EmptyState(
                icon: Icons.group_add_outlined,
                title: 'No members added yet. Add members to complete your kameti group.',
              )
            else if (filteredMembers.isEmpty)
              const EmptyState(icon: Icons.search_off_outlined, title: 'No members match your search.')
            else
              ...filteredMembers.map(
                (member) => MemberCard(
                  member: member,
                  canRemove: member.role != MemberRole.organizer &&
                      member.status != MemberStatus.removed &&
                      kameti.status == KametiStatus.draft,
                  onView: () => Navigator.of(context).pushNamed(AppRoutes.memberDetails, arguments: member.id),
                  onEdit: () => Navigator.of(context).pushNamed(
                    AppRoutes.editMember,
                    arguments: {'kametiId': kameti.id, 'memberId': member.id},
                  ),
                  onRemove: () => _removeMember(kameti, member),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _removeMember(KametiModel kameti, MemberModel member) async {
    if (member.role == MemberRole.organizer) {
      SnackbarHelper.showError(context, 'Organizer cannot be removed.');
      return;
    }
    if (kameti.status != KametiStatus.draft) {
      SnackbarHelper.showError(context, 'Cannot remove members after kameti has started.');
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => const ConfirmationDialog(
        title: 'Remove Member?',
        message: 'Are you sure you want to remove this member from this kameti?',
        confirmLabel: 'Remove',
        isDestructive: true,
      ),
    );
    if (confirmed != true) return;
    final error = ref.read(memberControllerProvider.notifier).removeMember(kameti: kameti, memberId: member.id);
    if (!mounted) return;
    if (error != null) {
      SnackbarHelper.showError(context, error);
    } else {
      SnackbarHelper.showSuccess(context, 'Member removed successfully.');
    }
  }

  KametiModel? _findKameti(List<KametiModel> kametis, String id) {
    for (final kameti in kametis) {
      if (kameti.id == id) return kameti;
    }
    return null;
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return FilterChip(label: Text(label), selected: selected, onSelected: (_) => onTap());
  }
}
