import 'package:flutter/material.dart';
import '../utils/date_utils.dart' as custom_date_utils;

/// Widget to display the result of a lottery draw.
/// Shows the date, additional information, and the result text in a colored card.

class LotteryResultBox extends StatelessWidget {
  /// The date of the lottery result.
  final DateTime? date;
  /// Any additional information about the lottery.
  final String information;
  /// The result text to display (e.g., who was picked).
  final String resultText;
  /// The background color of the result box.
  final Color boxColor;

  /// Creates a result box for a lottery draw.
  const LotteryResultBox({
    super.key,
    required this.date,
    required this.information,
    required this.resultText,
    required this.boxColor,
  });

  @override
  Widget build(BuildContext context) {
    // The main card displaying the lottery result.
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
              // Title
              Text('Ergebnis der Lotterie', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              // Date of the lottery
              Text(
                date != null
                  ? custom_date_utils.DateUtils.formatWeekdayDate(date!)
                  : 'unbekannt',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              // Optional information section
              if (information.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text('Info: $information', style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade900)),
              ],
              const SizedBox(height: 8),
              // The main result text (e.g., who was picked)
              Text(resultText, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
      ),
    );
  }
}
