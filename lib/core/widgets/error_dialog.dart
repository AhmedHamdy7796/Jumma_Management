import 'package:flutter/material.dart';
import 'package:gomaa_management/core/resources/app_strings.dart';

class ErrorDialog extends StatelessWidget {
  final String message;

  const ErrorDialog({
    super.key,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(
        AppStrings.error,
        textAlign: TextAlign.right,
        style: TextStyle(fontFamily: 'Arial', color: Colors.red, fontWeight: FontWeight.bold),
      ),
      content: Text(
        message,
        textAlign: TextAlign.right,
        textDirection: TextDirection.rtl,
        style: const TextStyle(fontFamily: 'Arial'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            AppStrings.cancel,
            style: TextStyle(fontFamily: 'Arial'),
          ),
        ),
      ],
    );
  }

  static void show(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (context) => ErrorDialog(message: message),
    );
  }
}
