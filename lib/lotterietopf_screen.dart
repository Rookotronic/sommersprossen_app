import 'package:flutter/material.dart';
import 'mock_data.dart';
import 'child.dart';
import 'lottery.dart';
import 'lotterypot.dart';


class LotterietopfScreen extends StatefulWidget {
  const LotterietopfScreen({super.key});

  @override
  State<LotterietopfScreen> createState() => _LotterietopfScreenState();
}

class _LotterietopfScreenState extends State<LotterietopfScreen> {
  late final LotteryPot lotterypot;
  late final List<LotteryPotEntry> entries;
  List<Lottery> _lotteries = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    lotterypot = MockData().lotterypot;
    entries = lotterypot.kids;
    _loadLotteries();
  }

  Future<void> _loadLotteries() async {
    final list = await MockData().fetchLotteries();
    setState(() {
      _lotteries = List<Lottery>.from(list);
      _loading = false;
    });
  }

  bool get hasActiveLottery => _lotteries.any((l) => !l.finished);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lotterietopf')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Card(
                    color: Colors.blue.shade50,
                    margin: const EdgeInsets.only(bottom: 24),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Startdatum: ${_formatDate(lotterypot.startDate)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  Text('Einträge:', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, index) {
                        final entry = entries[index];
                        final child = MockData().findChildById(entry.childId);
                        final style = entry.priorityPick
                            ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
                            : Theme.of(context).textTheme.bodyLarge;
                        return ListTile(
                          leading: Text('#${entry.entryOrder}'),
                          title: child != null
                              ? Text('${child.nachname}, ${child.vorname}', style: style)
                              : Text('Unbekanntes Kind', style: style),
                          trailing: entry.priorityPick
                              ? const Icon(Icons.star, color: Colors.orange)
                              : null,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
      floatingActionButton: hasActiveLottery
          ? null
          : FloatingActionButton(
              onPressed: () async {
                final result = await showDialog<bool>(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Topf neu befüllen?'),
                    content: const Text('Möchtest du den Lotterietopf neu befüllen?'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('Abbrechen'),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Call cloud function to refill the pot
                          Navigator.of(context).pop(true);
                        },
                        child: const Text('Neu befüllen'),
                      ),
                    ],
                  ),
                );
                // Optionally handle result here
              },
              child: const Icon(Icons.refresh),
              tooltip: 'Topf neu befüllen',
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
