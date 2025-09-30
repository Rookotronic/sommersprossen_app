enum GroupName { ratz, ruebe }

class Child {
  final String id;
  String vorname;
  String nachname;
  List<String>? parentIds; // List of parent IDs, nullable
  GroupName gruppe;

  Child({
    required this.id,
    required this.vorname,
    required this.nachname,
    this.parentIds,
    required this.gruppe,
  });

  factory Child.fromFirestore(String id, Map<String, dynamic> data) {
    return Child(
      id: id,
      vorname: data['vorname'] ?? '',
      nachname: data['nachname'] ?? '',
      parentIds: (data['parentIds'] as List?)?.map((e) => e.toString()).toList(),
      gruppe: _groupNameFromString(data['gruppe']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'vorname': vorname,
    'nachname': nachname,
    'parentIds': parentIds,
    'gruppe': gruppe.name,
  };

  static GroupName _groupNameFromString(dynamic value) {
    if (value is GroupName) return value;
    if (value is String) {
      return GroupName.values.firstWhere(
        (g) => g.name == value,
        orElse: () => GroupName.ratz,
      );
    }
    return GroupName.ratz;
  }
}

extension GroupNameDisplay on GroupName {
  String get displayName {
    switch (this) {
      case GroupName.ratz:
        return 'Ratz';
      case GroupName.ruebe:
        return 'Rübe';
    }
  }
}
