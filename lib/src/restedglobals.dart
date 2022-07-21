library rested.globals;

import 'restederrors.dart';
export 'restederrors.dart' show Errors;
import 'resteddatabase.dart';
import 'restedschema.dart';

RestedErrors error = RestedErrors();
DatabaseManager rdb = DatabaseManager();
Map<String, RestedSchema> global_schemas = {};