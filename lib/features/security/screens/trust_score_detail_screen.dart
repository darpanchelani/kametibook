import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../ledger/providers/ledger_controller.dart';
import '../../member/providers/member_controller.dart';
import '../../payment/providers/payment_controller.dart';
import '../providers/security_controller.dart';
import '../widgets/security_widgets.dart';

class TrustScoreDetailScreen extends ConsumerWidget {
  const TrustScoreDetailScreen({required this.memberId, super.key});
  final String memberId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final member = ref
        .watch(memberControllerProvider)
        .where((item) => item.id == memberId)
        .firstOrNull;
    if (member == null) {
      return Scaffold(
          appBar: AppBar(title: const Text('Trust Score')),
          body: const Center(child: Text('Member not found')));
    }
    final score =
        ref.read(securityControllerProvider.notifier).calculateMemberTrustScore(
              member: member,
              payments: ref.watch(paymentControllerProvider).payments,
              ledgerEntries: ref.watch(ledgerControllerProvider),
            );
    return Scaffold(
      appBar: AppBar(title: const Text('Trust Score')),
      body: SafeArea(
        child: ListView(padding: const EdgeInsets.all(16), children: [
          TrustScoreCard(score: score),
          TrustScoreBreakdown(score: score),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Positive factors',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    if (score.positiveFactors.isEmpty)
                      const Text('No positive factors yet.')
                    else
                      ...score.positiveFactors.map((item) => Text('- $item')),
                    const SizedBox(height: 14),
                    Text('Areas to review',
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w900)),
                    if (score.negativeFactors.isEmpty)
                      const Text('No risk factors found.')
                    else
                      ...score.negativeFactors.map((item) => Text('- $item')),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
