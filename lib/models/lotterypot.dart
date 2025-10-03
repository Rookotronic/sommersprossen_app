

import 'package:cloud_firestore/cloud_firestore.dart';

  late final String id;
  late final DateTime startDate;
  late final List<String> kids;

  class LotteryPot {
    final String id;
    final DateTime startDate;
    final List<String> kids;

    LotteryPot({
      required this.id,
      required this.startDate,
      required this.kids,
    });

    factory LotteryPot.fromFirestore(String id, Map<String, dynamic> data) {
      return LotteryPot(
        id: id,
        startDate: (data['startDate'] is Timestamp)
            ? (data['startDate'] as Timestamp).toDate()
            : DateTime.tryParse(data['startDate']?.toString() ?? '') ?? DateTime.now(),
        kids: (data['kids'] as List<dynamic>? ?? []).map((e) => e.toString()).toList(),
      );
    }
  }
