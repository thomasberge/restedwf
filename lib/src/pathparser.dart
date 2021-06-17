// Part of Rested Web Framework
// www.restedwf.com
// © 2020 Thomas Sebastian Berge

import 'parser.dart';

class PathParser {
  PathParser();

  static String get_uri_parameters(String path) {
    if (path.contains('{')) {
      Parser parser = new Parser(path);
      int args = '{'.allMatches(path).length;
      while (args > 0) {
        parser.moveUntil('{');
        parser.move(); // add one more to not select the {
        parser.setStartMark();
        parser.moveUntil('}');
        parser.setStopMark();
        parser.position = parser.start_mark;
        parser.deleteMarkedString();
        parser.insertAtPosition('var');
        args--;
      }
      return parser.data;
    } else {
      return null;
    }
  }

  static List<String> get_uri_keys(String path) {
    if (path.contains('{')) {
      List<String> varlist = new List();
      Parser parser = new Parser(path);
      int args = '{'.allMatches(path).length;
      while (args > 0) {
        parser.moveUntil('{');
        parser.move(); // add one more to not select the {
        parser.setStartMark();
        parser.moveUntil('}');
        parser.setStopMark();
        varlist.add(parser.getMarkedString());
        parser.position = parser.start_mark;
        parser.deleteMarkedString();
        args--;
      }
      return varlist;
    } else {
      return null;
    }
  }
}