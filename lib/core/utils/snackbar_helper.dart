import 'package:flutter/material.dart';

class SnackbarHelper {
  static void showSuccess(BuildContext context, String message) {
    _show(context, message, const Color(0xFF087F5B));
  }

  static void showInfo(BuildContext context, String message) {
    _show(context, message, const Color(0xFF0B7285));
  }

  static void showError(BuildContext context, String message) {
    _show(context, message, Colors.red.shade700);
  }

  static void _show(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          behavior: SnackBarBehavior.floating,
          backgroundColor: color,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }
}
