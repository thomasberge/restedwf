// Part of Rested Web Framework
// www.restedwf.com
// © 2021 Thomas Sebastian Berge

import 'dart:io';
import 'package:nanoid/nanoid.dart';
import 'dart:convert';
import 'restedsettings.dart';
import 'dart:math';
import 'consolemessages.dart';

// New, simpler manager. Easier to migrate to Redis later.
class SessionManager {
  Map<String, Map<String, dynamic>> sessions = new Map();

  SessionManager();

  void printSessions() {
    console.debug("--- SESSIONS ---");
    console.debug(sessions.toString());
    console.debug("--- END ---");
  }

  // Takes whatever is stored in RestedRequest.session and creates a new session.
  String newSession(Map<String, dynamic> data) {
    try {
      data['id'] = nanoid(32);
      sessions[data['id']] = data;
      return data['id'];
    } catch(e) {
      console.error(e.toString());
      return null;
    }
  }

  void updateSession(Map<String, dynamic> data) {
    try {
      if(sessions.containsKey(data['id'])) {
        sessions[data['id']] = data;
      }
    } catch(e) {
      console.error(e.toString());
    }
  }

  void deleteSession(String sessionid) {
    try {
      if(sessions.containsKey(sessionid)) {
        sessions.remove(sessionid);
      }
    } catch(e) {
      console.error(e.toString());
    }
  }

  void setValue(String sessionid, String key, String value) {
    try {
      if(sessions.containsKey(sessionid)) {
        sessions[sessionid][key] = value;
      }
    } catch(e) {
      console.error(e.toString());
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
      console.error(e.toString());
      return null;
    }
  }

  void deleteKey(String sessionid, String key) {
    try {
      if(sessions.containsKey(sessionid)) {
        sessions[sessionid].remove(key);
      }
    } catch(e) {
      console.error(e.toString());
    }
  }

  Map<String, dynamic> getSession(String sessionid) {
    try {
      if(sessions.containsKey(sessionid)) {
        return sessions[sessionid];
      }
    } catch(e) {
      console.error(e.toString());
      return null;
    }
  }
}