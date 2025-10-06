import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';

Widget NotifyParentsButton({required VoidCallback onSuccess}) {
  return ElevatedButton(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
    ),
    onPressed: () async {
      try {
        final functions = FirebaseFunctions.instanceFor(region: 'europe-west1');
        final notifyParentsForLottery = functions.httpsCallable('notifyParentsForLottery');
        final result = await notifyParentsForLottery();
        print('Notification sent: ${result.data}');
        onSuccess();
        // Show feedback
        // Use context from builder if needed
      } catch (error) {
        print('Error sending notification: $error');
        // Optionally show error feedback
      }
    },
    child: const Text('Benachrichtigungen senden'),
  );
}
