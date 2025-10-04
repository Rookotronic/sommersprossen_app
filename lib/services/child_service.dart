import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/child.dart';

class ChildService {
  static Future<List<Child>> fetchChildrenByIds(List<String> childIds) async {
    final ids = childIds.toSet().toList();
    if (ids.isEmpty) return [];
    final query = await FirebaseFirestore.instance.collection('children').where(FieldPath.documentId, whereIn: ids).get();
    return query.docs.map((doc) => Child.fromFirestore(doc.id, doc.data())).toList();
  }
}
