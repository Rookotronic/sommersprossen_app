import 'package:flutter/material.dart';
import '../models/lottery.dart';
import '../models/child.dart';
import '../services/child_service.dart';

class LotteryDetailScreen extends StatelessWidget {
  Widget _buildBoolCircle(bool value) {
    return Container(
      width: 18,
      height: 18,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: value ? Colors.green : Colors.red,
        border: Border.all(color: Colors.grey.shade400),
      ),
    );
  }
  final Lottery lottery;
  const LotteryDetailScreen({super.key, required this.lottery});

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Lotterie Details')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Datum: ${_formatDate(lottery.date)}', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text('Zeit: ${lottery.timeOfDay}', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 8),
            Text('Zu ziehende Kinder: ${lottery.nrOfChildrenToPick}', style: Theme.of(context).textTheme.bodyLarge),
            const SizedBox(height: 16),
            Text('Kinder:', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<Child>>(
                future: ChildService.fetchChildrenByIds(lottery.children.map((c) => c.childId).toList()),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(child: Text('Fehler beim Laden der Kinder: ${snapshot.error}'));
                  }
                  final children = snapshot.data ?? [];
                  // Ensure children are displayed in saved order, not reversed
                  final orderedChildren = lottery.children;
                  return Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        color: Colors.grey.shade200,
                        child: Row(
                          children: [
                            Expanded(flex: 3, child: Text('Name', style: Theme.of(context).textTheme.bodyMedium)),
                            Expanded(child: Center(child: Text('Benachrichtigt', style: Theme.of(context).textTheme.bodyMedium))),
                            Expanded(child: Center(child: Text('Geantwortet', style: Theme.of(context).textTheme.bodyMedium))),
                            Expanded(child: Center(child: Text('Bedarf', style: Theme.of(context).textTheme.bodyMedium))),
                          ],
                        ),
                      ),
                      Expanded(
                        child: ListView.builder(
                          itemCount: orderedChildren.length,
                          itemBuilder: (context, index) {
                            final entry = orderedChildren[index];
                            final child = children.firstWhere(
                              (c) => c.id == entry.childId,
                              orElse: () => Child(id: entry.childId, vorname: '', nachname: '', gruppe: GroupName.ratz),
                            );
                            final isPicked = entry.picked;
                            return Container(
                              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                              decoration: BoxDecoration(
                                color: isPicked ? Colors.red.shade700 : null,
                                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 3,
                  child: child.vorname.isNotEmpty || child.nachname.isNotEmpty
                    ? Text(
                      '${child.nachname}, ${child.vorname}' + (isPicked ? ' (Gezogen)' : ''),
                      style: isPicked
                        ? const TextStyle(color: Colors.white)
                        : null,
                      )
                    : Text(
                      child.id + (isPicked ? ' (Gezogen)' : ''),
                      style: isPicked
                        ? const TextStyle(color: Colors.white)
                        : null,
                      ),
                                  ),
                                  Expanded(
                                    child: Center(child: _buildBoolCircle(entry.notified)),
                                  ),
                                  Expanded(
                                    child: Center(child: _buildBoolCircle(entry.responded)),
                                  ),
                                  Expanded(
                                    child: Center(child: _buildBoolCircle(entry.need)),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}.${date.month.toString().padLeft(2, '0')}.${date.year}';
  }
}
