import 'package:flutter/material.dart';
import '../models/parent.dart';

class ParentListDisplay extends StatelessWidget {
  final List<Parent> parents;
  final String emptyText;
  final TextStyle? style;
  final EdgeInsetsGeometry? padding;

  const ParentListDisplay({
    super.key,
    required this.parents,
    this.emptyText = 'Keine Eltern gefunden.',
    this.style,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (parents.isEmpty) {
      return Padding(
        padding: padding ?? const EdgeInsets.only(left: 32),
        child: Text(emptyText, style: style ?? const TextStyle(color: Colors.grey)),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: parents.map((p) => Padding(
        padding: padding ?? const EdgeInsets.only(left: 32, bottom: 2),
        child: Text('${p.nachname}, ${p.vorname}', style: style ?? Theme.of(context).textTheme.bodyLarge),
      )).toList(),
    );
  }
}
