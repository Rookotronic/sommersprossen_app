import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Button zum Versenden von Benachrichtigungen an Eltern.
///
/// Ruft eine Cloud Function auf und zeigt Feedback an.
Widget notifyparentsbutton({
  required String lotteryId,
  required Future<void> Function() onSuccess,
}) {
  final isSending = ValueNotifier<bool>(false);
  return Builder(
    builder: (context) => ValueListenableBuilder<bool>(
      valueListenable: isSending,
      builder: (context, sending, _) => ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
        onPressed: sending
            ? null
            : () async {
                isSending.value = true;
                try {
                  final functions = FirebaseFunctions.instanceFor(
                    region: 'europe-west1',
                  );
                  final notifyParentsForLottery = functions.httpsCallable(
                    'notifyParentsForLottery',
                  );
                  await notifyParentsForLottery({'lotteryId': lotteryId});

                  // Firestore-Feld `requestsSend` auf true setzen.
                  await FirebaseFirestore.instance
                      .collection('lotteries')
                      .doc(lotteryId)
                      .update({'requestsSend': true});

                  await onSuccess();
                } on FirebaseFunctionsException catch (error) {
                  if (!context.mounted) return;
                  final message =
                      error.message ?? 'Unbekannter Fehler beim Senden.';
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Senden fehlgeschlagen: $message')),
                  );
                } catch (error) {
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Senden fehlgeschlagen: $error')),
                  );
                } finally {
                  isSending.value = false;
                }
              },
        child: Text(
          sending ? 'Wird gesendet...' : 'Benachrichtigungen senden',
        ),
      ),
    ),
  );
}
