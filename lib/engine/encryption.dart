import 'dart:math';

import 'package:encrypt/encrypt.dart';
import 'package:passwordmanager/engine/account.dart';
import 'package:passwordmanager/engine/manager.dart';

class Encryption {
  static String encrypt(String plainText, String password) {
    password = _inflatePassword(password);
    Encrypter crypt = Encrypter(AES(Key.fromUtf8(password)));
    Encrypted encrypted = crypt.encrypt(plainText, iv: IV.fromLength(16));
    return encrypted.base64;
  }

  static String decrypt(String encryptedText, String password) {
    password = _inflatePassword(password);
    Encrypter crypt = Encrypter(AES(Key.fromUtf8(password)));
    String decrypted = crypt.decrypt64(encryptedText, iv: IV.fromLength(16));
    return decrypted;
  }

  static List<Account> getAccountsFromString(String string) {
    String c = Manager.disallowedCharacter;
    String test = 'jkhvjmdnccjskd${c}Name1${c}Tag${c}Info${c}Email${c}Pw${c}dgfdgdgdgddggdds${c}Name2${c}Tag${c}Info${c}Email${c}pw${c}fdsvsfsfdd';

    List<Account> accounts = List.empty(growable: true);
    RegExp regex = RegExp('\\${Manager.disallowedCharacter}([^\\${Manager.disallowedCharacter}]+\\${Manager.disallowedCharacter}){5}');
    Iterable<Match> matches = regex.allMatches(test);
    print('Found ${matches.length} matches');
    for(Match match in matches) {
      print(match.group(0));
    }
    return accounts;
  }

  static String generateStringFromAccounts(List<Account> accounts) {
    const chars = 'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random rand = Random.secure();
    String string = '';
    for(int i = 0; i < accounts.length; i++) {
      int length = rand.nextInt(64) + 1;
      for(int j = 0; j < accounts.length; j++) {
        string += String.fromCharCode(chars.codeUnitAt(rand.nextInt(chars.length)));
      }
      string += accounts.elementAt(i).toString();
    }
    return string;
  }

  static String _inflatePassword(String password) {
    String hash = password.hashCode.toString();
    int missing = 32 - password.length;
    while(hash.length < missing) {
      hash += hash;
    }
    if(missing > 0) {
      password += hash.substring(0, missing);
    }
    print('Password: $password | length: ${password.length}');
    return password;
  }
}