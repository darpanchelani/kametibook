import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/empty_state.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../auth/providers/auth_controller.dart';
import '../models/friend_models.dart';
import '../providers/friends_controller.dart';

class FriendsScreen extends ConsumerStatefulWidget {
  const FriendsScreen({super.key});

  @override
  ConsumerState<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends ConsumerState<FriendsScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    FocusManager.instance.primaryFocus?.unfocus();
    await ref
        .read(friendsControllerProvider.notifier)
        .searchUsers(_searchController.text);
  }

  void _openChatPicker(List<FriendModel> friends) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ChatLauncherSheet(
        friends: friends,
        onOpenChat: (friend) {
          Navigator.of(context).pop();
          Navigator.of(this.context)
              .pushNamed(AppRoutes.chat, arguments: friend.chatId);
        },
      ),
    );
  }

  void _openFriendRequests(
    String currentUserId,
    List<FriendRequestModel> requests,
  ) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _FriendRequestsSheet(
        currentUserId: currentUserId,
        requests: requests,
        onAccept: (request) async {
          final error = await ref
              .read(friendsControllerProvider.notifier)
              .acceptFriendRequest(request);
          if (!context.mounted) return;
          if (error != null) {
            SnackbarHelper.showError(context, error);
          } else {
            SnackbarHelper.showSuccess(
                context, '${request.fromName} is now your friend.');
          }
        },
        onReject: (request) async {
          final error = await ref
              .read(friendsControllerProvider.notifier)
              .rejectFriendRequest(request);
          if (!context.mounted) return;
          if (error != null) {
            SnackbarHelper.showError(context, error);
          } else {
            SnackbarHelper.showSuccess(context, 'Friend request rejected.');
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).user;
    final state = ref.watch(friendsControllerProvider);
    if (user == null) {
      return const Scaffold(
        body: EmptyState(
          icon: Icons.lock_outline,
          title: 'Please login to manage friends.',
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Friends')),
      floatingActionButton: FloatingActionButton(
        heroTag: 'friends-open-chat-fab',
        tooltip: 'Open chats',
        onPressed: () => _openChatPicker(state.friends),
        child: const Icon(Icons.chat_bubble_outline),
      ),
      body: ExcludeSemantics(
        child: SafeArea(
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _FriendsHeader(
                  friendCount: state.friends.length,
                  requestCount: state.incomingRequests.length,
                  onOpenRequests: () =>
                      _openFriendRequests(user.id, state.incomingRequests),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  controller: _searchController,
                  label: 'Search username, phone, or name',
                  prefixIcon: Icons.search,
                  textInputAction: TextInputAction.search,
                  onSubmitted: (_) => _search(),
                ),
                const SizedBox(height: 10),
                AppButton(
                  label: 'Search Friend',
                  icon: Icons.person_search_outlined,
                  isLoading: state.isSearching,
                  onPressed: state.isSearching ? null : _search,
                ),
                if (state.errorMessage.isNotEmpty) ...[
                  const SizedBox(height: 14),
                  EmptyState(
                      icon: Icons.info_outline, title: state.errorMessage),
                ],
                if (state.searchResults.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  const _SectionTitle(title: 'Search results'),
                  const SizedBox(height: 10),
                  for (final result in state.searchResults)
                    _SearchResultCard(
                      result: result,
                      onView: () => Navigator.of(context).pushNamed(
                        AppRoutes.friendProfile,
                        arguments: result.profile.id,
                      ),
                      onAdd: result.isFriend ||
                              result.hasOutgoingRequest ||
                              result.hasIncomingRequest
                          ? null
                          : () async {
                              final error = await ref
                                  .read(friendsControllerProvider.notifier)
                                  .addFriend(result.profile);
                              if (!context.mounted) return;
                              if (error != null) {
                                SnackbarHelper.showError(context, error);
                              } else {
                                SnackbarHelper.showSuccess(context,
                                    'Friend request sent to ${result.profile.fullName}.');
                              }
                            },
                    ),
                ],
                const SizedBox(height: 22),
                const _SectionTitle(title: 'My friends'),
                const SizedBox(height: 10),
                if (state.friends.isEmpty)
                  const EmptyState(
                    icon: Icons.people_outline,
                    title: 'No friends yet. Search a username, phone, or name.',
                  )
                else
                  for (final friend in state.friends)
                    _FriendCard(
                      friend: friend,
                      onProfile: () => Navigator.of(context).pushNamed(
                        AppRoutes.friendProfile,
                        arguments: friend.friendUserId,
                      ),
                    ),
                const SizedBox(height: 92),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FriendsHeader extends StatelessWidget {
  const _FriendsHeader({
    required this.friendCount,
    required this.requestCount,
    required this.onOpenRequests,
  });

  final int friendCount;
  final int requestCount;
  final VoidCallback onOpenRequests;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE6F4EF),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFFC9E5DA)),
      ),
      child: Row(
        children: [
          IconButton.filled(
            tooltip: 'Friend requests',
            onPressed: onOpenRequests,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFF087F5B),
              foregroundColor: Colors.white,
              fixedSize: const Size(58, 58),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            icon: Badge(
              isLabelVisible: requestCount > 0,
              label: Text(requestCount > 99 ? '99+' : '$requestCount'),
              child: const Icon(Icons.mark_email_unread_outlined),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add friends',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 3),
                Text(
                  '$friendCount friend(s) connected',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: const Color(0xFF51635B),
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: Theme.of(context)
          .textTheme
          .titleMedium
          ?.copyWith(fontWeight: FontWeight.w900),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  const _SearchResultCard({
    required this.result,
    required this.onView,
    required this.onAdd,
  });

  final FriendSearchResult result;
  final VoidCallback onView;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final profile = result.profile;
    final theme = Theme.of(context);
    final actionLabel = result.isFriend
        ? 'Added'
        : result.hasOutgoingRequest
            ? 'Request Sent'
            : result.hasIncomingRequest
                ? 'Respond'
                : 'Add Friend';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ProfileAvatar(
                  name: profile.fullName,
                  photoUrl: profile.profilePhotoUrl,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(profile.fullName,
                          style: theme.textTheme.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        '@${profile.username} • ${profile.city}',
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onView,
                    child: const Text('View Profile'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onAdd,
                    child: Text(actionLabel),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendRequestCard extends StatelessWidget {
  const _FriendRequestCard({
    required this.request,
    required this.currentUserId,
    required this.onAccept,
    required this.onReject,
  });

  final FriendRequestModel request;
  final String currentUserId;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final name = request.otherName(currentUserId);
    final username = request.otherUsername(currentUserId);
    final photo = request.otherPhotoUrl(currentUserId);
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                ProfileAvatar(name: name, photoUrl: photo),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: theme.textTheme.titleMedium),
                      if (username.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text('@$username', style: theme.textTheme.bodySmall),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: onReject,
                    child: const Text('Reject'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: onAccept,
                    child: const Text('Accept'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.friend,
    required this.onProfile,
  });

  final FriendModel friend;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        leading: ProfileAvatar(
          name: friend.friendName,
          photoUrl: friend.friendPhotoUrl,
        ),
        title: Text(friend.friendName),
        subtitle: Text('@${friend.friendUsername} • ${friend.friendCity}'),
        onTap: onProfile,
        trailing: const Icon(Icons.chevron_right_rounded),
      ),
    );
  }
}

class _FriendRequestsSheet extends StatelessWidget {
  const _FriendRequestsSheet({
    required this.currentUserId,
    required this.requests,
    required this.onAccept,
    required this.onReject,
  });

  final String currentUserId;
  final List<FriendRequestModel> requests;
  final ValueChanged<FriendRequestModel> onAccept;
  final ValueChanged<FriendRequestModel> onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5E4DD),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF087F5B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.mark_email_unread_outlined,
                      color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Friend requests',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        requests.isEmpty
                            ? 'No pending requests right now.'
                            : '${requests.length} request(s) waiting.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF60726A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            if (requests.isEmpty)
              const EmptyState(
                icon: Icons.mark_email_unread_outlined,
                title: 'No pending friend requests.',
              )
            else
              for (final request in requests)
                _FriendRequestCard(
                  request: request,
                  currentUserId: currentUserId,
                  onAccept: () => onAccept(request),
                  onReject: () => onReject(request),
                ),
          ],
        ),
      ),
    );
  }
}

class _ChatLauncherSheet extends StatefulWidget {
  const _ChatLauncherSheet({
    required this.friends,
    required this.onOpenChat,
  });

  final List<FriendModel> friends;
  final ValueChanged<FriendModel> onOpenChat;

  @override
  State<_ChatLauncherSheet> createState() => _ChatLauncherSheetState();
}

class _ChatLauncherSheetState extends State<_ChatLauncherSheet> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final filteredFriends = widget.friends.where((friend) {
      final query = _query.trim().toLowerCase();
      if (query.isEmpty) return true;
      return friend.friendName.toLowerCase().contains(query) ||
          friend.friendUsername.toLowerCase().contains(query) ||
          friend.friendPhone.toLowerCase().contains(query) ||
          friend.friendCity.toLowerCase().contains(query);
    }).toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 10,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                height: 4,
                width: 44,
                decoration: BoxDecoration(
                  color: const Color(0xFFD5E4DD),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(
                  height: 46,
                  width: 46,
                  decoration: BoxDecoration(
                    color: const Color(0xFF087F5B),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.chat_bubble_outline,
                      color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Start chat',
                        style: theme.textTheme.titleLarge
                            ?.copyWith(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Search friends and open a conversation.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF60726A),
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            AppTextField(
              controller: _searchController,
              label: 'Search friends',
              prefixIcon: Icons.search,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
            ),
            const SizedBox(height: 14),
            if (widget.friends.isEmpty)
              const EmptyState(
                icon: Icons.people_outline,
                title: 'No friends yet. Add a friend before starting chat.',
              )
            else if (filteredFriends.isEmpty)
              const EmptyState(
                icon: Icons.search_off_outlined,
                title: 'No friend found for this search.',
              )
            else
              for (final friend in filteredFriends)
                Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: ProfileAvatar(
                      name: friend.friendName,
                      photoUrl: friend.friendPhotoUrl,
                    ),
                    title: Text(friend.friendName),
                    subtitle: Text(
                        '@${friend.friendUsername} • ${friend.friendCity}'),
                    trailing: const Icon(Icons.chevron_right_rounded),
                    onTap: () => widget.onOpenChat(friend),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
