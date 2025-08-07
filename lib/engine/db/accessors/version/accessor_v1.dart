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

class DataAccessorV1 implements DataAccessor {
  static const String saltIdentifier = 'Salt';
  static const String ivIdentifier = 'IV';
  static const String hmacIdentifier = 'HMac';
  static const String dataIdentifier = 'Data';

  static const int pbkdf2Iterations = 4096;
  static const int keyLength = 32;
  static const int saltLength = 32;

  String? _password;
  Key? _totalKey;
  Key? _aesKey;
  Key? _hmacKey;

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

    _totalKey = await foundation.compute((message) {
      return _deriveKey(message[0], base16.decode(message[1]));
    }, [_password!, saltString]);
    _aesKey = Key(_totalKey!.bytes.sublist(0, keyLength)); // Lower bytes are aes key
    _hmacKey = Key(_totalKey!.bytes.sublist(keyLength)); // Upper bytes are hmac key

    // Verify data access / integrity
    final IV iv = IV(base16.decode(ivString));
    final Uint8List cipherBytes = base64.decode(cipher);

    final bBuilder = BytesBuilder(copy: false);
    bBuilder.add(_totalKey!.bytes);
    bBuilder.add(iv.bytes);
    bBuilder.add(cipherBytes);

    // Check HMAC
    final HMac hmac = HMac(SHA256Digest(), 64)..init(KeyParameter(_hmacKey!.bytes));
    final String testHMac = base16.encode(hmac.process(bBuilder.toBytes()));

    if (testHMac != hmacString) {
      throw Exception('Wrong password');
    }

    // Decrypt
    final String decryptedString = await foundation.compute((message) {
      final AES256 decrypter = AES256();
      return utf8.decode(decrypter.decrypt(cipher: message[0] as Uint8List, key: (message[1] as Key).bytes, iv: message[2] as IV),
          allowMalformed: true);
    }, [cipherBytes, _aesKey, iv]);

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
    buffer.write(jsonEncode({"accounts": sourceDatabase.accounts.map((a) => a.toJson()).toList()}));
    length = rand.nextInt(10) + 1;
    for (int j = 0; j < length; j++) {
      buffer.write(String.fromCharCode(chars.codeUnitAt(rand.nextInt(chars.length))));
    }

    if (_totalKey == null) {
      _totalKey = await foundation.compute((message) {
        return _deriveKey(message);
      }, _password!);
      _aesKey = Key(_totalKey!.bytes.sublist(0, keyLength)); // Lower bytes are aes key
      _hmacKey = Key(_totalKey!.bytes.sublist(keyLength)); // Upper bytes are hmac key
    }

    final AES256 encrypter = AES256();
    final Uint8List expandedData = CryptographicService.expandWithValues(utf8.encode(buffer.toString()), encrypter.blockLength, chars.codeUnits);
    final HMac newHmac = HMac(SHA256Digest(), 64)..init(KeyParameter(_hmacKey!.bytes));
    final IV iv = IV.fromLength(encrypter.blockLength);

    final Uint8List cipherBytes = await foundation.compute((message) {
      final AES256 encrypter = AES256();
      return encrypter.encrypt(data: message[0] as Uint8List, key: (message[1] as Key).bytes, iv: message[2] as IV);
    }, [expandedData, _aesKey, iv]);

    final bBuilder = BytesBuilder(copy: false);
    bBuilder.add(_totalKey!.bytes);
    bBuilder.add(iv.bytes);
    bBuilder.add(cipherBytes);

    final Uint8List newHmacBytes = newHmac.process(bBuilder.toBytes());

    StringBuffer outBuffer = StringBuffer();
    outBuffer.write('version=$version;');
    outBuffer.write('$saltIdentifier=${base16.encode(_totalKey!.salt!)};');
    outBuffer.write('$hmacIdentifier=${base16.encode(newHmacBytes)};');
    outBuffer.write('$ivIdentifier=${base16.encode(iv.bytes)};');
    outBuffer.write('$dataIdentifier=${base64.encode(cipherBytes)};');

    return outBuffer.toString();
  }
}
