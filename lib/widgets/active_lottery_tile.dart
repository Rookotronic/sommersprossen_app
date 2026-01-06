import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lottery.dart';
import '../widgets/notify_parents_button.dart';
import '../widgets/reporting_period_control.dart';
import '../widgets/confirmation_dialog.dart';
import '../screens/lottery_detail_screen.dart';

class ActiveLotteryTile extends StatelessWidget {
  final Lottery lottery;
  final String lotteryId;

  const ActiveLotteryTile({
    super.key,
    required this.lottery,
    required this.lotteryId,
  });

  String getGroupDisplay(String groupRaw) {
    switch (groupRaw.toLowerCase()) {
      case 'ratz':
        return 'Gruppe Ratz';
      case 'ruebe':
        return 'Gruppe Rübe';
      case 'beide':
        return 'Beide Gruppen';
      default:
        return 'Gruppe unbekannt';
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupDisplay = getGroupDisplay(lottery.group);
    final showSendButton = !lottery.requestsSend && !lottery.finished && !lottery.allAnswersReceived;
    final dateStr = lottery.date.toString().split(' ')[0];
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => LotteryDetailScreen(lotteryId: lotteryId, lottery: lottery),
          ),
        );
      },
      child: Card(
        color: Colors.blue.shade50,
        margin: const EdgeInsets.only(bottom: 24),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Aktive Lotterie ($groupDisplay)', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text('Datum: $dateStr'),
              if (showSendButton)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: notifyparentsbutton(
                    lotteryId: lotteryId,
                    onSuccess: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Benachrichtigungen gesendet!')),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 12),
              ReportingPeriodControl(
                lottery: lottery,
                onEndPeriod: () async {
                  final confirmed = await showConfirmationDialog(
                    context,
                    title: 'Lotterie jetzt ziehen?',
                    content: 'Bist du sicher, dass du die Lotterie jetzt ziehen und die Ziehung durchführen möchtest? Dies kann nicht rückgängig gemacht werden.',
                    confirmText: 'Jetzt ziehen',
                  );
                  if (confirmed == true) {
                    try {
                      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
                      final handleLotteryPicking = functions.httpsCallable('handleLotteryPicking');
                      await handleLotteryPicking({'lotteryId': lotteryId});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Lotterie wurde gezogen!')),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Fehler beim Ziehen der Lotterie: $e')),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
