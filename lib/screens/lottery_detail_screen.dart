import '../widgets/reporting_period_control_section.dart';
import '../widgets/children_list_section.dart';
import 'package:sommersprossen_app/widgets/confirmation_dialog.dart';
import '../widgets/print_lottery_button.dart';
import '../widgets/lottery_info_section.dart';
import 'package:flutter/material.dart';
import '../models/lottery.dart';
import '../models/child.dart';
import '../services/child_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Bildschirm zur Anzeige und Verwaltung der Details einer Lotterie.
///
/// Zeigt alle relevanten Informationen zur Lotterie, ermöglicht das Beenden des Meldezeitraums,
/// das Senden von Benachrichtigungen und das Löschen der Lotterie.
class LotteryDetailScreen extends StatefulWidget {
  /// Die ID der Lotterie in Firestore.
  final String lotteryId;
  /// Das Lotterie-Objekt mit allen relevanten Daten.
  final Lottery lottery;

  /// Erstellt eine Instanz des Lotterie-Detailbildschirms.
  const LotteryDetailScreen({super.key, required this.lottery, required this.lotteryId});

  @override
  State<LotteryDetailScreen> createState() => _LotteryDetailScreenState();
}

/// State-Klasse für LotteryDetailScreen.
///
/// Beinhaltet die Logik zur Anzeige, Bearbeitung und Löschung einer Lotterie.
class _LotteryDetailScreenState extends State<LotteryDetailScreen> {
  Future<void> _editInformation(BuildContext context, String currentInfo) async {
    final controller = TextEditingController(text: currentInfo);
    String? errorText;
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Information bearbeiten'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  maxLines: 4,
                  maxLength: 300,
                  decoration: InputDecoration(
                    hintText: 'Information zur Lotterie',
                    errorText: errorText,
                  ),
                  onChanged: (value) {
                    if (value.length > 300) {
                      setState(() => errorText = 'Maximal 300 Zeichen erlaubt');
                    } else {
                      setState(() => errorText = null);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Abbrechen'),
              ),
              ElevatedButton(
                onPressed: controller.text.length > 300
                    ? null
                    : () => Navigator.of(context).pop(controller.text),
                child: const Text('Speichern'),
              ),
            ],
          ),
        );
      },
    );
    if (result != null && result != currentInfo) {
      await FirebaseFirestore.instance
          .collection('lotteries')
          .doc(widget.lotteryId)
          .update({'information': result});
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Information aktualisiert.')),
      );
    }
  }

  @override
  /// Baut das UI für die Anzeige und Verwaltung der Lotterie-Details.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lotterie Details')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance.collection('lotteries').doc(widget.lotteryId).snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            Future.microtask(() {
              if (context.mounted) {
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Lotterie wurde gelöscht.')),
                );
              }
            });
            return const SizedBox();
          }
          final doc = snapshot.data!;
          final lottery = Lottery.fromFirestore(doc);
          final showSendButton = !lottery.finished && !lottery.requestsSend && !lottery.allAnswersReceived;
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LotteryInfoSection(
                  lottery: lottery,
                  lotteryId: widget.lotteryId,
                  onEditInformation: _editInformation,
                ),
                ReportingPeriodControlSection(
                  lottery: lottery,
                  lotteryId: widget.lotteryId,
                  showSendButton: showSendButton,
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
                  onNotifyParents: () async {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Benachrichtigungen gesendet!')),
                    );
                  },
                ),
                const SizedBox(height: 16),
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
                      return ListView(
                        padding: EdgeInsets.zero,
                        children: [
                          ChildrenListSection(
                            lottery: lottery,
                            children: children,
                            lotteryId: widget.lotteryId,
                          ),
                          const SizedBox(height: 16),
                          if (lottery.finished)
                            PrintLotteryButton(lottery: lottery, children: children),
                          const SizedBox(height: 8),
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
}