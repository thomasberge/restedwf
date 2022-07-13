// Part of Rested Web Framework
// www.restedwf.com
// © 2022 Thomas Sebastian Berge

library rested.sessions;

import 'dart:io';
import 'dart:convert';
import 'restedsettings.dart';
import 'dart:math';

import 'package:nanoid/nanoid.dart';

import 'restederrors.dart';
import 'restedrequest.dart';


SessionManager manager = SessionManager();

// New, simpler manager. Easier to migrate to Redis later.
class SessionManager {
  Map<String, Map<String, dynamic>> sessions = new Map();

  SessionManager();

  void saveSession(RestedRequest request) {
    if (request.session.containsKey('id')) {
      updateSession(request.session);
    } else {
      String encrypted_sessionid = newSession(request.session);
      request.request.response.headers.add(
          "Set-Cookie",
          "session=" +
              encrypted_sessionid +
              "; Path=/; Max-Age=" +
              rsettings.getVariable('cookies_max_age').toString() +
              "; HttpOnly");
    }
  }

  // Takes whatever is stored in RestedRequest.session and creates a new session.
  String newSession(Map<String, dynamic> data) {
    try {
      data['id'] = nanoid(32);
      sessions[data['id']] = data;
      return data['id'];
    } catch(e) {
      error.raise("exception_new_session", details: e.toString());
      return null;
    }
  }

  void updateSession(Map<String, dynamic> data) {
    try {
      if(sessions.containsKey(data['id'])) {
        sessions[data['id']] = data;
      }
    } catch(e) {
      error.raise("exception_update_session", details: e.toString());
    }
  }

  void deleteSession(String sessionid) {
    try {
      if(sessions.containsKey(sessionid)) {
        sessions.remove(sessionid);
      }
    } catch(e) {
      error.raise("exception_delete_session", details: e.toString());
    }
  }

  void setValue(String sessionid, String key, String value) {
    try {
      if(sessions.containsKey(sessionid)) {
        sessions[sessionid][key] = value;
      }
    } catch(e) {
      error.raise("exception_session_variables", details: e.toString());
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
      error.raise("exception_session_variables", details: e.toString());
      return null;
    }
  }

  void deleteKey(String sessionid, String key) {
    try {
      if(sessions.containsKey(sessionid)) {
        sessions[sessionid].remove(key);
      }
    } catch(e) {
      error.raise("exception_session_variables", details: e.toString());
    }
  }

  Map<String, dynamic> getSession(String sessionid) {
    try {
      if(sessions.containsKey(sessionid)) {
        return sessions[sessionid];
      }
    } catch(e) {
      error.raise("exception_retrieve_session", details: e.toString());
      return null;
    }
  }
}