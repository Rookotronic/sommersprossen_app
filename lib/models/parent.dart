class Parent {
  /// Data model for a parent in the lottery system.
  /// Firestore document ID for the parent.
  final String id;
  /// First name of the parent.
  final String vorname;
  /// Last name of the parent.
  final String nachname;
  /// Email address of the parent. It also has to be unique because of Firebase Authentication.
  /// It also connects the user to the parent data in Firestore.
  final String email;

  Parent({required this.id, required this.vorname, required this.nachname, required this.email});

  /// Creates a [Parent] instance from Firestore document data.
  factory Parent.fromFirestore(String id, Map<String, dynamic> data) {
    try {
      final vorname = data['vorname'];
      final nachname = data['nachname'];
      final email = data['email'];
      if (vorname is! String || nachname is! String || email is! String) {
        throw ArgumentError('Invalid or missing fields in Parent Firestore data');
      }
      return Parent(
        id: id,
        vorname: vorname,
        nachname: nachname,
        email: email,
      );
    } catch (e) {
      // Optionally log error here
      throw ArgumentError('Failed to parse Parent from Firestore: $e');
    }
  }

  /// Converts this [Parent] instance to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() => {
    'vorname': vorname,
    'nachname': nachname,
    'email': email,
  };
}
