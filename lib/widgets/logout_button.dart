import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../screens/startup_screen.dart';

/// Button zum Ausloggen des aktuellen Benutzers.
///
/// Führt ein Sign-Out durch und navigiert zum Startbildschirm.
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.logout),
      tooltip: 'Logout',
      onPressed: () async {
        await FirebaseAuth.instance.signOut();
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const StartupScreen()),
          );
        }
      },
    );
  }
}
