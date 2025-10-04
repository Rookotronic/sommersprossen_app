import 'package:flutter/material.dart';
import '../models/lotterypot.dart';
import '../services/firestore_service.dart';
import '../models/child.dart';
import '../services/child_service.dart';
import 'package:cloud_functions/cloud_functions.dart';


class LotterietopfScreen extends StatefulWidget {
  const LotterietopfScreen({super.key});

  @override
  State<LotterietopfScreen> createState() => _LotterietopfScreenState();
}

class _LotterietopfScreenState extends State<LotterietopfScreen> {
  // Use shared ChildService for fetching children by IDs
  final FirestoreService _firestoreService = FirestoreService();
  LotteryPot? lotterypot;
  bool _loading = true;
  bool hasActiveLottery = false;

  @override
  void initState() {
    super.initState();
    _loadPotData();
    _checkActiveLottery();

  }

  Future<void> _loadPotData() async {
    setState(() => _loading = true);
    try {
      final potDoc = await _firestoreService.db.collection('lotterypot').doc('current').get();
      if (potDoc.exists) {
        final data = potDoc.data() as Map<String, dynamic>;
        lotterypot = LotteryPot.fromFirestore(potDoc.id, data);
      } else {
        lotterypot = null;
      }
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fehler beim Laden des Lotterietopfs: ${e.toString()}')),
        );
    }
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
      body: _loading || lotterypot == null || lotterypot!.kids.isEmpty
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
                        'Startdatum: ${_formatDate(lotterypot!.startDate)}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                  ),
                  Text('Einträge:', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 12),
                  Expanded(
                    child: FutureBuilder<List<Child>>(
                      future: ChildService.fetchChildrenByIds(lotterypot!.kids),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return const Center(child: CircularProgressIndicator());
                        }
                        if (snapshot.hasError) {
                          return Center(child: Text('Fehler beim Laden der Kinder: ${snapshot.error}'));
                        }
                        final children = snapshot.data ?? [];
                        return ListView.builder(
                          itemCount: lotterypot!.kids.length,
                          itemBuilder: (context, index) {
                            final childId = lotterypot!.kids[index];
                            final child = children.firstWhere(
                              (c) => c.id == childId,
                              orElse: () => Child(id: '', vorname: '', nachname: '', gruppe: GroupName.ratz),
                            );
                            final style = Theme.of(context).textTheme.bodyLarge;
                            return ListTile(
                              leading: Text('#${index + 1}'),
                              title: child.id.isNotEmpty
                                  ? Text('${child.nachname}, ${child.vorname}', style: style)
                                  : Text('Unbekanntes Kind', style: style),
                            );
                          },
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
                        onPressed: () async {
                          try {
                            final callable = FirebaseFunctions.instanceFor(region: 'europe-west1').httpsCallable('createLotteryPot');
                            await callable.call();
                            Navigator.of(context).pop(true);
                          } catch (e, stack) {
                            Navigator.of(context).pop(false);
                            if (!mounted) return;
                            print('Cloud function error: $e');
                            print('Stack trace: $stack');
                            String errorMsg;
                            if (e is FirebaseFunctionsException) {
                              errorMsg = 'Fehler beim Befüllen des Lotterietopfs:\n'
                                'Code: 	${e.code}\n'
                                'Message: ${e.message}\n'
                                'Details: ${e.details ?? ''}';
                            } else {
                              errorMsg = 'Fehler beim Befüllen des Lotterietopfs: ${e.toString()}';
                            }
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(errorMsg, maxLines: 30, overflow: TextOverflow.visible),
                                duration: const Duration(seconds: 15),
                              ),
                            );
                            await showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                title: const Text('Fehler beim Cloud Function Call'),
                                content: SizedBox(
                                  width: double.maxFinite,
                                  child: SingleChildScrollView(
                                    child: SelectableText(errorMsg),
                                  ),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.of(context).pop(),
                                    child: const Text('OK'),
                                  ),
                                ],
                              ),
                            );
                          }
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
