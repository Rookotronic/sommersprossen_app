import 'package:flutter/material.dart';
import '../utils/controller_lifecycle_mixin.dart';
import '../models/lottery.dart';
import 'lottery_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';

/// Bildschirm zur Anzeige und Verwaltung aller Lotterien.
///
/// Zeigt eine Liste aller Lotterien, ermöglicht das Starten einer neuen Lotterie und die Anzeige von Details.
class LotteryScreen extends StatefulWidget {
  /// Erstellt eine Instanz des Lotterie-Bildschirms.
  const LotteryScreen({super.key});

  @override
  State<LotteryScreen> createState() => _LotteryScreenState();
}

/// State-Klasse für LotteryScreen.
///
/// Beinhaltet die Logik zum Laden, Anzeigen und Erstellen von Lotterien.
class _LotteryScreenState extends State<LotteryScreen> with ControllerLifecycleMixin {
  
  @override
  /// Wird bei Abhängigkeitsänderungen aufgerufen und triggert einen Rebuild.
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  setState(() {});
  }

  @override
  /// Baut das UI für die Anzeige und Verwaltung der Lotterien.
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('lotteries').orderBy('date', descending: true).snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Losverfahren')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Losverfahren')),
            body: Center(child: Text('Fehler beim Laden der Lotterien: ${snapshot.error}')),
          );
        }
  final docs = snapshot.data?.docs ?? [];
  final lotteries = docs.map((doc) => Lottery.fromFirestore(doc)).toList();
        final hasUnfinished = lotteries.any((l) => !l.finished);
        return Scaffold(
          appBar: AppBar(title: const Text('Losverfahren')),
          body: ListView.builder(
            itemCount: lotteries.length,
            itemBuilder: (context, index) {
              final lottery = lotteries[index];
              final docId = docs[index].id;
              final dateStr = _formatDate(lottery.date);
              final textColor = lottery.finished
                  ? Colors.grey.shade600
                  : Theme.of(context).textTheme.bodyLarge?.color;
              return ListTile(
                title: Text(
                  dateStr,
                  style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  'Zu ziehende Kinder: ${lottery.nrOfChildrenToPick}',
                  style: TextStyle(color: textColor),
                ),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => LotteryDetailScreen(lottery: lottery, lotteryId: docId),
                    ),
                  );
                },
              );
            },
          ),
          floatingActionButton: hasUnfinished
              ? null
              : FloatingActionButton(
                  onPressed: () async {
                    await _showNewLotteryDialog();
                  },
                  tooltip: 'Neue Lotterie starten',
                  child: const Icon(Icons.add),
                ),
        );
      },
    );
  }


  /// Öffnet einen Dialog zum Erstellen einer neuen Lotterie.
  Future<bool?> _showNewLotteryDialog() async {
  DateTime selectedDate = DateTime.now();
  final nrController = createController();
  final timeOfDayController = createController();
  String? errorText;
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Neue Lotterie starten'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    title: Text(_formatDate(selectedDate)),
                    trailing: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                        selectableDayPredicate: (date) {
                          return date.weekday != DateTime.saturday && date.weekday != DateTime.sunday;
                        },
                      );
                      if (!mounted) return;
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                  ),
                  TextField(
                    controller: timeOfDayController,
                    decoration: const InputDecoration(labelText: 'Zeitangabe (z.B. Ganztägig, ab 13 Uhr)'),
                    maxLength: 15,
                  ),
                  TextField(
                    controller: nrController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Anzahl Kinder zu ziehen'),
                  ),
                  if (errorText != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(errorText ?? '', style: const TextStyle(color: Colors.red)),
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
                    final nr = int.tryParse(nrController.text.trim());
                    final now = DateTime.now();
                    final selectedDay = DateTime(selectedDate.year, selectedDate.month, selectedDate.day);
                    final today = DateTime(now.year, now.month, now.day);
                    if (nr == null || nr < 1) {
                      setState(() => errorText = 'Bitte eine gültige Anzahl Kinder eingeben.');
                      return;
                    }
                    if (selectedDay.isBefore(today)) {
                      setState(() => errorText = 'Bitte ein gültiges Datum wählen (nicht in der Vergangenheit).');
                      return;
                    }
                    try {
                      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('addLottery');
                      final result = await callable.call({
                        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                        'nrOfChildrenToPick': nr,
                        'timeOfDay': timeOfDayController.text.trim(),
                      });
                      if (result.data['success'] == true) {
                        if (context.mounted) {
                          Navigator.of(context, rootNavigator: true).pop(false);
                        } else {
                          return;
                        }
                      } else {
                        setState(() => errorText = result.data['message'] ?? 'Fehler beim Speichern.');
                      }
                    } catch (e) {
                      if (!mounted) return;
                      setState(() => errorText = 'Fehler beim Speichern: ${e.toString()}');
                    }
                  },
                  child: const Text('Erstellen'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Formatiert ein Datum als String im Format dd.MM.yyyy.
  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (_) {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }
}

