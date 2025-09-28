import 'package:flutter/material.dart';
import 'eltern_screen.dart';
import 'kinder_screen.dart';

class ParentMainMenuScreen extends StatelessWidget {
  const ParentMainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Parent Main Menu')),
      body: const Center(child: Text('Welcome, Parent!')),
    );
  }
}

class AdminMainMenuScreen extends StatelessWidget {
  const AdminMainMenuScreen({super.key});

  final String surname = 'Hannah'; // Mocked admin surname

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Main Menu')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Hallo $surname!',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 32),
            ListTile(
              leading: const Icon(Icons.shuffle),
              title: const Text('Losverfahren'),
              onTap: () {
                // TODO: Implement navigation or action
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.child_care),
              title: const Text('Kinder'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const KinderScreen(),
                  ),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Eltern'),
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const ElternScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
