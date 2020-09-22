// Part of Rested Web Framework
// www.restedwf.com
// © 2020 Thomas Sebastian Berge

import 'dart:io';
import 'package:encrypt/encrypt.dart';
import 'dart:convert';
import 'restedsettings.dart';
import 'dart:math';

class RestedSessionManager {
  Map<String, RestedSession> sessions;
  RestedSettings rsettings = null;

  bool containsKey(String key) {
    return sessions.containsKey(key);
  }

  Cookie getSessionCookie(String id) {
    return sessions[id].getSessionCookie();
  }

  void updateSession(Map<String, dynamic> session) {
    sessions[session['id']] = RestedSession(session['id'], session);
  }

  String decryptSessionId(String encrypted_session_id) {
    try {
      final key = Key.fromUtf8(rsettings.session_cookie_key);
      final iv = IV.fromLength(16);
      final encrypter = Encrypter(AES(key));
      final decrypted = encrypter.decrypt64(encrypted_session_id, iv: iv);
      return decrypted;
    } catch(e) {
      return null;
    }
  }

  String encryptSessionid(String session_id) {
    final key = Key.fromUtf8(rsettings.session_cookie_key);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(session_id, iv: iv);
    return encrypted.base64;
  }

  RestedSessionManager() {
    rsettings = new RestedSettings();
    sessions = new Map();
  }

  String createSession(Map<String, dynamic> session) {
    String id = _randomString(16);
    session['id'] = id;
    sessions[id] = new RestedSession(id, session);
    return id;
  }

  void saveSession(RestedSession session) {
    sessions[session.data['id']] = session;
  }

  Map getSessionData(String session_id) {
    RestedSession session = sessions[session_id];
    // --> implement security checks here later <--
    return session.data;
  }

  RestedSession getSession(String session_cookie) {
    String key = decrypt(rsettings.session_cookie_key, session_cookie);
    if(sessions.containsKey(key)) {
      return sessions[key];
    } else {
      return null;
    }
  }

  String _randomString(int length) {
    var rand = new Random();
    var codeUnits = new List.generate(length, (index) {
      return rand.nextInt(33) + 89;
    });

    return new String.fromCharCodes(codeUnits);
  }

  String decrypt(String encryption_key, String session_cookie) {
    final key = Key.fromUtf8(encryption_key);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    final decrypted = encrypter.decrypt64(session_cookie, iv: iv);
    return decrypted;
  }  
}

class RestedSession {
  RestedSettings rsettings = null;
  Map<String, dynamic> data;

  RestedSession(String id, this.data) {
    rsettings = new RestedSettings();
    data['id'] = id;
    data['age'] = new DateTime.now().millisecondsSinceEpoch / 1000;
  }

  bool containsKey(String key) {
    return data.containsKey(key);
  }

  String getKey(String key) {
    if (data.containsKey(key)) {
      return data[key];
    } else {
      return null;
    }
  }

  String toString() {
    return data.toString();
  }

  void setKey(String key, String value) {
    data[key] = value;
  }

  void removeKey(String key) {
    data.remove(key);
  }

  Cookie getSessionCookie() {
    final key = Key.fromUtf8(rsettings.session_cookie_key);
    final iv = IV.fromLength(16);
    final encrypter = Encrypter(AES(key));
    final encrypted = encrypter.encrypt(data['id'], iv: iv);

    Cookie newcookie = new Cookie("session_cookie", encrypted.base64);

    if (rsettings.cookies_max_age != 0) {
      newcookie.maxAge = rsettings.cookies_max_age * 60;
    }
    return newcookie;
  }
}