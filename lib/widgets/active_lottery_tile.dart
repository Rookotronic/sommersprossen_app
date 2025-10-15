import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lottery.dart';
import '../widgets/notify_parents_button.dart';
import '../widgets/reporting_period_control.dart';
import '../widgets/confirmation_dialog.dart';
import '../screens/lottery_detail_screen.dart';
import '../utils/date_utils.dart' as custom_date_utils;

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
  final dateStr = custom_date_utils.DateUtils.formatWeekdayDate(lottery.date);
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
              Text(dateStr),
              if (showSendButton)
                Padding(
                  padding: const EdgeInsets.only(top: 12.0),
                  child: Center(
                    child: notifyparentsbutton(
                      lotteryId: lotteryId,
                      onSuccess: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Benachrichtigungen gesendet!')),
                        );
                      },
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Center(
                child: ReportingPeriodControl(
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
                          .doc(lotteryId)
                          .update({'allAnswersReceived': true});
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Meldezeitraum wurde beendet.')),
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
