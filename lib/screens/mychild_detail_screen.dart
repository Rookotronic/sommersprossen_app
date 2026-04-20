import 'package:flutter/material.dart';
import '../widgets/lottery_result_box.dart';
import '../widgets/active_lottery_box.dart';
import '../models/child.dart';
import '../models/parent.dart';

import '../widgets/child_details_box.dart';
import 'mychild_history_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/lottery.dart';

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
                            .where('requestsSend', isEqualTo: true)
                            .snapshots(),
                        builder: (context, lotterySnapshot) {
                          if (lotterySnapshot.connectionState == ConnectionState.waiting) {
                            return const SizedBox.shrink();
                          }
                          if (!lotterySnapshot.hasData || lotterySnapshot.data!.docs.isEmpty) {
                            return const SizedBox.shrink();
                          }
                          final now = DateTime.now();
                          final List<Map<String, dynamic>> lotteryEntries = [];
                          for (final doc in lotterySnapshot.data!.docs) {
                            Lottery lottery;
                            try {
                              lottery = Lottery.fromFirestore(doc);
                            } catch (e, st) {
                              debugPrint('Skipping malformed lottery doc ${doc.id}: $e');
                              debugPrintStack(stackTrace: st);
                              continue;
                            }
                            LotteryChild? lotteryChild;
                            for (final entry in lottery.children) {
                              if (entry.childId == child.id) {
                                lotteryChild = entry;
                                break;
                              }
                            }
                            if (lotteryChild == null) continue;
                            final finished = lottery.finished;
                            final date = lottery.date;
                            final information = lottery.information;
                            final picked = lotteryChild.picked;
                            final responded = lotteryChild.responded;
                            final need = lotteryChild.need;
                            final allAnswersReceived = lottery.allAnswersReceived;
                            final stateText = picked
                                ? 'Ausgewählt'
                                : responded
                                    ? (need ? 'Bedarf angemeldet' : 'Kein Bedarf')
                                    : 'Keine Antwort';
                            final boxColor = finished
                              ? (picked ? Colors.red : Colors.green)
                              : (responded ? (need ? Colors.orange : Colors.red) : Colors.blue.shade100);
                            // Only show finished lotteries if the date is today or in the future
                            if (finished && date.isBefore(DateTime(now.year, now.month, now.day))) {
                              continue;
                            }
                            lotteryEntries.add({
                              'finished': finished,
                              'date': date,
                              'information': information,
                              'responded': responded,
                              'need': need,
                              'allAnswersReceived': allAnswersReceived,
                              'stateText': stateText,
                              'boxColor': boxColor,
                              'picked': picked,
                            });
                          }

                          lotteryEntries.sort((a, b) {
                            final aFinished = a['finished'] as bool;
                            final bFinished = b['finished'] as bool;
                            if (aFinished != bFinished) {
                              return aFinished ? 1 : -1;
                            }

                            final aDate = a['date'] as DateTime;
                            final bDate = b['date'] as DateTime;
                            return aDate.compareTo(bDate);
                          });

                          final List<Widget> lotteryBoxes = [];
                          for (final entry in lotteryEntries) {
                            final finished = entry['finished'] as bool;
                            final date = entry['date'] as DateTime;
                            final information = entry['information'] as String;
                            final responded = entry['responded'] as bool;
                            final need = entry['need'] as bool;
                            final allAnswersReceived = entry['allAnswersReceived'] as bool;
                            final stateText = entry['stateText'] as String;
                            final boxColor = entry['boxColor'] as Color;
                            final picked = entry['picked'] as bool;

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
