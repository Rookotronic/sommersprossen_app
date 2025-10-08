

import '../widgets/reporting_period_control.dart';
import '../widgets/notify_parents_button.dart';
import 'package:sommersprossen_app/widgets/confirmation_dialog.dart';

import 'package:flutter/material.dart';
import '../models/lottery.dart';
import '../models/child.dart';
import '../utils/date_format.dart';
import '../services/child_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class LotteryDetailScreen extends StatefulWidget {
  final String lotteryId;
  final Lottery lottery;

  const LotteryDetailScreen({super.key, required this.lottery, required this.lotteryId});

  @override
  State<LotteryDetailScreen> createState() => _LotteryDetailScreenState();
}

class _LotteryDetailScreenState extends State<LotteryDetailScreen> {
  // Remove local _lottery and _loading, use StreamBuilder instead

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lotterie Details')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('lotteries').doc(widget.lotteryId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: CircularProgressIndicator());
          }
          final doc = snapshot.data!;
          final lottery = Lottery.fromFirestore(doc);
          final showSendButton = !lottery.finished && !lottery.requestsSend && !lottery.allAnswersReceived;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ...existing code for lottery info, controls, children list, etc...
                Text('Datum: ${formatDate(lottery.date)}', style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 8),
                Text('Zeit: ${lottery.timeOfDay}', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 8),
                Text('Zu ziehende Kinder: ${lottery.nrOfChildrenToPick}', style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 16),
                ReportingPeriodControl(
                  lottery: lottery,
                  onEndPeriod: () async {
                    final confirmed = await showConfirmationDialog(
                      context,
                      title: 'Meldezeitraum beenden?',
                      content: 'Bist du sicher, dass du den Meldezeitraum beenden möchtest?',
                      confirmText: 'Beenden',
                    );
                    if (confirmed == true) {
                      await FirebaseFirestore.instance
                          .collection('lotteries')
                          .doc(widget.lotteryId)
                          .update({'allAnswersReceived': true});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Meldezeitraum wurde beendet.')),
                      );
                    }
                  },
                ),
                if (showSendButton)
                  Padding(
                    padding: const EdgeInsets.only(top: 8.0),
                    child: notifyparentsbutton(
                      onSuccess: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Benachrichtigungen gesendet!')),
                        );
                      },
                    ),
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
                                final requestsSend = lottery.requestsSend == true;
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
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: child.vorname.isNotEmpty || child.nachname.isNotEmpty
                                                  ? Text(
                                                      '${child.nachname}, ${child.vorname}${isPicked ? ' (Gezogen)' : ''}',
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
                                            if (!requestsSend)
                                              IconButton(
                                                icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                                                tooltip: 'Kind entfernen',
                                                onPressed: () async {
                                                  final confirmed = await showConfirmationDialog(
                                                    context,
                                                    title: 'Kind entfernen',
                                                    content: 'Möchtest du dieses Kind wirklich aus der Lotterie entfernen?',
                                                    confirmText: 'Entfernen',
                                                  );
                                                  if (confirmed == true) {
                                                    final updatedChildren = lottery.children
                                                      .where((c) => c.childId != child.id)
                                                      .map((c) => c.toMap())
                                                      .toList();
                                                    await FirebaseFirestore.instance
                                                        .collection('lotteries')
                                                        .doc(widget.lotteryId)
                                                        .update({'children': updatedChildren});
                                                  }
                                                },
                                              ),
                                          ],
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
                              final confirmed = await showConfirmationDialog(
                                context,
                                title: 'Lotterie löschen',
                                content: 'Bist du sicher, dass du diese Lotterie löschen möchtest? Dies kann nicht rückgängig gemacht werden.',
                                confirmText: 'Ja, löschen',
                              );
                              if (confirmed == true) {
                                final doubleCheck = await showConfirmationDialog(
                                  context,
                                  title: 'Wirklich löschen?',
                                  content: 'Bitte bestätige erneut, dass du die Lotterie wirklich löschen willst.',
                                  confirmText: 'Endgültig löschen',
                                  cancelText: 'Nein',
                                );
                                if (doubleCheck == true) {
                                  // ...existing code for deletion...
                                }
                              }
                              if (confirmed == true) {
                                try {
                                  await FirebaseFirestore.instance.collection('lotteries').doc(widget.lotteryId).delete();
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
          );
        },
      ),
    );
  }

  // ...existing code...
}
