import 'child.dart';

class LotteryPotEntry {
  final String childId;
  final int entryOrder;
  bool priorityPick;

  LotteryPotEntry({
    required this.childId,
    required this.entryOrder,
    this.priorityPick = false,
  });
}

class LotteryPot {
  final DateTime startDate;
  final List<LotteryPotEntry> kids;

  LotteryPot({
    required this.startDate,
    required List<LotteryPotEntry> kids,
  }) : kids = List.from(kids)..sort((a, b) => a.entryOrder.compareTo(b.entryOrder));
}
