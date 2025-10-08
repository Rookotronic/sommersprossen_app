/// Represents the kindergarten group a child belongs to.
/// Possible values: [ratz], [ruebe].
enum GroupName { ratz, ruebe }

/// Data model for a child in the lottery system.
///
/// [id]: Unique Firestore document ID.
/// [vorname]: First name of the child.
/// [nachname]: Last name of the child.
/// [parentIds]: List of parent IDs (nullable).
/// [gruppe]: Group assignment (see [GroupName]).
class Child {
  /// Unique Firestore document ID for the child.
  final String id;
  /// First name of the child.
  final String vorname;
  /// Last name of the child.
  final String nachname;
  /// List of parent IDs associated with the child (never null, defaults to empty list).
  final List<String> parentIds;
  /// Group assignment for the child.
  final GroupName gruppe;

  Child({
    required this.id,
    required this.vorname,
    required this.nachname,
    List<String>? parentIds,
    required this.gruppe,
  }) : parentIds = parentIds ?? [];

  /// Creates a [Child] instance from Firestore data.
  ///
  /// [id]: Firestore document ID.
  /// [data]: Map of field values from Firestore.
  factory Child.fromFirestore(String id, Map<String, dynamic> data) {
    try {
      final vorname = data['vorname'];
      final nachname = data['nachname'];
      final gruppeRaw = data['gruppe'];
      final parentIdsRaw = data['parentIds'];

      if (vorname is! String || nachname is! String) {
        throw ArgumentError('Invalid or missing name fields in Child Firestore data');
      }

      List<String> parentIds;
      if (parentIdsRaw is List) {
        parentIds = parentIdsRaw.map((e) => e.toString()).toList();
      } else if (parentIdsRaw == null) {
        parentIds = [];
      } else {
        throw ArgumentError('Invalid parentIds field in Child Firestore data');
      }

      return Child(
        id: id,
        vorname: vorname,
        nachname: nachname,
        parentIds: parentIds,
        gruppe: _groupNameFromString(gruppeRaw),
      );
    } catch (e) {
      // Optionally log error here
      throw ArgumentError('Failed to parse Child from Firestore: $e');
    }
  }

  /// Converts this [Child] instance to a Firestore-compatible map.
  Map<String, dynamic> toFirestore() => {
    'vorname': vorname,
    'nachname': nachname,
    'parentIds': parentIds,
    'gruppe': gruppe.name,
  };

  /// Helper to parse [GroupName] from Firestore value.
  static GroupName _groupNameFromString(dynamic value) {
    if (value is GroupName) return value;
    if (value is String) {
      final lowerValue = value.toLowerCase();
      return GroupName.values.firstWhere(
        (g) => g.name.toLowerCase() == lowerValue,
        orElse: () => GroupName.ratz,
      );
    }
    return GroupName.ratz;
  }
}

/// Extension to provide display names for [GroupName] enum values.
extension GroupNameDisplay on GroupName {
  /// Returns a user-friendly display name for the group.
  String get displayName {
    switch (this) {
      case GroupName.ratz:
        return 'Ratz';
      case GroupName.ruebe:
        return 'Rübe';
    }
  }
}
