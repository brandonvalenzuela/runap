import 'package:flutter/material.dart';

enum AppSnackBarType { error, success, info, warning }

class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarType type = AppSnackBarType.info,
    String? title,
  }) {
    Color backgroundColor;
    switch (type) {
      case AppSnackBarType.error:
        backgroundColor = Colors.red;
        break;
      case AppSnackBarType.success:
        backgroundColor = Colors.green;
        break;
      case AppSnackBarType.warning:
        backgroundColor = Colors.orange;
        break;
      default:
        backgroundColor = Colors.blueGrey;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: title != null
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  Text(message),
                ],
              )
            : Text(message),
        backgroundColor: backgroundColor,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
} 