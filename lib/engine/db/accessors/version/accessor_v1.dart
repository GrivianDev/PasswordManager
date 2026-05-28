import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:ethercrypt/engine/account.dart';
import 'package:ethercrypt/engine/app_exception.dart';
import 'package:ethercrypt/engine/cryptography/base16_codec.dart';
import 'package:ethercrypt/engine/cryptography/datatypes.dart';
import 'package:ethercrypt/engine/cryptography/implementation/aes_encryption.dart';
import 'package:ethercrypt/engine/cryptography/padding_mode.dart';
import 'package:ethercrypt/engine/cryptography/service.dart';
import 'package:ethercrypt/engine/db/accessors/accessor.dart';
import 'package:ethercrypt/engine/db/database_content.dart';
import 'package:flutter/foundation.dart' as foundation;
import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';

/// DataAccessorV1 implements a secure version of the data accessor interface,
/// providing encryption and decryption of account data using AES-256 CBC with
/// HMAC-SHA256 verification and PBKDF2 key derivation.
///
/// This version improves upon V0 by:
/// - Using a higher PBKDF2 iteration count (100,000) for stronger key derivation.
/// - Deriving a 64-byte key split into separate AES encryption and HMAC keys for seperation of concerns.
/// - Storing data in JSON format for improved structure and extensibility.
/// - Verifying integrity with an HMAC over the combined key, IV, and ciphertext.
///
/// Properties include:
/// - [saltIdentifier] (hex-encoded salt used for PBKDF2)
/// - [ivIdentifier] (hex-encoded AES initialization vector)
/// - [hmacIdentifier] (hex-encoded HMAC of key+IV+ciphertext)
/// - [dataIdentifier] (Base64-encoded AES-encrypted JSON data)
class DataAccessorV1 extends DataAccessor {
  static const String versionIdentifier = 'version';
  static const String compressedIdentifier = 'Compressed';
  static const String saltIdentifier = 'Salt';
  static const String ivIdentifier = 'IV';
  static const String hmacIdentifier = 'HMac';
  static const String dataIdentifier = 'Data';

  static const int pbkdf2Iterations = 100000;
  static const int keyLength = 32;
  static const int saltLength = 32;

  String? _password;
  Key? _totalKey;
  Key? _aesKey; // The 32-byte AES encryption key (lower half of _totalKey).
  Key? _hmacKey; // The 32-byte HMAC key (upper half of _totalKey).

  /// Derives a 64-byte key from the given password and optional salt using PBKDF2
  /// with HMAC-SHA256 and [pbkdf2Iterations].
  ///
  /// If no salt is provided, a random salt of length [saltLength] is generated.
  /// The returned [Key] contains the derived key bytes and the salt used.
  static Key _deriveKey(String password, [Uint8List? salt]) {
    final usedSalt = salt ?? CryptographicService.randomBytes(saltLength);
    final Pbkdf2Parameters params = Pbkdf2Parameters(usedSalt, pbkdf2Iterations, keyLength * 2); // Double sized key
    final PBKDF2KeyDerivator pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(params);

    final Uint8List keyBytes = pbkdf2.process(utf8.encode(password));
    return Key(keyBytes, usedSalt);
  }

  @override
  String get version => 'v1';

  @override
  void setPassword(String password) {
    _password = password;

    // Reset cached keys
    _totalKey = null;
    _aesKey = null;
    _hmacKey = null;
  }

  @override
  Future<DatabaseContent> unpack(Map<String, String> properties) async {
    if (_password == null) {
      throw Exception('No password was defined in accessor');
    }

    if (properties['version'] != version) {
      throw Exception('Version mismatch while reading data');
    }
    final String? saltString = properties[saltIdentifier];
    final String? ivString = properties[ivIdentifier];
    final String? hmacString = properties[hmacIdentifier];
    final String? cipher = properties[dataIdentifier];
    
    final bool isCompressed = properties[compressedIdentifier] == 'true';

    if (saltString == null || hmacString == null || ivString == null || cipher == null) throw Exception('Missing properties');

    // Derive the 64-byte combined key from password and salt
    _totalKey = await foundation.compute((message) {
      return _deriveKey(message[0], base16.decode(message[1]));
    }, [_password!, saltString]);
    // Split total key into AES and HMAC keys
    _aesKey = Key(_totalKey!.bytes.sublist(0, keyLength)); // Lower bytes are aes key
    _hmacKey = Key(_totalKey!.bytes.sublist(keyLength)); // Upper bytes are hmac key

    // Verify data access / integrity
    final IV iv = IV(base16.decode(ivString));
    final Uint8List cipherBytes = base64.decode(cipher);

    // Concatenate totalKey + IV + ciphertext for HMAC verification
    final bBuilder = BytesBuilder(copy: false);
    bBuilder.add(_totalKey!.bytes);
    bBuilder.add(iv.bytes);
    bBuilder.add(cipherBytes);

    // Verify HMAC integrity
    final HMac hmac = HMac(SHA256Digest(), 64)..init(KeyParameter(_hmacKey!.bytes));
    final String testHMac = base16.encode(hmac.process(bBuilder.toBytes()));

    if (testHMac != hmacString) {
      throw AppException('Wrong password', debugContext: 'Accessor v1 Decrypt');
    }

    // Decrypt AES-encrypted data asynchronously
    final String decryptedString = await foundation.compute((message) {
      bool newGzipMode = message[3] as bool;
      final AES256CBC decrypter = AES256CBC(padding: newGzipMode ? PaddingMode.pkcs7 : PaddingMode.none);
      final Uint8List decrypted = decrypter.decrypt(cipher: message[0] as Uint8List, key: (message[1] as Key).bytes, iv: message[2] as IV);
      final Uint8List decompressed = newGzipMode ? Uint8List.fromList(gzip.decode(decrypted)) : decrypted;
      return utf8.decode(decompressed);
    }, [cipherBytes, _aesKey, iv, isCompressed]);

    // Extract JSON object from decrypted string
    final start = decryptedString.indexOf('{');
    final end = decryptedString.lastIndexOf('}');

    if (start == -1 || end == -1 || start > end) {
      throw const FormatException('No valid JSON object found in input');
    }

    final jsonStr = decryptedString.substring(start, end + 1);
    final Map<String, dynamic> decoded = json.decode(jsonStr);
    final accountsJson = decoded['accounts'];

    if (accountsJson is! List) {
      throw const FormatException('Expected "accounts" to be a List');
    }

    return DatabaseContent(accounts: accountsJson.map((e) => Account.fromJson(e as Map<String, dynamic>)).toList());
  }

  @override
  Future<Map<String, String>> pack(DatabaseContent dbContent) async {
    if (_password == null) {
      throw Exception('No password was defined in accessor');
    }

    // Serialize accounts as JSON string
    final String serialized = json.encode({'accounts': dbContent.accounts.map((a) => a.toJson()).toList()});

    // Derive keys if not already done
    if (_totalKey == null) {
      _totalKey = await foundation.compute((message) {
        return _deriveKey(message);
      }, _password!);
      _aesKey = Key(_totalKey!.bytes.sublist(0, keyLength)); // Lower bytes are aes key
      _hmacKey = Key(_totalKey!.bytes.sublist(keyLength)); // Upper bytes are hmac key
    }

    // Compute HMAC over key + IV + ciphertext later, so create HMac object now
    final AES256CBC encrypter = AES256CBC(padding: PaddingMode.pkcs7);
    final HMac newHmac = HMac(SHA256Digest(), 64)..init(KeyParameter(_hmacKey!.bytes));
    final IV iv = IV.fromLength(encrypter.blockLength);

    final Uint8List cipherBytes = await foundation.compute((message) {
      final AES256CBC encrypter = AES256CBC(padding: PaddingMode.pkcs7);
      final Uint8List encoded = Uint8List.fromList(gzip.encode(utf8.encode(message[0] as String)));
      return encrypter.encrypt(data: encoded, key: (message[1] as Key).bytes, iv: message[2] as IV);
    }, [serialized, _aesKey, iv]);

    // Prepare bytes for HMAC calculation
    final bBuilder = BytesBuilder(copy: false);
    bBuilder.add(_totalKey!.bytes);
    bBuilder.add(iv.bytes);
    bBuilder.add(cipherBytes);

    final Uint8List newHmacBytes = newHmac.process(bBuilder.toBytes());

    return {
      versionIdentifier: version,
      compressedIdentifier: 'true',
      saltIdentifier: base16.encode(_totalKey!.salt!),
      hmacIdentifier: base16.encode(newHmacBytes),
      ivIdentifier: base16.encode(iv.bytes),
      dataIdentifier: base64.encode(cipherBytes),
    };
  }
}
