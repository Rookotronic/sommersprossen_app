import 'package:flutter/material.dart';
import '../utils/controller_lifecycle_mixin.dart';
import '../utils/validators.dart';
import '../models/child.dart';
import '../widgets/group_dropdown.dart';
import '../models/parent.dart';
import '../widgets/parent_list_display.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/firestore_service.dart';


/// Detailbildschirm zur Anzeige und Bearbeitung eines Kindes.
///
/// Zeigt die Details eines Kindes, ermöglicht das Bearbeiten von Namen, Eltern und Gruppe,
/// sowie das Löschen des Kindes aus Firestore.
class KinderDetailScreen extends StatefulWidget {
  final Child child;
  const KinderDetailScreen({super.key, required this.child});

  @override
  /// Erstellt den State für den KinderDetailScreen.
  @override
  State<KinderDetailScreen> createState() => _KinderDetailScreenState();
}

/// State-Klasse für KinderDetailScreen.
///
/// Beinhaltet die Logik zum Bearbeiten und Löschen eines Kindes sowie das Auswählen der Eltern.
class _KinderDetailScreenState extends State<KinderDetailScreen> with ControllerLifecycleMixin {
  final FirestoreService _firestoreService = FirestoreService();
  late TextEditingController _vornameController;
  late TextEditingController _nachnameController;
  GroupName? _selectedGroup;
  List<Parent> _parentList = [];
  List<Parent> _selectedParents = [];
  bool _loadingParents = true;

  @override
  /// Initialisiert die Controller und lädt die Elternliste.
  @override
  void initState() {
    super.initState();
  _vornameController = createController(text: widget.child.vorname);
  _nachnameController = createController(text: widget.child.nachname);
    _selectedGroup = widget.child.gruppe;
    _loadParents();
  }

  /// Lädt die Eltern aus Firestore und setzt die Auswahl entsprechend dem Kind.
  Future<void> _loadParents() async {
  // Fetch parents from Firestore, order by last name
  final snapshot = await FirebaseFirestore.instance
    .collection('parents')
    .orderBy('nachname')
    .get();
  final parentList = snapshot.docs
    .map((doc) => Parent.fromFirestore(doc.id, doc.data()))
    .toList();
    setState(() {
      _parentList = parentList;
      // Always match selected parents to the child's parentIds (handle null)
  final childParentIds = widget.child.parentIds ?? [];
  _selectedParents = parentList.where((p) => childParentIds.contains(p.id)).toList();
      _loadingParents = false;
    });
  }

  @override
  void dispose() {
  // Lifecycle handled by ControllerLifecycleMixin
  super.dispose();
  }

  /// Speichert die Änderungen am Kind in Firestore.
  ///
  /// Validiert die Eingaben und zeigt Fehler-Snackbars bei ungültigen Daten.
  void _save() async {
    final vorname = _vornameController.text.trim();
    final nachname = _nachnameController.text.trim();
    if (vorname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vorname ist erforderlich.')));
      return;
    }
    if (!isAlpha(vorname)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vorname: Nur Buchstaben und Sonderzeichen erlaubt.')));
      return;
    }
    if (nachname.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nachname ist erforderlich.')));
      return;
    }
    if (!isAlpha(nachname)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nachname: Nur Buchstaben und Sonderzeichen erlaubt.')));
      return;
    }
    final updated = Child(
      id: widget.child.id,
      vorname: vorname,
      nachname: nachname,
      parentIds: _selectedParents.isEmpty ? null : _selectedParents.map((p) => p.id).toList(),
      gruppe: _selectedGroup ?? GroupName.ratz,
    );
    // Update child in Firestore
    final success = await _firestoreService.set('children', updated.id.toString(), updated.toFirestore());
    if (!mounted) return;
    if (success) {
      Navigator.of(context).pop(updated);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fehler beim Speichern.')));
    }
  }

  /// Löscht das Kind nach Bestätigung aus Firestore.
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
      // Delete child from Firestore
      final success = await _firestoreService.delete('children', widget.child.id.toString());
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop({'delete': true, 'id': widget.child.id});
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fehler beim Löschen.')));
      }
    }
  }

  /// Öffnet einen Dialog zur Auswahl der Eltern für das Kind.
  void _showParentPicker() async {
    // Fetch parents from Firestore, order by last name
    final snapshot = await FirebaseFirestore.instance
        .collection('parents')
        .orderBy('nachname')
        .get();
    final all = snapshot.docs
        .map((doc) => Parent.fromFirestore(doc.id, doc.data()))
        .toList();
    final childParentIds = _selectedParents.isNotEmpty
        ? _selectedParents.map((p) => p.id).toList()
  : widget.child.parentIds;
    final List<Parent> tempSelected = all.where((p) => childParentIds.contains(p.id)).toList();
    setState(() {
      _parentList = all;
    });
    if (!mounted) return;
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
      if (!mounted) return;
      setState(() {
        _selectedParents = result;
      });
    }
  }

  @override
  /// Baut das UI für die Detailansicht und Bearbeitung eines Kindes.
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
                    InputDecorator(
                      decoration: const InputDecoration(labelText: 'Eltern'),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: ParentListDisplay(parents: _selectedParents, emptyText: 'Keine'),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: _showParentPicker,
                            child: const Text('Bearbeiten'),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    GroupDropdown(
                      value: _selectedGroup,
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