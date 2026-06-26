import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/auth/providers/auth_controller.dart';
import '../../features/kameti/providers/kameti_controller.dart';
import 'app_state_views.dart';

class ProtectedKametiRoute extends ConsumerWidget {
  const ProtectedKametiRoute({
    required this.kametiId,
    required this.child,
    this.requireManager = false,
    super.key,
  });

  final String kametiId;
  final Widget child;
  final bool requireManager;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).user;
    if (user == null) {
      return const Scaffold(
        body: AppPermissionDeniedView(
          title: 'Login required',
          message:
              'Please login with an active KametiBook account to continue.',
        ),
      );
    }
    ref.watch(kametiControllerProvider);
    final kametiController = ref.read(kametiControllerProvider.notifier);
    final allowed = requireManager
        ? kametiController.canManageKameti(kametiId, user.id)
        : kametiController.canViewKameti(kametiId, user.id);
    if (!allowed) {
      return const Scaffold(
        body: AppPermissionDeniedView(
          title: 'No access to this kameti',
          message:
              'You can only open kametis where you are an approved organizer or member.',
        ),
      );
    }
    return child;
  }
}
