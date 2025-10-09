import 'package:flutter/material.dart';

/// Ein einfacher Ladebildschirm mit Logo und Fortschrittsanzeige.
///
/// Wird angezeigt, während die App initialisiert oder Daten lädt.
class LoadingScreen extends StatelessWidget {
  /// Erstellt eine Instanz des Ladebildschirms.
  const LoadingScreen({super.key});

  @override
  /// Baut das UI für den Ladebildschirm mit Logo und Fortschrittsanzeige.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/Sommersprossen_Logo.png',
              width: 150,
              height: 150,
            ),
            const SizedBox(height: 30),
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text('Loading...'),
          ],
        ),
      ),
    );
  }
}
