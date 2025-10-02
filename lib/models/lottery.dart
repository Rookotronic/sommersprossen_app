// Top-level class for child data in lottery
class LotteryChild {
  final String childId;
  bool notified;
  bool responded;
  bool need;

  LotteryChild({
    required this.childId,
    this.notified = false,
    this.responded = false,
    this.need = false,
  });

  factory LotteryChild.fromMap(Map<String, dynamic> map) => LotteryChild(
    childId: map['childId'],
    notified: map['notified'] ?? false,
    responded: map['responded'] ?? false,
    need: map['need'] ?? false,
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
  final int nrOfchildrenToPick;

// Top-level class for child data in lottery

  final List<LotteryChild> children;
  final String timeOfDay;

  Lottery({
    required this.date,
    this.finished = false,
    this.requestsSend = false,
    this.allAnswersReceived = false,
    required this.nrOfchildrenToPick,
    required this.children,
    required this.timeOfDay,
  });
  factory Lottery.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Lottery(
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] ?? 0),
      finished: data['finished'] ?? false,
      requestsSend: data['requestsSend'] ?? false,
      allAnswersReceived: data['allAnswersReceived'] ?? false,
      nrOfchildrenToPick: data['nrOfchildrenToPick'] ?? 0,
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
      'nrOfchildrenToPick': nrOfchildrenToPick,
  'children': children.map((c) => c.toMap()).toList(),
      'timeOfDay': timeOfDay,
    };
  }
}
