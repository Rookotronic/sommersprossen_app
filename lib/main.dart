import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'screens/startup_screen.dart';

import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

/// Einstiegspunkt der App.
///
/// Initialisiert Firebase und startet die Hauptanwendung.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kIsWeb) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } else {
    switch (defaultTargetPlatform) {
      case TargetPlatform.iOS:
      case TargetPlatform.macOS:
        if (Firebase.apps.isEmpty) {
          await Firebase.initializeApp();
        }
        break;
      default:
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        );
        break;
    }
  }

  runApp(const MainApp());
}

/// Haupt-Widget der App.
///
/// Setzt das globale Theme und zeigt den Startbildschirm.
class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          surface: Colors.white, 
        ),
      ),
      home: const StartupScreen(),
    );
  }
}
