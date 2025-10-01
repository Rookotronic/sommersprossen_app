import 'package:flutter/material.dart';
import '../models/child.dart';

class GroupDropdown extends StatelessWidget {
  final GroupName? value;
  final void Function(GroupName?)? onChanged;
  final String? label;
  final EdgeInsetsGeometry? padding;
  final bool enabled;

  const GroupDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.label,
    this.padding,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: DropdownButtonFormField<GroupName>(
        value: value,
        decoration: InputDecoration(labelText: label ?? 'Gruppe'),
        items: const [
          DropdownMenuItem(
            value: GroupName.ratz,
            child: Text('Ratz'),
          ),
          DropdownMenuItem(
            value: GroupName.ruebe,
            child: Text('Rübe'),
          ),
        ],
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}
