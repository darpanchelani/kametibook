import 'package:flutter/material.dart';

import '../models/ledger_entry_model.dart';

class LedgerTypeBadge extends StatelessWidget {
  const LedgerTypeBadge({required this.type, super.key});
  final LedgerEntryType type;

  @override
  Widget build(BuildContext context) {
    return Chip(label: Text(type.label), visualDensity: VisualDensity.compact);
  }
}
