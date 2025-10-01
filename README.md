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
- 🔒 Firebase authentication (parents vs. admin accounts)  
- ☁️ Firebase backend (Firestore, Cloud Functions, Messaging)  

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

