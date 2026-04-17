import 'package:flutter/material.dart';

/// Dialog zur Anzeige eines Formulars mit Validierungs- und Fehleranzeige.
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
    final maxContentHeight = MediaQuery.sizeOf(context).height * 0.6;

    return AlertDialog(
      title: Text(title),
      content: SizedBox(
        width: minWidth,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxContentHeight),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ...fields,
                if (errorText != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: Text(
                      errorText!,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      actions: actions,
    );
  }
}
