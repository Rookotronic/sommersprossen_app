// Top-level class for child data in lottery
class LotteryChild {
  final String childId;
  bool notified;
  bool responded;
  bool need;
  bool picked;

  LotteryChild({
    required this.childId,
    this.notified = false,
    this.responded = false,
    this.need = false,
    this.picked = false,
  });

  factory LotteryChild.fromMap(Map<String, dynamic> map) => LotteryChild(
    childId: map['childId'],
    notified: map['notified'] ?? false,
    responded: map['responded'] ?? false,
    need: map['need'] ?? false,
    picked: map['picked'] ?? false,
  );

  Map<String, dynamic> toMap() => {
    'childId': childId,
    'notified': notified,
    'responded': responded,
    'need': need,
  };
}
class Lottery {
  final DateTime date;
  bool finished;
  bool requestsSend;
  bool allAnswersReceived;
  final int nrOfChildrenToPick;
  final List<LotteryChild> children;
  final String timeOfDay;

  Lottery({
    required this.date,
    this.finished = false,
    this.requestsSend = false,
    this.allAnswersReceived = false,
    required this.nrOfChildrenToPick,
    required this.children,
    required this.timeOfDay,
  });
  factory Lottery.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Lottery(
      date: DateTime.parse(data['date'] ?? ''),
      finished: data['finished'] ?? false,
      requestsSend: data['requestsSend'] ?? false,
      allAnswersReceived: data['allAnswersReceived'] ?? false,
      nrOfChildrenToPick: data['nrOfChildrenToPick'] ?? 0,
      children: (data['children'] as List<dynamic>? ?? [])
        .map((c) => LotteryChild.fromMap(Map<String, dynamic>.from(c)))
        .toList(),
      timeOfDay: data['timeOfDay'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'date': date.millisecondsSinceEpoch,
      'finished': finished,
      'requestsSend': requestsSend,
      'allAnswersReceived': allAnswersReceived,
      'nrOfchildrenToPick': nrOfChildrenToPick,
  'children': children.map((c) => c.toMap()).toList(),
      'timeOfDay': timeOfDay,
    };
  }
}
