/// Maps FirebaseAuth error codes to user-friendly German messages.
/// [context] can be 'login', 'reset', 'register', etc. Default is 'login'.
String firebaseAuthErrorMessage(String code, {String context = 'login'}) {
  switch (code) {
    case 'invalid-email':
      return 'Ungültige E-Mail-Adresse.';
    case 'user-disabled':
      return 'Dieses Konto wurde deaktiviert.';
    case 'user-not-found':
      return 'Kein Benutzer mit dieser E-Mail gefunden.';
    case 'wrong-password':
      return 'Falsches Passwort.';
    case 'email-already-in-use':
      return 'Diese E-Mail-Adresse wird bereits verwendet.';
    case 'operation-not-allowed':
      return 'Anmeldung mit diesem Anbieter ist deaktiviert.';
    case 'weak-password':
      return 'Das Passwort ist zu schwach.';
    case 'too-many-requests':
      return 'Zu viele Anmeldeversuche. Bitte später erneut versuchen.';
    case 'invalid-credential':
      return 'Ungültige Anmeldedaten.';
    case 'account-exists-with-different-credential':
      return 'Es existiert bereits ein Konto mit einer anderen Anmeldemethode.';
    default:
      switch (context) {
        case 'reset':
          return 'Unbekannter Fehler beim Passwort-Reset.';
        case 'register':
          return 'Unbekannter Fehler bei der Registrierung.';
        default:
          return 'Unbekannter Fehler bei der Anmeldung.';
      }
  }
}
