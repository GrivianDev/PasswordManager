import 'dart:convert';
import 'dart:typed_data';
import 'package:passwordmanager/engine/cryptography/base16_codec.dart';
import 'package:passwordmanager/engine/cryptography/encryption.dart';
import 'package:passwordmanager/engine/cryptography/service.dart';
import 'package:passwordmanager/engine/cryptography/datatypes.dart';

/// Data formatter used for storing and restoring information of a certain format.
/// Data fields are evaluated if the follow the format: <data identifier>=<some data>;
class DataFormatInterpreter {
  final Encryption _encryption;

  final String _saltIdentifier = 'Salt=';
  final String _hMacIdentifier = 'HMac=';
  final String _ivIdentifier = 'IV=';
  final String _dataIdentifier = 'Data=';
  final String _delimiter = ';';

  /// Constructor defining the encryption algorithm used for this instance.
  const DataFormatInterpreter(Encryption encryption) : _encryption = encryption;

  /// Method for interpreting data before the 2.0.0 update, in order to maintain some backwards compatibility.
  /// Does not return the unsave key. Instead returns the safer version.
  /// Note: No create formatted data method is available for legacy mode since it is considerably more unsave.
  InterpretionResult legacyInterpretDataWithPassword(String data, String password) {
    if(data.contains(_delimiter)) throw Exception('Data is not in legacy format');
    final Key legacyKey = Key(CryptographicService.sha256(utf8.encode(password)));
    final Key key = CryptographicService.createAES256Key(password: password);

    final Uint8List cipher = CryptographicService.expand(base64.decode(data), _encryption.blockLength, max: 0x00);

    final Uint8List presumedData = _encryption.decrypt(cipher: cipher, key: legacyKey, iv: IV.allZero(_encryption.blockLength));

    return InterpretionResult(key, utf8.decode(presumedData, allowMalformed: true));
  }

  /// Use the underling encryption to interpret the entire data string. May throw an Exception if a needed parameter field was not found.
  /// Uses the stored HMAC value to verify a decryption success.
  InterpretionResult interpretDataWithPassword(String data, String password) {
    String? salt = _getProperty(_saltIdentifier, data);
    String? hmac = _getProperty(_hMacIdentifier, data);
    String? iv = _getProperty(_ivIdentifier, data);
    String? cipher = _getProperty(_dataIdentifier, data);

    if(salt == null || hmac == null || iv == null || cipher == null) throw Exception('Missing propertys');

    final Key key = CryptographicService.recreateAES256Key(password: password, salt: base16.decode(salt));

    final Uint8List presumedData = _encryption.decrypt(cipher: base64.decode(cipher), key: key, iv: IV(base16.decode(iv)));

    final String testHMac = base16.encode(CryptographicService.verificationCodeFrom(key, presumedData));

    if(hmac == testHMac) {
      return InterpretionResult(key, utf8.decode(presumedData, allowMalformed: true));
    }
    throw Exception('Wrong password');
  }

  /// Fits given data in simple format. Values that are formatted are the cipher, hmac, iv and salt values.
  InterpretionResult createFormattedDataWithKey(String data, Key key) {
    final Uint8List rawData = CryptographicService.expandWithValues(utf8.encode(data), _encryption.blockLength, 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890'.codeUnits);
    final Uint8List newHMac = CryptographicService.verificationCodeFrom(key, rawData);
    final IV iv = IV.fromLength(_encryption.blockLength);
    final Uint8List cipher = _encryption.encrypt(data: rawData, key: key, iv: iv);

    StringBuffer buffer = StringBuffer();
    buffer.write('$_saltIdentifier${base16.encode(key.salt!)}$_delimiter');
    buffer.write('$_hMacIdentifier${base16.encode(newHMac)}$_delimiter');
    buffer.write('$_ivIdentifier${base16.encode(iv.bytes)}$_delimiter');
    buffer.write('$_dataIdentifier${base64.encode(cipher)}$_delimiter');

    return InterpretionResult(key, buffer.toString());
  }

  /// Searches a data field inside the string. In case "<data identifier>=<some data>;" is found then
  /// "<some data>" is returned.
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