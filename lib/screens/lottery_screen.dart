import 'package:flutter/material.dart';
import '../utils/controller_lifecycle_mixin.dart';
import '../models/lottery.dart';
import 'lottery_detail_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:intl/intl.dart';
import '../models/child.dart';

/// Zeitoptionen für die Lotterie, einfach änderbar.
const List<String> kTimeOptions = [
  '11:00',
  '12:00',
  '13:00',
  '14:00',
  '15:00',
  'Ende',
];

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
        // Find all active unfinished lotteries
        final activeLotteries = lotteries.where((l) => !l.finished).toList();
        bool showAddButton = false;
        if (activeLotteries.isEmpty) {
          showAddButton = true;
        } else if (activeLotteries.length == 1 && activeLotteries.first.group != 'Beide') {
          showAddButton = true;
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Losverfahren')),
          body: docs.isEmpty
              ? const Center(child: Text('Keine Lotterien vorhanden.'))
              : ListView.builder(
                  itemCount: lotteries.length,
                  itemBuilder: (context, index) {
                    final lottery = lotteries[index];
                    final docId = docs[index].id;
                    final dateStr = _formatDate(lottery.date);
                    final groupStr = lottery.group == 'Beide'
                        ? 'Beide'
                        : GroupName.values.firstWhere((g) => g.name == lottery.group).displayName;
                    final textColor = lottery.finished
                        ? Colors.grey.shade600
                        : Theme.of(context).textTheme.bodyLarge?.color;
                    return ListTile(
                      title: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: dateStr,
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                            ),
                            TextSpan(
                              text: '  $groupStr',
                              style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                            ),
                          ],
                          style: DefaultTextStyle.of(context).style,
                        ),
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
          floatingActionButton: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (showAddButton)
                FloatingActionButton(
                  heroTag: 'addLottery',
                  onPressed: () async {
                    await _showNewLotteryDialog(
                      activeLottery: (activeLotteries.length == 1) ? activeLotteries.first : null,
                    );
                  },
                  tooltip: 'Neue Lotterie starten',
                  child: const Icon(Icons.add),
                ),
              const SizedBox(width: 16),
              FloatingActionButton(
                heroTag: 'clearLotteries',
                backgroundColor: Colors.red,
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      title: const Text('Alle Lotterien löschen?'),
                      content: const Text('Bist du sicher, dass du wirklich ALLE Lotterien löschen möchtest? Dies kann nicht rückgängig gemacht werden.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(false),
                          child: const Text('Abbrechen'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(true),
                          child: const Text('Löschen', style: TextStyle(color: Colors.red)),
                        ),
                      ],
                    ),
                  );
                  if (confirmed == true) {
                    try {
                      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('deleteAllLotterys');
                      final result = await callable.call();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Alle Lotterien gelöscht (${result.data['deleted'] ?? 0})')),
                      );
                    } catch (e) {
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Fehler beim Löschen: $e')),
                      );
                    }
                  }
                },
                tooltip: 'Alle Lotterien löschen',
                child: const Icon(Icons.clear_all),
              ),
            ],
          ),
        );
      },
    );
  }


  /// Öffnet einen Dialog zum Erstellen einer neuen Lotterie.
  Future<bool?> _showNewLotteryDialog({Lottery? activeLottery}) async {
    DateTime selectedDate = DateTime.now();
    final nrController = createController();
    final infoController = TextEditingController();
    String endFirstPartOfDay = kTimeOptions.first;
    String selectedGroup = 'Beide';
    bool groupLocked = false;
    // If there is an active lottery and its group is not 'Beide', preselect the other group and lock selection
    if (activeLottery != null && activeLottery.group != 'Beide') {
      if (activeLottery.group == 'ratz') {
        selectedGroup = 'ruebe';
      } else if (activeLottery.group == 'ruebe') {
        selectedGroup = 'ratz';
      }
      groupLocked = true;
    }
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
                  DropdownButtonFormField<String>(
                    initialValue: selectedGroup,
                    decoration: const InputDecoration(labelText: 'Gruppe'),
                    items: [
                      const DropdownMenuItem(value: 'Beide', child: Text('Beide')),
                      ...GroupName.values.map((g) => DropdownMenuItem(
                        value: g.name,
                        child: Text(g.displayName),
                      ))
                    ],
                    onChanged: groupLocked
                        ? null
                        : (value) {
                            if (value != null) setState(() => selectedGroup = value);
                          },
                  ),
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
                  DropdownButtonFormField<String>(
                    initialValue: endFirstPartOfDay,
                    decoration: const InputDecoration(labelText: 'Ende des ersten Tagesabschnitts'),
                    items: kTimeOptions
                        .map((time) => DropdownMenuItem(
                              value: time,
                              child: Text(time),
                            ))
                        .toList(),
                    onChanged: (value) {
                      if (value != null) setState(() => endFirstPartOfDay = value);
                    },
                  ),
                  TextField(
                    controller: nrController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Anzahl Kinder zu ziehen'),
                  ),
                  // Information field (always last)
                  Flexible(
                    child: TextField(
                      controller: infoController,
                      maxLength: 300,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Information',
                        hintText: 'Weitere Details zum Losverfahren',
                      ),
                    ),
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
                    // Validate endFirstPartOfDay
                    final validEndFirstPartOfDay = (endFirstPartOfDay.isNotEmpty && kTimeOptions.contains(endFirstPartOfDay))
                      ? endFirstPartOfDay
                      : kTimeOptions.first;
                    try {
                      final callable = FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('addLottery');
                      final result = await callable.call({
                        'date': DateFormat('yyyy-MM-dd').format(selectedDate),
                        'nrOfChildrenToPick': nr,
                        'endFirstPartOfDay': validEndFirstPartOfDay,
                        'group': selectedGroup,
                        'information': infoController.text.trim(),
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

