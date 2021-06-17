// Part of Rested Web Framework
// www.restedwf.com
// © 2020 Thomas Sebastian Berge

import 'dart:io';
import 'package:encrypt/encrypt.dart';
import 'package:nanoid/nanoid.dart';
import 'dart:convert';
import 'restedsettings.dart';
import 'dart:math';

// New, simpler manager. Easier to migrate to Redis later.
class SessionManager {
  RestedSettings rsettings = null;
  //int idpool = 0;
  Map<String, Map<String, dynamic>> sessions = new Map();

  SessionManager(){
    rsettings = new RestedSettings();
  }

  void printSessions() {
    print("--- SESSIONS ---");
    print(sessions.toString());
    print("--- END ---");
  }

  // Takes whatever is stored in RestedRequest.session and creates a new session.
  String newSession(Map<String, dynamic> data) {
    try {
      //String sessionid = idpool.toString();
      //idpool = idpool + 1;
      //String encrypted_sessionid = encrypt(sessionid);
      //data['id'] = encrypted_sessionid;
      data['id'] = nanoid(32);
      sessions[data['id']] = data;
      return data['id'];
    } catch(e) {
      print(e.toString());
      return null;
    }
  }

  void updateSession(Map<String, dynamic> data) {
    try {
      if(sessions.containsKey(data['id'])) {
        sessions[data['id']] = data;
      }
    } catch(e) {
      print(e.toString());
    }
  }

  void deleteSession(String sessionid) {
    try {
      if(sessions.containsKey(sessionid)) {
        sessions.remove(sessionid);
      }
    } catch(e) {
      print(e.toString());
    }
  }

  void setValue(String sessionid, String key, String value) {
    try {
      if(sessions.containsKey(sessionid)) {
        sessions[sessionid][key] = value;
      }
    } catch(e) {
      print(e.toString());
    }
  }

  String getValue(String sessionid, String key) {
    try {
      if(sessions.containsKey(sessionid)) {
        return sessions[sessionid][key];
      } else {
        return null;
      }
    } catch(e) {
      print(e.toString());
      return null;
    }
  }

  void deleteKey(String sessionid, String key) {
    try {
      if(sessions.containsKey(sessionid)) {
        sessions[sessionid].remove(key);
      }
    } catch(e) {
      print(e.toString());
    }
  }

  Map<String, dynamic> getSession(String sessionid) {
    try {
      if(sessions.containsKey(sessionid)) {
        return sessions[sessionid];
      }
    } catch(e) {
      print(e.toString());
      return null;
    }
  }
  /*
  // Encrypts the argument data using AES128 with session_cookie_key from RestedSettings and
  // returns the base64 representation of the encryption.
  String encrypt(String data) {
    try {
      String keySTR = "16 characters16 characters"; //16 byte
      String ivSTR = "16 characters16 characters"; //16 byte
      final key = Key.fromUtf8(keySTR);
      final iv = IV.fromUtf8(ivSTR);      
      //final iv = IV.fromBase64("8PzGKSMLuqSm0MVf");
      //print("rsettings.session_cookie_key=" + rsettings.session_cookie_key);
      //print("encrypting " + data);
      //final key = Key.fromUtf8(rsettings.session_cookie_key);
      //final iv = IV.fromBase64("8PzGKSMLuqSm0MVf");//IV.fromLength(16);
      //final encrypter = Encrypter(AES(key));
      final encrypter = Encrypter(AES(key,mode: AESMode.cbc,padding: 'PKCS7'));
      final encrypted = encrypter.encrypt(data, iv: iv);
      return encrypted.base64;
    } catch(e) {
      print(e.toString());
      return null;
    }
  }

  // Decrypts the argument base 64 AES128 encoded data and returns the decrypted string.
  String decrypt(String data) {
    try {
      String keySTR = "16 characters"; //16 byte
      String ivSTR = "16 characters"; //16 byte
      final key = Key.fromUtf8(keySTR);
      final iv = IV.fromUtf8(ivSTR);
      //final key = Key.fromUtf8(rsettings.session_cookie_key);
      //final iv = IV.fromLength(16);
      //final iv = IV.fromBase64("8PzGKSMLuqSm0MVf");//IV.fromLength(16);
      //final encrypter = Encrypter(AES(key));
      final encrypter = Encrypter(AES(key,mode: AESMode.cbc,padding: 'PKCS7'));
      final decrypted = encrypter.decrypt64(data, iv: iv);
      return decrypted;
    } catch(e) {
      print(e.toString());
      return null;
    }
  }  
  */
}