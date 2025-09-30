import 'package:flutter/material.dart';
import 'child.dart';
import 'parent.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MeinKindDetailScreen extends StatefulWidget {
  final Child child;
  const MeinKindDetailScreen({super.key, required this.child});

  @override
  State<MeinKindDetailScreen> createState() => _MeinKindDetailScreenState();
}

class _MeinKindDetailScreenState extends State<MeinKindDetailScreen> {
  List<Parent> _parents = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchParents();
  }

  Future<void> _fetchParents() async {
    if (widget.child.parentIds == null || widget.child.parentIds!.isEmpty) {
      setState(() {
        _parents = [];
        _loading = false;
      });
      return;
    }
    final snapshot = await FirebaseFirestore.instance
        .collection('parents')
        .where(FieldPath.documentId, whereIn: widget.child.parentIds)
        .get();
    setState(() {
      _parents = snapshot.docs.map((doc) => Parent.fromFirestore(doc.id, doc.data())).toList();
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    return Scaffold(
      appBar: AppBar(
        title: Text('${child.vorname} ${child.nachname}'),
        backgroundColor: Colors.blue,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Card(
                    elevation: 6,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    margin: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              CircleAvatar(
                                radius: 32,
                                backgroundColor: Colors.blue.shade100,
                                child: Icon(Icons.child_care, size: 36, color: Colors.blue.shade700),
                              ),
                              const SizedBox(width: 20),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(child.vorname, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
                                  Text(child.nachname, style: Theme.of(context).textTheme.titleMedium),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 28),
                          Row(
                            children: [
                              Icon(Icons.groups, color: Colors.blue.shade400),
                              const SizedBox(width: 8),
                              Text('Eltern:', style: Theme.of(context).textTheme.titleMedium),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ..._parents.isEmpty
                              ? [const Padding(
                                  padding: EdgeInsets.only(left: 32),
                                  child: Text('Keine Eltern gefunden.', style: TextStyle(color: Colors.grey)),
                                )]
                              : _parents.map((p) => Padding(
                                    padding: const EdgeInsets.only(left: 32, bottom: 2),
                                    child: Text('${p.nachname}, ${p.vorname}', style: Theme.of(context).textTheme.bodyLarge),
                                  )),
                          const SizedBox(height: 24),
                          Row(
                            children: [
                              Icon(Icons.groups_2, color: Colors.blue.shade400),
                              const SizedBox(width: 8),
                              Text('Gruppe:', style: Theme.of(context).textTheme.titleMedium),
                              const SizedBox(width: 8),
                              Chip(
                                label: Text(child.gruppe.displayName, style: const TextStyle(color: Colors.white)),
                                backgroundColor: Colors.blue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  // Space for future content below
                ],
              ),
            ),
    );
  }
}
