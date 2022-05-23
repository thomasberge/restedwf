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
import 'src/restedrequests.dart';
export 'src/restedrequests.dart';
import 'src/restedschema.dart';
export 'src/restedschema.dart';
import 'src/external.dart';
export 'src/external.dart';

RestedSettings rsettings = new RestedSettings();
ConsoleMessages console =
    new ConsoleMessages(debug_level: rsettings.message_level);

Map responses = new Map();

