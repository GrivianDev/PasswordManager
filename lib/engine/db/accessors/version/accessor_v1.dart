import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' as foundation;
import 'package:passwordmanager/engine/db/accessors/accessor.dart';
import 'package:passwordmanager/engine/db/local_database.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:passwordmanager/engine/account.dart';
import 'package:passwordmanager/engine/cryptography/base16_codec.dart';
import 'package:passwordmanager/engine/cryptography/datatypes.dart';
import 'package:passwordmanager/engine/cryptography/implementation/aes_encryption.dart';
import 'package:passwordmanager/engine/cryptography/service.dart';

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
class DataAccessorV1 implements DataAccessor {
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
  String get version => "v1";

  @override
  void definePassword(String password) {
    _password = password;

    // Reset cached keys
    _totalKey = null;
    _aesKey = null;
    _hmacKey = null;
  }

  @override
  Future<void> loadAndDecrypt(LocalDatabase targetDatabase, Map<String, String> properties) async {
    if (_password == null) {
      throw Exception("No password was defined in accessor");
    }

    final String? saltString = properties[saltIdentifier];
    final String? ivString = properties[ivIdentifier];
    final String? hmacString = properties[hmacIdentifier];
    final String? cipher = properties[dataIdentifier];

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
      throw Exception('Wrong password');
    }

    // Decrypt AES-encrypted data asynchronously
    final String decryptedString = await foundation.compute((message) {
      final AES256 decrypter = AES256();
      return utf8.decode(decrypter.decrypt(cipher: message[0] as Uint8List, key: (message[1] as Key).bytes, iv: message[2] as IV),
          allowMalformed: true);
    }, [cipherBytes, _aesKey, iv]);

    // Extract JSON object from decrypted string
    final start = decryptedString.indexOf('{');
    final end = decryptedString.lastIndexOf('}');

    if (start == -1 || end == -1 || start > end) {
      throw const FormatException('No valid JSON object found in input');
    }

    final jsonStr = decryptedString.substring(start, end + 1);
    final Map<String, dynamic> decoded = jsonDecode(jsonStr);
    final accountsJson = decoded['accounts'];

    if (accountsJson is! List) {
      throw const FormatException('Expected "accounts" to be a List');
    }

    // Populate database with decrypted accounts
    targetDatabase.addAllAccounts(accountsJson.map((e) => Account.fromJson(e as Map<String, dynamic>)).toList());
  }

  @override
  Future<String> encryptAndFormat(LocalDatabase sourceDatabase) async {
    if (_password == null) {
      throw Exception("No password was defined in accessor");
    }

    // Create data string
    const String chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random rand = Random.secure();
    StringBuffer buffer = StringBuffer();
    int length = rand.nextInt(10) + 1;
    for (int j = 0; j < length; j++) {
      buffer.write(String.fromCharCode(chars.codeUnitAt(rand.nextInt(chars.length))));
    }
    // Serialize accounts as JSON string
    buffer.write(jsonEncode({"accounts": sourceDatabase.accounts.map((a) => a.toJson()).toList()}));
    length = rand.nextInt(10) + 1;
    for (int j = 0; j < length; j++) {
      buffer.write(String.fromCharCode(chars.codeUnitAt(rand.nextInt(chars.length))));
    }

    // Derive keys if not already done
    if (_totalKey == null) {
      _totalKey = await foundation.compute((message) {
        return _deriveKey(message);
      }, _password!);
      _aesKey = Key(_totalKey!.bytes.sublist(0, keyLength)); // Lower bytes are aes key
      _hmacKey = Key(_totalKey!.bytes.sublist(keyLength)); // Upper bytes are hmac key
    }

    final AES256 encrypter = AES256();
    // Expand data to block-aligned length with allowed characters
    final Uint8List expandedData = CryptographicService.expandWithValues(utf8.encode(buffer.toString()), encrypter.blockLength, chars.codeUnits);

    // Compute HMAC over key + IV + ciphertext later, so create HMac object now
    final HMac newHmac = HMac(SHA256Digest(), 64)..init(KeyParameter(_hmacKey!.bytes));
    final IV iv = IV.fromLength(encrypter.blockLength);

    final Uint8List cipherBytes = await foundation.compute((message) {
      final AES256 encrypter = AES256();
      return encrypter.encrypt(data: message[0] as Uint8List, key: (message[1] as Key).bytes, iv: message[2] as IV);
    }, [expandedData, _aesKey, iv]);

    // Prepare bytes for HMAC calculation
    final bBuilder = BytesBuilder(copy: false);
    bBuilder.add(_totalKey!.bytes);
    bBuilder.add(iv.bytes);
    bBuilder.add(cipherBytes);

    final Uint8List newHmacBytes = newHmac.process(bBuilder.toBytes());

    // Format the encrypted data and metadata as key=value; pairs
    StringBuffer outBuffer = StringBuffer();
    outBuffer.write('version=$version;');
    outBuffer.write('$saltIdentifier=${base16.encode(_totalKey!.salt!)};');
    outBuffer.write('$hmacIdentifier=${base16.encode(newHmacBytes)};');
    outBuffer.write('$ivIdentifier=${base16.encode(iv.bytes)};');
    outBuffer.write('$dataIdentifier=${base64.encode(cipherBytes)};');

    return outBuffer.toString();
  }
}
