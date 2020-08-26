import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'consolemessages.dart';
import 'parser.dart';

ConsoleMessages console = new ConsoleMessages(debug_level: 4);

String _randomString(int length) {
  var rand = new Random();
  var codeUnits = new List.generate(length, (index) {
    return rand.nextInt(33) + 89;
  });

  return new String.fromCharCodes(codeUnits);
}

// ----------- RestedScript ----------------------------------------------- //

class RestedScriptArguments {
  Map setmap = new Map<String, String>();
  Map stringmap = new Map<String, String>();
  Map boolmap = new Map<String, bool>();

  void setBool(String key, bool value) {
    boolmap[key] = value;
  }

  void setString(String key, String value) {
    stringmap[key] = value;
  }

  String getString(String key) {
    if (stringmap.containsKey(key)) {
      return stringmap[key];
    } else {
      console.error("Key " + key + " does not exist in rscript stringmap.");
      return "";
    }
  }

  bool getBool(String key) {
    if (boolmap.containsKey(key)) {
      return boolmap[key];
    } else {
      console.error("Key " + key + " does not exist in rscript boolmap.");
      return false;
    }
  }
}

class RestedScriptDocument {
  String flag = null;
  String document = "";
  
  RestedScriptDocument();

}

class CodeBlock {
  int id;
  String data;

  CodeBlock(this.id, this.data);

  String toString() {
    return this.id.toString() + ": " + this.data;
  }
}

class RestedScript {
  RestedScript();

  String flag = null;

  List<CodeBlock> CreateCodeBlocks(String data) {
    int start_tags = 0;
    Parser bparser = new Parser(data);
    List<String> tags = new List();
    tags.add('{');
    tags.add('}');
    int levels = 0;
    String character = "startvalue";
    List<int> levellist = new List();
    while(character != null) {
      character = bparser.moveToFirstInList(tags);
      if(character != null) {
        if(character == '{') {
          levels++;
          levellist.add(levels);
          String movestring = "{{" + levels.toString() + "}}";
          int movelength = movestring.length;
          bparser.replaceCharacters(1, "{{" + levels.toString() + "}}");
          bparser.move(characters: movelength);
        } else if (character == '}') {
          int last_uplevel = levellist.removeLast();
          String movestring = "{{" + last_uplevel.toString() + "}}";
          int movelength = movestring.length;
          bparser.replaceCharacters(1, "{{" + last_uplevel.toString() + "}}");
          bparser.move(characters: movelength);
        }
      }
    }
    data = bparser.data;

    List<CodeBlock> codeblocks = new List();

    int i = levels;
    while(i > 0) {
      List<String> blocklist = data.split('{{' + i.toString() + '}}');
      String temp = blocklist[1].toString();
      String temp2 = collapseBlockTags(temp, levels);
      CodeBlock newblock = new CodeBlock(i, temp);
      codeblocks.add(newblock);
      i--;
    }

    return codeblocks;
  }

  // Collapses {{i}}<code>{{i}} to {{i}}
  String collapseBlockTags(String data, int levels) {
    Parser bparser = new Parser(data);
    int i = levels;
    while(i > 0) {
      String nextTag = '{{' + i.toString() + '}}';
      if(data.contains(nextTag)) {
        bparser.position = 0;
        bparser.moveUntil(nextTag);
        bparser.move(characters: 5);
        bparser.setStartMark();
        bparser.moveUntil(nextTag);
        bparser.move(characters: 5);
        bparser.setStopMark();
        bparser.deleteMarkedString();
      }
      i--;
    }
  }


  String createDocument(String filepath, RestedScriptArguments args) {

    // TESTING FUNCTION
    //List<CodeBlock> blocks = CreateCodeBlocks('{this{is}a{test}string}');
    //for(CodeBlock block in blocks) {
    //}

    flag = null;
    String doc = parse(filepath, args);
    if(flag != null) {
      doc = parse("bin/resources/flagsites/" + flag, args);
    }
    return doc;
  }

  String parse(String filepath, RestedScriptArguments args) {
    try {
      File data = new File('bin/resources/' + filepath);
      List<String> lines = data.readAsLinesSync(encoding: utf8);
      //String unused = processLines2(lines, args);
      return (processLines(lines, args));
    } on FileSystemException {
      console.error("Error reading bin/resources/" + filepath);
      return ("");
    }
  }

  String doCommands(List<String> commands, RestedScriptArguments args) {
    String data = "";
    for (String command in commands) {
      if(command != null) {
        command = command.trim();
        if(command != "") {
          Parser cparser = new Parser(command);
          if('${cparser.data[0]}' == '\$') {

            // set-function
            if(command[command.length-1] == ')')
            {
              cparser.move();
              cparser.setStartMark();
              cparser.moveUntil('(');
              cparser.setStopMark();
              String key = cparser.getMarkedString();
              cparser.move();
              cparser.setStartMark();
              cparser.moveUntil(')');
              cparser.setStopMark();
              String scriptarguments = cparser.getMarkedString();
              List<String> arglist = scriptarguments.split('|');
              if(args.setmap.containsKey(key)) {
                int i = 0;
                String constructed_string = args.setmap[key];
                for(String replacement in arglist) {
                  constructed_string = constructed_string.replaceAll(('\$' + i.toString()), replacement);
                  i++;
                }
                data = data + constructed_string;
              } else {
                console.error("Key " + key + " not in setmap.");
              }              
            } else {
              String key = cparser.data.substring(1);
              if(args.setmap.containsKey(key)) {
                data = data + args.setmap[key];
              } else {
                console.error("Key " + key + " not in setmap.");
              }              
            }
          } else {
            cparser.setStartMark();
            cparser.moveUntil('(');
            cparser.setStopMark();
            String scriptfunction = cparser.getMarkedString();
            cparser.move();
            cparser.setStartMark();
            cparser.moveUntil(')');
            cparser.setStopMark();
            String scriptargument = cparser.getMarkedString();

            if(scriptfunction == "include") {
              data = data + f_include(scriptargument, args);
            } else  if(scriptfunction == "flag") {
              data = data + f_flag(scriptargument, args);
            } else if(scriptfunction == "print") {
              data = data + f_print(scriptargument, args);
            } else if(scriptfunction == "set") {
              data = data + f_set(scriptargument, args);
            }
          }
        }
        }
    }
    return data;
  }

  String f_set(scriptargument, args) {
    List<String> arguments = scriptargument.split(',');
    if(arguments.length != 2) {
      console.error("set() needs 2 arguments (key, value) but " + arguments.length.toString() + " was provided.");
      return "";
    } else {
      String key = arguments[0].trim();
      String value = arguments[1].trim();
      args.setmap[key] = value;
      return "";
    }
  }

  String f_include(String argument, RestedScriptArguments args) {
    argument = argument.replaceAll('"', '');
    List<String> split = argument.split('.');
    if(split.length > 1) {
      String filetype = argument.split('.')[1];

      if (filetype == 'html' || filetype == 'css') {
        return (parse(argument, args));
      } else {
        console.error("RestedScript: Unsupported include filetype for " +
            argument.toString());
        return "";
      }
    } else {
      console.error("RestedScript: Attempted to include file with no filetype: " + argument.toString());
    }
  }

  String f_flag(String argument, RestedScriptArguments args) {
    argument = argument.replaceAll('"', '');
    String filetype = argument.split('.')[1];

    if (filetype == 'html') {
      flag = argument;
      return "";
    } else {
      console.error("RestedScript: Unsupported flag filetype for " +
          argument);
      return "";
    }    
  }  

  String f_print(String argument, RestedScriptArguments args) {
    Parser fparser = new Parser(argument);
    String output = "";
    bool string_on = false;

    while(fparser.eol == false) {
      if(fparser.lookNext() == '"')
      {
        fparser.move();
        fparser.setStartMark();
        fparser.moveUntil('"');
        fparser.setStopMark();
        output = output + fparser.getMarkedString();
      }
    }

    return output;
  }

bool comment_on = false;

  String removeCommentsFromLine(String line) {
    if(comment_on) {
      line = "";
    } else if(line.contains('//')) {
      line = line.split('//')[0];
    } else if(line.contains('/*')) {
      comment_on = true;
      line = line.split('/*')[0];
    }else if(line.contains('*/')) {
      comment_on = false;
      line = line.split('*/')[0];
    }
    return line;
  }

  String removeComments(List<String> lines) {
    List<String> document = new List();
    bool rs= false;

    for (var line in lines) {
      document.add(line + "\n");
      /*
      if(rs || line.contains('<?rs')) {
        if(line.contains('?>')) {
          rs = false;
          document.add(removeCommentsFromLine(line));
        } else {
          rs = true;
          document.add(removeCommentsFromLine(line));
        }
      }    
      if(rs) {
        if(line.contains('?>')) {
          rs = false;
        }
      }*/
    }

    return document.join();
  }

  String processLines(List<String> lines, RestedScriptArguments args) {

    String document = removeComments(lines);
    List<String> rs_blocks = new List();
    Parser dparser = new Parser(document);
    bool run = true;

    while(run) {
      //console.message("setmap=" + args.setmap.toString());
      if(dparser.moveUntil('<?rs')) {
        dparser.deleteCharacters(4);
        dparser.setStartMark();
        if(dparser.moveUntil('?>')) {
          dparser.deleteCharacters(2);
          dparser.setStopMark();
          rs_blocks.add(dparser.getMarkedString().trim());
          dparser.position = dparser.start_mark;
          dparser.deleteMarkedString();
          String codeblocktag = "{%" + (rs_blocks.length-1).toString() + "%}";
          dparser.insertAtPosition(codeblocktag);
        } else {
          console.error("Missing closing bracket restedscript ?>");
        }
      } else {
        run = false;
      }
    }

    document = dparser.data;

    int i = 0;
    for(String block in rs_blocks) {
      if(block != null) {
        if(block.contains(';')) {
          List<String> command_list = block.split(';');
          String result = doCommands(command_list, args);
          String codeblocktag = "{%" + i.toString() + "%}";
          document = document.replaceAll(codeblocktag, result);
        }
      }
      i++;
    }

    return document;
  }

  String do_if(String command, String line, RestedScriptArguments args) {
    List<String> command_details = command.split(':');
    bool do_this = args.getBool(command_details[1]);
    print("cookie_policy_agree=" + do_this.toString());
    return "";
  }
}
