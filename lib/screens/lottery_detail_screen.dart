import 'package:flutter/material.dart';
import '../models/lottery.dart';
import '../models/child.dart';
import '../services/child_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LotteryDetailScreen extends StatelessWidget {
  final String lotteryId;
  final Lottery lottery;

  const LotteryDetailScreen({super.key, required this.lottery, required this.lotteryId});

  Widget _buildBoolCircle(bool value) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: value ? Colors.green : Colors.red,
        border: Border.all(color: Colors.grey.shade400),
      ),
    );
  }

  @override
  @override
  Widget build(BuildContext context) {
    final showSendButton = !lottery.finished && !lottery.requestsSend && !lottery.allAnswersReceived;
    return Scaffold(
      appBar: AppBar(title: const Text('Lotterie Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Datum: ${_formatDate(lottery.date)}', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text('Zeit: ${lottery.timeOfDay}', style: Theme.of(context).textTheme.bodyLarge),
                      const SizedBox(height: 8),
                      Text('Zu ziehende Kinder: ${lottery.nrOfChildrenToPick}', style: Theme.of(context).textTheme.bodyLarge),
                    ],
                  ),
                ),
                if (showSendButton)
                  Padding(
                    padding: const EdgeInsets.only(left: 12.0, top: 2.0),
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        // TODO: Call cloud onCall function to send notifications
                      },
                      child: const Text('Benachrichtigungen senden'),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Text('Kinder:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Child>>(
                future: ChildService.fetchChildrenByIds(lottery.children.map((c) => c.childId).toList()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Fehler beim Laden der Kinder: ${snapshot.error}'));
                  }
                  final children = snapshot.data ?? [];
                  // Ensure children are displayed in saved order, not reversed
                  final orderedChildren = lottery.children;
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        color: Colors.grey.shade200,
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text('Name', style: const TextStyle(fontSize: 11))),
                            Expanded(child: Center(child: Text('Benachrichtigt', style: const TextStyle(fontSize: 11)))),
                            Expanded(child: Center(child: Text('Geantwortet', style: const TextStyle(fontSize: 11)))),
                            Expanded(child: Center(child: Text('Bedarf', style: const TextStyle(fontSize: 11)))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: orderedChildren.length,
                          itemBuilder: (context, index) {
                            final entry = orderedChildren[index];
                            final child = children.firstWhere(
                              (c) => c.id == entry.childId,
                              orElse: () => Child(id: entry.childId, vorname: '', nachname: '', gruppe: GroupName.ratz),
                            );
                            final isPicked = entry.picked;
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              decoration: BoxDecoration(
                                color: isPicked ? Colors.red.shade700 : null,
                                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: child.vorname.isNotEmpty || child.nachname.isNotEmpty
                                        ? Text(
                                            '${child.nachname}, ${child.vorname}' + (isPicked ? ' (Gezogen)' : ''),
                                            style: isPicked
                                                ? const TextStyle(color: Colors.white, fontSize: 11)
                                                : const TextStyle(fontSize: 11),
                                          )
                                        : Text(
                                            child.id + (isPicked ? ' (Gezogen)' : ''),
                                            style: isPicked
                                                ? const TextStyle(color: Colors.white, fontSize: 11)
                                                : const TextStyle(fontSize: 11),
                                          ),
                                  ),
                                  Expanded(
                                    child: Center(child: _buildBoolCircle(entry.notified)),
                                  ),
                                  Expanded(
                                    child: Center(child: _buildBoolCircle(entry.responded)),
                                  ),
                                  Expanded(
                                    child: Center(child: _buildBoolCircle(entry.need)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) {
                              return AlertDialog(
                                title: const Text('Lotterie löschen'),
                                content: const Text('Bist du sicher, dass du diese Lotterie löschen möchtest? Dies kann nicht rückgängig gemacht werden.'),
                                actions: [
                                  TextButton(
                                    child: const Text('Abbrechen'),
                                    onPressed: () => Navigator.of(context).pop(false),
                                  ),
                                  TextButton(
                                    child: const Text('Ja, löschen'),
                                    onPressed: () async {
                                      final doubleCheck = await showDialog<bool>(
                                        context: context,
                                        builder: (context) {
                                          return AlertDialog(
                                            title: const Text('Wirklich löschen?'),
                                            content: const Text('Bitte bestätige erneut, dass du die Lotterie wirklich löschen willst.'),
                                            actions: [
                                              TextButton(
                                                child: const Text('Nein'),
                                                onPressed: () => Navigator.of(context).pop(false),
                                              ),
                                              TextButton(
                                                child: const Text('Endgültig löschen'),
                                                onPressed: () => Navigator.of(context).pop(true),
                                              ),
                                            ],
                                          );
                                        },
                                      );
                                      Navigator.of(context).pop(doubleCheck == true);
                                    },
                                  ),
                                ],
                              );
                            },
                          );
                          if (confirmed == true) {
                            try {
                              await FirebaseFirestore.instance.collection('lotteries').doc(lotteryId).delete();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Lotterie gelöscht!')),
                              );
                              Navigator.of(context).pop();
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Fehler beim Löschen: $e')),
                              );
                            }
                          }
                        },
                        child: const Text('Löschen'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
