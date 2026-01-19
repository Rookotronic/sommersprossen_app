/// Represents a child's participation and status in a lottery.
class LotteryChild {
  /// Firestore document ID of the child.
  final String childId;
  /// Whether the child has been notified about the lottery.
  final bool notified;
  /// Whether the parent has responded for the child.
  final bool responded;
  /// Whether the child needs to be picked.
  final bool need;
  /// Whether the child was picked in the lottery.
  final bool picked;

  /// Creates a [LotteryChild] instance.
  const LotteryChild({
    required this.childId,
    required this.notified,
    required this.responded,
    required this.need,
    required this.picked,
  });

  /// Creates a [LotteryChild] from a map (Firestore or local data).
  factory LotteryChild.fromMap(Map<String, dynamic> map) => LotteryChild(
    childId: map['childId'],
    notified: map['notified'] ?? false,
    responded: map['responded'] ?? false,
    need: map['need'] ?? false,
    picked: map['picked'] ?? false,
  );

  /// Converts this [LotteryChild] to a map for Firestore or local storage.
  Map<String, dynamic> toMap() => {
    'childId': childId,
    'notified': notified,
    'responded': responded,
    'need': need,
    'picked': picked,
  };
}

/// Data model for a lottery event, including children and status.
class Lottery {
  /// Date of the emergency childcare event.
  final DateTime date;
  /// Timestamp when the lottery was created.
  final DateTime createdAt;
  /// Group for the lottery event ("Beide", "ratz", "ruebe").
  final String group;
  /// Number of children to pick in the lottery.
  final int nrOfChildrenToPick;
  /// List of children participating in the lottery.
  final List<LotteryChild> children;
  /// Whether the lottery is finished.
  final bool finished;
  /// Whether requests have been sent to parents.
  final bool requestsSend;
  /// Whether all answers have been received from parents or the admin has closed the reporting period.
  final bool allAnswersReceived;
  /// Additional information for the lottery event.
  final String information;

  /// Creates a [Lottery] instance.
  Lottery({
    required this.date,
    required this.createdAt,
    this.finished = false,
    this.requestsSend = false,
    this.allAnswersReceived = false,
    required this.nrOfChildrenToPick,
    required this.children,
    required this.group,
    this.information = '',
  });

  /// Creates a [Lottery] from Firestore document data.
  factory Lottery.fromFirestore(dynamic doc) {
    try {
      final data = doc.data() as Map<String, dynamic>;
      final dateRaw = data['date'];
      final createdAtRaw = data['createdAt'];
    final finished = data['finished'] ?? false;
    final requestsSend = data['requestsSend'] ?? false;
    final allAnswersReceived = data['allAnswersReceived'] ?? false;
    final nrOfChildrenToPick = data['nrOfChildrenToPick'] ?? 0;
    final childrenRaw = data['children'];
    final group = data['group'] ?? 'Beide';
    final information = (data['information'] ?? '').toString();

      DateTime date;
      if (dateRaw is String && dateRaw.isNotEmpty) {
        date = DateTime.parse(dateRaw);
      } else if (dateRaw is int) {
        date = DateTime.fromMillisecondsSinceEpoch(dateRaw);
      } else {
        throw ArgumentError('Invalid or missing date field in Lottery Firestore data');
      }

      DateTime createdAt;
      if (createdAtRaw is String && createdAtRaw.isNotEmpty) {
        createdAt = DateTime.parse(createdAtRaw);
      } else if (createdAtRaw is int) {
        createdAt = DateTime.fromMillisecondsSinceEpoch(createdAtRaw);
      } else {
        // If missing, fallback to date
        createdAt = date;
      }

      List<LotteryChild> children;
      if (childrenRaw is List) {
        children = childrenRaw
          .map((c) => LotteryChild.fromMap(Map<String, dynamic>.from(c)))
          .toList();
      } else if (childrenRaw == null) {
        children = [];
      } else {
        throw ArgumentError('Invalid children field in Lottery Firestore data');
      }

      return Lottery(
        date: date,
        createdAt: createdAt,
        finished: finished,
        requestsSend: requestsSend,
        allAnswersReceived: allAnswersReceived,
        nrOfChildrenToPick: nrOfChildrenToPick,
        children: children,
        group: group,
        information: information,
      );
    } catch (e) {
      // Optionally log error here
      throw ArgumentError('Failed to parse Lottery from Firestore: $e');
    }
  }

  /// Converts this [Lottery] instance to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() {
    return {
      'date': date.millisecondsSinceEpoch,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'finished': finished,
      'requestsSend': requestsSend,
      'allAnswersReceived': allAnswersReceived,
      'nrOfChildrenToPick': nrOfChildrenToPick,
      'children': children.map((c) => c.toMap()).toList(),
      'group': group,
      'information': information,
    };
  }
}
