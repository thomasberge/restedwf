// Container for external functions
library rested.external;
import 'restedrequest.dart';

Map<String, Function(RestedRequest)> xfunctions = {};
List<String> xfunctions_require_token = [];
Map<String, String> xfunctions_redirect = {};