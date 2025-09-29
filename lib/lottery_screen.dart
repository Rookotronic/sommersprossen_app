import 'package:flutter/material.dart';
import 'mock_data.dart';
import 'lottery.dart';
import 'package:intl/intl.dart';

class LotteryScreen extends StatelessWidget {
  const LotteryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final lotteries = List<Lottery>.from(MockData().lotteries)
      ..sort((a, b) => b.date.compareTo(a.date));
    return Scaffold(
      appBar: AppBar(title: const Text('Lotterien')),
      body: ListView.builder(
        itemCount: lotteries.length,
        itemBuilder: (context, index) {
          final lottery = lotteries[index];
          final dateStr = _formatDate(lottery.date);
          final textColor = lottery.finished
              ? Colors.grey.shade600
              : Theme.of(context).textTheme.bodyLarge?.color;
          return ListTile(
            title: Text(
              dateStr,
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              'Zu ziehende Kinder: ${lottery.nrOfchildrenToPick}',
              style: TextStyle(color: textColor),
            ),
          );
        },
      ),
    );
  }

  String _formatDate(DateTime date) {
    // Use intl if available, otherwise fallback
    try {
      // ignore: unused_import
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (_) {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }
}
