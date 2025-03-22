import 'package:flutter/material.dart';

class UIHelpers {
  static void showSnackBar(
    BuildContext context, {
    required String message,
    bool isSuccess = true,
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.fixed, // Use fixed behavior
        duration: duration,
      ),
    );
  }
}
