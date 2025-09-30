class Lottery {
  final DateTime date;
  bool finished;
  bool requestsSend;
  bool allAnswersReceived;
  final int nrOfchildrenToPick;

  Lottery({
    required this.date,
    this.finished = false,
    this.requestsSend = false,
    this.allAnswersReceived = false,
    required this.nrOfchildrenToPick,
  });

  factory Lottery.fromFirestore(dynamic doc) {
    final data = doc.data() as Map<String, dynamic>;
    return Lottery(
      date: DateTime.fromMillisecondsSinceEpoch(data['date'] ?? 0),
      finished: data['finished'] ?? false,
      requestsSend: data['requestsSend'] ?? false,
      allAnswersReceived: data['allAnswersReceived'] ?? false,
      nrOfchildrenToPick: data['nrOfchildrenToPick'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
        'date': date.millisecondsSinceEpoch,
        'finished': finished,
        'requestsSend': requestsSend,
        'allAnswersReceived': allAnswersReceived,
        'nrOfchildrenToPick': nrOfchildrenToPick,
      };
}
