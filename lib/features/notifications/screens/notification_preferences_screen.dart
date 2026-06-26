import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/utils/snackbar_helper.dart';
import '../../auth/providers/auth_controller.dart';
import '../models/notification_model.dart';
import '../providers/notification_controller.dart';

class NotificationPreferencesScreen extends ConsumerStatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  ConsumerState<NotificationPreferencesScreen> createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends ConsumerState<NotificationPreferencesScreen> {
  late UserNotificationPreferencesModel preferences;

  @override
  void initState() {
    super.initState();
    final userId = ref.read(authControllerProvider).user?.id ?? '';
    preferences = ref
        .read(notificationControllerProvider.notifier)
        .preferencesFor(userId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: SafeArea(
        child: ListView(
          children: [
            _tile('In-app notifications', preferences.inAppEnabled,
                (value) => _update(preferences.copyWith(inAppEnabled: value))),
            _tile(
                'Payment notifications',
                preferences.paymentNotifications,
                (value) =>
                    _update(preferences.copyWith(paymentNotifications: value))),
            _tile(
                'Payout notifications',
                preferences.payoutNotifications,
                (value) =>
                    _update(preferences.copyWith(payoutNotifications: value))),
            _tile(
                'Receiver notifications',
                preferences.receiverNotifications,
                (value) => _update(
                    preferences.copyWith(receiverNotifications: value))),
            _tile(
                'Bidding notifications',
                preferences.biddingNotifications,
                (value) =>
                    _update(preferences.copyWith(biddingNotifications: value))),
            _tile(
                'Lucky draw notifications',
                preferences.luckyDrawNotifications,
                (value) => _update(
                    preferences.copyWith(luckyDrawNotifications: value))),
            _tile(
                'Report notifications',
                preferences.reportNotifications,
                (value) =>
                    _update(preferences.copyWith(reportNotifications: value))),
            _tile(
                'Ledger warnings',
                preferences.ledgerWarningNotifications,
                (value) => _update(
                    preferences.copyWith(ledgerWarningNotifications: value))),
            _tile('Sound placeholder', preferences.soundEnabled,
                (value) => _update(preferences.copyWith(soundEnabled: value))),
            _tile(
                'Vibration placeholder',
                preferences.vibrationEnabled,
                (value) =>
                    _update(preferences.copyWith(vibrationEnabled: value))),
            _tile(
                'Local push placeholder',
                preferences.localPushEnabled,
                (value) =>
                    _update(preferences.copyWith(localPushEnabled: value))),
            _tile(
                'Hide amount on lock screen',
                preferences.hideAmountOnLockScreen,
                (value) => _update(
                    preferences.copyWith(hideAmountOnLockScreen: value))),
            Padding(
              padding: const EdgeInsets.all(16),
              child: FilledButton.icon(
                onPressed: () {
                  ref
                      .read(notificationControllerProvider.notifier)
                      .updatePreferences(preferences);
                  SnackbarHelper.showSuccess(
                      context, 'Notification preferences saved.');
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('Save Preferences'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _tile(String title, bool value, ValueChanged<bool> onChanged) {
    return SwitchListTile(
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
      value: value,
      onChanged: onChanged,
    );
  }

  void _update(UserNotificationPreferencesModel updated) {
    setState(() => preferences = updated);
  }
}
