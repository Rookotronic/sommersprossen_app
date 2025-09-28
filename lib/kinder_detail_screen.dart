import 'package:flutter/material.dart';
import 'kinder_screen.dart';
import 'eltern_screen.dart' show Parent;


class KinderDetailScreen extends StatefulWidget {
  final Child child;
  const KinderDetailScreen({super.key, required this.child});

  @override
  State<KinderDetailScreen> createState() => _KinderDetailScreenState();
}

class _KinderDetailScreenState extends State<KinderDetailScreen> {
  late TextEditingController _vornameController;
  late TextEditingController _nachnameController;
  GroupName? _selectedGroup;
  List<Parent> _parentList = [];
  List<Parent> _selectedParents = [];
  bool _loadingParents = true;

  @override
  void initState() {
    super.initState();
    _vornameController = TextEditingController(text: widget.child.vorname);
    _nachnameController = TextEditingController(text: widget.child.nachname);
    _selectedGroup = widget.child.gruppe;
    _loadParents();
  }

  Future<void> _loadParents() async {
    // Simulate backend fetch (should match ElternScreen logic)
    await Future.delayed(const Duration(milliseconds: 400));
    final all = [
      Parent(id: 1, vorname: 'Anna', nachname: 'Müller', email: 'anna.mueller@email.de'),
      Parent(id: 2, vorname: 'Bernd', nachname: 'Schmidt', email: 'bernd.schmidt@email.de'),
      Parent(id: 3, vorname: 'Claudia', nachname: 'Fischer', email: 'claudia.fischer@email.de'),
      Parent(id: 4, vorname: 'Dieter', nachname: 'Klein', email: 'dieter.klein@email.de'),
      Parent(id: 5, vorname: 'Eva', nachname: 'Schulz', email: 'eva.schulz@email.de'),
    ];
    setState(() {
      _parentList = all;
      // Try to match existing parents by name
      _selectedParents = all.where((p) => widget.child.eltern.contains('${p.nachname}, ${p.vorname}')).toList();
      _loadingParents = false;
    });
  }

  @override
  void dispose() {
    _vornameController.dispose();
    _nachnameController.dispose();
    super.dispose();
  }

  void _save() {
    final updated = Child(
      id: widget.child.id,
      vorname: _vornameController.text.trim(),
      nachname: _nachnameController.text.trim(),
      eltern: _selectedParents.map((p) => '${p.nachname}, ${p.vorname}').toList(),
      gruppe: _selectedGroup ?? GroupName.ratz,
    );
    Navigator.of(context).pop(updated);
  }

  void _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Kind löschen'),
        content: const Text('Sind Sie sicher, dass Sie dieses Kind löschen möchten?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Löschen'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      Navigator.of(context).pop({'delete': true, 'id': widget.child.id});
    }
  }

  void _showParentPicker() async {
    final List<Parent> tempSelected = List.from(_selectedParents);
    final result = await showDialog<List<Parent>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eltern auswählen'),
          content: SizedBox(
            width: 300,
            child: ListView(
              shrinkWrap: true,
              children: _parentList.map((parent) {
                final isChecked = tempSelected.contains(parent);
                return CheckboxListTile(
                  value: isChecked,
                  title: Text('${parent.nachname}, ${parent.vorname}'),
                  onChanged: (checked) {
                    setState(() {
                      if (checked == true) {
                        if (!tempSelected.contains(parent)) tempSelected.add(parent);
                      } else {
                        tempSelected.remove(parent);
                      }
                    });
                  },
                );
              }).toList(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(_selectedParents),
              child: const Text('Abbrechen'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(tempSelected),
              child: const Text('Übernehmen'),
            ),
          ],
        );
      },
    );
    if (result != null) {
      setState(() {
        _selectedParents = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kind-Details'),
      ),
      body: _loadingParents
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: _vornameController,
                      decoration: const InputDecoration(labelText: 'Vorname'),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _nachnameController,
                      decoration: const InputDecoration(labelText: 'Nachname'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            children: _selectedParents
                                .map((parent) => Chip(
                                      label: Text('${parent.nachname}, ${parent.vorname}'),
                                      onDeleted: () => setState(() => _selectedParents.remove(parent)),
                                    ))
                                .toList(),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _showParentPicker,
                          child: const Text('Bearbeiten'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<GroupName>(
                      value: _selectedGroup,
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
                      onChanged: (value) => setState(() => _selectedGroup = value),
                    ),
                    const SizedBox(height: 32),
                    Row(
                      children: [
                        ElevatedButton(
                          onPressed: _save,
                          child: const Text('Speichern'),
                        ),
                        const SizedBox(width: 16),
                        ElevatedButton(
                          onPressed: _delete,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Löschen'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}