import 'package:cloud_firestore/cloud_firestore.dart';

/// Data model for the lottery pot, representing a collection of children for a lottery event. 
/// It also implements the picking fairness by being an ordered list where kids are
/// picked from the front and added to the back.
class LotteryPot {
  /// Firestore document ID for the lottery pot. Which is always 'current'. There will be only
  ///  one lotterypot at all timesin the database.
  final String id;
  /// Start date of the lottery pot.
  final DateTime startDate;
  /// List of child IDs in the lottery pot.
  final List<String> kids;

    /// Creates a [LotteryPot] instance.
    LotteryPot({
      required this.id,
      required this.startDate,
      required this.kids,
    });

    /// Creates a [LotteryPot] instance from Firestore document data.
    factory LotteryPot.fromFirestore(String id, Map<String, dynamic> data) {
      try {
        final startRaw = data['startDate'];
        DateTime startDate;
        if (startRaw is Timestamp) {
          startDate = startRaw.toDate();
        } else if (startRaw is String && startRaw.isNotEmpty) {
          startDate = DateTime.tryParse(startRaw) ?? DateTime.now();
        } else if (startRaw is int) {
          startDate = DateTime.fromMillisecondsSinceEpoch(startRaw);
        } else {
          throw ArgumentError('Invalid or missing startDate field in LotteryPot Firestore data');
        }

        final kidsRaw = data['kids'];
        List<String> kids;
        if (kidsRaw is List) {
          kids = kidsRaw.map((e) => e.toString()).toList();
        } else if (kidsRaw == null) {
          kids = [];
        } else {
          throw ArgumentError('Invalid kids field in LotteryPot Firestore data');
        }

        return LotteryPot(
          id: id,
          startDate: startDate,
          kids: kids,
        );
      } catch (e) {
        // Optionally log error here
        throw ArgumentError('Failed to parse LotteryPot from Firestore: $e');
      }
    }
}
