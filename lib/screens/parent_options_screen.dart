import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/child.dart';
import 'startup_screen.dart';

class ParentOptionsScreen extends StatefulWidget {
  final String parentId;
  final List<Child> children;

  const ParentOptionsScreen({
    super.key,
    required this.parentId,
    required this.children,
  });

  @override
  State<ParentOptionsScreen> createState() => _ParentOptionsScreenState();
}

class _ParentOptionsScreenState extends State<ParentOptionsScreen> {
  bool _isUpdatingSiblingMode = false;
  bool _isDeletingAccount = false;

  bool get _hasLinkedSiblings {
    return widget.children.any((c) => c.siblings.isNotEmpty);
  }

  bool get _canConfigureSiblingMode {
    return widget.children.length > 1;
  }

  Future<void> _activateLinkedSiblings() async {
    if (!_canConfigureSiblingMode || _isUpdatingSiblingMode) return;
    setState(() => _isUpdatingSiblingMode = true);
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final callable = functions.httpsCallable('LinkSiblings');
      final childIds = widget.children.map((c) => c.id).toList();
      await callable({'childIds': childIds});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kinder werden ab jetzt zusammen gezogen.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Umstellen: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingSiblingMode = false);
      }
    }
  }

  Future<void> _activateSeparatedSiblings() async {
    if (!_canConfigureSiblingMode || _isUpdatingSiblingMode) return;
    setState(() => _isUpdatingSiblingMode = true);
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final callable = functions.httpsCallable('SeperateSiblings');
      final childIds = widget.children.map((c) => c.id).toList();
      await callable({'childIds': childIds});
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Kinder werden ab jetzt getrennt gezogen.')),
      );
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Fehler beim Umstellen: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isUpdatingSiblingMode = false);
      }
    }
  }

  Future<void> _deleteOwnAccount() async {
    if (_isDeletingAccount) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Konto wirklich löschen?'),
        content: const Text(
          'Diese Aktion kann nicht rückgängig gemacht werden. '
          'Das Konto kann danach nur von der Kindergartenleitung wiederhergestellt werden.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Abbrechen'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Konto löschen'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _isDeletingAccount = true);
    try {
      final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
      final callable = functions.httpsCallable('deleteParent');
      await callable({'parentId': widget.parentId});

      await FirebaseAuth.instance.signOut();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('isLoggedIn');
      await prefs.remove('userType');

      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const StartupScreen()),
        (route) => false,
      );
    } on FirebaseFunctionsException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e.message ?? 'Konto konnte nicht gelöscht werden.',
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Konto konnte nicht gelöscht werden: $e')),
      );
    } finally {
      if (mounted) {
        setState(() => _isDeletingAccount = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final hasLinkedSiblings = _hasLinkedSiblings;

    return Scaffold(
      appBar: AppBar(title: const Text('Optionen')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ziehungsmodus Geschwister',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  if (!_canConfigureSiblingMode)
                    const Text(
                      'Diese Option ist erst verfügbar, wenn mindestens zwei Kinder zugeordnet sind.',
                    )
                  else if (hasLinkedSiblings)
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Kinder werden zusammen gezogen.'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isUpdatingSiblingMode
                              ? null
                              : _activateSeparatedSiblings,
                          child: const Text('Getrennt ziehen'),
                        ),
                      ],
                    )
                  else
                    Row(
                      children: [
                        const Expanded(
                          child: Text('Kinder werden getrennt gezogen.'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: _isUpdatingSiblingMode
                              ? null
                              : _activateLinkedSiblings,
                          child: const Text('Zusammen ziehen'),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Konto löschen',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Diese Aktion kann nicht rückgängig gemacht werden. '
                    'Das Konto kann danach nur von der Kindergartenleitung wiederhergestellt werden.',
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: _isDeletingAccount ? null : _deleteOwnAccount,
                    child: _isDeletingAccount
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Konto löschen'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
