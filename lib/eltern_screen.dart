import 'package:flutter/material.dart';
// ...existing code...
import 'utils/controller_lifecycle_mixin.dart';
import 'utils/validators.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/parent.dart';
import 'services/firestore_service.dart';

class ElternScreen extends StatefulWidget {
  const ElternScreen({super.key});

  @override
  State<ElternScreen> createState() => ElternScreenState();
}

class ElternScreenState extends State<ElternScreen> with ControllerLifecycleMixin {
  final FirestoreService _firestoreService = FirestoreService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Eltern')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('parents').orderBy('nachname').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Fehler beim Laden der Eltern:\n${snapshot.error}'));
          }
          final docs = snapshot.data?.docs ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('Keine Eltern gefunden.'));
          }
          final eltern = docs.map((doc) => Parent.fromFirestore(doc.id, doc.data() as Map<String, dynamic>)).toList();
          return ListView.builder(
            itemCount: eltern.length,
            itemBuilder: (context, index) {
              final parent = eltern[index];
              final isEven = index % 2 == 0;
              return Container(
                color: isEven ? Colors.white : Colors.blue[50],
                child: ListTile(
                  title: Text('${parent.nachname}, ${parent.vorname}'),
                  onTap: () => _showElternDetails(parent),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addEltern,
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showElternDetails(Parent parent) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ElternDetailScreen(parent: parent),
      ),
    );
    if (!mounted) return;
    // Firestore updates handled in detail screen
  }


  void _addEltern() async {
  final vornameController = createController();
  final nachnameController = createController();
  final emailController = createController();
    String? errorText;

  bool isAlpha(String value) => RegExp(r"^[\p{L}'\- ]+$", unicode: true).hasMatch(value);
    bool isValidEmail(String value) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+\u0000?').hasMatch(value);

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Neue Eltern hinzufügen'),
              content: Column(
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
                  TextField(
                    controller: emailController,
                    decoration: const InputDecoration(labelText: 'Emailadresse'),
                    keyboardType: TextInputType.emailAddress,
                  ),
                  if (errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(errorText!, style: const TextStyle(color: Colors.red)),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: const Text('Abbrechen'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final vorname = vornameController.text.trim();
                    final nachname = nachnameController.text.trim();
                    final email = emailController.text.trim();
                    if (vorname.isEmpty || nachname.isEmpty || email.isEmpty) {
                      if (!mounted) return;
                      setState(() => errorText = 'Alle Felder sind erforderlich.');
                      return;
                    }
                    if (!isAlpha(vorname)) {
                      if (!mounted) return;
                      setState(() => errorText = 'Vorname: Nur Buchstaben und Sonderzeichen erlaubt.');
                      return;
                    }
                    if (!isAlpha(nachname)) {
                      if (!mounted) return;
                      setState(() => errorText = 'Nachname: Nur Buchstaben und Sonderzeichen erlaubt.');
                      return;
                    }
                    if (!isValidEmail(email)) {
                      if (!mounted) return;
                      setState(() => errorText = 'Bitte gültige Emailadresse eingeben.');
                      return;
                    }
                    if (!mounted) return;
                    setState(() => errorText = null);
                    try {
                      final result = await _firestoreService.add('parents', {
                        'vorname': vorname,
                        'nachname': nachname,
                        'email': email,
                      });
                      
                      if (result != null) {
                        if (!mounted) return;
                        if(context.mounted) {Navigator.of(context).pop(true);}
                        else {return;}
                      } else {
                        if (!mounted) return;
                        setState(() => errorText = 'Fehler beim Speichern.');
                      }
                    } catch (e) {
                      if (!mounted) return;
                      setState(() => errorText = 'Fehler beim Speichern: ${e.toString()}');
                    }
                  },
                  child: const Text('Hinzufügen'),
                ),
              ],
            );
          },
        );
      },
    );
    if (!mounted) return;
    if (result == true) {
      final email = emailController.text.trim();
      // Show info dialog after add-parent dialog is closed
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Neues Passwort gesendet'),
          content: Text('Ein neues Passwort wurde an $email gesendet.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }

}

class ElternDetailScreen extends StatefulWidget {
  final Parent parent;
  const ElternDetailScreen({super.key, required this.parent});

  @override
  State<ElternDetailScreen> createState() => _ElternDetailScreenState();
}

class _ElternDetailScreenState extends State<ElternDetailScreen> with ControllerLifecycleMixin {
  final FirestoreService _firestoreService = FirestoreService();
  // ...existing code...
  late TextEditingController _vornameController;
  late TextEditingController _nachnameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
  _vornameController = createController(text: widget.parent.vorname);
  _nachnameController = createController(text: widget.parent.nachname);
  _emailController = createController(text: widget.parent.email);
  }

  @override
  void dispose() {
  // Lifecycle handled by ControllerLifecycleMixin
  super.dispose();
  }


  Future<void> _save() async {
    final vorname = _vornameController.text.trim();
    final nachname = _nachnameController.text.trim();
    final email = _emailController.text.trim();
    if (vorname.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vorname ist erforderlich.')));
      return;
    }
    if (!isAlpha(vorname)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vorname: Nur Buchstaben und Sonderzeichen erlaubt.')));
      return;
    }
    if (nachname.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nachname ist erforderlich.')));
      return;
    }
    if (!isAlpha(nachname)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nachname: Nur Buchstaben und Sonderzeichen erlaubt.')));
      return;
    }
    if (email.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Emailadresse ist erforderlich.')));
      return;
    }
    if (!isValidEmail(email)) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Bitte gültige Emailadresse eingeben.')));
      return;
    }
    final updated = Parent(
      id: widget.parent.id,
      vorname: vorname,
      nachname: nachname,
      email: email,
    );
    // Update parent in Firestore
    try {
      final success = await _firestoreService.update('parents', updated.id, updated.toFirestore());
      if (!mounted) return;
      if (success) {
        Navigator.of(context).pop(updated);
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fehler beim Speichern.')));
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler beim Speichern: ${e.toString()}')));
    }
  }

  void _delete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eltern löschen'),
        content: const Text('Sind Sie sicher, dass Sie diesen Elternteil löschen möchten?'),
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
      // Delete parent from Firestore
      try {
        final success = await _firestoreService.delete('parents', widget.parent.id);
        if (!mounted) return;
        if (success) {
          Navigator.of(context).pop({'delete': true, 'id': widget.parent.id});
        } else {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Fehler beim Löschen.')));
        }
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Fehler beim Löschen: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Eltern: ${widget.parent.vorname} ${widget.parent.nachname}')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
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
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(labelText: 'Emailadresse'),
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
            // ...removed Passwort senden button...
          ],
        ),
      ),
    );
  }
}
