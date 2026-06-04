![icon](assets/appIcon.svg)

# Ethercrypt

**Powered by Flutter**

A lightweight, open-source, and password manager and TOTP authenticator. Ethercrypt allows you to securely store credentials and generate 2FA codes in a single application. It supports multiple storage backends, including local encrypted files and cloud-based providers, giving you flexible access across devices.

## Supported platforms

* Android
* Windows
* Linux

## Storage backends

* **Local Storage** - Encrypted files stored directly on the device
* **Cloud Firestore** - Encrypted data stored online as documents in Google Cloud Firestore. Requires a Firebase project setup.
* _[Planned] Google Drive_
* _[Planned] OneDrive_
* _[Planned] Dropbox_

## Features

* **Local-first encrypted storage** - Store all data securely on your device using encrypted files.
* **Multiple storage providers** - Choose where your data is stored.
* **Cross-device access** - Access the same encrypted storage from different devices via the selected provider.
* **Built-in TOTP authenticator** - Generate and manage 2FA codes without external apps.
* **Password generator** - Create secure passwords with configurable length.
* **Cloud management tools** - Upload, download, and delete remote storage entries when using supported providers.
* **Optional time synchronisation** - NTP time synchronization over a server can be configured to increase local TOTP generation accuracy.

## Security Overview

Ethercrypt follows a zero-knowledge approach where the master password is never stored or transmitted. _**Important:** As a result, if the password is lost, access to encrypted data <u>**cannot be recovered**</u>, as no recovery mechanism exists by design._

* **Key derivation:** PBKDF2 with per-storage random salt and increased iteration count (v2.1.0+)
* **Encryption:** AES-256 in CBC mode with a unique IV per encryption
* **Integrity protection:** HMAC verification to detect tampering
* **Secure credential handling:** Sensitive authentication data is stored locally using Flutter Secure Storage when required for online backends.