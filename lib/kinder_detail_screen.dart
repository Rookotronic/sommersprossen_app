import 'package:flutter/material.dart';
import 'child.dart';
import 'parent.dart';
import 'mock_data.dart';


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
    final all = await MockData().fetchParents();
    setState(() {
      _parentList = all;
      // Always match selected parents to the child's parentIds (handle null)
      final childParentIds = widget.child.parentIds ?? [];
      _selectedParents = all.where((p) => childParentIds.contains(p.id)).toList();
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
      parentIds: _selectedParents.isEmpty ? null : _selectedParents.map((p) => p.id).toList(),
      gruppe: _selectedGroup ?? GroupName.ratz,
    );
    MockData().updateChild(updated);
    Navigator.of(context).pop();
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
      MockData().deleteChild(widget.child.id);
      Navigator.of(context).pop();
    }
  }

  void _showParentPicker() async {
    final all = await MockData().fetchParents();
  final childParentIds = _selectedParents.isNotEmpty
    ? _selectedParents.map((p) => p.id).toList()
    : (widget.child.parentIds ?? []);
  final List<Parent> tempSelected = all.where((p) => childParentIds.contains(p.id)).toList();
    setState(() {
      _parentList = all;
    });
    final result = await showDialog<List<Parent>>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Eltern auswählen'),
          content: StatefulBuilder(
            builder: (context, setStateDialog) {
              return SizedBox(
                width: 300,
                child: ListView(
                  shrinkWrap: true,
                  children: _parentList.map((parent) {
                    final isChecked = tempSelected.contains(parent);
                    return CheckboxListTile(
                      value: isChecked,
                      title: Text('${parent.nachname}, ${parent.vorname}'),
                      onChanged: (checked) {
                        setStateDialog(() {
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
              );
            },
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
                    // Eltern field styled like Vorname/Nachname/Gruppe
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            readOnly: true,
                            decoration: const InputDecoration(labelText: 'Eltern'),
                            controller: TextEditingController(
                              text: _selectedParents.isEmpty
                                  ? 'Keine'
                                  : _selectedParents.map((p) => '${p.nachname}, ${p.vorname}').join(', '),
                            ),
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