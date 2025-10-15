import 'package:flutter/material.dart';

class ActiveLotteryBox extends StatelessWidget {
  final DateTime? date;
  final String information;
  final bool responded;
  final bool need;
  final bool allAnswersReceived;
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
    required this.stateText,
    required this.boxColor,
    this.onNeed,
    this.onNoNeed,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      color: boxColor,
      margin: const EdgeInsets.fromLTRB(24, 8, 24, 0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Aktive Lotterie', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              date != null
                  ? 'Datum: ${date!.day.toString().padLeft(2, '0')}.${date!.month.toString().padLeft(2, '0')}.${date!.year}'
                  : 'Datum: unbekannt',
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
            if (!allAnswersReceived) Row(
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
