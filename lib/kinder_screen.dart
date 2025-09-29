import 'package:flutter/material.dart';
import 'kinder_detail_screen.dart';
import 'eltern_screen.dart';
import 'mock_data.dart';
import 'child.dart';
import 'parent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class KinderScreen extends StatefulWidget {
  const KinderScreen({super.key});

  @override
  State<KinderScreen> createState() => _KinderScreenState();
}

class _KinderScreenState extends State<KinderScreen> {
  List<Child> _kinder = [];

  // Simulate backend fetch
  Future<List> _fetchKinderFromServer() async {
    return await MockData().fetchChildren();
  }

  @override
  void initState() {
    super.initState();
    _reloadKinder();
  }

  Future<void> _reloadKinder() async {
    final list = await _fetchKinderFromServer();
    setState(() {
      _kinder = List<Child>.from(list);
      _kinder.sort((a, b) => a.nachname.toLowerCase().compareTo(b.nachname.toLowerCase()));
    });
  }

  void _addKind() async {
    final vornameController = TextEditingController();
    final nachnameController = TextEditingController();
    GroupName? selectedGroup;
    String? errorText;
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
            return AlertDialog(
              title: const Text('Neues Kind hinzufügen'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                    DropdownButtonFormField<GroupName>(
                      value: selectedGroup,
                      decoration: const InputDecoration(labelText: 'Gruppe'),
                      items: const [
                        DropdownMenuItem(
                          value: GroupName.ratz,
                          child: Text('Ratz'),
                        ),
                        DropdownMenuItem(
                          value: GroupName.ruebe,
                          child: Text('Rübe'),
                        ),
                      ],
                      onChanged: (value) => setState(() => selectedGroup = value),
                    ),
                    if (errorText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(errorText ?? '', style: const TextStyle(color: Colors.red)),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final vorname = vornameController.text.trim();
                    final nachname = nachnameController.text.trim();
                    if (vorname.isEmpty || nachname.isEmpty || selectedGroup == null) {
                      setState(() => errorText = 'Vorname, Nachname und Gruppe sind erforderlich.');
                      return;
                    }
                    setState(() => errorText = null);
                    MockData().addChild(Child(
                      id: MockData().nextChildId,
                      vorname: vorname,
                      nachname: nachname,
                      parentIds: selectedParents.isEmpty ? null : selectedParents.map((p) => p.id).toList(),
                      gruppe: selectedGroup!,
                    ));
                    await _reloadKinder();
                    Navigator.of(context).pop();
                  },
                  child: const Text('Hinzufügen'),
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
      MockData().deleteChild(result['id'] as int);
      await _reloadKinder();
    } else if (result is Child) {
      // Update child (even if parentIds is null/empty)
      MockData().deleteChild(result.id);
      MockData().addChild(result);
      await _reloadKinder();
    } else {
      await _reloadKinder();
    }
  }

// --- KinderDetailScreen moved to end of file ---
}
