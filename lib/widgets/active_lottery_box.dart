import 'package:flutter/material.dart';
import '../utils/date_utils.dart' as custom_date_utils;

class ActiveLotteryBox extends StatelessWidget {
  final DateTime? date;
  final String information;
  final bool responded;
  final bool need;
  final bool allAnswersReceived;
  final bool finished;
  final String stateText;
  final Color boxColor;
  final VoidCallback? onNeed;
  final VoidCallback? onNoNeed;

  const ActiveLotteryBox({
    super.key,
    required this.date,
    required this.information,
    required this.responded,
    required this.need,
    required this.allAnswersReceived,
    required this.finished,
    required this.stateText,
    required this.boxColor,
    this.onNeed,
    this.onNoNeed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: boxColor,
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0), // Wie ChildDetailsBox
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aktive Lotterie', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              date != null
                  ? custom_date_utils.DateUtils.formatWeekdayDate(date!)
                  : 'unbekannt',
            ),
            if (information.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('Info: $information', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade900)),
            ],
            if (responded) ...[
              const SizedBox(height: 12),
              Text(
                stateText,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
            const SizedBox(height: 12),
            if (!finished)
              Row(
                children: [
                  ElevatedButton(
                    onPressed: onNeed,
                    child: const Text('Bedarf'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: onNoNeed,
                    child: const Text('Kein Bedarf'),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
