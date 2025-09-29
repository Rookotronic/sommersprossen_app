

import 'package:sommersprossen_app/child.dart';

import 'child.dart';
import 'parent.dart';
import 'lottery.dart';
import 'lotterypot.dart';

class MockData {
  Future<List<Lottery>> fetchLotteries() async {
    await Future.delayed(const Duration(milliseconds: 400));
    return List.unmodifiable(_lotteries);
  }
  void addLottery(Lottery lottery) => _lotteries.add(lottery);
  List<Lottery> get lotteries => _lotteries; late final LotteryPot lotterypot;
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

  final List<Child> _children = [
    // Sibling group 1 (2 kids, parents 15 & 18)
    Child(id: 101, vorname: 'Ben', nachname: 'Bauer', gruppe: GroupName.ratz),
    Child(id: 104, vorname: 'Lilly', nachname: 'Bauer', gruppe: GroupName.ruebe),
    // Sibling group 2 (2 kids, parents 22 & 25)
    Child(id: 110, vorname: 'Emma', nachname: 'Brandt', gruppe: GroupName.ruebe),
    Child(id: 115, vorname: 'Noah', nachname: 'Brandt', gruppe: GroupName.ratz),
    // Sibling group 3 (2 kids, parents 28 & 31)
    Child(id: 120, vorname: 'Leon', nachname: 'Keller', gruppe: GroupName.ratz),
    Child(id: 121, vorname: 'Mila', nachname: 'Keller', gruppe: GroupName.ruebe),
    // Sibling group 4 (3 kids, parents 34 & 37)
    Child(id: 130, vorname: 'Sophie', nachname: 'Neumann', gruppe: GroupName.ruebe),
    Child(id: 131, vorname: 'Jonas', nachname: 'Neumann', gruppe: GroupName.ratz),
    Child(id: 132, vorname: 'Mia', nachname: 'Neumann', gruppe: GroupName.ruebe),
    // Non-sibling child with three parents (mom, dad, grandmother)
    Child(id: 140, vorname: 'Greta', nachname: 'Fischer', gruppe: GroupName.ruebe),
    Child(id: 141, vorname: 'Marie', nachname: 'Schwarz', gruppe: GroupName.ruebe),
    Child(id: 145, vorname: 'Tim', nachname: 'Voigt', gruppe: GroupName.ratz),
    Child(id: 150, vorname: 'Lara', nachname: 'Winter', gruppe: GroupName.ruebe),
    Child(id: 155, vorname: 'Jan', nachname: 'Schmidt', gruppe: GroupName.ratz),
    Child(id: 160, vorname: 'Mila', nachname: 'Klein', gruppe: GroupName.ruebe),
    Child(id: 161, vorname: 'Luis', nachname: 'Klein', gruppe: GroupName.ratz),
    Child(id: 170, vorname: 'Lena', nachname: 'Müller', gruppe: GroupName.ratz),
    Child(id: 180, vorname: 'Tom', nachname: 'Schmidt', gruppe: GroupName.ruebe),
    Child(id: 190, vorname: 'Max', nachname: 'Mustermann', gruppe: GroupName.ratz),
    Child(id: 200, vorname: 'Ella', nachname: 'Klein', gruppe: GroupName.ruebe),
    Child(id: 210, vorname: 'Nico', nachname: 'Voigt', gruppe: GroupName.ratz),
  ];



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
