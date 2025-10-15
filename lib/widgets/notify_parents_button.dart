import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Button zum Versenden von Benachrichtigungen an Eltern.
///
/// Ruft eine Cloud Function auf und zeigt Feedback an.
Widget notifyparentsbutton({required String lotteryId, required VoidCallback onSuccess}) {
  final logger = Logger();
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    onPressed: () async {
      try {
        final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
        final notifyParentsForLottery = functions.httpsCallable('notifyParentsForLottery');
        final result = await notifyParentsForLottery({'lotteryId': lotteryId});
        logger.i('Notification sent: ${result.data}');
        // Update Firestore to set requestsSend: true
        await FirebaseFirestore.instance.collection('lotteries').doc(lotteryId).update({'requestsSend': true});
        onSuccess();
      } catch (error) {
        logger.e('Error sending notification: $error');
        // Optionally show error feedback
      }
    },
    child: const Text('Benachrichtigungen senden'),
  );
}
