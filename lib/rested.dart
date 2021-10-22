// Rested Web Framework
// Version: 0.4.0-alpha
// www.restedwf.com
// © 2021 Thomas Sebastian Berge

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:encrypt/encrypt.dart';
import 'package:string_tools/string_tools.dart';

import 'src/consolemessages.dart';
import 'src/pathparser.dart';

import 'src/restedrequest.dart';
export 'src/restedrequest.dart';
import 'src/restedsettings.dart';
import 'src/restedremoteserver.dart';
export 'src/restedremoteserver.dart';
import 'src/restedsession.dart';
export 'src/restedsession.dart';
import 'src/restedserver.dart';
export 'src/restedserver.dart';
import 'src/restedrequesthandler.dart';
export 'src/restedrequesthandler.dart';
import 'src/restedvirtualdisk.dart';
export 'src/restedvirtualdisk.dart';

RestedSettings rsettings = new RestedSettings();
ConsoleMessages console =
    new ConsoleMessages(debug_level: rsettings.message_level);

Map responses = new Map();

class RestedSchema {
  List<String> mandatory_strings = new List();
  List<String> mandatory_strings_label = new List();
  List<String> strings = new List();
  List<String> strings_label = new List();

  RestedSchema();

  void addString(String label, String data, {bool mandatory = false}) {
    if (mandatory) {
      mandatory_strings_label.add(label);
      mandatory_strings.add(data);
    } else {
      strings_label.add(label);
      strings.add(data);
    }
  }
}
