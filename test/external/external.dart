import 'restedrequest.dart';
export 'restedrequest.dart';

import 'otherfile.dart';

Map<String, Function> xfunctions = {
    "list-users": listusers,
    "create-user": createuser
};

void listusers(RestedRequest request) {
    request.response(data: "listing users ...");
}
