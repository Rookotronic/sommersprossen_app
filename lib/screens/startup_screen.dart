import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../utils/controller_lifecycle_mixin.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:logger/logger.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'loading_screen.dart';
import 'main_menus.dart';
import '../utils/validators.dart';

class StartupScreen extends StatefulWidget {
  const StartupScreen({super.key});

  @override
  State<StartupScreen> createState() => _StartupScreenState();
}

class _StartupScreenState extends State<StartupScreen> {
  @override
  void initState() {
    super.initState();
    _initApp();
  }

  Future<void> _initApp() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    final userType = prefs.getString('userType');
    if (isLoggedIn && userType != null) {
      Widget menu;
      if (userType == 'parent') {
        menu = const ParentMainMenuScreen();
      } else if (userType == 'admin') {
        menu = const AdminMainMenuScreen();
      } else {
        menu = const MainMenuScreen();
      }
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => menu),
        );
      }
    } else {
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const LoadingScreen();
  }
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with ControllerLifecycleMixin {
  final _logger = Logger();
  Future<void> _resetPassword(BuildContext context) async {
    final email = _userController.text.trim();
    if (!isValidEmail(email)) {
      setState(() {
        _errorMessage = 'Bitte gültige Email-Adresse eingeben.';
      });
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Passwort-Reset Email wurde gesendet!')),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Fehler: ${e.message ?? e.code}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Unbekannter Fehler beim Passwort-Reset.';
      });
    }
  }
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _userController;
  late final TextEditingController _passwordController;
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _userController = createController();
    _passwordController = createController();
  }

  @override
  void dispose() {
    // Lifecycle handled by ControllerLifecycleMixin
    super.dispose();
  }

  bool _isAlphanumeric(String value) {
    final alphanumeric = RegExp(r'^[a-zA-Z0-9]*$');
    return alphanumeric.hasMatch(value);
  }

  Future<void> _login(BuildContext context) async {
    final email = _userController.text.trim();
    final password = _passwordController.text.trim();
    if (!isValidEmail(email)) {
      setState(() {
        _errorMessage = 'Only letters and numbers allowed.';
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
        // Platform-aware FCM logic
        try {
          if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
            await FirebaseMessaging.instance.requestPermission();
            final token = await FirebaseMessaging.instance.getToken();
            if (token != null) {
              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'fcmToken': token});
            }
            FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
              await FirebaseFirestore.instance.collection('users').doc(user.uid).update({'fcmToken': newToken});
            });
          }
        } catch (e) {
          // Log error, do not block login
          _logger.e('FCM token error', e);
        }

        final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
        final userType = doc.data()?['type'] ?? 'parent';
        Widget menu = userType == 'admin' ? const AdminMainMenuScreen() : const ParentMainMenuScreen();
        if (context.mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => menu),
          );
        }
      } else {
        setState(() {
          _errorMessage = 'Login failed: No user found.';
        });
      }
    } on FirebaseAuthException catch (e) {
      setState(() {
        _errorMessage = 'Login failed: [${e.code}] ${e.message ?? ''}';
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Login failed: ${e is Exception ? e.toString() : 'Unknown error'}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _userController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter your email';
                    }
                    if (!isValidEmail(value)) {
                      return 'Please enter a valid email address';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility : Icons.visibility_off),
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
                      return 'Please enter your password';
                    }
                    if (!_isAlphanumeric(value)) {
                      return 'Only letters and numbers allowed';
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
                    child: const Text('Login'),
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () {
                    _resetPassword(context);
                  },
                  child: const Text('Passwort vergessen?'),
                ),
              ],
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
      appBar: AppBar(title: const Text('Main Menu')),
      body: const Center(child: Text('Welcome to the Main Menu!')),
    );
  }
}
