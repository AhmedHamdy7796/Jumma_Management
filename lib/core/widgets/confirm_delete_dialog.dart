import 'package:flutter/material.dart';
import 'package:gomaa_management/core/resources/app_strings.dart';
import 'package:gomaa_management/core/resources/app_colors.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  final String title;
  final String content;
  final VoidCallback onDelete;

  const ConfirmDeleteDialog({
    super.key,
    required this.title,
    required this.content,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(
        title,
        textAlign: TextAlign.right,
        style: const TextStyle(fontFamily: 'Arial'),
      ),
      content: Text(
        content,
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
        TextButton(
          onPressed: () {
            onDelete();
            Navigator.pop(context);
          },
          child: const Text(
            AppStrings.delete,
            style: TextStyle(color: AppColors.error, fontFamily: 'Arial'),
          ),
        ),
      ],
    );
  }

  static void show(
    BuildContext context, {
    required String title,
    required String content,
    required VoidCallback onDelete,
  }) {
    showDialog(
      context: context,
      builder: (context) => ConfirmDeleteDialog(
        title: title,
        content: content,
        onDelete: onDelete,
      ),
    );
  }
}
