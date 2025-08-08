# Ethercrypt

**Powered by Flutter**

A lightweight, open-source, secure, and privacy-focused password manager that also works as a TOTP authenticator. Manage your account credentials locally or in the cloud, and generate 2FA codes — all in one app.

## Features

* **Secure Local Storage** – Keep your accounts safe directly on your device.
* **Cloud Sync (since v1.1.0)** – Optional synchronization with Firebase Firestore for access across devices.
* **Zero Knowledge** – Your master password is never stored or transmitted; only a hashed verification value is stored to ensure the storage integrity.
* **Built-in TOTP Generator** – Replace third-party apps like Google Authenticator with integrated 2FA code generation.

## Security Overview (For version 2.1.0)

* **Key Derivation:** PBKDF2 with a randomly generated salt, password UTF-8 encoded before derivation.
* **Encryption:** AES-256 in CBC mode, unique IV for each encryption.
* **Integrity:** HMAC verification to ensure no tampering.

## Getting Started & Development Setup

Follow these steps to configure, build, and run the app locally. This project requires some initial developer setup before it can be built and used.

### 1. Prerequisites

* **Flutter SDK** — Install Flutter [Flutter installation guide](https://flutter.dev/docs/get-started/install)
* **Android Studio** (or your preferred IDE) with Flutter and Dart plugins installed.
* **A Firebase Project** (optional, for cloud sync) — see step 3.

### 2. Clone the Repository
Clone it with git or download it manually.

### 3. Create Configuration File

> **Important:** The project will **not compile** until you create a config file.

1. Create the file:

    ```
    lib/engine/config/app_config.dart
    ```

2. Add the following content:

   ```dart
   final class Config {
     static const String firestoreApiKey = '<firestore-api-key>';
     static const String firestoreProjectId = '<firestore-project-id>';
     static const String ntpTimeSyncDomain = 'time.google.com';
   }
   ```

   * **`firestoreApiKey`** and **`firestoreProjectId`** are required for using Firestore cloud storage.
        * The app communicates with Firestore exclusively via REST APIs — no Firestore SDK or CLI is required.
        * You only need these two values from your Firebase project setup.
   * If you do **not** want Firestore integration, leave them as empty strings (`''`).
   * **`ntpTimeSyncDomain`** can be customized; is used for accurate time synchronization to ensure correct 2FA code generation.

### 4. Install Dependencies

From the project root, run:

```bash
flutter pub get
```

### 5. Run the App

* Open the project in Android Studio or your preferred IDE.
* Connect a device or start an emulator.
* Run the app via the IDE or use the command line:

```bash
flutter run
```

### 6. Build Release Versions

Example for building APK for Android:

```bash
flutter build apk --release
```