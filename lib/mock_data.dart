import 'eltern_screen.dart';
import 'kinder_screen.dart';

class MockData {
  // Singleton pattern
  static final MockData _instance = MockData._internal();
  factory MockData() => _instance;
  MockData._internal();

  // Initial parents
  final List<Parent> _initialParents = [
    Parent(id: 1, vorname: 'Anna', nachname: 'Müller', email: 'anna.mueller@email.de'),
    Parent(id: 2, vorname: 'Bernd', nachname: 'Schmidt', email: 'bernd.schmidt@email.de'),
    Parent(id: 3, vorname: 'Claudia', nachname: 'Fischer', email: 'claudia.fischer@email.de'),
    Parent(id: 4, vorname: 'Dieter', nachname: 'Klein', email: 'dieter.klein@email.de'),
    Parent(id: 5, vorname: 'Eva', nachname: 'Schulz', email: 'eva.schulz@email.de'),
  ];
  final List<Parent> _addedParents = [];
  final List<int> _deletedParentIds = [];

  // Initial children
  final List<Child> _initialChildren = [
    Child(id: 1, vorname: 'Lena', nachname: 'Müller', eltern: ['Anna Müller'], gruppe: GroupName.ratz),
    Child(id: 2, vorname: 'Tom', nachname: 'Schmidt', eltern: ['Bernd Schmidt', 'Eva Schulz'], gruppe: GroupName.ruebe),
  ];
  final List<Child> _addedChildren = [];
  final List<int> _deletedChildIds = [];

  // Parent methods
  Future<List<Parent>> fetchParents() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final all = [..._initialParents, ..._addedParents];
    return all.where((p) => !_deletedParentIds.contains(p.id)).toList();
  }
  void addParent(Parent parent) => _addedParents.add(parent);
  void deleteParent(int id) {
    _addedParents.removeWhere((p) => p.id == id);
    _deletedParentIds.add(id);
  }

  // Child methods
  Future<List<Child>> fetchChildren() async {
    await Future.delayed(const Duration(milliseconds: 400));
    final all = [..._initialChildren, ..._addedChildren];
    return all.where((c) => !_deletedChildIds.contains(c.id)).toList();
  }
  void addChild(Child child) => _addedChildren.add(child);
  void deleteChild(int id) {
    _addedChildren.removeWhere((c) => c.id == id);
    _deletedChildIds.add(id);
  }

  // For testing: clear all added/deleted
  void reset() {
    _addedParents.clear();
    _deletedParentIds.clear();
    _addedChildren.clear();
    _deletedChildIds.clear();
  }
}
