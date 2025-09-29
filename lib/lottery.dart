class Lottery {
  final DateTime date;
  bool finished;
  bool requestsSend;
  bool allAnswersReceived;
  int lotterypotId;
  int nrOfchildrenToPick;

  Lottery({
    required this.date,
    this.finished = false,
    this.requestsSend = false,
    this.allAnswersReceived = false,
    required this.lotterypotId,
    this.nrOfchildrenToPick = 0,
  });
}
