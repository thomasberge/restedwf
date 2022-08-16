library rested.globals;

import 'restederrors.dart';
export 'restederrors.dart' show Errors;
import 'resteddatabase.dart';
import 'restedschema.dart';
import 'restedrequest.dart';
import 'restedsettings.dart';
import 'restedauth.dart';

RestedErrors error = RestedErrors();
DatabaseManager rdb = DatabaseManager();
Map<String, RestedSchema> global_schemas = {};
Map<String, Function(RestedRequest)> xfunctions = {};
List<String> xfunctions_require_token = [];
Map<String, String> xfunctions_redirect = {};
RestedSettings rsettings = RestedSettings();
RestedJWT jwt_handler = RestedJWT();