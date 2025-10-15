import 'package:flutter/material.dart';
import '../utils/date_utils.dart' as custom_date_utils;

class LotteryResultBox extends StatelessWidget {
  final DateTime? date;
  final String information;
  final String resultText;
  final Color boxColor;

  const LotteryResultBox({
    super.key,
    required this.date,
    required this.information,
    required this.resultText,
    required this.boxColor,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
        color: boxColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ergebnis der Lotterie', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(
        date != null
          ? custom_date_utils.DateUtils.formatWeekdayDate(date!)
          : 'unbekannt',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              if (information.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Info: $information', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade900)),
              ],
              const SizedBox(height: 8),
              Text(resultText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
