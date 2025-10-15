import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/lottery.dart';
import '../widgets/reporting_period_control.dart';
import '../widgets/notify_parents_button.dart';
import '../widgets/confirmation_dialog.dart';

class ReportingPeriodControlSection extends StatelessWidget {
  final Lottery lottery;
  final String lotteryId;
  final bool showSendButton;
  final Future<void> Function() onEndPeriod;
  final Future<void> Function() onNotifyParents;

  const ReportingPeriodControlSection({
    super.key,
    required this.lottery,
    required this.lotteryId,
    required this.showSendButton,
    required this.onEndPeriod,
    required this.onNotifyParents,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ReportingPeriodControl(
          lottery: lottery,
          onEndPeriod: onEndPeriod,
        ),
        if (showSendButton)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: notifyparentsbutton(
              lotteryId: lotteryId,
              onSuccess: () async => await onNotifyParents(),
            ),
          ),
      ],
    );
  }
}
