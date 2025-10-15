import 'package:flutter/material.dart';
import '../models/lottery.dart';
import '../models/child.dart';
import '../utils/date_utils.dart' as custom_date_utils;

class LotteryInfoSection extends StatelessWidget {
  final Lottery lottery;
  final String lotteryId;
  final void Function(BuildContext, String) onEditInformation;

  const LotteryInfoSection({
    super.key,
    required this.lottery,
    required this.lotteryId,
    required this.onEditInformation,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(custom_date_utils.DateUtils.formatWeekdayDate(lottery.date), style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text('Gruppe: ${lottery.group == 'Beide' ? 'Beide' : GroupName.values.firstWhere((g) => g.name == lottery.group).displayName}', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        Text('Zeit: ${lottery.endFirstPartOfDay}', style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        Text('Zu ziehende Kinder: ${lottery.nrOfChildrenToPick}', style: Theme.of(context).textTheme.bodyLarge),
        if (lottery.information.isNotEmpty) ...[
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  lottery.information,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey.shade900),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'Bearbeiten',
                onPressed: () => onEditInformation(context, lottery.information),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ]
        else ...[
          Row(
            children: [
              Expanded(child: const SizedBox()),
              IconButton(
                icon: const Icon(Icons.edit, size: 20),
                tooltip: 'Information hinzufügen',
                onPressed: () => onEditInformation(context, ''),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ],
    );
  }
}
