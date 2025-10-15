import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'eltern_screen.dart';
import 'kinder_screen.dart';
import 'lottery_screen.dart';
import '../models/lottery.dart';
import '../widgets/active_lottery_tile.dart';
import '../widgets/confirmation_dialog.dart';
import '../models/child.dart';
import 'mychild_detail_screen.dart';
import 'lotterietopf_screen.dart';
import '../widgets/menu_entry_tile.dart';
import '../widgets/logout_button.dart';

/// Hauptmenü für Eltern.
///
/// Zeigt die Kinder des eingeloggten Elternteils und ermöglicht die Navigation zu deren Detailansicht.
class ParentMainMenuScreen extends StatelessWidget {
  /// Erstellt eine Instanz des Eltern-Hauptmenüs.
  const ParentMainMenuScreen({super.key});

  /// Holt die Dokumenten-ID des eingeloggten Elternteils aus Firestore.
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

  /// Baut das UI für das Eltern-Hauptmenü.
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

/// Hauptmenü für Administratoren.
///
/// Zeigt die wichtigsten Verwaltungsfunktionen und die aktive Lotterie für Admins.
class AdminMainMenuScreen extends StatelessWidget {
  /// Returns the list of menu entry tiles for the admin main menu.
  List<Widget> _buildMenuEntryTiles(BuildContext context) {
    return [
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
          final confirmed = await showConfirmationDialog(
            context,
            title: 'Lotterietopf öffnen?',
            content: 'Bist du sicher, dass du den Lotterietopf öffnen möchtest?',
            confirmText: 'Öffnen',
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
    ];
  }
  /// Erstellt eine Instanz des Admin-Hauptmenüs.
  const AdminMainMenuScreen({super.key});

  /// Holt den Benutzernamen aus der aktuellen Email-Adresse.
  String get userName {
    final email = FirebaseAuth.instance.currentUser?.email ?? '';
    if (email.contains('@')) {
      return email.split('@').first;
    }
    return email;
  }

  /// Baut das UI für das Admin-Hauptmenü.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Hallo $userName!'),
        actions: const [LogoutButton()],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reduce gap between greeting and first menu point
              const SizedBox(height: 4),
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('lotteries')
                    .where('finished', isEqualTo: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Card(
                      color: Colors.blue.shade50,
                      margin: const EdgeInsets.only(bottom: 24),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Text('Lade aktive Lotterien...', style: Theme.of(context).textTheme.bodyLarge),
                      ),
                    );
                  }
                  if (snapshot.hasError) {
                    return const SizedBox();
                  }
                  final docs = snapshot.data?.docs ?? [];
                  if (docs.isEmpty) {
                    return const SizedBox.shrink();
                  }
                  return Column(
                    children: docs.map((doc) {
                      final lotteryId = doc.id;
                      final lottery = Lottery.fromFirestore(doc);
                      return ActiveLotteryTile(lottery: lottery, lotteryId: lotteryId);
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 16),
              ..._buildMenuEntryTiles(context),
            ],
          ),
        ),
      ),
    );
  }
}
