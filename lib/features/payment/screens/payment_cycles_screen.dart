import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../../core/widgets/empty_state.dart';
import '../../kameti/models/kameti_model.dart';
import '../../kameti/providers/kameti_controller.dart';
import '../providers/payment_controller.dart';
import '../widgets/payment_cycle_card.dart';

class PaymentCyclesScreen extends ConsumerWidget {
  const PaymentCyclesScreen({required this.kametiId, super.key});

  final String kametiId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final kameti = _findKameti(ref.watch(kametiControllerProvider), kametiId);
    ref.watch(paymentControllerProvider);
    final paymentController = ref.read(paymentControllerProvider.notifier);
    final cycles = paymentController.getCyclesByKametiId(kametiId);

    return Scaffold(
      appBar: AppBar(title: const Text('Payment Cycles')),
      body: SafeArea(
        child: kameti == null
            ? const Center(child: Text('Kameti not found'))
            : cycles.isEmpty
                ? const EmptyState(
                    icon: Icons.calendar_month_outlined,
                    title: 'No payment cycles yet.',
                    message: 'Start this kameti to generate monthly cycles.',
                  )
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final cycle = cycles[index];
                      return PaymentCycleCard(
                        cycle: cycle,
                        paidCount: paymentController.getPaidMembersCount(cycle.id),
                        pendingCount: paymentController.getPendingMembersCount(cycle.id),
                        onOpen: () => Navigator.of(context).pushNamed(AppRoutes.cyclePayments, arguments: cycle.id),
                        onMarkCurrent: () {
                          paymentController.markCycleCurrent(cycle.id);
                          SnackbarHelper.showSuccess(context, 'Cycle marked as current.');
                        },
                        onComplete: () {
                          final error = paymentController.completeCycle(cycle.id);
                          if (error != null) {
                            SnackbarHelper.showError(context, error);
                          } else {
                            SnackbarHelper.showSuccess(context, 'Cycle marked as completed.');
                          }
                        },
                      );
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: cycles.length,
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
