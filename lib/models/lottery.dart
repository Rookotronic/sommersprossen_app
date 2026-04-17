import 'package:cloud_firestore/cloud_firestore.dart';

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
  factory LotteryChild.fromMap(Map<String, dynamic> map) {
    bool parseBool(dynamic raw) {
      if (raw is bool) return raw;
      if (raw is num) return raw != 0;
      if (raw is String) {
        final normalized = raw.trim().toLowerCase();
        return normalized == 'true' || normalized == '1';
      }
      return false;
    }

    final childIdRaw = map['childId'];
    final childId = (childIdRaw ?? '').toString();

    return LotteryChild(
      childId: childId,
      notified: parseBool(map['notified']),
      responded: parseBool(map['responded']),
      need: parseBool(map['need']),
      picked: parseBool(map['picked']),
    );
  }

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
    this.information = '',
  });

  /// Creates a [Lottery] from Firestore document data.
  factory Lottery.fromFirestore(dynamic doc) {
    final rawData = doc.data();
    final data = rawData is Map ? Map<String, dynamic>.from(rawData) : <String, dynamic>{};

    DateTime parseDate(dynamic raw, DateTime fallback) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
      if (raw is String && raw.isNotEmpty) {
        return DateTime.tryParse(raw) ?? fallback;
      }
      return fallback;
    }

    bool parseBool(dynamic raw) {
      if (raw is bool) return raw;
      if (raw is num) return raw != 0;
      if (raw is String) {
        final normalized = raw.trim().toLowerCase();
        return normalized == 'true' || normalized == '1';
      }
      return false;
    }

    int parseInt(dynamic raw, int fallback) {
      if (raw is int) return raw;
      if (raw is num) return raw.toInt();
      if (raw is String) return int.tryParse(raw) ?? fallback;
      return fallback;
    }

    final now = DateTime.now();
    final date = parseDate(data['date'], now);
    final createdAt = parseDate(data['createdAt'], date);
    final finished = parseBool(data['finished']);
    final requestsSend = parseBool(data['requestsSend']);
    final allAnswersReceived = parseBool(data['allAnswersReceived']);
    final nrOfChildrenToPick = parseInt(data['nrOfChildrenToPick'], 0);
    final childrenRaw = data['children'];
    final information = (data['information'] ?? '').toString();

    final List<LotteryChild> children = [];
    if (childrenRaw is List) {
      for (final rawChild in childrenRaw) {
        if (rawChild is! Map) continue;

        // Firestore data can occasionally contain unexpected key/value types.
        // Coerce keys to String so malformed entries do not crash the UI.
        final childMap = <String, dynamic>{};
        rawChild.forEach((key, value) {
          childMap[key.toString()] = value;
        });

        children.add(LotteryChild.fromMap(childMap));
      }
    }

    return Lottery(
      date: date,
      createdAt: createdAt,
      finished: finished,
      requestsSend: requestsSend,
      allAnswersReceived: allAnswersReceived,
      nrOfChildrenToPick: nrOfChildrenToPick,
      children: children,
      information: information,
    );
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
      'information': information,
    };
  }
}
