import 'package:flutter/material.dart';

/// A reusable confirmation dialog widget.
///
/// Usage:
/// ```dart
/// final confirmed = await showConfirmationDialog(
///   context,
///   title: 'Delete?',
///   content: 'Are you sure you want to delete this item?',
/// );
/// if (confirmed == true) { ... }
/// ```
Future<bool?> showConfirmationDialog(
  BuildContext context, {
  required String title,
  required String content,
  String cancelText = 'Abbrechen',
  String confirmText = 'Bestätigen',
  Color? confirmColor,
}) {
  return showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(cancelText),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(confirmText),
          style: confirmColor != null
              ? TextButton.styleFrom(foregroundColor: confirmColor)
              : null,
        ),
      ],
    ),
  );
}

/// A reusable error dialog widget.
///
/// Usage:
/// ```dart
/// await showErrorDialog(
///   context,
///   title: 'Error',
///   content: 'Something went wrong.',
/// );
/// ```
Future<void> showErrorDialog(
  BuildContext context, {
  required String title,
  required String content,
  String buttonText = 'OK',
}) {
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(content),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(buttonText),
        ),
      ],
    ),
  );
}
