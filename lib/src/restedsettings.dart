// Rested v0.1.0-alpha
// www.restedwf.com
// © 2020 Thomas Sebastian Berge

import 'dart:io';
import 'dart:convert';

class RestedSettings {
  RestedSettings() {
    loadSettingsFromFile();
    loadSettingsFromEnvironment();
  }

  /// Path to settings JSON file.
  String settings_filepath = '/bin/settings.json';

  /// Number of concurrent server threads (isolates).
  int threads;

  /// Name of JSON web token issuer.
  String jwt_issuer;

  /// JSON web token encryption key.
  String jwt_key;

  /// Duration in minutes before the JSON web token expires.
  int jwt_duration;

  /// Set to true to enable RestedCookie in RestedRequest.
  bool cookies_enabled;

  /// Duration in minutes before cookies expire.
  int cookies_max_age;

  /// Set to true to store cookie data as ASE encrypted map in base64 as cookie. Set to false if you want everything to break.
  bool cookies_encrypt;

  /// Cookie encryption key. Must be 32 bytes.
  String cookies_key;

  /// Set to true to enable file serving if there are no matching endpoint for the resource.
  bool files_enabled;

  /// Set to true if html files served will be treated as an rscriptResponse. Dependable on files_enabled to be true.
  bool open_html_as_rscript;

  void createSettingsFile() {
    Map<String, dynamic> settings = new Map();
    settings['threads'] = 4;
    settings['jwt_issuer'] = 'Rested Examples';
    settings['jwt_key'] = 'CANNONBALLS!!!?';
    settings['jwt_duration'] = 20;
    settings['cookies_enabled'] = true;
    settings['cookies_max_age'] = 60; // minutes
    settings['cookies_encrypt'] = true;
    settings['cookies_key'] = "my 32 length key................";
    settings['files_enabled'] = true;
    settings['open_html_as_rscript'] = true;
    File(settings_filepath)
        .writeAsStringSync(jsonEncode(settings), encoding: utf8);
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
    cookies_max_age = settings['cookies_max_age'];
    cookies_encrypt = settings['cookies_encrypt'];
    cookies_key = settings['cookies_key'];
    files_enabled = settings['files_enabled'];
    open_html_as_rscript = settings['open_html_as_rscript'];
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
    if (_envVars.containsKey("cookies_max_age")) {
      cookies_max_age = int.parse(_envVars["cookies_max_age"]);
    }
    if (_envVars.containsKey("cookies_encrypt")) {
      cookies_encrypt = toBool(_envVars["cookies_encrypt"]);
    }
    if (_envVars.containsKey("cookies_key")) {
      cookies_key = _envVars["cookies_key"];
    }
    if (_envVars.containsKey("files_enabled")) {
      files_enabled = toBool(_envVars["files_enabled"]);
    }
    if (_envVars.containsKey("open_html_as_rscript")) {
      open_html_as_rscript = toBool(_envVars["open_html_as_rscript"]);
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
