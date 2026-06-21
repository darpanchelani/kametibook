import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/routes.dart';
import '../../../core/widgets/empty_state.dart';
import '../providers/lucky_draw_controller.dart';
import '../widgets/draw_history_card.dart';

class DrawHistoryScreen extends ConsumerWidget {
  const DrawHistoryScreen({required this.kametiId, super.key});

  final String kametiId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(luckyDrawControllerProvider);
    final draws = ref.read(luckyDrawControllerProvider.notifier).getDrawsByKametiId(kametiId);
    return Scaffold(
      appBar: AppBar(title: const Text('Draw History')),
      body: SafeArea(
        child: draws.isEmpty
            ? const EmptyState(icon: Icons.casino_outlined, title: 'No draw history yet.')
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemBuilder: (context, index) {
                  final draw = draws[index];
                  return DrawHistoryCard(
                    draw: draw,
                    onTap: () => Navigator.of(context).pushNamed(AppRoutes.drawDetail, arguments: draw.id),
                  );
                },
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemCount: draws.length,
              ),
      ),
    );
  }
}
