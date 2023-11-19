import 'dart:convert';
import 'dart:typed_data';
import 'package:passwordmanager/engine/cryptography/base16_codec.dart';
import 'package:passwordmanager/engine/cryptography/encryption.dart';
import 'package:passwordmanager/engine/cryptography/service.dart';
import 'package:passwordmanager/engine/cryptography/datatypes.dart';

class DataFormatInterpreter {
  final Encryption _encryption;

  final String _saltIdentifier = 'Salt=';
  final String _hMacIdentifier = 'HMac=';
  final String _ivIdentifier = 'IV=';
  final String _dataIdentifier = 'Data=';
  final String _delimiter = ';';

  const DataFormatInterpreter(Encryption encryption) : _encryption = encryption;

  InterpretionResult legacyInterpretDataWithPassword(String data, String password) {
    if(data.contains(_delimiter)) throw Exception('Data is not in legacy format');
    final Key legacyKey = Key(CryptograhicService.sha256(utf8.encode(password)), null);
    final Key key = CryptograhicService.createAES256Key(password: password);

    final Uint8List presumedData = _encryption.decrypt(cipher: base64.decode(data), key: legacyKey, iv: IV.allZero(_encryption.blockLength));

    return InterpretionResult(key, utf8.decode(presumedData, allowMalformed: true));
  }

  InterpretionResult interpretDataWithPassword(String data, String password) {
    String? salt = _getProperty(_saltIdentifier, data);
    String? hmac = _getProperty(_hMacIdentifier, data);
    String? iv = _getProperty(_ivIdentifier, data);
    String? cipher = _getProperty(_dataIdentifier, data);

    if(salt == null || hmac == null || iv == null || cipher == null) throw Exception('Missing propertys');

    final Key key = CryptograhicService.recreateAES256Key(password: password, salt: base16.decode(salt));

    final Uint8List presumedData = _encryption.decrypt(cipher: base64.decode(cipher), key: key, iv: IV(base16.decode(iv)));

    final String testHMac = base16.encode(CryptograhicService.verificationCodeFrom(key, presumedData));

    if(hmac == testHMac) {
      return InterpretionResult(key, utf8.decode(presumedData, allowMalformed: true));
    }
    throw Exception('Wrong password');
  }

  InterpretionResult createFormattedDataWithKey(String data, Key key) {
    final Uint8List rawData = CryptograhicService.expand(utf8.encode(data), _encryption.blockLength);
    final Uint8List newHMac = CryptograhicService.verificationCodeFrom(key, rawData);
    final IV iv = IV.fromLength(_encryption.blockLength);
    final Uint8List cipher = _encryption.encrypt(data: rawData, key: key, iv: iv);

    StringBuffer buffer = StringBuffer();
    buffer.write('$_saltIdentifier${base16.encode(key.salt!)}$_delimiter');
    buffer.write('$_hMacIdentifier${base16.encode(newHMac)}$_delimiter');
    buffer.write('$_ivIdentifier${base16.encode(iv.bytes)}$_delimiter');
    buffer.write('$_dataIdentifier${base64.encode(cipher)}$_delimiter');

    return InterpretionResult(key, buffer.toString());
  }

  String? _getProperty(String identifier, String data) {
    int start = data.indexOf(identifier);
    if(start == -1) return null;
    start += identifier.length;
    int end = data.indexOf(_delimiter, start);
    if(end == -1) return null;
    return data.substring(start, end);
  }
}

class InterpretionResult {
  final Key key;
  final String data;

  const InterpretionResult(this.key, this.data);
}