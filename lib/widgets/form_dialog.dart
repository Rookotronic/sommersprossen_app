import 'package:flutter/material.dart';

class FormDialog extends StatelessWidget {
  final String title;
  final List<Widget> fields;
  final String? errorText;
  final List<Widget> actions;
  final double minWidth;

  const FormDialog({
    super.key,
    required this.title,
    required this.fields,
    this.errorText,
    required this.actions,
    this.minWidth = 320,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: minWidth,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ...fields,
            if (errorText != null)
              Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(errorText!, style: const TextStyle(color: Colors.red)),
              ),
          ],
        ),
      ),
      actions: actions,
    );
  }
}
