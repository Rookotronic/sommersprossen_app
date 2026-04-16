import 'package:flutter/material.dart';

/// Wiederverwendbarer Bestätigungsdialog.
///
/// Verwendung:
/// ```dart
/// final confirmed = await showConfirmationDialog(
///   context,
///   title: 'Löschen?',
///   content: 'Möchtest du diesen Eintrag wirklich löschen?',
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
          style: confirmColor != null
              ? TextButton.styleFrom(foregroundColor: confirmColor)
              : null,
          child: Text(confirmText),
        ),
      ],
    ),
  );
}

/// Wiederverwendbarer Fehlerdialog.
///
/// Verwendung:
/// ```dart
/// await showErrorDialog(
///   context,
///   title: 'Fehler',
///   content: 'Es ist ein Fehler aufgetreten.',
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
