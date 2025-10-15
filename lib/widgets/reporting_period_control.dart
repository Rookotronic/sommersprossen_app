import 'package:flutter/material.dart';
import '../models/lottery.dart';

/// Widget zur Anzeige und Steuerung des Meldezeitraums einer Lotterie.
///
/// Zeigt einen Fortschrittsbalken und einen Button zum Beenden des Zeitraums.
class ReportingPeriodControl extends StatelessWidget {
  final Lottery lottery;
  final VoidCallback? onEndPeriod;
  const ReportingPeriodControl({super.key, required this.lottery, this.onEndPeriod});

  @override
  Widget build(BuildContext context) {
    final totalChildren = lottery.children.length;
    final respondedChildren = lottery.children.where((c) => c.responded).length;
    final percent = totalChildren > 0 ? respondedChildren / totalChildren : 0.0;
    final showBox = !lottery.finished && !lottery.allAnswersReceived && lottery.requestsSend;
    if (!showBox) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Meldezeitraum läuft', style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        LinearProgressIndicator(
          value: percent,
          minHeight: 8,
          backgroundColor: Colors.grey.shade300,
          color: Colors.blue,
        ),
        Text('${(percent * 100).toStringAsFixed(0)}% ($respondedChildren/$totalChildren)', style: const TextStyle(fontSize: 11)),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 180,
              child: ElevatedButton(
                onPressed: onEndPeriod,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                  textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  alignment: Alignment.center,
                ),
                child: const Text(
                  'Meldezeitraum beenden!',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
