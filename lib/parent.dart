class Parent {
  final String id; // Firestore doc id
  String vorname;
  String nachname;
  String email;

  Parent({required this.id, required this.vorname, required this.nachname, required this.email});

  factory Parent.fromFirestore(String id, Map<String, dynamic> data) {
    return Parent(
      id: id,
      vorname: data['vorname'] ?? '',
      nachname: data['nachname'] ?? '',
      email: data['email'] ?? '',
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vorname': vorname,
    'nachname': nachname,
    'email': email,
  };
}
