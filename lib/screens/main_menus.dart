import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:sommersprossen_app/widgets/notify_parents_button.dart';
import 'eltern_screen.dart';
import 'kinder_screen.dart';
import 'lottery_screen.dart';
import '../models/lottery.dart';
import 'lottery_detail_screen.dart';
import '../widgets/reporting_period_control.dart';
import '../widgets/confirmation_dialog.dart';
import '../models/child.dart';
import 'mychild_detail_screen.dart';
import 'lotterietopf_screen.dart';
import '../widgets/menu_entry_tile.dart';
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
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('lotteries')
                  .where('finished', isEqualTo: false)
                  .limit(1)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SizedBox();
                }
                if (snapshot.hasError) {
                  return const SizedBox();
                }
                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return const SizedBox();
                }
                final data = docs.first.data() as Map<String, dynamic>;
                final date = data['date'] ?? '';
                final timeOfDay = data['timeOfDay'] ?? '';
                final nrOfChildrenToPick = data['nrOfChildrenToPick'] ?? '';
                final requestsSend = data['requestsSend'] ?? false;
                final allAnswersReceived = data['allAnswersReceived'] ?? false;
                final finished = data['finished'] ?? false;
                final showSendButton = !requestsSend && !finished && !allAnswersReceived;
                final lotteryId = docs.first.id;
                final lottery = Lottery.fromFirestore(docs.first);
                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => LotteryDetailScreen(lotteryId: lotteryId, lottery: lottery),
                      ),
                    );
                  },
                  child: Column(
                    children: [
                      Card(
                        color: Colors.blue.shade50,
                        margin: const EdgeInsets.only(bottom: 24),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Aktive Lotterie', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(height: 8),
                              Text('Datum: $date'),
                              Text('Zeit: $timeOfDay'),
                              Text('Zu ziehende Kinder: $nrOfChildrenToPick'),
                              if (showSendButton)
                                Padding(
                                  padding: const EdgeInsets.only(top: 12.0),
                                  child: notifyparentsbutton(
                                    onSuccess: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Benachrichtigungen gesendet!')),
                                      );
                                    },
                                  ),
                                ),
                              const SizedBox(height: 12),
                              ReportingPeriodControl(
                                lottery: lottery,
                                onEndPeriod: () async {
                                  final confirmed = await showConfirmationDialog(
                                    context,
                                    title: 'Meldezeitraum beenden?',
                                    content: 'Bist du sicher, dass du den Meldezeitraum beenden möchtest?',
                                    confirmText: 'Beenden',
                                  );
                                  if (confirmed == true) {
                                    await FirebaseFirestore.instance
                                        .collection('lotteries')
                                        .doc(lotteryId)
                                        .update({'allAnswersReceived': true});
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Meldezeitraum wurde beendet.')),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
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
          ],
        ),
      ),
    );
  }
}
