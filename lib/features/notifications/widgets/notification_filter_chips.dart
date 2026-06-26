import 'package:flutter/material.dart';

enum NotificationFilter {
  all('All'),
  unread('Unread'),
  payments('Payments'),
  payouts('Payouts'),
  bidding('Bidding'),
  draws('Draws'),
  reports('Reports'),
  warnings('Warnings'),
  receiver('Receiver');

  const NotificationFilter(this.label);
  final String label;
}

class NotificationFilterChips extends StatelessWidget {
  const NotificationFilterChips(
      {required this.selected, required this.onChanged, super.key});

  final NotificationFilter selected;
  final ValueChanged<NotificationFilter> onChanged;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (final filter in NotificationFilter.values) ...[
            ChoiceChip(
                label: Text(filter.label),
                selected: selected == filter,
                onSelected: (_) => onChanged(filter)),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}
