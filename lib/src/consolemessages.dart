// Part of Rested Web Framework
// www.restedwf.com
// © 2020 Thomas Sebastian Berge

import 'package:ansicolor/ansicolor.dart';

class ConsoleMessages {

  // 0 = silent
  // 1 = errors
  // 2 = errors, alerts/warnings
  // 3 = errors, alerts/warnings, headers/messages
  // 4 = errors, alerts/warnings, headers/messages, debug
  int debugLevel;

  bool colors = true;
  AnsiPen errorPen = new AnsiPen()..red(bold: true);
  AnsiPen headerPen = new AnsiPen()..white(bold: true);
  AnsiPen messagePen = new AnsiPen()..rgb(r: 0.9, g: 0.9, b: 0.9);
  AnsiPen debugPen = new AnsiPen()..rgb(r: 0.0, g: 0.9, b: 0.0);
  AnsiPen alertPen = new AnsiPen()..rgb(r: 1.0, g: 1.0, b: 0.0);
  AnsiPen warningPen = new AnsiPen()..red(bold: true);

  ConsoleMessages({int debug_level = 1})
  {
    debugLevel = debug_level;
  }

  void error(String message) {
    if(debugLevel > 0)
    {
      if (colors)
        print(errorPen("-- ERROR: " + message));
      else
        print("-- ERROR: " + message);
    }
  }

  void alert(String message) {
    if(debugLevel > 1)
    {
      if (colors)
        print(alertPen("-- ALERT: " + message));
      else
        print("-- ALERT: " + message);
    }
  }

    void warning(String message) {
    if(debugLevel > 1)
    {
      if (colors)
        print(warningPen("-- WARNING: " + message));
      else
        print("-- WARNING: " + message);
    }
  }

  void header(String message) {
    if(debugLevel > 2)
    {
      if (colors)
        print(headerPen("-- *** " + message + " ***"));
      else
        print("-- *** " + message + " ***");
    }
  }

  void message(String message) {
    if(debugLevel > 2)
    {    
      if (colors)
        print(messagePen("-- " + message));
      else
        print("-- " + message);
    }
  }

  void debug(String message) {
    if(debugLevel > 3)
    {
      if (colors)
        print(debugPen("-- " + message));
      else
        print("-- " + message);
    }
  }
}