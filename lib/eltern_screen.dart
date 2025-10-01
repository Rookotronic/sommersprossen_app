import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'parent.dart';

class ElternScreen extends StatefulWidget {
  const ElternScreen({super.key});

  @override
  State<ElternScreen> createState() => ElternScreenState();
}

class ElternScreenState extends State<ElternScreen> {

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
    // Firestore updates handled in detail screen
  }


  void _addEltern() async {
    final vornameController = TextEditingController();
    final nachnameController = TextEditingController();
    final emailController = TextEditingController();
    String? errorText;

    bool isAlpha(String value) => RegExp(r"^[a-zA-ZäöüÄÖÜß'\- ]+").hasMatch(value);
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
                      setState(() => errorText = 'Alle Felder sind erforderlich.');
                      return;
                    }
                    if (!isAlpha(vorname)) {
                      setState(() => errorText = 'Vorname: Nur Buchstaben erlaubt.');
                      return;
                    }
                    if (!isAlpha(nachname)) {
                      setState(() => errorText = 'Nachname: Nur Buchstaben erlaubt.');
                      return;
                    }
                    if (!isValidEmail(email)) {
                      setState(() => errorText = 'Bitte gültige Emailadresse eingeben.');
                      return;
                    }
                    setState(() => errorText = null);
                    await FirebaseFirestore.instance.collection('parents').add({
                      'vorname': vorname,
                      'nachname': nachname,
                      'email': email,
                    });
                    Navigator.of(context).pop(true);
                  },
                  child: const Text('Hinzufügen'),
                ),
              ],
            );
          },
        );
      },
    );
    if (result == true) {
      final email = emailController.text.trim();
      // Show info dialog after add-parent dialog is closed
      // ignore: use_build_context_synchronously
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

class _ElternDetailScreenState extends State<ElternDetailScreen> {
  late TextEditingController _vornameController;
  late TextEditingController _nachnameController;
  late TextEditingController _emailController;

  @override
  void initState() {
    super.initState();
    _vornameController = TextEditingController(text: widget.parent.vorname);
    _nachnameController = TextEditingController(text: widget.parent.nachname);
    _emailController = TextEditingController(text: widget.parent.email);
  }

  @override
  void dispose() {
    _vornameController.dispose();
    _nachnameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  void _sendNewPassword(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Neues Passwort gesendet'),
        content: Text('Ein neues Passwort wurde an ${_emailController.text} gesendet.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final updated = Parent(
      id: widget.parent.id,
      vorname: _vornameController.text.trim(),
      nachname: _nachnameController.text.trim(),
      email: _emailController.text.trim(),
    );
    // Update parent in Firestore
    await FirebaseFirestore.instance.collection('parents').doc(updated.id).update(updated.toFirestore());
    Navigator.of(context).pop(updated);
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
      await FirebaseFirestore.instance.collection('parents').doc(widget.parent.id).delete();
      Navigator.of(context).pop({'delete': true, 'id': widget.parent.id});
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
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => _sendNewPassword(context),
                    child: const Text('Passwort senden'),
                  ),
                ),
                const SizedBox(width: 16),
                // Empty space to match the width of the two buttons above
                const Expanded(child: SizedBox()),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
