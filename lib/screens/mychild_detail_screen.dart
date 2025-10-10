import 'package:flutter/material.dart';
import '../models/child.dart';
import '../models/parent.dart';
import '../widgets/parent_list_display.dart';
import 'mychild_history_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Zeigt die Detailansicht für ein oder mehrere Kinder an.
///
/// Listet alle Kinderkarten mit Eltern, Gruppe und Lotterie-Status auf.
class MeinKindDetailScreen extends StatelessWidget {
  /// Die anzuzeigenden Kinder.
  final List<Child> children;

  /// Erstellt die Detailansicht für die übergebenen Kinder.
  const MeinKindDetailScreen({super.key, required this.children});

  /// Holt die Eltern für ein bestimmtes Kind aus Firestore.
  Future<List<Parent>> _fetchParentsForChild(Child child) async {
    if (child.parentIds.isEmpty) {
      return [];
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('parents')
        .where(FieldPath.documentId, whereIn: child.parentIds)
        .get();
    return snapshot.docs.map((doc) => Parent.fromFirestore(doc.id, doc.data())).toList();
  }

  /// Baut die UI für die Kinder-Detailansicht.
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
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => MyChildHistoryScreen(
                          childId: child.id,
                          childName: '${child.vorname} ${child.nachname}',
                        ),
                      ),
                    );
                  },
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
                            children: [
                              CircleAvatar(
                                radius: 24,
                                backgroundColor: Colors.blue.shade100,
                                child: Icon(Icons.child_care, size: 28, color: Colors.blue.shade700),
                              ),
                              const SizedBox(width: 12),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(child.vorname, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                                  Text(child.nachname, style: Theme.of(context).textTheme.bodyMedium),
                                ],
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
                              Text('Gruppe:', style: Theme.of(context).textTheme.bodyMedium),
                              const SizedBox(width: 6),
                              Chip(
                                label: Text(child.gruppe.displayName, style: const TextStyle(color: Colors.white)),
                                backgroundColor: Colors.blue,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 0),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                // Zeigt die Lotterie-Info-Box unter jeder Kinderkarte an
                StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
            .collection('lotteries')
            .orderBy('createdAt', descending: true)
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
                    DateTime? lotteryDate;
                    if (data['date'] is Timestamp) {
                      lotteryDate = (data['date'] as Timestamp).toDate();
                    } else if (data['date'] is String) {
                      // Try to parse ISO8601 string
                      try {
                        lotteryDate = DateTime.parse(data['date'] as String);
                      } catch (_) {
                        lotteryDate = null;
                      }
                    }
                    final now = DateTime.now();
                    // Show result info box if finished and UNTIL 2 days have passed after lottery start
                    if (finished && lotteryDate != null && now.isBefore(lotteryDate.add(const Duration(days: 1)))) {
                      Color boxColor = picked ? Colors.red.shade300 : Colors.green.shade300;
                      String resultText = picked
                          ? '${child.vorname} muss Zuhause bleiben!'
                          : '${child.vorname} wird betreut!';
                      String dateText = 'Datum: ${lotteryDate.day.toString().padLeft(2, '0')}.${lotteryDate.month.toString().padLeft(2, '0')}.${lotteryDate.year}';
                      return SizedBox(
                        width: double.infinity,
                        child: Card(
                          elevation: 4,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                          color: boxColor,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Ergebnis Lotterie', style: Theme.of(context).textTheme.titleMedium),
                                const SizedBox(height: 8),
                                Text(dateText, style: Theme.of(context).textTheme.bodyMedium),
                                const SizedBox(height: 8),
                                Text(resultText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    // Show old info box only if not finished
                    final allAnswersReceived = data['allAnswersReceived'] == true;
                    final responded = childEntry != null && childEntry['responded'] == true;
                    final need = childEntry != null && childEntry['need'] == true;
                    final requestsSend = data['requestsSend'] == true || data['requestsSent'] == true;
                    if (requestsSend && !finished) {
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
                              if (!allAnswersReceived) Row(
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
