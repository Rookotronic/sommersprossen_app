import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';

/// A service class for generic Firestore CRUD operations with error handling and logging.
///
/// Provides methods to add, update, set, delete, and fetch documents from Firestore collections.
/// All methods log errors using the Logger package and return null or empty results on failure.
///
/// Example usage:
/// ```dart
/// final firestoreService = FirestoreService();
/// await firestoreService.add('users', {'name': 'Alice'});
/// ```
class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  FirebaseFirestore get db => _db;
  final Logger _logger = Logger();

  // Generic add

  /// Adds a new document to the specified [collection] with the given [data].
  ///
  /// Returns the [DocumentReference] of the created document, or null if an error occurs.
  Future<DocumentReference?> add(String collection, Map<String, dynamic> data) async {
    try {
      return await _db.collection(collection).add(data);
    } catch (e) {
      _logger.e('Firestore add error', e);
      return null;
    }
  }

  // Generic update

  /// Updates an existing document in the specified [collection] with [docId] using the provided [data].
  ///
  /// Returns true if the update succeeds, or false if an error occurs.
  Future<bool> update(String collection, String docId, Map<String, dynamic> data) async {
    try {
      await _db.collection(collection).doc(docId).update(data);
      return true;
    } catch (e) {
      _logger.e('Firestore update error', e);
      return false;
    }
  }

  // Generic set

  /// Sets (creates or overwrites) a document in the specified [collection] with [docId] and [data].
  ///
  /// Returns true if the operation succeeds, or false if an error occurs.
  Future<bool> set(String collection, String docId, Map<String, dynamic> data) async {
    try {
      await _db.collection(collection).doc(docId).set(data);
      return true;
    } catch (e) {
      _logger.e('Firestore set error', e);
      return false;
    }
  }

  // Generic delete

  /// Deletes the document with [docId] from the specified [collection].
  ///
  /// Returns true if the deletion succeeds, or false if an error occurs.
  Future<bool> delete(String collection, String docId) async {
    try {
      await _db.collection(collection).doc(docId).delete();
      return true;
    } catch (e) {
      _logger.e('Firestore delete error', e);
      return false;
    }
  }

  // Generic get (single doc)

  /// Fetches a single document with [docId] from the specified [collection].
  ///
  /// Returns the [DocumentSnapshot] if found, or null if an error occurs.
  Future<DocumentSnapshot<Map<String, dynamic>>?> get(String collection, String docId) async {
    try {
      return await _db.collection(collection).doc(docId).get();
    } catch (e) {
      _logger.e('Firestore get error', e);
      return null;
    }
  }

  // Generic query (all docs)
  /// Gets all documents from the specified Firestore collection.

  /// Gets all documents from the specified [collection].
  ///
  /// Returns a list of [DocumentSnapshot]s, or an empty list if an error occurs.
  Future<List<DocumentSnapshot<Map<String, dynamic>>>> getAllDocs(String collection) async {
    try {
      final snapshot = await _db.collection(collection).get();
      return snapshot.docs;
    } catch (e) {
      _logger.e('Firestore getAllDocs error', e);
      return [];
    }
  }
}
