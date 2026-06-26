import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../../member/providers/member_controller.dart';
import '../models/bidding_models.dart';
import '../providers/bidding_controller.dart';
import '../widgets/bidding_history_card.dart';

class BiddingHistoryScreen extends ConsumerWidget {
  const BiddingHistoryScreen({required this.kametiId, super.key});

  final String kametiId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(biddingControllerProvider);
    ref.watch(memberControllerProvider);
    final biddingController = ref.read(biddingControllerProvider.notifier);
    final memberController = ref.read(memberControllerProvider.notifier);
    final sessions = biddingController
        .getBiddingSessionsByKametiId(kametiId)
        .where((session) => session.status == BiddingSessionStatus.completed)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Bidding History')),
      body: SafeArea(
        child: sessions.isEmpty
            ? const EmptyState(
                icon: Icons.gavel_outlined, title: 'No bidding history yet.')
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final session = sessions[index];
                  return BiddingHistoryCard(
                    session: session,
                    winnerName: memberController
                            .getMember(session.winnerMemberId)
                            ?.fullName ??
                        '-',
                    onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.biddingDetail,
                        arguments: session.id),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: sessions.length,
              ),
      ),
    );
  }
}
