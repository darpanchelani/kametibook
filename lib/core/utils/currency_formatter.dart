import 'package:intl/intl.dart';

class CurrencyFormatter {
  static final NumberFormat _amountFormat =
      NumberFormat.decimalPattern('en_PK');

  static String pkr(num amount) {
    return 'PKR ${_amountFormat.format(amount)}';
  }
}
