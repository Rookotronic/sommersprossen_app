import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'eltern_screen.dart';
import 'kinder_screen.dart';
import 'lottery_screen.dart';
import '../models/child.dart';
import 'mychild_detail_screen.dart';
import 'lotterietopf_screen.dart';
import '../widgets/menu_entry_tile.dart';
// ...existing code...
import '../widgets/logout_button.dart';

class ParentMainMenuScreen extends StatelessWidget {
  const ParentMainMenuScreen({super.key});

  Future<String?> _getParentDocId() async {
    final email = FirebaseAuth.instance.currentUser?.email;
    if (email == null) return null;
    final snap = await FirebaseFirestore.instance
        .collection('parents')
        .where('email', isEqualTo: email)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    return snap.docs.first.id;
  }

  @override
  Widget build(BuildContext context) {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    final userName = email.contains('@') ? email.split('@').first : email;
    return Scaffold(
      appBar: AppBar(
        title: Text('Hallo $userName!'),
        actions: const [LogoutButton()],
      ),
      body: FutureBuilder<String?>(
        future: _getParentDocId(),
        builder: (context, parentSnapshot) {
          if (parentSnapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!parentSnapshot.hasData || parentSnapshot.data == null) {
            return const Center(child: Text('Kein Eltern-Datensatz gefunden.'));
          }
          final parentId = parentSnapshot.data!;
          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('children')
                .where('parentIds', arrayContains: parentId)
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return Center(child: Text('Fehler beim Laden der Kinder:\n${snapshot.error}'));
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('Keine Kinder gefunden.'));
              }
              final kinder = docs.map((doc) => Child.fromFirestore(doc.id, doc.data() as Map<String, dynamic>)).toList();
              // Always show all children vertically in MeinKindDetailScreen
              return MeinKindDetailScreen(children: kinder);
            },
          );
        },
      ),
    );
  }
}

class AdminMainMenuScreen extends StatelessWidget {
  const AdminMainMenuScreen({super.key});

  String get userName {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    if (email.contains('@')) {
      return email.split('@').first;
    }
    return email;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Main Menu'),
        actions: const [LogoutButton()],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hallo $userName!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            MenuEntryTile(
              icon: Icons.shuffle,
              title: 'Losverfahren',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LotteryScreen(),
                  ),
                );
              },
            ),
            MenuEntryTile(
              icon: Icons.account_balance_wallet,
              title: 'Lotterietopf',
              onTap: () async {
                final confirmed = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Lotterietopf öffnen?'),
                    content: const Text('Bist du sicher, dass du den Lotterietopf öffnen möchtest?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Abbrechen'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text('Öffnen'),
                      ),
                    ],
                  ),
                );
                if (confirmed == true) {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const LotterietopfScreen(),
                    ),
                  );
                }
              },
            ),
            MenuEntryTile(
              icon: Icons.child_care,
              title: 'Kinder',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const KinderScreen(),
                  ),
                );
              },
            ),
            MenuEntryTile(
              icon: Icons.people,
              title: 'Eltern',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ElternScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
