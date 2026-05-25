import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:logger/logger.dart';
import 'screens/startup_screen.dart';
import 'widgets/offline_banner.dart';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'firebase_options.dart';

Future<void> initializeFirebase() async {
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    final isDuplicateApp = error is FirebaseException
        ? error.code == 'duplicate-app'
        : error.toString().contains('duplicate-app');

    if (!isDuplicateApp) {
      rethrow;
    }
  }
}

/// Einstiegspunkt der App.
///
/// Initialisiert Firebase und startet die Hauptanwendung.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kReleaseMode) {
    Logger.level = Level.off;
  }

  await initializeFirebase();

  const flavor = String.fromEnvironment('FLAVOR');
  // isProd nur wenn FLAVOR=prod explizit gesetzt.
  // kReleaseMode NICHT verwenden: dev-signierte Release-Builds
  // unterstützen kein DeviceCheck und würden App-Check-Fehler produzieren.
  final isProd = flavor == 'prod';

  await FirebaseAppCheck.instance.activate(
    providerAndroid: isProd ? const AndroidPlayIntegrityProvider() : const AndroidDebugProvider(),
    providerApple: isProd ? const AppleAppAttestProvider() : const AppleDebugProvider(),
  );

  if (!isProd) {
    // Token asynchron abrufen – nicht auf Ergebnis warten, damit App nicht hängt
    FirebaseAppCheck.instance.getToken(true).then((token) {
      // ignore: avoid_print
      print('🔑 App Check Debug Token: $token');
    });
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
      debugShowCheckedModeBanner: false,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('de', 'DE'),
        Locale('en', 'US'),
      ],
      theme: ThemeData(
        scaffoldBackgroundColor: Colors.white,
        colorScheme: ColorScheme.fromSwatch().copyWith(
          surface: Colors.white, 
        ),
      ),
      builder: (context, child) => OfflineBanner(
        child: child ?? const SizedBox.shrink(),
      ),
      home: const StartupScreen(),
    );
  }
}
