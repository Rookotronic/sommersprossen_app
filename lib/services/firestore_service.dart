import 'package:cloud_firestore/cloud_firestore.dart';
// This file has been moved to: /Users/lorenztheuer/VS CODE/sommersprossen_app/lib/services/firestore_service.dart
// Please update your imports accordingly.
import 'package:cloud_firestore/cloud_firestore.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  FirebaseFirestore get db => _db;

  // Generic add
  Future<DocumentReference?> add(String collection, Map<String, dynamic> data) async {
    try {
      return await _db.collection(collection).add(data);
    } catch (e) {
      print('Firestore add error: $e');
      return null;
    }
  }

  // Generic update
  Future<bool> update(String collection, String docId, Map<String, dynamic> data) async {
    try {
      await _db.collection(collection).doc(docId).update(data);
      return true;
    } catch (e) {
      print('Firestore update error: $e');
      return false;
    }
  }

  // Generic set
  Future<bool> set(String collection, String docId, Map<String, dynamic> data) async {
    try {
      await _db.collection(collection).doc(docId).set(data);
      return true;
    } catch (e) {
      print('Firestore set error: $e');
      return false;
    }
  }

  // Generic delete
  Future<bool> delete(String collection, String docId) async {
    try {
      await _db.collection(collection).doc(docId).delete();
      return true;
    } catch (e) {
      print('Firestore delete error: $e');
      return false;
    }
  }

  // Generic get (single doc)
  Future<DocumentSnapshot?> get(String collection, String docId) async {
    try {
      return await _db.collection(collection).doc(docId).get();
    } catch (e) {
      print('Firestore get error: $e');
      return null;
    }
  }

  // Generic query (all docs)
  Future<List<DocumentSnapshot>> getAll(String collection) async {
    try {
      final snapshot = await _db.collection(collection).get();
      return snapshot.docs;
    } catch (e) {
      print('Firestore getAll error: $e');
      return [];
    }
  }
}
