import 'package:flutter/material.dart';
import '../models/child.dart';
import '../models/parent.dart';
import '../widgets/parent_list_display.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ...existing code...

class MeinKindDetailScreen extends StatelessWidget {
  final List<Child> children;
  const MeinKindDetailScreen({super.key, required this.children});

  Future<List<Parent>> _fetchParentsForChild(Child child) async {
    if (child.parentIds == null || child.parentIds!.isEmpty) {
      return [];
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('parents')
        .where(FieldPath.documentId, whereIn: child.parentIds)
        .get();
    return snapshot.docs.map((doc) => Parent.fromFirestore(doc.id, doc.data())).toList();
  }

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: children.length,
      itemBuilder: (context, index) {
        final child = children[index];
        return FutureBuilder<List<Parent>>(
          future: _fetchParentsForChild(child),
          builder: (context, snapshot) {
            final parents = snapshot.data ?? [];
            return Card(
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 32,
                          backgroundColor: Colors.blue.shade100,
                          child: Icon(Icons.child_care, size: 36, color: Colors.blue.shade700),
                        ),
                        const SizedBox(width: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(child.vorname, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                            Text(child.nachname, style: Theme.of(context).textTheme.titleMedium),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
                    Row(
                      children: [
                        Icon(Icons.groups, color: Colors.blue.shade400),
                        const SizedBox(width: 8),
                        Text('Eltern:', style: Theme.of(context).textTheme.titleMedium),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ParentListDisplay(parents: parents),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Icon(Icons.groups_2, color: Colors.blue.shade400),
                        const SizedBox(width: 8),
                        Text('Gruppe:', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(width: 8),
                        Chip(
                          label: Text(child.gruppe.displayName, style: const TextStyle(color: Colors.white)),
                          backgroundColor: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
