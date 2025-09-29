import 'child.dart';

class LotteryPotEntry {
  final int childId;
  bool gotPicked;

  LotteryPotEntry({
    required this.childId,
    this.gotPicked = false,
  });
}

class LotteryPot {
  final DateTime startDate;
  final List<LotteryPotEntry> kids;
  final int lotterypotId;

  LotteryPot({
    required this.startDate,
    required this.kids,
    required this.lotterypotId,
  });
}
