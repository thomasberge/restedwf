// Rested v0.1.0-alpha
// www.restedwf.com
// © 2020 Thomas Sebastian Berge

import 'dart:io';
import 'package:encrypt/encrypt.dart';
import 'dart:convert';
import 'restedsettings.dart';

class RestedCookie {
  Map _data = new Map<String, String>();

  RestedCookie(String key, List<Cookie> cookies) {
    if (cookies != '[]') {
      for(Cookie cookie in cookies) {
        if(cookie.name == 'data') {
          String data = decrypt(key, cookie.value);
          if(data != null) {
            _data = json.decode(data);
          }
        }
      }
    }
  }

  bool containsKey(String key) {
    return _data.containsKey(key);
  }

  String getKey(String key) {
    if (_data.containsKey(key)) {
      return _data[key];
    } else {
      return null;
    }
  }

  String toString() {
    return _data.toString();
  }

  void setKey(String key, String value) {
    _data[key] = value;
  }

  Cookie remove() {
    Cookie nullcookie = new Cookie("data", "");
    nullcookie.maxAge = 0;
    return nullcookie;
  }

  String decrypt(String encryption_key, String tokendata) {
    //String tokendata = json.encode(_data).toString();
    final key = Key.fromUtf8(encryption_key);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    //final encrypted = encrypter.encrypt(tokendata, iv: iv);
    //final decrypted = encrypter.decrypt(encrypted, iv : iv);
    final decrypted = encrypter.decrypt64(tokendata, iv: iv);
    return decrypted;
  }

  Cookie create(String encryption_key, int max_age) {
    String tokendata = json.encode(_data).toString();
    final key = Key.fromUtf8(encryption_key);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(tokendata, iv: iv);

    Cookie newcookie = new Cookie("data", encrypted.base64);

    if (max_age != 0) {
      newcookie.maxAge = max_age * 60;
    }
    return newcookie;
  }
}