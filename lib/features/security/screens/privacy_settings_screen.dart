import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../../auth/providers/auth_controller.dart';
import '../models/security_models.dart';
import '../providers/security_controller.dart';
import '../widgets/security_widgets.dart';

class PrivacySettingsScreen extends ConsumerStatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  ConsumerState<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends ConsumerState<PrivacySettingsScreen> {
  late PrivacySettingsModel settings;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authControllerProvider).user?.id ?? '';
    settings = ref.read(securityControllerProvider.notifier).privacySettingsFor(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Settings')),
      body: SafeArea(
        child: ListView(children: [
          PrivacySettingTile(title: 'Hide phone number from non-organizers', value: settings.hidePhoneFromMembers, onChanged: (value) => setState(() => settings = settings.copyWith(hidePhoneFromMembers: value))),
          PrivacySettingTile(title: 'Hide city from members', value: settings.hideCityFromMembers, onChanged: (value) => setState(() => settings = settings.copyWith(hideCityFromMembers: value))),
          PrivacySettingTile(title: 'Hide financial amount in lock screen notifications', value: settings.hideFinancialAmountInLockScreen, onChanged: (value) => setState(() => settings = settings.copyWith(hideFinancialAmountInLockScreen: value))),
          PrivacySettingTile(title: 'Hide CNIC in reports by default', value: settings.hideCnicInReports, onChanged: (value) => setState(() => settings = settings.copyWith(hideCnicInReports: value))),
          PrivacySettingTile(title: 'Allow members to download own statement', value: settings.allowMembersDownloadOwnStatement, onChanged: (value) => setState(() => settings = settings.copyWith(allowMembersDownloadOwnStatement: value))),
          PrivacySettingTile(title: 'Allow group members to view full ledger', value: settings.allowGroupMembersViewFullLedger, onChanged: (value) => setState(() => settings = settings.copyWith(allowGroupMembersViewFullLedger: value))),
          Padding(
            padding: const EdgeInsets.all(16),
            child: FilledButton.icon(
              onPressed: () {
                ref.read(securityControllerProvider.notifier).updatePrivacySettings(settings);
                SnackbarHelper.showSuccess(context, 'Privacy settings saved.');
              },
              icon: const Icon(Icons.save_outlined),
              label: const Text('Save Settings'),
            ),
          ),
        ]),
      ),
    );
  }
}
