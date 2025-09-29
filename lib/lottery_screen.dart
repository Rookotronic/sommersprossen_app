import 'package:flutter/material.dart';
import 'lottery.dart';
import 'mock_data.dart';
import 'package:intl/intl.dart';

class LotteryScreen extends StatefulWidget {
  const LotteryScreen({super.key});

  @override
  State<LotteryScreen> createState() => _LotteryScreenState();
}

class _LotteryScreenState extends State<LotteryScreen> {
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    setState(() {}); // Triggers rebuild every time the screen is shown
  }

  List<Lottery> _lotteries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadLotteries();
  }

  Future<void> _loadLotteries() async {
    setState(() => _loading = true);
    final list = await MockData().fetchLotteries();
    setState(() {
      _lotteries = List<Lottery>.from(list)..sort((a, b) => b.date.compareTo(a.date));
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasUnfinished = _lotteries.any((l) => !l.finished);
    return Scaffold(
      appBar: AppBar(title: const Text('Lotterien')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              itemCount: _lotteries.length,
              itemBuilder: (context, index) {
                final lottery = _lotteries[index];
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
                    'Zu ziehende Kinder: ${lottery.nrOfchildrenToPick}',
                    style: TextStyle(color: textColor),
                  ),
                );
              },
            ),
      floatingActionButton: hasUnfinished
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final created = await _showNewLotteryDialog();
                await _loadLotteries(); // Always reload after dialog closes
              },
              child: const Icon(Icons.add),
              tooltip: 'Neue Lotterie starten',
            ),
    );
  }

  Future<bool?> _showNewLotteryDialog() async {
    DateTime selectedDate = DateTime.now();
    final nrController = TextEditingController();
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
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
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
                  onPressed: () {
                    final nr = int.tryParse(nrController.text);
                    if (nr == null || nr < 1) {
                      setState(() => errorText = 'Bitte Datum und gültige Anzahl eingeben.');
                      return;
                    }
                    // Add new lottery to MockData
                    MockData().addLottery(
                      Lottery(
                        date: selectedDate,
                        finished: false,
                        requestsSend: false,
                        allAnswersReceived: false,
                        lotterypotId: MockData().lotteries.length + 1,
                        nrOfchildrenToPick: nr,
                      ),
                    );
                    Navigator.of(context, rootNavigator: true).pop(false);
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

  String _formatDate(DateTime date) {
    try {
      return DateFormat('dd.MM.yyyy').format(date);
    } catch (_) {
      return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
    }
  }
}

