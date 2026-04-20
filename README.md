# Sommersprossen App

Flutter-App zur Organisation von Betreuungsengpaessen in der Kita.

Die App unterstuetzt zwei Rollen:

1. Eltern
2. Kindergartenleitung/Administration

Im Mittelpunkt stehen Bedarfsrueckmeldungen, eine faire Lotterie-Logik, transparente Kommunikation und einfache Verwaltung.

## Funktionsumfang

### Eltern

1. Anmeldung mit E-Mail/Passwort (Firebase Auth)
2. Einsicht in eigene Kinder inklusive aktueller Lotterie-/Betreuungsinformationen
3. Historie pro Kind
4. Optionenseite mit:
5. Ziehungsmodus fuer Geschwister (zusammen oder getrennt)
6. Konto-Loeschung mit Sicherheitsabfrage

### Administration

1. Verwaltung von Eltern und Kindern
2. Anlage und Steuerung von Lotterien
3. Lotterietopf-Management
4. PDF-Ausgabe abgeschlossener Lotterien
5. Ausloesen von Benachrichtigungsprozessen

### Plattformen

1. Android
2. iOS
3. Web (vor allem fuer Entwicklung und schnelle Pruefung)

## Architektur und Technik

1. Flutter (Dart, null-safety)
2. Firebase Auth fuer Login
3. Cloud Firestore fuer Fachdaten
4. Cloud Functions fuer kritische Serverlogik
5. Firebase Messaging fuer Push-Token-Verwaltung
6. PDF/Printing fuer Ausgaben

## Projektstruktur (Kurzueberblick)

1. lib/screens: Hauptseiten und Flows
2. lib/widgets: Wiederverwendbare UI-Bausteine
3. lib/models: Datenmodelle (Kind, Eltern, Lotterie)
4. lib/services: Zugriffe auf Firestore/Fachdienste
5. scripts: Hilfsskripte fuer Deploy/Entwicklung

## Voraussetzungen

1. Flutter SDK (aktuell/stable)
2. Xcode fuer iOS-Builds
3. Android SDK/ADB fuer Android-Builds
4. Firebase-Projekt(e) inkl. Konfigurationsdateien

## Einrichtung

### 1) Repository klonen

```bash
git clone https://github.com/Rookotronic/sommersprossen_app.git
cd sommersprossen_app
```

### 2) Abhaengigkeiten installieren

```bash
flutter pub get
```

### 3) Firebase konfigurieren

1. Android: google-services.json pro Flavor hinterlegen
2. iOS: GoogleService-Info-*.plist pro Umgebung hinterlegen
3. FlutterFire-Optionen in lib/firebase_options.dart aktuell halten

## Starten in der Entwicklung

### Web (Chrome)

```bash
flutter run -d chrome --dart-define=FLAVOR=dev
```

### Android Emulator (dev-Flavor)

```bash
flutter run -d emulator-5554 --flavor dev --dart-define=FLAVOR=dev
```

### iPhone (dev)

```bash
flutter run -d <DEVICE_ID> --dart-define=FLAVOR=dev
```

## Deploy-Hinweis Android

Fuer stabile Android-Deploys steht ein Skript bereit:

```bash
./scripts/deploy_android_dev.sh
```

Das Skript:

1. erkennt einen laufenden Emulator
2. baut das dev-debug APK
3. installiert die App neu
4. startet die App automatisch
5. fuehrt eine deploy-Version mit Fingerprint-Logik

## Konfiguration und Versionen

1. App-Version: in pubspec.yaml
2. Login-Label zeigt deploy-Version (falls gesetzt) oder App-Version
3. Flavors werden ueber dart-define FLAVOR gesteuert

## Aktuelle Produktlogik (Auszug)

1. Eltern-E-Mail ist in der Eltern-Detailansicht nicht editierbar
2. Parent-Optionen sind auch ohne zugeordnete Kinder sichtbar
3. Aktionen mit hohem Fehlklick-Risiko wurden mit bestaetigenden Dialogen abgesichert
4. Startup-Flow nutzt Firebase-Session/Rollenauflösung statt lokaler Login-Flags

## Datenschutz und Rechtliches

1. Datenschutzhinweise:
   https://sommersprossen.org/datenschutzhinweise/
   https://rookotronic.github.io/sommersprossen_app/privacy.html
2. Impressum:
   https://sommersprossen.org/impressum/

## Qualitaetssicherung (empfohlen)

```bash
flutter analyze
```

## Lizenz

MIT