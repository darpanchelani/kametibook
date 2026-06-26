import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../../app/routes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/app_button.dart';
import '../../../core/widgets/profile_avatar.dart';
import '../../auth/providers/auth_controller.dart';
import '../../cloud/services/storage_service.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _isUploadingPhoto = false;

  Future<void> _pickAndUploadPhoto() async {
    final profile = ref.read(authControllerProvider).userProfile;
    if (profile == null) {
      SnackbarHelper.showError(
          context, 'Please login before updating profile photo.');
      return;
    }
    final image = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 60,
      maxWidth: 320,
    );
    if (image == null) return;

    setState(() => _isUploadingPhoto = true);
    try {
      final photoUrl = await _uploadOrCreateInlinePhoto(profile.id, image);
      final updated = await ref
          .read(authControllerProvider.notifier)
          .updateProfilePhoto(photoUrl);
      if (!mounted) return;
      if (!updated) {
        SnackbarHelper.showError(
            context, ref.read(authControllerProvider).errorMessage);
        return;
      }
      SnackbarHelper.showSuccess(context, 'Profile photo updated.');
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.showError(
          context, 'Profile photo could not be uploaded. Please try again.');
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<String> _uploadOrCreateInlinePhoto(String userId, XFile image) async {
    try {
      return await StorageService().uploadProfilePhoto(
        userId: userId,
        file: File(image.path),
      );
    } catch (error) {
      debugPrint(
          'KametiBook Storage profile upload failed, using inline image: $error');
      final bytes = await image.readAsBytes();
      return 'data:image/jpeg;base64,${base64Encode(bytes)}';
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final user = auth.user;
    final profile = auth.userProfile;
    final photoUrl = profile?.profilePhotoUrl ?? '';

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  children: [
                    Stack(
                      alignment: Alignment.bottomRight,
                      children: [
                        ProfileAvatar(
                          name: user?.fullName ?? '',
                          photoUrl: photoUrl,
                          radius: 42,
                        ),
                        Material(
                          color: Theme.of(context).colorScheme.primary,
                          shape: const CircleBorder(),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap:
                                _isUploadingPhoto ? null : _pickAndUploadPhoto,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: _isUploadingPhoto
                                  ? const SizedBox(
                                      height: 18,
                                      width: 18,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2, color: Colors.white),
                                    )
                                  : const Icon(Icons.camera_alt_outlined,
                                      color: Colors.white, size: 18),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      user?.fullName ?? 'Kameti User',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 4),
                    Text(profile?.username.isNotEmpty == true
                        ? '@${profile!.username}'
                        : ''),
                    const SizedBox(height: 4),
                    Text(user?.phone ?? ''),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: _isUploadingPhoto ? null : _pickAndUploadPhoto,
                      icon: const Icon(Icons.image_outlined),
                      label: Text(_isUploadingPhoto
                          ? 'Uploading...'
                          : 'Upload Profile Picture'),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.location_city_outlined),
                    title: const Text('City'),
                    subtitle: Text(user?.city ?? 'Pakistan'),
                  ),
                  const Divider(height: 1),
                  const ListTile(
                    leading: Icon(Icons.info_outline),
                    title: Text('App Version'),
                    subtitle: Text('1.0.0'),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.group_add_outlined),
                    title: const Text('Join Kameti'),
                    subtitle:
                        const Text('Enter invite code shared by organizer'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () =>
                        Navigator.of(context).pushNamed(AppRoutes.joinKameti),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.notifications_active_outlined),
                    title: const Text('Notification Preferences'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.notificationPreferences),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.security_outlined),
                    title: const Text('Security Center'),
                    subtitle: const Text(
                        'Privacy, disputes, trust score, and account requests'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context)
                        .pushNamed(AppRoutes.securityCenter),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            AppButton(
              label: 'Logout',
              icon: Icons.logout,
              isOutlined: true,
              onPressed: () async {
                await ref.read(authControllerProvider.notifier).logout();
                if (!context.mounted) return;
                Navigator.of(context)
                    .pushNamedAndRemoveUntil(AppRoutes.login, (_) => false);
              },
            ),
          ],
        ),
      ),
    );
  }
}
