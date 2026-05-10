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
