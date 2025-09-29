

import 'parent.dart';
import 'child.dart';
import 'lottery.dart';
import 'lotterypot.dart';

class MockData {
  List<Lottery> get lotteries => List.unmodifiable(_lotteries);
  late final LotteryPot lotterypot;
  final List<Lottery> _lotteries = [
    Lottery(
      date: DateTime(2025, 9, 26),
      finished: true,
      requestsSend: true,
      allAnswersReceived: true,
      lotterypotId: 1,
      nrOfchildrenToPick: 2,
    ),
  ];
 
  // Singleton pattern
  static final MockData _instance = MockData._internal();
  factory MockData() => _instance;
  MockData._internal() {
    // Pick two random children to have gotPicked = true
    final kids = List<Child>.from(_children);
    kids.shuffle();
    final entries = kids.asMap().entries.map((entry) {
      final idx = entry.key;
      final child = entry.value;
      return LotteryPotEntry(childId: child.id, gotPicked: idx < 2);
    }).toList();
    lotterypot = LotteryPot(
      startDate: DateTime(2025, 9, 26),
      kids: entries,
      lotterypotId: 1,
    );
  }

  int _lastParentId = 100; // highest used parent id
  int _lastChildId = 210;  // highest used child id
  final List<Parent> _parents = [
    Parent(id: 1, vorname: 'Anna', nachname: 'Müller', email: 'anna.mueller@email.de'),
    Parent(id: 4, vorname: 'Bernd', nachname: 'Schmidt', email: 'bernd.schmidt@email.de'),
    Parent(id: 7, vorname: 'Claudia', nachname: 'Fischer', email: 'claudia.fischer@email.de'),
    Parent(id: 10, vorname: 'Dieter', nachname: 'Klein', email: 'dieter.klein@email.de'),
    Parent(id: 13, vorname: 'Eva', nachname: 'Schulz', email: 'eva.schulz@email.de'),
    Parent(id: 15, vorname: 'Frank', nachname: 'Bauer', email: 'frank.bauer@email.de'),
    Parent(id: 18, vorname: 'Gisela', nachname: 'Bauer', email: 'gisela.bauer@email.de'),
    Parent(id: 22, vorname: 'Heiko', nachname: 'Brandt', email: 'heiko.brandt@email.de'),
    Parent(id: 25, vorname: 'Ines', nachname: 'Brandt', email: 'ines.brandt@email.de'),
    Parent(id: 28, vorname: 'Jörg', nachname: 'Keller', email: 'joerg.keller@email.de'),
    Parent(id: 31, vorname: 'Karin', nachname: 'Keller', email: 'karin.keller@email.de'),
    Parent(id: 34, vorname: 'Lars', nachname: 'Neumann', email: 'lars.neumann@email.de'),
    Parent(id: 37, vorname: 'Mona', nachname: 'Neumann', email: 'mona.neumann@email.de'),
    Parent(id: 40, vorname: 'Nina', nachname: 'Peters', email: 'nina.peters@email.de'),
    Parent(id: 44, vorname: 'Oliver', nachname: 'Peters', email: 'oliver.peters@email.de'),
    Parent(id: 48, vorname: 'Petra', nachname: 'Schwarz', email: 'petra.schwarz@email.de'),
    Parent(id: 53, vorname: 'Quirin', nachname: 'Schwarz', email: 'quirin.schwarz@email.de'),
    Parent(id: 58, vorname: 'Ralf', nachname: 'Voigt', email: 'ralf.voigt@email.de'),
    Parent(id: 62, vorname: 'Sabine', nachname: 'Voigt', email: 'sabine.voigt@email.de'),
    Parent(id: 67, vorname: 'Tina', nachname: 'Winter', email: 'tina.winter@email.de'),
    Parent(id: 71, vorname: 'Uwe', nachname: 'Winter', email: 'uwe.winter@email.de'),
    Parent(id: 76, vorname: 'Vera', nachname: 'Schmidt', email: 'vera.schmidt@email.de'),
    Parent(id: 80, vorname: 'Wolfgang', nachname: 'Schmidt', email: 'wolfgang.schmidt@email.de'),
    Parent(id: 85, vorname: 'Yvonne', nachname: 'Klein', email: 'yvonne.klein@email.de'),
    Parent(id: 90, vorname: 'Zoe', nachname: 'Klein', email: 'zoe.klein@email.de'),
    Parent(id: 100, vorname: 'Gertrud', nachname: 'Neumann', email: 'gertrud.neumann@email.de'), // grandmother
  ];
  final List<Child> _children = [
  // Sibling group 1 (2 kids, parents 15 & 18)
  Child(id: 101, vorname: 'Ben', nachname: 'Bauer', parentIds: [15, 18], gruppe: GroupName.ratz),
  Child(id: 104, vorname: 'Lilly', nachname: 'Bauer', parentIds: [15, 18], gruppe: GroupName.ruebe),
  // Sibling group 2 (2 kids, parents 22 & 25)
  Child(id: 110, vorname: 'Emma', nachname: 'Brandt', parentIds: [22, 25], gruppe: GroupName.ruebe),
  Child(id: 115, vorname: 'Noah', nachname: 'Brandt', parentIds: [22, 25], gruppe: GroupName.ratz),
  // Sibling group 3 (2 kids, parents 28 & 31)
  Child(id: 120, vorname: 'Leon', nachname: 'Keller', parentIds: [28, 31], gruppe: GroupName.ratz),
  Child(id: 121, vorname: 'Mila', nachname: 'Keller', parentIds: [28, 31], gruppe: GroupName.ruebe),
  // Sibling group 4 (3 kids, parents 34 & 37)
  Child(id: 130, vorname: 'Sophie', nachname: 'Neumann', parentIds: [34, 37], gruppe: GroupName.ruebe),
  Child(id: 131, vorname: 'Jonas', nachname: 'Neumann', parentIds: [34, 37], gruppe: GroupName.ratz),
  Child(id: 132, vorname: 'Mia', nachname: 'Neumann', parentIds: [34, 37], gruppe: GroupName.ruebe),
  // Non-sibling child with three parents (mom, dad, grandmother)
  Child(id: 140, vorname: 'Greta', nachname: 'Fischer', parentIds: [7, 44, 100], gruppe: GroupName.ruebe),
  Child(id: 141, vorname: 'Marie', nachname: 'Schwarz', parentIds: [48, 53], gruppe: GroupName.ruebe),
  Child(id: 145, vorname: 'Tim', nachname: 'Voigt', parentIds: [58, 62], gruppe: GroupName.ratz),
  Child(id: 150, vorname: 'Lara', nachname: 'Winter', parentIds: [67, 71], gruppe: GroupName.ruebe),
  Child(id: 155, vorname: 'Jan', nachname: 'Schmidt', parentIds: [76, 80], gruppe: GroupName.ratz),
  Child(id: 160, vorname: 'Mila', nachname: 'Klein', parentIds: [85], gruppe: GroupName.ruebe),
  Child(id: 161, vorname: 'Luis', nachname: 'Klein', parentIds: [90], gruppe: GroupName.ratz),
  Child(id: 170, vorname: 'Lena', nachname: 'Müller', parentIds: [1], gruppe: GroupName.ratz),
  Child(id: 180, vorname: 'Tom', nachname: 'Schmidt', parentIds: [4, 13], gruppe: GroupName.ruebe),
  Child(id: 190, vorname: 'Max', nachname: 'Mustermann', parentIds: [7], gruppe: GroupName.ratz),
  Child(id: 200, vorname: 'Ella', nachname: 'Klein', parentIds: [85, 90], gruppe: GroupName.ruebe),
  Child(id: 210, vorname: 'Nico', nachname: 'Voigt', parentIds: [58], gruppe: GroupName.ratz),
  ];

  // Parent methods
  Future<List<Parent>> fetchParents() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_parents);
  }
  void addParent(Parent parent) {
    _parents.add(parent);
    if (parent.id > _lastParentId) _lastParentId = parent.id;
  }
  void deleteParent(int id) {
    _parents.removeWhere((p) => p.id == id);
  }
  void updateParent(Parent updated) {
   final idx = _parents.indexWhere((p) => p.id == updated.id);
   if (idx != -1) {
     _parents[idx] = updated;
   }
   if (updated.id > _lastParentId) _lastParentId = updated.id;
  }

  // Child methods
  Future<List<Child>> fetchChildren() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.from(_children);
  }
  void addChild(Child child) {
    _children.add(child);
    if (child.id > _lastChildId) _lastChildId = child.id;
  }
  void deleteChild(int id) {
    _children.removeWhere((c) => c.id == id);
  }
  void updateChild(Child updated) {
    final idx = _children.indexWhere((c) => c.id == updated.id);
    if (idx != -1) {
      _children[idx] = updated;
    }
    if (updated.id > _lastChildId) _lastChildId = updated.id;
  }
  // reset() removed
  int get nextParentId => _lastParentId + 1;
  int get nextChildId => _lastChildId + 1;
}
