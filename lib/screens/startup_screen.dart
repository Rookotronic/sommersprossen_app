import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/controller_lifecycle_mixin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logger/logger.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'loading_screen.dart';
import 'main_menus.dart';
import '../utils/validators.dart';

/// Startbildschirm der App.
///
/// Prueft den Login-Status und leitet den Nutzer zum passenden Hauptmenue oder Login weiter.
class StartupScreen extends StatefulWidget {
  /// Erstellt den Startbildschirm.
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

/// State fuer den Startbildschirm.
class _StartupScreenState extends State<StartupScreen> {
  static const Duration _startupRoleFetchTimeout = Duration(seconds: 8);
  late final Future<Widget> _startupTarget;

  /// Initialisiert die App und prueft den Login-Status.
  @override
  void initState() {
    super.initState();
    _startupTarget = _resolveStartupTarget();
  }

  /// Prueft, ob der Nutzer eingeloggt ist und liefert den Zielscreen.
  Future<Widget> _resolveStartupTarget() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const LoginScreen();
    }

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get()
          .timeout(_startupRoleFetchTimeout);

      final userType = doc.data()?['type'] as String?;
      final Widget menu = userType == 'admin'
          ? const AdminMainMenuScreen()
          : const ParentMainMenuScreen();
      return menu;
    } catch (e) {
      debugPrint('Startup role fetch failed, falling back to login: $e');
      FirebaseAuth.instance.signOut().catchError((_) {
        // Ignore signOut errors during startup fallback.
      });
      return const LoginScreen();
    }
  }

  /// Zeigt einen Ladebildschirm waehrend der Initialisierung.
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Widget>(
      future: _startupTarget,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done &&
            snapshot.hasData) {
          return snapshot.data!;
        }
        return const LoadingScreen();
      },
    );
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with ControllerLifecycleMixin {
  static const String _deployVersion = String.fromEnvironment(
    'APP_DEPLOY_VERSION',
    defaultValue: '',
  );
  final _logger = Logger();
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _userController;
  late final TextEditingController _passwordController;

  bool _obscurePassword = true;
  String? _errorMessage;
  String? _versionLabel;

  @override
  void initState() {
    super.initState();
    _userController = createController();
    _passwordController = createController();
    _initVersionLabel();
  }

  Future<void> _initVersionLabel() async {
    final deployVersion = _deployVersion.trim();
    if (deployVersion.isNotEmpty) {
      if (!mounted) return;
      setState(() {
        _versionLabel = 'Version $deployVersion';
      });
      return;
    }

    try {
      final info = await PackageInfo.fromPlatform();
      if (!mounted) return;
      setState(() {
        _versionLabel = 'App-Version ${info.version}';
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _versionLabel = null;
      });
    }
  }

  @override
  void dispose() {
    // Lifecycle wird vom ControllerLifecycleMixin verwaltet.
    super.dispose();
  }

  Future<void> _resetPassword(BuildContext context) async {
    final email = _userController.text.trim();
    if (!isValidEmail(email)) {
      setState(() {
        _errorMessage = 'Bitte gültige E-Mail-Adresse eingeben.';
      });
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Passwort-Reset-E-Mail wurde gesendet!'),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Fehler: ${e.message ?? e.code}';
      });
    } catch (_) {
      setState(() {
        _errorMessage = 'Unbekannter Fehler beim Passwort-Reset.';
      });
    }
  }

  Future<void> _login(BuildContext context) async {
    final email = _userController.text.trim();
    final password = _passwordController.text.trim();
    if (!isValidEmail(email)) {
      setState(() {
        _errorMessage = 'Bitte gültige E-Mail-Adresse eingeben.';
      });
      return;
    }

    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        // Bei erfolgreichem Login die Passwortspeicherung (Keychain) anstoßen.
        TextInput.finishAutofillContext(shouldSave: true);

        try {
          if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
            await FirebaseMessaging.instance.requestPermission();
            final token = await FirebaseMessaging.instance.getToken();
            if (token != null) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update({'fcmToken': token});
            }
            FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .update({'fcmToken': newToken});
            });
          }
        } catch (e) {
          // Fehler nur protokollieren, Anmeldung nicht blockieren.
          _logger.e('Fehler beim FCM-Token: $e');
        }

        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        final userType = doc.data()?['type'] ?? 'parent';
        final Widget menu = userType == 'admin'
            ? const AdminMainMenuScreen()
            : const ParentMainMenuScreen();

        if (context.mounted) {
          Navigator.of(
            context,
          ).pushReplacement(MaterialPageRoute(builder: (_) => menu));
        }
      } else {
        setState(() {
          _errorMessage = 'Anmeldung fehlgeschlagen: Kein Benutzer gefunden.';
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage =
            'Anmeldung fehlgeschlagen: [${e.code}] ${e.message ?? ''}';
      });
    } catch (e) {
      setState(() {
        _errorMessage =
            'Anmeldung fehlgeschlagen: ${e is Exception ? e.toString() : 'Unbekannter Fehler'}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Anmeldung')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: AutofillGroup(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _userController,
                    decoration: const InputDecoration(
                      labelText: 'E-Mail-Adresse',
                      border: OutlineInputBorder(),
                    ),
                    textInputAction: TextInputAction.next,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [
                      AutofillHints.username,
                      AutofillHints.email,
                    ],
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte E-Mail-Adresse eingeben';
                      }
                      if (!isValidEmail(value)) {
                        return 'Bitte gültige E-Mail-Adresse eingeben';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: InputDecoration(
                      labelText: 'Passwort',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    autofillHints: const [AutofillHints.password],
                    obscureText: _obscurePassword,
                    textInputAction: TextInputAction.done,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Bitte Passwort eingeben';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  if (_errorMessage != null)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12.0),
                      child: Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        if (_formKey.currentState?.validate() ?? false) {
                          _login(context);
                        }
                      },
                      child: const Text('Anmelden'),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () {
                      _resetPassword(context);
                    },
                    child: const Text('Passwort vergessen?'),
                  ),
                  if (_versionLabel != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        _versionLabel!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Hauptmenü')),
      body: const Center(child: Text('Willkommen im Hauptmenü!')),
    );
  }
}
