import 'package:intl/intl.dart';

class DateFormatter {
  static final DateFormat _displayFormat = DateFormat('dd MMM yyyy');

  static String display(DateTime date) => _displayFormat.format(date);
}
