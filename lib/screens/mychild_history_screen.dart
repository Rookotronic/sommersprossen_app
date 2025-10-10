import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Zeigt die Lotterie-Historie für ein bestimmtes Kind an.
///
/// Listet alle vergangenen Lotterien und deren Ergebnis für das Kind auf.
class MyChildHistoryScreen extends StatelessWidget {
  /// Die ID des Kindes, dessen Historie angezeigt wird.
  final String childId;
  /// Der Name des Kindes (für die AppBar).
  final String childName;

  /// Erstellt die Historienansicht für das übergebene Kind.
  const MyChildHistoryScreen({super.key, required this.childId, required this.childName});

  /// Baut die UI für die Historienansicht des Kindes.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(childName),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
          .collection('lotteries')
          .orderBy('createdAt', descending: true)
          .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          // Holt und filtert die Lotterie-Historie für das Kind
          final docs = snapshot.data!.docs;
          final history = <Map<String, dynamic>>[];
          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final childrenList = (data['children'] as List<dynamic>? ?? []);
            final entry = childrenList.firstWhere(
              (c) => c['childId'] == childId,
              orElse: () => null,
            );
            if (entry != null) {
              history.add({
                'date': data['date'],
                'picked': entry['picked'] ?? false,
                'need': entry['need'] ?? false,
                'lotteryId': doc.id,
              });
            }
          }
          if (history.isEmpty) {
            return const Center(child: Text('Keine Historie gefunden.'));
          }
          // Baut die Liste der Historieneinträge
          return ListView.builder(
            itemCount: history.length,
            itemBuilder: (context, index) {
              final item = history[index];
              DateTime? date;
              if (item['date'] is Timestamp) {
                date = (item['date'] as Timestamp).toDate();
              } else if (item['date'] is String) {
                try {
                  date = DateTime.parse(item['date'] as String);
                } catch (_) {
                  date = null;
                }
              }
              final dateText = date != null
                  ? '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}'
                  : 'Unbekanntes Datum';
              final picked = item['picked'] == true;
              final need = item['need'] == true;
              Color cardColor;
              if (!picked) {
                cardColor = Colors.green.shade300;
              } else if (picked && need) {
                cardColor = Colors.red.shade300;
              } else {
                cardColor = Colors.orange.shade300;
              }
              // Baut die Kartenansicht für jeden Historieneintrag
              return Card(
                margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                color: cardColor,
                child: ListTile(
                  title: Text(dateText),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(picked ? 'Zuhause geblieben' : 'Wurde betreut'),
                      Text(need ? 'Bedarf gemeldet' : 'Kein Bedarf gemeldet'),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
