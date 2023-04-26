import 'package:string_tools/string_tools.dart';

class PathParser {
  PathParser();

  static String get_uri_parameters(String path) {
    if (path.contains('{')) {
      StringTools parser = new StringTools(path);
      int args = '{'.allMatches(path).length;
      while (args > 0) {
        parser.moveTo('{');
        parser.move(); // add one more to not select the {
        parser.startSelection();
        parser.moveTo('}');
        parser.stopSelection();
        parser.position = parser.start_selection;
        parser.deleteSelection();
        parser.insertAtPosition('var');
        args--;
      }
      return parser.data;
    } else {
      return "null";
    }
  }

  static List<String> get_uri_keys(String path) {
    if (path.contains('{')) {
      List<String> varlist = [];
      StringTools parser = new StringTools(path);
      int args = '{'.allMatches(path).length;
      while (args > 0) {
        parser.moveTo('{');
        parser.move(); // add one more to not select the {
        parser.startSelection();
        parser.moveTo('}');
        parser.stopSelection();
        varlist.add(parser.getSelection());
        parser.position = parser.start_selection;
        parser.deleteSelection();
        args--;
      }
      return varlist;
    } else {
      return [];
    }
  }
}