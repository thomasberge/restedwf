// Part of Rested Web Framework
// www.restedwf.com
// © 2020 Thomas Sebastian Berge

library rested.rsettings;

import 'dart:io';
import 'dart:convert';
import 'package:nanoid/nanoid.dart';

RestedSettings rsettings = RestedSettings();

class RestedSettings {
  RestedSettings() {
    loadSettingsFromFile();
    loadSettingsFromEnvironment();
  }

  List<String> allowedMethods = ["get", "post", "put", "patch", "delete", "copy", "head", "options", "link", "unlink", "purge", "lock", "unlock", "propfind" "view"];

  /// Path to settings JSON file.
  String settings_filepath = '/bin/settings.json';

  /// Number of concurrent server threads (isolates).
  int threads;

  /// Name of JSON web token issuer.
  String jwt_issuer;

  bool ignoreAuthorizationHeaders;

  /// JSON web token encryption key.
  String jwt_key;

  /// Duration in minutes before the JSON web token expires.
  int jwt_duration;

  /// Set to true to enable RestedCookie in RestedRequest.
  bool cookies_enabled;

  /// Duration in minutes before cookies expire.
  int cookies_max_age;

  /// Set to true to enable storing session data. WARNING: Will not work unless cookies are also enabled.
  bool sessions_enabled;

  /// Set to true to enable file serving if there are no matching endpoint for the resource.
  bool files_enabled;

  /// Set to true if html files served will be treated as an rscriptResponse. Dependable on files_enabled to be true.
  bool open_html_as_rscript;

  /// 0 = silent
  /// 1 = errors
  /// 2 = errors, alerts/warnings
  /// 3 = errors, alerts/warnings, headers/messages
  /// 4 = errors, alerts/warnings, headers/messages, debug
  int message_level;

  void createSettingsFile() {
    Map<String, dynamic> settings = new Map();
    settings['threads'] = 4;
    settings['jwt_issuer'] = 'Rested Examples';
    settings['jwt_key'] = nanoid(32);
    settings['jwt_duration'] = 20;
    settings['cookies_enabled'] = true;
    settings['sessions_enabled'] = true;
    settings['cookies_max_age'] = 60; // minutes
    settings['files_enabled'] = true;
    settings['open_html_as_rscript'] = true;
    settings['message_level'] = 0;
    settings['ignore_authorization_headers'] = false;
    File(settings_filepath)
        .writeAsStringSync(jsonEncode(settings), encoding: utf8);
  }

  Map getSettingsFile() {
    String text = File(settings_filepath).readAsStringSync(encoding: utf8);
    Map settings = json.decode(text);
    return(settings);
  }

  void loadSettingsFromFile() {
    if (File(settings_filepath).existsSync() == false) {
      createSettingsFile();
    }
    String text = File(settings_filepath).readAsStringSync(encoding: utf8);
    Map settings = json.decode(text);
    threads = settings['threads'];
    jwt_issuer = settings['jwt_issuer'];
    jwt_key = settings['jwt_key'];
    jwt_duration = settings['jwt_duration'];
    cookies_enabled = settings['cookies_enabled'];
    sessions_enabled = settings['sessions_enabled'];
    cookies_max_age = settings['cookies_max_age'];
    files_enabled = settings['files_enabled'];
    open_html_as_rscript = settings['open_html_as_rscript'];
    message_level = settings['message_level'];
    ignoreAuthorizationHeaders = settings['ignore_authorization_headers'];
  }

  void loadSettingsFromEnvironment() {
    Map<String, String> _envVars = Platform.environment;
    if (_envVars.containsKey("threads")) {
      threads = int.parse(_envVars["threads"]);
    }
    if (_envVars.containsKey("jwt_issuer")) {
      jwt_issuer = _envVars["jwt_issuer"];
    }
    if (_envVars.containsKey("jwt_key")) {
      jwt_key = _envVars["jwt_key"];
    }
    if (_envVars.containsKey("jwt_duration")) {
      jwt_duration = int.parse(_envVars["jwt_duration"]);
    }
    if (_envVars.containsKey("cookies_enabled")) {
      cookies_enabled = toBool(_envVars["cookies_enabled"]);
    }
    if (_envVars.containsKey("sessions_enabled")) {
      sessions_enabled = toBool(_envVars["sessions_enabled"]);
    }    
    if (_envVars.containsKey("cookies_max_age")) {
      cookies_max_age = int.parse(_envVars["cookies_max_age"]);
    }
    if (_envVars.containsKey("files_enabled")) {
      files_enabled = toBool(_envVars["files_enabled"]);
    }
    if (_envVars.containsKey("open_html_as_rscript")) {
      open_html_as_rscript = toBool(_envVars["open_html_as_rscript"]);
    }
    if (_envVars.containsKey("message_level")) {
      message_level = int.parse(_envVars["message_level"]);
    }
    if (_envVars.containsKey("ignore_authorization_headers")) {
      ignoreAuthorizationHeaders = toBool(_envVars["ignore_authorization_headers"]);
    }
  }

  bool toBool(String input) {
    if (input.toLowerCase() == "true") {
      return true;
    } else {
      return false;
    }
  }
}
