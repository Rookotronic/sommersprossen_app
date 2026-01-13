import 'package:flutter/material.dart';
import '../widgets/lottery_result_box.dart';
import '../widgets/active_lottery_box.dart';
import '../models/child.dart';
import '../models/parent.dart';

import '../widgets/child_details_box.dart';
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
    return Column(
      children: [
        if (children.length > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (children.every((c) => c.siblings.isEmpty))
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
                        final callable = functions.httpsCallable('LinkSiblings');
                        final childIds = children.map((c) => c.id).toList();
                        await callable({'childIds': childIds});
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kinder wurden verknüpft.')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Fehler: $e')),
                        );
                      }
                    },
                    child: const Text('Kinder gemeinsam ziehen'),
                  ),
                if (children.any((c) => c.siblings.isNotEmpty))
                  ElevatedButton(
                    onPressed: () async {
                      try {
                        final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
                        final callable = functions.httpsCallable('SeperateSiblings');
                        final childIds = children.map((c) => c.id).toList();
                        await callable({'childIds': childIds});
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Kinder wurden getrennt.')),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Fehler: $e')),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Kinder trennen'),
                  ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            itemCount: children.length,
            itemBuilder: (context, index) {
              final child = children[index];
              return FutureBuilder<List<Parent>>(
                future: _fetchParentsForChild(child),
                builder: (context, snapshot) {
                  final parents = snapshot.data ?? [];
                  return Column(
                    children: [
                      ChildDetailsBox(
                        child: child,
                        parents: parents,
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
                      ),
                      // Show all relevant lotteries for this child
                      StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('lotteries')
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, lotterySnapshot) {
                          if (lotterySnapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }
                          if (!lotterySnapshot.hasData || lotterySnapshot.data!.docs.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final now = DateTime.now();
                          final List<Widget> lotteryBoxes = [];
                          for (final doc in lotterySnapshot.data!.docs) {
                            final data = doc.data() as Map<String, dynamic>?;
                            if (data == null) continue;
                            final childrenList = (data['children'] as List?) ?? [];
                            final lotteryChild = childrenList.firstWhere(
                              (c) => c['childId'] == child.id,
                              orElse: () => null,
                            );
                            if (lotteryChild == null) continue;
                            final finished = data['finished'] == true;
                            final date = (data['date'] != null) ? DateTime.tryParse(data['date']) : null;
                            final information = (data['information'] ?? '') as String;
                            final picked = lotteryChild['picked'] == true;
                            final responded = lotteryChild['responded'] == true;
                            final need = lotteryChild['need'] == true;
                            final allAnswersReceived = data['allAnswersReceived'] == true;
                            final stateText = picked
                                ? 'Ausgewählt'
                                : responded
                                    ? (need ? 'Bedarf angemeldet' : 'Kein Bedarf')
                                    : 'Keine Antwort';
                            final boxColor = finished
                              ? (picked ? Colors.red : Colors.green)
                              : (responded ? (need ? Colors.orange : Colors.red) : Colors.blue.shade100);
                            // Only show finished lotteries if the date is today or in the future
                            if (finished && date != null && date.isBefore(DateTime(now.year, now.month, now.day))) {
                              continue;
                            }
                            if (!finished) {
                              lotteryBoxes.add(ActiveLotteryBox(
                                date: date,
                                information: information,
                                responded: responded,
                                need: need,
                                allAnswersReceived: allAnswersReceived,
                                stateText: stateText,
                                boxColor: boxColor,
                                onNeed: () async {
                                  try {
                                    final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
                                    final callable = functions.httpsCallable('childHasNeed');
                                    await callable({'childId': child.id});
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Bedarf gemeldet!')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Fehler: $e')),
                                    );
                                  }
                                },
                                onNoNeed: () async {
                                  try {
                                    final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
                                    final callable = functions.httpsCallable('childHasNoNeed');
                                    await callable({'childId': child.id});
                                    if (!context.mounted) return;
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Kein Bedarf gemeldet!')),
                                    );
                                  } catch (e) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Fehler: $e')),
                                    );
                                  }
                                },
                              ));
                            } else {
                              lotteryBoxes.add(LotteryResultBox(
                                date: date,
                                information: information,
                                resultText: picked
                                    ? 'Ihr Kind muss zuhause bleiben.'
                                    : 'Ihr Kind wird betreut.',
                                boxColor: boxColor,
                              ));
                            }
                          }
                          if (lotteryBoxes.isEmpty) return const SizedBox.shrink();
                          return Column(children: lotteryBoxes);
                        },
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
