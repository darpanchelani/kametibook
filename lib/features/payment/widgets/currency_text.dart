import 'package:flutter/material.dart';

import '../../../core/utils/currency_formatter.dart';

class CurrencyText extends StatelessWidget {
  const CurrencyText(this.amount, {this.style, super.key});

  final num amount;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    return Text(CurrencyFormatter.pkr(amount), style: style);
  }
}
