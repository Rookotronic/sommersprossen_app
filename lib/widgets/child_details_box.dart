import 'package:flutter/material.dart';
import '../models/child.dart';
import '../models/parent.dart';
import 'parent_list_display.dart';

class ChildDetailsBox extends StatelessWidget {
  final Child child;
  final List<Parent> parents;
  final VoidCallback? onTap;
  final VoidCallback? onHistoryTap;

  const ChildDetailsBox({
    super.key,
    required this.child,
    required this.parents,
    this.onTap,
    this.onHistoryTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Zeigt die Basisdaten des Kindes an
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.blue.shade100,
                    child: Icon(Icons.child_care, size: 28, color: Colors.blue.shade700),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(child.vorname, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        Text(child.nachname, style: Theme.of(context).textTheme.bodyMedium),
                      ],
                    ),
                  ),
                  TextButton.icon(
                    onPressed: onHistoryTap,
                    icon: const Icon(Icons.history, size: 16),
                    label: const Text('Historie'),
                    style: TextButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Zeigt die Elternliste an
              Row(
                children: [
                  Icon(Icons.groups, color: Colors.blue.shade400, size: 18),
                  const SizedBox(width: 6),
                  Text('Eltern:', style: Theme.of(context).textTheme.bodyMedium),
                ],
              ),
              const SizedBox(height: 4),
              ParentListDisplay(parents: parents),
              const SizedBox(height: 10),
              // Zeigt die Gruppenzugehörigkeit an
              Row(
                children: [
                  Icon(Icons.groups_2, color: Colors.blue.shade400, size: 18),
                  const SizedBox(width: 6),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
