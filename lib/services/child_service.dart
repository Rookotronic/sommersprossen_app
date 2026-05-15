import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child.dart';

/// Service class for fetching child data from Firestore.
class ChildService {
  static const int _whereInChunkSize = 10;

  /// Fetches children from Firestore by their IDs.
  ///
  /// Returns an empty list if no IDs are provided or if an error occurs.
  ///
  /// [childIds]: List of child document IDs to fetch.
  static Future<List<Child>> fetchChildrenByIds(List<String> childIds) async {
    final ids = childIds.toSet().toList();
    if (ids.isEmpty) return [];

    try {
      final children = <Child>[];

      for (var index = 0; index < ids.length; index += _whereInChunkSize) {
        final end = (index + _whereInChunkSize) > ids.length
            ? ids.length
            : index + _whereInChunkSize;
        final chunk = ids.sublist(index, end);
        final query = await FirebaseFirestore.instance
            .collection('children')
            .where(FieldPath.documentId, whereIn: chunk)
            .get();
        children.addAll(
          query.docs.map((doc) => Child.fromFirestore(doc.id, doc.data())),
        );
      }

      return children;
    } catch (e) {
      // Optionally log error here
      return [];
    }
  }
}
