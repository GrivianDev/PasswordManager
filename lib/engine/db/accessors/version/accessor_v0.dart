import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' as foundation;
import 'package:passwordmanager/engine/db/accessors/accessor.dart';
import 'package:passwordmanager/engine/cryptography/implementation/aes_encryption.dart';
import 'package:passwordmanager/engine/db/local_database.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/digests/sha256.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:pointycastle/key_derivators/pbkdf2.dart';
import 'package:pointycastle/macs/hmac.dart';
import 'package:passwordmanager/engine/account.dart';
import 'package:passwordmanager/engine/cryptography/datatypes.dart';
import 'package:passwordmanager/engine/cryptography/service.dart';
import 'package:passwordmanager/engine/cryptography/base16_codec.dart';

class DataAccessorV0 implements DataAccessor {
  static const String saltIdentifier = 'Salt';
  static const String ivIdentifier = 'IV';
  static const String hmacIdentifier = 'HMac';
  static const String dataIdentifier = 'Data';

  static const int pbkdf2Iterations = 4096;
  static const int keyLength = 32;
  static const int saltLength = 32;

  Key? _key;

  @override
  String get version => "v0";

  static Key _deriveKey(String password, [Uint8List? salt]) {
    final usedSalt = salt ?? CryptographicService.randomBytes(saltLength);
    final Pbkdf2Parameters params = Pbkdf2Parameters(usedSalt, pbkdf2Iterations, keyLength);
    final PBKDF2KeyDerivator pbkdf2 = PBKDF2KeyDerivator(HMac(SHA256Digest(), 64));
    pbkdf2.init(params);

    final Uint8List keyBytes = pbkdf2.process(utf8.encode(password));
    return Key(keyBytes, usedSalt);
  }

  @override
  Future<void> loadAndDecrypt(LocalDatabase targetDatabase, Map<String, String> properties, String password) async {
    final String? saltString = properties[saltIdentifier];
    final String? ivString = properties[ivIdentifier];
    final String? hmacString = properties[hmacIdentifier];
    final String? cipher = properties[dataIdentifier];

    if (saltString == null || hmacString == null || ivString == null || cipher == null) throw Exception('Missing properties');

    // Recreate key
    _key = await foundation.compute((message) {
      return _deriveKey(message[0], base16.decode(message[1]));
    }, [password, saltString]);

    // Decrypt
    final Uint8List presumedData = await foundation.compute((message) {
      final AES256 decrypter = AES256();
      return decrypter.decrypt(cipher: base64.decode(message[0]), key: _key!.bytes, iv: IV(base16.decode(message[1])));
    }, [cipher, ivString]);

    // Check HMAC
    final HMac hmac = HMac(SHA256Digest(), 64)..init(KeyParameter(_key!.bytes));
    final String testHMac = base16.encode(hmac.process(presumedData));

    if (testHMac != hmacString) {
      throw Exception('Wrong password');
    }

    final String decryptedString = utf8.decode(presumedData, allowMalformed: true);

    // Push data into database (Uses old regex read format)
    const String c = LocalDatabase.disallowedCharacter;

    List<List<String>> foundAccounts = [];
    RegExp regex = RegExp('\\$c([^\\$c]+\\$c){5}');
    Iterable<Match> matches = regex.allMatches(decryptedString);
    for (Match match in matches) {
      List<String>? parts = match.group(0)?.split(c);
      if (parts != null) {
        parts.retainWhere((element) => element.isNotEmpty);
        foundAccounts.add(parts);
      }
    }

    targetDatabase.addAllAccounts(
      foundAccounts
          .map((parts) => Account(
                tag: parts[0],
                name: parts[1],
                info: parts[2],
                email: parts[3],
                password: parts[4],
              ))
          .toList(),
    );
  }

  @override
  Future<String> encryptAndFormat(LocalDatabase sourceDatabase, [String? password]) async {
    // Create data string
    const String chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random rand = Random.secure();
    StringBuffer buffer = StringBuffer();
    int length = rand.nextInt(10) + 1;
    for (int j = 0; j < length; j++) {
      buffer.write(String.fromCharCode(chars.codeUnitAt(rand.nextInt(chars.length))));
    }

    const String c = LocalDatabase.disallowedCharacter;
    for (Account acc in sourceDatabase.accounts) {
      buffer.write('$c${acc.tag}$c${acc.name}$c${acc.info}$c${acc.email}$c${acc.password}$c');
      length = rand.nextInt(10) + 1;
      for (int j = 0; j < length; j++) {
        buffer.write(String.fromCharCode(chars.codeUnitAt(rand.nextInt(chars.length))));
      }
    }

    final AES256 encrypter = AES256();
    final Uint8List expandedData = CryptographicService.expandWithValues(utf8.encode(buffer.toString()), encrypter.blockLength, chars.codeUnits);

    if (_key == null && password == null) {
      throw Exception('Can not encrypt data wihout a key, if initializing a new source then the password was missing');
    }

    if (password != null) {
      // Initialize new source
      _key = await foundation.compute((message) {
        return _deriveKey(message);
      }, password);
    }

    // Encrypt data
    final HMac newHmac = HMac(SHA256Digest(), 64)..init(KeyParameter(_key!.bytes));
    final Uint8List newHmacBytes = newHmac.process(expandedData);
    final IV iv = IV.fromLength(encrypter.blockLength); // New IV for each encryption

    final Uint8List cipher = await foundation.compute((message) {
      final AES256 encrypter = AES256();
      return encrypter.encrypt(data: message[0] as Uint8List, key: (message[1] as Key).bytes, iv: message[2] as IV);
    }, [expandedData, _key, iv]);

    // Write out formatted properties
    StringBuffer outBuffer = StringBuffer();
    outBuffer.write('version=$version;');
    outBuffer.write('$saltIdentifier=${base16.encode(_key!.salt!)};');
    outBuffer.write('$hmacIdentifier=${base16.encode(newHmacBytes)};');
    outBuffer.write('$ivIdentifier=${base16.encode(iv.bytes)};');
    outBuffer.write('$dataIdentifier=${base64.encode(cipher)};');

    return outBuffer.toString();
  }
}
