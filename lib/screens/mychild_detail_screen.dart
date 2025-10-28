import '../widgets/lottery_result_box.dart';
import '../widgets/active_lottery_box.dart';
import 'package:flutter/material.dart';
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
                // Zeigt die Lotterie-Info-Box unter jeder Kinderkarte an
                StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
            .collection('lotteries')
            .orderBy('createdAt', descending: true)
            .snapshots(),
                  builder: (context, snapshot) {
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    final now = DateTime.now();
                    final relevantBoxes = <Widget>[];
                    for (final doc in snapshot.data!.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      final group = data['group'] ?? 'Beide';
                      final finished = data['finished'] ?? false;
                      final information = (data['information'] ?? '').toString().trim();
                      // Only show lottery info if group matches child's group or is 'Beide'
                      if (group != 'Beide' && group != child.gruppe.name) {
                        continue;
                      }
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
                      // Show result info box if finished and UNTIL 2 days have passed after lottery start
                      if (finished && lotteryDate != null && now.isBefore(lotteryDate.add(const Duration(days: 1)))) {
                        Color boxColor = picked ? Colors.red.shade300 : Colors.green.shade300;
                        String resultText = picked
                            ? '${child.vorname} muss Zuhause bleiben!'
                            : '${child.vorname} wird betreut!';
                        relevantBoxes.add(
                          LotteryResultBox(
                            date: lotteryDate,
                            information: information,
                            resultText: resultText,
                            boxColor: boxColor,
                          ),
                        );
                        continue;
                      }
                      // Show old info box only if not finished
                      final allAnswersReceived = data['allAnswersReceived'] == true;
                      final responded = childEntry != null && childEntry['responded'] == true;
                      final need = childEntry != null && childEntry['need'] == true;
                      final requestsSend = data['requestsSend'] == true || data['requestsSent'] == true;
                      if (requestsSend && !finished) {
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
                        relevantBoxes.add(
                          ActiveLotteryBox(
                            date: lotteryDate,
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
                          ),
                        );
                      }
                    }
                    if (relevantBoxes.isEmpty) {
                      return const SizedBox.shrink();
                    }
                    return Column(children: relevantBoxes);
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
