// Part of Rested Web Framework
// www.restedwf.com
// © 2021 Thomas Sebastian Berge

library rested.console;

import 'restedsettings.dart';

ConsoleMessages console = ConsoleMessages(debug_level: rsettings.message_level);

class ConsoleMessages {

  // 0 = silent
  // 1 = errors
  // 2 = errors, alerts/warnings
  // 3 = errors, alerts/warnings, headers/messages
  // 4 = errors, alerts/warnings, headers/messages, debug
  int debugLevel;
  bool colors = true;
  Map<String,String> color = new Map();

  ConsoleMessages({int debug_level = 1})
  {
    color["default"] = "\u001b[0m]";  // resets back to system default
    color["green"] = "\u001b[31m";  // green
    color["warning"] = "\u001B[33m"; // yellow
    color["error"] = "\u001B[31m";  // red    
    debugLevel = debug_level;
  }

  void error(String message) {
    if(debugLevel > 0)
    {
      if (colors)
        print(color["error"] + "-- ERROR: " + message + color["default"]);
      else
        print("-- ERROR: " + message);
    }
  }

  void alert(String message) {
    if(debugLevel > 1)
    {
      if (colors)
        print(color["alert"] + "-- ALERT: " + message + color["default"]);
      else
        print("-- ALERT: " + message);
    }
  }

    void warning(String message) {
    if(debugLevel > 1)
    {
      if (colors)
        print(color["warning"] + "-- WARNING: " + message + color["default"]);
      else
        print("-- WARNING: " + message);
    }
  }

  void header(String message) {
    if(debugLevel > 2)
    {
      if (colors)
        print(color["header"] + "-- *** " + message + " ***" + color["default"]);
      else
        print("-- *** " + message + " ***");
    }
  }

  void message(String message) {
    if(debugLevel > 2)
    {    
      if (colors)
        print( color["message"] + "-- " + message + color["default"]);
      else
        print("-- " + message);
    }
  }

  void debug(String message) {
    if(debugLevel > 3)
    {
      if (colors)
        print(color["debug"] + "-- " + message + color["default"]);
      else
        print("-- " + message);
    }
  }
}