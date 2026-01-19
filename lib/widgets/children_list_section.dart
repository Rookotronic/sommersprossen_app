import 'package:flutter/material.dart';
import '../models/lottery.dart';
import '../models/child.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/confirmation_dialog.dart';

class ChildrenListSection extends StatelessWidget {
  final Lottery lottery;
  final List<Child> children;
  final String lotteryId;

  const ChildrenListSection({
    super.key,
    required this.lottery,
    required this.children,
    required this.lotteryId,
  });

  @override
  Widget build(BuildContext context) {
    final orderedChildren = lottery.children;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Kinder:', style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          color: Colors.grey.shade200,
          child: Row(
            children: [
              Expanded(flex: 3, child: Text('Name', style: const TextStyle(fontSize: 11))),
              Expanded(child: Center(child: Text('Benachrichtigt', style: const TextStyle(fontSize: 11)))),
              Expanded(child: Center(child: Text('Geantwortet', style: const TextStyle(fontSize: 11)))),
              Expanded(child: Center(child: Text('Bedarf', style: const TextStyle(fontSize: 11)))),
            ],
          ),
        ),
        ...orderedChildren.map((lotteryChild) {
          final child = children.firstWhere(
            (c) => c.id == lotteryChild.childId,
            orElse: () => Child(id: '', vorname: '', nachname: ''),
          );
          final showGezogen = lottery.finished && lotteryChild.picked;
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 4),
            decoration: BoxDecoration(
              color: lotteryChild.picked ? const Color.fromARGB(255, 255, 192, 192) : null,
              border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      Text(
                        '${child.vorname} ${child.nachname}${showGezogen ? ' (gezogen)' : ''}',
                        style: const TextStyle(fontSize: 13),
                      ),
                      if (!lottery.requestsSend)
                        IconButton(
                          icon: const Icon(Icons.delete, size: 18, color: Colors.red),
                          tooltip: 'Kind entfernen',
                          onPressed: () async {
                            final confirmed = await showConfirmationDialog(
                              context,
                              title: 'Kind entfernen',
                              content: 'Möchtest du dieses Kind wirklich aus der Lotterie entfernen?',
                              confirmText: 'Entfernen',
                            );
                            if (confirmed == true) {
                              final updatedChildren = orderedChildren
                                .where((c) => c.childId != lotteryChild.childId)
                                .map((c) => c.toMap())
                                .toList();
                              await FirebaseFirestore.instance
                                .collection('lotteries')
                                .doc(lotteryId)
                                .update({'children': updatedChildren});
                                if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Kind entfernt.')),
                              );
                            }
                          },
                        ),
                    ],
                  ),
                ),
                Expanded(child: Center(child: Icon(lotteryChild.notified ? Icons.check_circle : Icons.cancel, color: lotteryChild.notified ? Colors.green : Colors.red, size: 18))),
                Expanded(child: Center(child: Icon(lotteryChild.responded ? Icons.check_circle : Icons.cancel, color: lotteryChild.responded ? Colors.green : Colors.red, size: 18))),
                Expanded(child: Center(child: Icon(lotteryChild.need ? Icons.check_circle : Icons.cancel, color: lotteryChild.need ? Colors.green : Colors.red, size: 18))),
              ],
            ),
          );
        }),
      ],
    );
  }
}
