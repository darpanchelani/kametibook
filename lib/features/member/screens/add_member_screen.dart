import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/services/firebase_bootstrap.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../auth/providers/auth_controller.dart';
import '../../cloud/models/user_profile_model.dart';
import '../../kameti/models/kameti_model.dart';
import '../../kameti/providers/kameti_controller.dart';
import '../../notifications/providers/notification_controller.dart';
import '../models/member_model.dart';
import '../providers/member_controller.dart';

class AddMemberScreen extends ConsumerStatefulWidget {
  const AddMemberScreen({required this.kametiId, super.key});

  final String kametiId;

  @override
  ConsumerState<AddMemberScreen> createState() => _AddMemberScreenState();
}

class _AddMemberScreenState extends ConsumerState<AddMemberScreen> {
  final _searchController = TextEditingController();
  final _firestore = FirebaseFirestore.instance;
  List<UserProfileModel> _results = const [];
  bool _isSearching = false;
  bool _isAdding = false;
  String _message = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchUsers() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!mounted) return;

    final query = _searchController.text.trim().toLowerCase();
    if (query.length < 2) {
      _setStateIfMounted(() {
        _results = const [];
        _message = 'Enter at least 2 characters to search by name or username.';
      });
      return;
    }
    if (!FirebaseBootstrap.isInitialized) {
      _setStateIfMounted(
          () => _message = 'Firebase is required to search member accounts.');
      return;
    }

    _setStateIfMounted(() {
      _isSearching = true;
      _message = '';
      _results = const [];
    });
    try {
      final byId = <String, UserProfileModel>{};
      final usernameProfile = await _findByExactUsername(query);
      if (usernameProfile != null) {
        byId[usernameProfile.id] = usernameProfile;
      }

      final collection = _firestore.collection('publicUserProfiles');
      final snapshots = await Future.wait([
        collection
            .where('usernameLower', isGreaterThanOrEqualTo: query)
            .where('usernameLower', isLessThanOrEqualTo: '$query\uf8ff')
            .orderBy('usernameLower')
            .limit(10)
            .get(),
        collection
            .where('fullNameLower', isGreaterThanOrEqualTo: query)
            .where('fullNameLower', isLessThanOrEqualTo: '$query\uf8ff')
            .orderBy('fullNameLower')
            .limit(10)
            .get(),
        collection
            .where('searchKeywords', arrayContains: query)
            .limit(10)
            .get(),
      ]);
      for (final snapshot in snapshots) {
        for (final doc in snapshot.docs) {
          byId[doc.id] = UserProfileModel.fromMap({
            ...doc.data(),
            'id': doc.data()['id'] ?? doc.id,
          });
        }
      }
      _setStateIfMounted(() {
        _results = byId.values.toList()
          ..sort((a, b) => a.fullName.compareTo(b.fullName));
        _message = _results.isEmpty
            ? 'No searchable account found for "$query". Make sure the member has signed up and logged in once.'
            : '';
      });
    } catch (error) {
      debugPrint('KametiBook member search failed: $error');
      _setStateIfMounted(() => _message =
          'Search failed. Please check Firebase rules and try again.');
    } finally {
      _setStateIfMounted(() => _isSearching = false);
    }
  }

  void _setStateIfMounted(VoidCallback update) {
    if (!mounted) return;
    setState(update);
  }

  Future<UserProfileModel?> _findByExactUsername(String query) async {
    final usernameDoc =
        await _firestore.collection('usernames').doc(query).get();
    if (!usernameDoc.exists) return null;
    final userId = '${usernameDoc.data()?['userId'] ?? ''}';
    if (userId.isEmpty) return null;
    final profileDoc =
        await _firestore.collection('publicUserProfiles').doc(userId).get();
    if (!profileDoc.exists || profileDoc.data() == null) return null;
    return UserProfileModel.fromMap({
      ...profileDoc.data()!,
      'id': profileDoc.data()!['id'] ?? profileDoc.id,
    });
  }

  Future<void> _addUserProfile(
      KametiModel kameti, UserProfileModel profile) async {
    if (_isAdding) return;
    final currentUserId = ref.read(authControllerProvider).user?.id ?? '';
    if (profile.id == currentUserId) {
      SnackbarHelper.showError(
          context, 'Organizer is already added to this kameti.');
      return;
    }
    if (kameti.memberUserIds.contains(profile.id)) {
      SnackbarHelper.showError(
          context, 'This account is already a member of this kameti.');
      return;
    }

    final now = DateTime.now();
    final member = MemberModel(
      id: profile.id,
      kametiId: kameti.id,
      fullName: profile.fullName,
      phone: profile.phone,
      city: profile.city,
      cnic: '',
      whatsappNumber: profile.phone,
      email: profile.email,
      notes: 'Added through KametiBook account @${profile.username}',
      profilePhotoUrl: profile.profilePhotoUrl,
      role: MemberRole.member,
      status: MemberStatus.active,
      hasReceivedKameti: false,
      joinedAt: now,
      createdAt: now,
      updatedAt: now,
      userId: profile.id,
      inviteStatus: MemberInviteStatus.accepted,
      joinedByApp: true,
      linkedAt: now,
    );

    final memberController = ref.read(memberControllerProvider.notifier);
    if (memberController.getActiveMembersCount(kameti.id) >=
        kameti.totalMembers) {
      SnackbarHelper.showError(context, 'All member slots are filled.');
      return;
    }
    if (memberController.hasDuplicatePhone(kameti.id, member.phone)) {
      SnackbarHelper.showError(
          context, 'A member with this phone number already exists.');
      return;
    }

    setState(() => _isAdding = true);
    try {
      if (FirebaseBootstrap.isInitialized) {
        await _saveCloudMembership(kameti, member);
      }
      memberController.addMember(member);
      ref
          .read(kametiControllerProvider.notifier)
          .addMemberUser(kameti.id, profile.id);
      ref
          .read(notificationControllerProvider.notifier)
          .createMemberAddedNotification(
            userId: currentUserId,
            kameti: kameti,
            member: member,
          );
      if (!mounted) return;
      SnackbarHelper.showSuccess(
          context, '${profile.fullName} added successfully.');
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showError(
          context, 'Member could not be added. Please try again.');
      setState(() => _isAdding = false);
    }
  }

  Future<void> _saveCloudMembership(
      KametiModel kameti, MemberModel member) async {
    final batch = _firestore.batch();
    final kametiRef = _firestore.collection('kametis').doc(kameti.id);
    final memberRef = kametiRef.collection('members').doc(member.userId);
    final joinedRef = _firestore
        .collection('users')
        .doc(member.userId)
        .collection('joinedKametis')
        .doc(kameti.id);

    batch.set(memberRef, member.toFirestore());
    batch.set(joinedRef, {
      'kametiId': kameti.id,
      'role': member.role.name,
      'status': 'active',
      'joinedAt': member.joinedAt.millisecondsSinceEpoch,
    });
    batch.update(kametiRef, {
      'memberUserIds': FieldValue.arrayUnion([member.userId]),
    });
    await batch.commit();
  }

  @override
  Widget build(BuildContext context) {
    final kameti =
        _findKameti(ref.watch(kametiControllerProvider), widget.kametiId);
    if (kameti == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Add Member')),
        body: const Center(child: Text('Kameti not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Add Member')),
      body: ExcludeSemantics(
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Add by KametiBook account',
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 6),
                Text(
                  'Search a member by username, name, phone, or email. Members must create their own account first.',
                  style: Theme.of(context)
                      .textTheme
                      .bodyMedium
                      ?.copyWith(color: Colors.black54),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  enableSuggestions: false,
                  autocorrect: false,
                  autofillHints: const <String>[],
                  smartDashesType: SmartDashesType.disabled,
                  smartQuotesType: SmartQuotesType.disabled,
                  controller: _searchController,
                  label: 'Search account',
                  hint: 'username or name',
                  prefixIcon: Icons.search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _searchUsers(),
                ),
                const SizedBox(height: 12),
                AppButton(
                  label: 'Search Member',
                  icon: Icons.person_search_outlined,
                  isLoading: _isSearching,
                  onPressed: _isSearching ? null : _searchUsers,
                ),
                const SizedBox(height: 18),
                _SearchResultsView(
                  message: _message,
                  results: _results,
                  isAdding: _isAdding,
                  memberUserIds: kameti.memberUserIds,
                  onAdd: (profile) => _addUserProfile(kameti, profile),
                ),
              ],
            ),
          ),
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

class _SearchResultsView extends StatelessWidget {
  const _SearchResultsView({
    required this.message,
    required this.results,
    required this.isAdding,
    required this.memberUserIds,
    required this.onAdd,
  });

  final String message;
  final List<UserProfileModel> results;
  final bool isAdding;
  final List<String> memberUserIds;
  final ValueChanged<UserProfileModel> onAdd;

  @override
  Widget build(BuildContext context) {
    if (message.isNotEmpty) {
      return EmptyState(icon: Icons.info_outline, title: message);
    }
    if (results.isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final profile in results)
          _UserResultCard(
            profile: profile,
            isAlreadyMember: memberUserIds.contains(profile.id),
            isAdding: isAdding,
            onAdd: () => onAdd(profile),
          ),
      ],
    );
  }
}

class _UserResultCard extends StatelessWidget {
  const _UserResultCard({
    required this.profile,
    required this.isAlreadyMember,
    required this.isAdding,
    required this.onAdd,
  });

  final UserProfileModel profile;
  final bool isAlreadyMember;
  final bool isAdding;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      constraints: const BoxConstraints(minHeight: 76),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            ProfileAvatar(
                name: profile.fullName, photoUrl: profile.profilePhotoUrl),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(profile.fullName, style: theme.textTheme.titleMedium),
                  const SizedBox(height: 2),
                  Text('@${profile.username}',
                      style: theme.textTheme.bodyMedium),
                  const SizedBox(height: 2),
                  Text('${profile.city} • ${profile.phone}',
                      style: theme.textTheme.bodySmall),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: isAlreadyMember || isAdding ? null : onAdd,
              child: Text(isAlreadyMember ? 'Added' : 'Add'),
            ),
          ],
        ),
      ),
    );
  }
}
