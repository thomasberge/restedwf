// Part of Rested Web Framework
// www.restedwf.com
// © 2020 Thomas Sebastian Berge

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'consolemessages.dart';
import 'parser.dart';
import 'restedsettings.dart';

RestedSettings rsettings = new RestedSettings();
ConsoleMessages console = new ConsoleMessages(debug_level: rsettings.message_level);

String _randomString(int length) {
  var rand = new Random();
  var codeUnits = new List.generate(length, (index) {
    return rand.nextInt(33) + 89;
  });

  return new String.fromCharCodes(codeUnits);
}

// ----------- RestedScript ----------------------------------------------- //

class RestedScriptArguments {

  // From dart source
  List<dynamic> list = new List();
  Map<dynamic, dynamic> map = new Map();

  Map args = new Map<String, dynamic>();

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
  String rootDirectory = "";

  String flag = null;

  String expandForLists(String data, int count) {}

  List<CodeBlock> CreateCodeBlocks(String data) {
    int start_tags = 0;
    Parser bparser = new Parser(data);
    List<String> tags = new List();
    tags.add('{');
    tags.add('}');
    int levels = 0;
    String character = "startvalue";
    List<int> levellist = new List();
    while (character != null) {
      character = bparser.moveToFirstInList(tags);
      if (character != null) {
        if (character == '{') {
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
    while (i > 0) {
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
    while (i > 0) {
      String nextTag = '{{' + i.toString() + '}}';
      if (data.contains(nextTag)) {
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

  Future<String> createDocument(String filepath, RestedScriptArguments args) async {
    //console.debug("createDocument().filepath=" + filepath.toString());
    // TESTING FUNCTION
    //List<CodeBlock> blocks = CreateCodeBlocks('{this{is}a{test}string}');
    //for(CodeBlock block in blocks) {
    //}
    
    flag = null;
    String doc = await parse(filepath, args);
    if (flag != null) {
      doc = await parse("bin/resources/flagsites/" + flag, args);
    }
    return doc;
  }

  Future<String> parse(String filepath, RestedScriptArguments args, {String externalfile=null}) async {
    if(filepath != null) {
      try {
        File data = new File(filepath);
        List<String> lines = data.readAsLinesSync(encoding: utf8);
        //String unused = processLines2(lines, args);
        return (await processLines(lines, args));
      } on FileSystemException {
        console.error("Error reading " + filepath);
        return ("");
      }
    } else if(externalfile!= null) {
        LineSplitter ls = new LineSplitter();
        List<String> lines = ls.convert(externalfile);
        return(await processLines(lines, args));
    } else {
      return "";
    }
  }

  Future<String> doCommands(List<String> commands, RestedScriptArguments args) async {
    String data = "";
    for (String command in commands) {
      if (command != null) {
        command = command.trim();
        if (command != "") {
          //console.debug("COMMAND:" + command);
          Parser cparser = new Parser(command);
          if ('${cparser.data[0]}' == '\$') { // if the character first is a $ ...
            // set-function
            if (command[command.length - 1] == ')') {
              cparser.move();
              cparser.setStartMark();
              cparser.moveUntil('(');
              cparser.setStopMark();
              String key = cparser.getMarkedString();
              cparser.move();
              cparser.setStartMark();
              cparser.moveToEnd();
              cparser.move(characters: -2);
              cparser.setStopMark();
              String scriptarguments = cparser.getMarkedString();
              //console.debug("scriptarguments=" + scriptarguments);
              if(scriptarguments != null) {
                List<String> arglist = scriptarguments.split('|');
                if (args.setmap.containsKey(key)) {
                  int i = 0;
                  String constructed_string = args.setmap[key];
                  for (String replacement in arglist) {
                    constructed_string = constructed_string.replaceAll(
                        ('\$' + i.toString()), replacement);
                    i++;
                  }
                  data = data + constructed_string;
                } else {
                  console.error("Key >" + key + "< not in setmap.");
                }
              } else {
                console.error("Set variable reffered to as function " + key + "() but does not provide any arguments. Either use without () or add argument.");
              }
            } else {
              String key = cparser.data.substring(1);
              if (args.setmap.containsKey(key)) {
                data = data + args.setmap[key];
              } else {
                console.error("Key >" + key + "< not in setmap.");
              }
            }
          } else {
            cparser.setStartMark();
            cparser.moveUntil('(');
            cparser.setStopMark();
            String scriptfunction = cparser.getMarkedString();
            /*
            cparser.move();
            cparser.setStartMark();
            cparser.moveUntil(')');
            cparser.setStopMark();
            */
            cparser.move();
            cparser.setStartMark();
            cparser.moveToEnd();
            cparser.move(characters: -2);
            cparser.setStopMark();
            String scriptargument = cparser.getMarkedString();
            //print("scriptargument=" + scriptargument);

            console.debug(extractArgument(scriptargument));

            if (scriptfunction == "include") {
              data = data + await f_include(scriptargument, args);
            } else if (scriptfunction == "flag") {
              data = data + f_flag(scriptargument, args);
            } else if (scriptfunction == "print" || scriptfunction == "echo") {
              data = data + f_print(scriptargument, args);
            } else if (scriptfunction == "set") {
              data = data + f_set(scriptargument, args);
            } else if (scriptfunction == "args") {
              data = data + f_args(scriptargument, args);
            } else if (scriptfunction == "debug") {
              f_debug(scriptargument, args);
            }
          }
        }
      }
    }
    return data;
  }

  /// RestedScript function: include
  ///
  /// Example:
  /// include("scripts.html");

  String f_set(String scriptargument, RestedScriptArguments args) {
    Parser argparser = new Parser(scriptargument);
    argparser.moveUntil(',');
    String key = argparser.getPreString();
    String value = argparser.getPostString();
    args.setmap[key] = value;
    return "";
  }

  /// RestedScript function: args
  ///
  /// Example:
  /// 
  String f_args(String scriptargument, RestedScriptArguments args) {
    //console.debug("argument=" + scriptargument);
    //console.debug("args=" + args.args.toString());
    if (args.args.containsKey(scriptargument)) {
      return args.args[scriptargument].toString();
    } else {
      //console.debug("ARG not found! args="+scriptargument);
      //console.debug("All args=" + args.args.toString());
      return "";
    }
  }

  /// RestedScript function: include
  /// Reads the file and inserts the text at the position of the command.
  ///
  /// Example:
  /// include("scripts.html");

  Future<String> downloadTextFile(String argument) async {
    //console.debug("Downloading " + argument + " ...");
    HttpClient client = new HttpClient();
    HttpClientRequest web_request = await client.getUrl(Uri.parse(argument));
    dynamic result;
    HttpClientResponse web_response = await web_request.close();
    result = await utf8.decoder.bind(web_response).join();
    return result;
  }

  Future<String> f_include(String argument, RestedScriptArguments args) async {
    if(argument.substring(0,4) == "http") {
      String result = await downloadTextFile(argument);
      return (await parse(null, args, externalfile: result));
    } else {
      argument = argument.replaceAll('"', '');
      List<String> split = argument.split('.');
      if (split.length > 1) {
        String filetype = argument.split('.')[1];

        if (filetype == 'html' || filetype == 'css') {
          return (await parse(rootDirectory + '/' + argument, args));
        } else {
          console.error("RestedScript: Unsupported include filetype for " +
              argument.toString());
          return "";
        }
      } else {
        console.error(
            "RestedScript: Attempted to include file with no filetype: " +
                argument.toString());
      }
    }
  }

  String f_flag(String argument, RestedScriptArguments args) {
    argument = argument.replaceAll('"', '');
    String filetype = argument.split('.')[1];

    if (filetype == 'html') {
      flag = argument;
      return "";
    } else {
      console.error("RestedScript: Unsupported flag filetype for " + argument);
      return "";
    }
  }

  String extractArgument(String argument) {
    // single or doublequote?
    Parser fparser = new Parser(argument);
    String output = "";
    //console.debug("*** EXTRACT ARGUMENT ***");
    //console.debug("-->" + argument + "<--");

    return output;
  }

  String f_print(String argument, RestedScriptArguments args) {
    Parser fparser = new Parser(argument);
    String output = "";
    bool string_on = false;

    while (fparser.eol == false) {
      if (fparser.lookNext() == '"') {
        fparser.move();
        fparser.setStartMark();
        fparser.moveUntil('"');
        fparser.setStopMark();
        output = output + fparser.getMarkedString();
      }
    }

    return output;
  }

  String f_debug(String argument, RestedScriptArguments args) {
    Parser fparser = new Parser(argument);
    String output = "";
    bool string_on = false;

    while (fparser.eol == false) {
      if (fparser.lookNext() == '"') {
        fparser.move();
        fparser.setStartMark();
        fparser.moveUntil('"');
        fparser.setStopMark();
        output = output + fparser.getMarkedString();
      }
    }

    print(output);
  }  

  bool comment_on = false;

  String removeCommentsFromLine(String line) {
    if (comment_on) {
      line = "";
    } else if (line.contains('//')) {
      line = line.split('//')[0];
    } else if (line.contains('/*')) {
      comment_on = true;
      line = line.split('/*')[0];
    } else if (line.contains('*/')) {
      comment_on = false;
      line = line.split('*/')[0];
    }
    return line;
  }

  String removeComments(List<String> lines) {
    List<String> document = new List();
    bool rs = false;

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

  Future<String> processLines(List<String> lines, RestedScriptArguments args) async {
    String document = removeComments(lines);
    List<String> rs_blocks = new List();
    Parser dparser = new Parser(document);
    bool run = true;

    // process <% %> tags
    while (run) {
      String block;
      if (dparser.moveUntil('<% forlist %>')) {
        dparser.deleteCharacters(13);
        dparser.setStartMark();
        if (dparser.moveUntil('<% endforlist %>')) {
          dparser.deleteCharacters(13);
          dparser.setStopMark();
          block = dparser.getMarkedString();
          dparser.position = dparser.start_mark;
          dparser.deleteMarkedString();
          int i = 0;
          while (i < args.list.length) {
            //console.debug("i = " + i.toString());
            //console.debug("args.list[i] = " + args.list[i]);
            String newblock =
                block.replaceAll("<% element %>", args.list[i].toString());
            dparser.insertAtPosition(newblock);
            dparser.move(characters: newblock.length);
            i++;
          }
        } else {
          console.error("Missing closing <% endforlist %>");
        }
      } else {
        run = false;
      }
    }

    document = dparser.data;
    dparser = new Parser(document);
    run = true;

    // process <?rs ?> tags
    while (run) {
      //console.message("setmap=" + args.setmap.toString());
      if (dparser.moveUntil('<?rs')) {
        dparser.deleteCharacters(4);
        dparser.setStartMark();
        if (dparser.moveUntil('?>')) {
          dparser.deleteCharacters(2);
          dparser.setStopMark();
          rs_blocks.add(dparser.getMarkedString().trim());
          dparser.position = dparser.start_mark;
          dparser.deleteMarkedString();
          String codeblocktag = "{%" + (rs_blocks.length - 1).toString() + "%}";
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
    for (String block in rs_blocks) {
      if (block != null) {
        if (block.contains(';')) {
          List<String> command_list = block.split(';');
          String result = await doCommands(command_list, args);
          String codeblocktag = "{%" + i.toString() + "%}";
          document = document.replaceAll(codeblocktag, result);
        }
      }
      i++;
    }

    return document;
  }

  String replaceInQuotedString(String block, String replace, String replaceWith) {
    Parser block_parser = new Parser(block);
    bool in_quote = false;
    while(block_parser.eol == false) {
      block_parser.moveUntil('"');
    }
    return block;
  }

  String do_if(String command, String line, RestedScriptArguments args) {
    List<String> command_details = command.split(':');
    bool do_this = args.getBool(command_details[1]);
    //console.debug("cookie_policy_agree=" + do_this.toString());
    return "";
  }
}
