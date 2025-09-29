enum GroupName { ratz, ruebe }

class Child {
  final int id;
  String vorname;
  String nachname;
  List<int>? parentIds; // List of parent IDs, nullable
  GroupName gruppe;

  Child({
    required this.id,
    required this.vorname,
    required this.nachname,
    this.parentIds,
    required this.gruppe,
  });
}
