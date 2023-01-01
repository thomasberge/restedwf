// Part of Rested Web Framework
// www.restedwf.com
// © 2022 Thomas Sebastian Berge

import 'dart:io';
import 'dart:convert';
import 'package:nanoid/nanoid.dart';

class RestedSettings {

  RestedSettings() {
    loadSettings();
  }

  Map<String, dynamic> variables = {};
  Map<String, dynamic> default_variables = {
    "allowed_methods": {
      "type": "List<String>",
      "value": ["get", "post", "put", "patch", "delete", "copy", "head", "options", "link", "unlink", "purge", "lock", "unlock", "propfind" "view"],
      "description": "Allowed HTTP methods.",
      "dependencies": {}
    },
    "settings_filepath": {
      "type": "String",
      "value": "/bin/settings.json",
      "description": "Path to settings JSON file",
      "dependencies": {}
    },
    "threads": {
      "type": "Integer",
      "value": 1,
      "description": "Number of concurrent server threads",
      "dependencies": {}
    },
    "jwt_issuer": {
      "type": "String",
      "value": "",
      "description": "Name of JSON web token issuer",
      "dependencies": {}
    },
    "jwt_key": {
      "type": "String",
      "value": "",
      "description": "JSON web token encryption key",
      "dependencies": {}
    },
    "jwt_duration": {
      "type": "Integer",
      "value": 15,
      "description": "Duration in minutes before the JSON web token expires",
      "dependencies": {}
    },
    "cookies_enabled": {
      "type": "Boolean",
      "value": true,
      "description": "Set to true to enable RestedCookie in RestedRequest",
      "dependencies": {}
    },
    "cookies_max_age": {
      "type": "Integer",
      "value": 60,
      "description": "Duration in minutes before cookies expire",
      "dependencies": {}
    },
    "sessions_enabled": {
      "type": "Boolean",
      "value": true,
      "description": "Set to true to enable storing session data. Dependent on cookies_enabled to true for storing session reference.",
      "dependencies": {}
    },
    "files_enabled": {
      "type": "Boolean",
      "value": true,
      "description": "Set to true to enable file serving if there are no matching endpoint for the resource",
      "dependencies": {}
    },
    "open_html_as_rscript": {   // !!! Seems to not be used anywhere
      "type": "Boolean",
      "value": true,
      "description": "Set to true if html files served will be treated as an rscriptResponse. Dependent on files_enabled to true.",
      "dependencies": {}
    },
    "message_level": {
      "type": "Integer",
      "value": 2,
      "description": "0 for silent, 1 adds errors, 2 adds alerts/warnings, 3 adds headers/messages, 4 adds debug info.",
      "dependencies": {}
    },
    "common_enabled": {
      "type": "Boolean",
      "value": true,
      "description": "Creates a root common RestedResource that includes all files in the common directory and makes the available on the root path of the server.",
      "dependencies": {}
    },
    "module_web_enabled": {
      "type": "Boolean",
      "value": true,
      "description": "Core feature that enables checks related to cookies, sessions, file collections etc.",
      "dependencies": {}
    },
    "module_admin_enabled": {
      "type:": "Boolean",
      "value": false,
      "description": "Enables admin website interface.",
      "dependencies": {
        "module_web_enabled": true,
        "files_enabled": true
      }
    },
    "server_threads": {
      "type": "Integer",
      "value": 4,
      "description": "Warning: Experimental. Number of threads for each server instance. More than 1 thread will currently fail with for example sessions.",
      "dependencies": {}
    }
  };

  dynamic getVariable(String name) {
    return variables[name]['value'];
  }

  void createSettingsFile() {
    File('/bin/settings.json').writeAsStringSync(jsonEncode(default_variables), encoding: utf8);
  }

  void loadSettings() {
    if (File('/bin/settings.json').existsSync() == false) {
      createSettingsFile();
    }
    String text = File('/bin/settings.json').readAsStringSync(encoding: utf8);
    variables = json.decode(text);
    loadSettingsFromEnvironment();
  }

  void loadSettingsFromEnvironment() {
    Map<String, String> _temp = Platform.environment;
    Map<String, String> _envVars = {};

    for(MapEntry e in _temp.entries) {
      _envVars[e.key.toLowerCase()] = e.value;
    }

    for(MapEntry variable in variables.entries) {
      if(_envVars.containsKey(variable.key)) {
        if(variables[variable.key]['type'] == "Boolean") {
          variables[variable.key]['value'] = toBool(_envVars[variable.key]);
        } else if(variables[variable.key]['type'] == "Integer") {
          try {
            variables[variable.key]['value'] = int.parse(_envVars[variable.key]);
          } catch(e) {
            print("Error parsing environment variable " + variable.key + " to integer.");
          } 
        } else if(variables[variable.key]['type'] == "String") {
          variables[variable.key]['value'] = _envVars[variable.key];
        }
        
      }
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
