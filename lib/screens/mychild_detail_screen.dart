import 'package:flutter/material.dart';
import '../models/child.dart';
import '../models/parent.dart';
import '../widgets/parent_list_display.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

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
            return Column(
              children: [
                Card(
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
                ),
                // Lottery info box below each child card
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('lotteries')
                      .orderBy('date', descending: true)
                      .limit(1)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                    final finished = data['finished'] ?? false;
                    final childrenList = (data['children'] as List<dynamic>? ?? []);
                    final childEntry = childrenList.firstWhere(
                      (c) => c['childId'] == child.id,
                      orElse: () => null,
                    );
                    final picked = childEntry != null && childEntry['picked'] == true;
                    final responded = childEntry != null && childEntry['responded'] == true;
                    final need = childEntry != null && childEntry['need'] == true;
                    // Show box if lottery is active or child was picked in latest lottery
                    if (!finished || picked) {
                      final date = data['date'] ?? '';
                      final timeOfDay = data['timeOfDay'] ?? '';
                      final nrOfChildrenToPick = data['nrOfChildrenToPick'] ?? '';
                      Color boxColor = Colors.blue.shade50;
                      String stateText = '';
                      if (responded) {
                        if (need) {
                          boxColor = Colors.green.shade300;
                          stateText = 'Für dieses Kind Bedarf angemeldet!';
                        } else {
                          boxColor = Colors.red.shade300;
                          stateText = 'Für dieses Kind KEINEN Bedarf angemeldet!';
                        }
                      }
                      return Card(
                        color: boxColor,
                        margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Aktive Lotterie', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text('Datum: $date'),
                              Text('Zeit: $timeOfDay'),
                              Text('Zu ziehende Kinder: $nrOfChildrenToPick'),
                              if (responded) ...[
                                const SizedBox(height: 12),
                                Text(
                                  stateText,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
                                        final callable = functions.httpsCallable('childHasNeed');
                                        await callable({'childId': child.id});
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Bedarf gemeldet!')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Fehler: $e')),
                                        );
                                      }
                                    },
                                    child: const Text('Bedarf'),
                                  ),
                                  const SizedBox(width: 12),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.red,
                                      foregroundColor: Colors.white,
                                    ),
                                    onPressed: () async {
                                      try {
                                        final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
                                        final callable = functions.httpsCallable('childHasNoNeed');
                                        await callable({'childId': child.id});
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(content: Text('Kein Bedarf gemeldet!')),
                                        );
                                      } catch (e) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Fehler: $e')),
                                        );
                                      }
                                    },
                                    child: const Text('Kein Bedarf'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
