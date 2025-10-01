import 'package:flutter/material.dart';
import '../utils/controller_lifecycle_mixin.dart';
import 'kinder_detail_screen.dart';
import '../models/child.dart';
import '../widgets/group_dropdown.dart';
import '../models/parent.dart';
import '../services/firestore_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/form_dialog.dart';

class KinderScreen extends StatefulWidget {
  const KinderScreen({super.key});

  @override
  State<KinderScreen> createState() => _KinderScreenState();
}

class _KinderScreenState extends State<KinderScreen> with ControllerLifecycleMixin {
  final FirestoreService _firestoreService = FirestoreService();
  List<Child> _kinder = [];

  // Simulate backend fetch
  // ...existing code...

  @override
  void initState() {
    super.initState();
    _reloadKinder();
  }

  Future<void> _reloadKinder() async {
    final snapshot = await FirebaseFirestore.instance
        .collection('children')
        .orderBy('nachname')
        .get();
    final list = snapshot.docs
        .map((doc) => Child.fromFirestore(doc.id, doc.data()))
        .toList();
    setState(() {
      _kinder = List<Child>.from(list);
      _kinder.sort((a, b) => a.nachname.toLowerCase().compareTo(b.nachname.toLowerCase()));
    });
  }

  void _addKind() async {
  final vornameController = createController();
  final nachnameController = createController();
  GroupName? selectedGroup;
  String? errorText;
  bool isAlpha(String value) => RegExp(r"^[\p{L}'\- ]+$", unicode: true).hasMatch(value);
  // Fetch parents from Firestore, order by last name
  final snapshot = await FirebaseFirestore.instance
    .collection('parents')
    .orderBy('nachname')
    .get();
  List<Parent> parentList = snapshot.docs
    .map((doc) => Parent.fromFirestore(doc.id, doc.data()))
    .toList();
    List<Parent> selectedParents = [];
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return FormDialog(
              title: 'Neues Kind hinzufügen',
              fields: [
                TextField(
                  controller: vornameController,
                  autofocus: true,
                  decoration: const InputDecoration(labelText: 'Vorname'),
                ),
                TextField(
                  controller: nachnameController,
                  decoration: const InputDecoration(labelText: 'Nachname'),
                ),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text('Eltern', style: Theme.of(context).textTheme.bodySmall),
                ),
                SizedBox(
                  width: 300,
                  height: 200,
                  child: ListView(
                    shrinkWrap: true,
                    children: parentList.map((parent) {
                      final isChecked = selectedParents.contains(parent);
                      return CheckboxListTile(
                        value: isChecked,
                        title: Text('${parent.nachname}, ${parent.vorname}'),
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              if (!selectedParents.contains(parent)) selectedParents.add(parent);
                            } else {
                              selectedParents.remove(parent);
                            }
                          });
                        },
                      );
                    }).toList(),
                  ),
                ),
                GroupDropdown(
                  value: selectedGroup,
                  onChanged: (value) => setState(() => selectedGroup = value),
                ),
              ],
              errorText: errorText,
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final vorname = vornameController.text.trim();
                    final nachname = nachnameController.text.trim();
                    if (vorname.isEmpty) {
                      setState(() => errorText = 'Vorname ist erforderlich.');
                      return;
                    }
                    if (!isAlpha(vorname)) {
                      setState(() => errorText = 'Vorname: Nur Buchstaben und Sonderzeichen erlaubt.');
                      return;
                    }
                    if (nachname.isEmpty) {
                      setState(() => errorText = 'Nachname ist erforderlich.');
                      return;
                    }
                    if (!isAlpha(nachname)) {
                      setState(() => errorText = 'Nachname: Nur Buchstaben und Sonderzeichen erlaubt.');
                      return;
                    }
                    setState(() => errorText = null);
                    // Add child to Firestore
                    final result = await _firestoreService.add('children', {
                      'vorname': vorname,
                      'nachname': nachname,
                      'parentIds': selectedParents.isEmpty ? null : selectedParents.map((p) => p.id).toList(),
                      'gruppe': selectedGroup?.name,
                    });
                    if (result != null) {
                      await _reloadKinder();
                      Navigator.of(context).pop();
                    } else {
                      setState(() => errorText = 'Fehler beim Speichern.');
                    }
                  },
                  child: const Text('Speichern'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kinder')),
      body: ListView.builder(
        itemCount: _kinder.length,
        itemBuilder: (context, index) {
          final kind = _kinder[index];
          final isEven = index % 2 == 0;
          return Container(
            color: isEven ? Colors.white : Colors.blue[50],
            child: ListTile(
              title: Text('${kind.vorname} ${kind.nachname}'),
              onTap: () => _showKinderDetails(kind),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addKind,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showKinderDetails(Child child) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => KinderDetailScreen(child: child),
      ),
    );
    if (result is Map && result['delete'] == true && result['id'] != null) {
      // Only delete if user requested deletion
    final success = await _firestoreService.delete('children', result['id'].toString());
    if (success) await _reloadKinder();
    } else if (result is Child) {
      // Update child (even if parentIds is null/empty)
    final success = await _firestoreService.set('children', result.id.toString(), result.toFirestore());
    if (success) await _reloadKinder();
    } else {
      await _reloadKinder();
    }
  }

// --- KinderDetailScreen moved to end of file ---
}
