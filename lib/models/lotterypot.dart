
class LotteryPotEntry {
  final String childId;
  final int entryOrder;

  LotteryPotEntry({
    required this.childId,
    required this.entryOrder,
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
