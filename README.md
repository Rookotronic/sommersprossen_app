# 🏫 Kindergarten Attendance Manager

A Flutter app for kindergartens to **organize care restrictions in case of staff illness**.
Parents can register attendance needs, while the **kindergarten administration** runs a fair **lottery system without replacement** until all children have stayed at home once.
The app is designed for families and administrators to communicate efficiently and transparently.

## ✨ Features
- 👩‍👩‍👧 **Two user roles**: Parents and Kindergarten Administration
- 📅 Parents can **submit attendance requests**
- 🎲 Administration runs a **lottery system** to distribute home days fairly
- 🔔 Push notifications to keep parents updated
- 📊 Dashboard for admins with requests, draws, and history
- 🖨️ Print finished lottery details as PDF (with sorting, marking, and export)
- 🔒 Firebase authentication (parents vs. admin accounts)
- ☁️ Firebase backend (Firestore, Cloud Functions, Messaging)
- 📝 Well-documented codebase for maintainability

## 🛠️ Tech Stack
- **Flutter** (Dart) — cross-platform app (iOS, Android, Web for dev)
- **Firebase** — Auth, Firestore, Cloud Functions, Messaging
- **Provider / Riverpod** (depending on your state management choice)
- **Xcode** / **Android Studio** for native builds

## 🚀 Getting Started

### 1. Prerequisites
- [Flutter SDK](https://docs.flutter.dev/get-started/install) (latest stable)
- [Firebase CLI](https://firebase.google.com/docs/cli)
- Xcode (for iOS) or Android Studio (for Android)
- A configured Firebase project (see below)

### 2. Clone the Repository
```bash
git clone https://github.com/Rookotronic/sommersprossen_app.git
cd sommersprossen_app
```

### 3. Install Dependencies
```bash
flutter pub get
```

### 4. Firebase Setup
- Add your Firebase config files (`google-services.json` for Android, `GoogleService-Info.plist` for iOS).
- Configure `firebase_options.dart` using the FlutterFire CLI.

### 5. Run the App
```bash
flutter run
```

### 6. Printing Lottery Details
- On finished lotteries, admins can print details as PDF (sorted, marked, exportable).

## 📄 Documentation
- All major screens, widgets, and services are documented with Dart doc comments.
- See `/lib/screens/` and `/lib/widgets/` for examples.

## 💡 Contributing
Pull requests and feedback are welcome!

## 📦 License
MIT

## 🔒 Privacy & Data Protection
See our [Privacy Policy](https://rookotronic.github.io/sommersprossen_app/privacy.html) for details on data handling and protection.