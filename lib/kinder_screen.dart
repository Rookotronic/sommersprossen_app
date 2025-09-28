import 'package:flutter/material.dart';
import 'kinder_detail_screen.dart';
import 'eltern_screen.dart';
import 'mock_data.dart';

enum GroupName { ratz, ruebe }

class Child {
  final int id;
  String vorname;
  String nachname;
  List<String> eltern; // List of parent names for mockup
  GroupName gruppe;

  Child({
    required this.id,
    required this.vorname,
    required this.nachname,
    required this.eltern,
    required this.gruppe,
  });
}

class KinderScreen extends StatefulWidget {
  const KinderScreen({super.key});

  @override
  State<KinderScreen> createState() => _KinderScreenState();
}

class _KinderScreenState extends State<KinderScreen> {
  List<Child> _kinder = [];
  int _nextId = 3;

  // Simulate backend fetch
  Future<List<Child>> _fetchKinderFromServer() async {
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
      _kinder = list;
      _kinder.sort((a, b) => a.nachname.toLowerCase().compareTo(b.nachname.toLowerCase()));
      _nextId = _kinder.isEmpty ? 1 : (_kinder.map((e) => e.id).reduce((a, b) => a > b ? a : b) + 1);
    });
  }

  void _addKind() async {
    final vornameController = TextEditingController();
    final nachnameController = TextEditingController();
    GroupName? selectedGroup;
    String? errorText;
    List<Parent> parentList = [];
    List<Parent> selectedParents = [];

    // Fetch parents from MockData
    Future<List<Parent>> fetchParents() async {
      return await MockData().fetchParents();
    }

    parentList = await fetchParents();

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
                    // Multi-select dropdown for parents
                    DropdownButtonFormField<Parent>(
                      isExpanded: true,
                      decoration: const InputDecoration(labelText: 'Eltern'),
                      items: parentList.map((parent) => DropdownMenuItem<Parent>(
                        value: parent,
                        child: Text('${parent.nachname}, ${parent.vorname}'),
                      )).toList(),
                      onChanged: (parent) {
                        if (parent != null && !selectedParents.contains(parent)) {
                          setState(() => selectedParents.add(parent));
                        }
                      },
                    ),
                    // Show selected parents as chips
                    Wrap(
                      spacing: 4,
                      children: selectedParents.map((parent) => Chip(
                        label: Text('${parent.nachname}, ${parent.vorname}'),
                        onDeleted: () => setState(() => selectedParents.remove(parent)),
                      )).toList(),
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
                    final eltern = selectedParents.map((p) => '${p.nachname}, ${p.vorname}').toList();
                    if (vorname.isEmpty || nachname.isEmpty || eltern.isEmpty || selectedGroup == null) {
                      setState(() => errorText = 'Alle Felder sind erforderlich.');
                      return;
                    }
                    setState(() => errorText = null);
                    MockData().addChild(Child(
                      id: _nextId++,
                      vorname: vorname,
                      nachname: nachname,
                      eltern: eltern,
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
              subtitle: Text('Eltern: ${kind.eltern.join(", ")}\nGruppe: ${kind.gruppe == GroupName.ratz ? 'Ratz' : 'Rübe'}'),
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
    if (result is Child) {
      MockData().deleteChild(result.id);
      MockData().addChild(result);
      await _reloadKinder();
    } else if (result is Map && result['delete'] == true && result['id'] != null) {
      MockData().deleteChild(result['id'] as int);
      await _reloadKinder();
    } else {
      await _reloadKinder();
    }
  }

// --- KinderDetailScreen moved to end of file ---
}
