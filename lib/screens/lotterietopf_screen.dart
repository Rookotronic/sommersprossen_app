import 'package:flutter/material.dart';
import '../services/mock_data.dart';
import '../models/lotterypot.dart';
import '../services/firestore_service.dart';


class LotterietopfScreen extends StatefulWidget {
  const LotterietopfScreen({super.key});

  @override
  State<LotterietopfScreen> createState() => _LotterietopfScreenState();
}

class _LotterietopfScreenState extends State<LotterietopfScreen> {
  final FirestoreService _firestoreService = FirestoreService();
  LotteryPot? lotterypot;
  List<LotteryPotEntry>? entries;
  bool _loading = true;
  bool hasActiveLottery = false;

  @override
  void initState() {
    super.initState();
    _loadPotData();
    _checkActiveLottery();

  }

  Future<void> _loadPotData() async {
    // TODO: Replace with Firestore fetch if needed
    // For now, use mock data fallback
    setState(() {
      lotterypot = MockData().lotterypot;
      entries = MockData().lotterypotEntries;
    });
  }

  Future<void> _checkActiveLottery() async {
    setState(() => _loading = true);
    try {
      final query = await _firestoreService.db
          .collection('lotteries')
          .where('finished', isEqualTo: false)
          .get();
      if (!mounted) return;
      setState(() {
        hasActiveLottery = query.docs.isNotEmpty;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        hasActiveLottery = false;
        _loading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Laden der Lotterien: ${e.toString()}')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lotterietopf')),
      body: _loading || lotterypot == null || entries == null
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
                        lotterypot != null
                            ? 'Startdatum: ${_formatDate(lotterypot!.startDate)}'
                            : 'Kein Topf geladen',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  Text('Einträge:', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Expanded(
                    child: entries != null
                        ? ListView.builder(
                            itemCount: entries!.length,
                            itemBuilder: (context, index) {
                              final entry = entries![index];
                              final child = MockData().findChildById(entry.childId);
                              final style = Theme.of(context).textTheme.bodyLarge;
                              return ListTile(
                                leading: Text('#${entry.entryOrder}'),
                                title: child != null
                                    ? Text('${child.nachname}, ${child.vorname}', style: style)
                                    : Text('Unbekanntes Kind', style: style),
                                // No trailing icon for priorityPick
                              );
                            },
                          )
                        : const Center(child: Text('Keine Einträge geladen')), 
                  ),
                ],
              ),
            ),
      floatingActionButton: hasActiveLottery
          ? null
          : FloatingActionButton(
              onPressed: () async {
                await showDialog<bool>(
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
                if (!mounted) return;
                // You can handle result here if needed
              },
              tooltip: 'Topf neu befüllen',
              child: const Icon(Icons.refresh),
            ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
