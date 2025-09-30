import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'eltern_screen.dart';
import 'kinder_screen.dart';
import 'lottery_screen.dart';
import 'child.dart';
import 'meinKind_detail_screen.dart';
import 'lotterietopf_screen.dart';

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
      appBar: AppBar(title: Text('Hallo $userName!')),
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
              // If only one child, go directly to detail screen
              if (kinder.length == 1) {
                // Use addPostFrameCallback to avoid calling Navigator during build
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (context) => MeinKindDetailScreen(child: kinder.first),
                    ),
                  );
                });
                return const Center(child: CircularProgressIndicator());
              }
              // Use the extension for display name
              return ListView.builder(
                itemCount: kinder.length,
                itemBuilder: (context, index) {
                  final child = kinder[index];
                  return ListTile(
                    leading: const Icon(Icons.child_care),
                    title: Text('${child.nachname}, ${child.vorname}'),
                    subtitle: Text('Gruppe: ${child.gruppe.displayName}'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => MeinKindDetailScreen(child: child),
                        ),
                      );
                    },
                  );
                },
              );
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
      appBar: AppBar(title: const Text('Admin Main Menu')),
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
            ListTile(
              leading: const Icon(Icons.shuffle),
              title: const Text('Losverfahren'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LotteryScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.account_balance_wallet),
              title: const Text('Lotterietopf'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const LotterietopfScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.child_care),
              title: const Text('Kinder'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const KinderScreen(),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Eltern'),
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
