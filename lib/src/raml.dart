import 'dart:io';
import 'parser.dart';

enum LineType {
  none,
  resource
}

class RAMLDocument {
  Map<String, dynamic> resteddoc = new Map();

  List<String> resources = new List();

  RAMLDocument(String filepath) {
    File data = new File(filepath);
    List<String> lines = data.readAsLinesSync();

    int linenumber = 1;
    int currentLevel = 0;
    String currentResource = "";
    String fullResourcePath = "";

    // Start parsing the RAML file line by line. Some good to knows:
    // - a 2 space indentation is a level. No space is 0 (root), 2 spaces is level 1 etc.
    for(String line in lines) {

      // Get line level
      int level = getLevel(line, linenumber);

      if(level > -1) {
        LineType lineType = getLineType(line);

        switch (lineType) {
          case :LineType.resource
            print("FOUND A RESOURCE: " + line.removeWhitespace());
            break;
        }        
      }

      linenumber++;
    }
  }
}

LineType getLineType(String line) {
  Parser parser = new Parser(line);
  if(parser.lookNext() == "/") {
    print("Resource added. " + line);
    return LineType.resources;
  }
}

String removeWhitespace(String data) {
  return data.replaceAll(new RegExp(r"\s+"), "");
}

int getLevel(String line, int linenumber) {
  Parser parser = new Parser(line);
  int space_count = parser.countCharacterSequenze(" ");
  if(space_count % 2 == 0) {
    return space_count;
  }
  else {
    print("Indentation error in line number " + linenumber.toString() + ". " + space_count.toString() + " spaces used. Must be divisible by 2. Line ignored.\r\n" + line);
    return -1;
  }
}