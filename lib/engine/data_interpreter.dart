import 'dart:convert';
import 'dart:typed_data';
import 'package:passwordmanager/engine/cryptography/base16_codec.dart';
import 'package:passwordmanager/engine/cryptography/service.dart';
import 'package:passwordmanager/engine/cryptography/datatypes.dart';
import 'package:passwordmanager/engine/cryptography/encryption.dart';

class DataFormatInterpreter {
  static const int desiredBlockLength = 16;
  static const int desiredKeyLength = 32;

  final _saltIdentifier = 'Salt=';
  final _hMacIdentifier = 'HMac=';
  final _ivIdentifier = 'IV=';
  final _dataIdentifier = 'Data=';
  final _delimiter = ';';

  InterpretionResult legacyInterpretDataWithPassword(String data, String password) {
    final Key legacyKey = Key(CryptograhicService.sha256(utf8.encode(password)), null);
    final Key key = CryptograhicService.createAES256Key(password: password);

    final Uint8List presumedData = EncryptionProvider.encryption.decrypt(cipher: base64.decode(data), key: legacyKey, iv: IV.allZero(DataFormatInterpreter.desiredBlockLength));

    return InterpretionResult(key, utf8.decode(presumedData, allowMalformed: true));
  }

  InterpretionResult interpretDataWithPassword(String data, String password) {
    String? salt = _getProperty(_saltIdentifier, data);
    String? hmac = _getProperty(_hMacIdentifier, data);
    String? iv = _getProperty(_ivIdentifier, data);
    String? cipher = _getProperty(_dataIdentifier, data);

    if(salt == null || hmac == null || iv == null || cipher == null) throw Exception('Missing propertys');

    final Key key = CryptograhicService.recreateAES256Key(password: password, salt: base16.decode(salt));

    final Uint8List presumedData = EncryptionProvider.encryption.decrypt(cipher: base64.decode(cipher), key: key, iv: IV(base16.decode(iv)));

    final String testHMac = base16.encode(CryptograhicService.verificationCodeFrom(key, presumedData));

    if(hmac == testHMac) {
      return InterpretionResult(key, utf8.decode(presumedData, allowMalformed: true));
    }
    throw Exception('Wrong password');
  }

  InterpretionResult createFormattedDataWithKey(String data, Key key) {
    final Uint8List rawData = CryptograhicService.expand(utf8.encode(data), desiredBlockLength);
    final Uint8List newHMac = CryptograhicService.verificationCodeFrom(key, rawData);
    final IV iv = IV.fromLength(desiredBlockLength);
    final Uint8List cipher = EncryptionProvider.encryption.encrypt(data: rawData, key: key, iv: iv);

    StringBuffer buffer = StringBuffer();
    buffer.write('$_saltIdentifier${base16.encode(key.salt!)}$_delimiter');
    buffer.write('$_hMacIdentifier${base16.encode(newHMac)}$_delimiter');
    buffer.write('$_ivIdentifier${base16.encode(iv.bytes)}$_delimiter');
    buffer.write('$_dataIdentifier${base64.encode(cipher)}$_delimiter');

    return InterpretionResult(key, buffer.toString());
  }

  String? _getProperty(String identifier, String data) {
    int start = data.indexOf(identifier);
    start += identifier.length;
    int end = data.indexOf(_delimiter, start);
    return data.substring(start, end);
  }
}

class InterpretionResult {
  final Key key;
  final String data;

  const InterpretionResult(this.key, this.data);
}