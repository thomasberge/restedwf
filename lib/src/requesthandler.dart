import 'dart:io';

import 'globals.dart';
import 'resource.dart';
import 'request.dart';
import 'contenttype.dart';
import 'pathparser.dart';

class RestedRequestHandler {
  String rootDirectory = Directory.current.path;
  String address = "0.0.0.0";
  int port = 8080;
  int threadid = 0;
  List<RestedResource> resources = [];
  Function? nopath = null;

  void handle(HttpRequest incomingRequest) async {
    print("thread #" + threadid.toString());

    RestedRequest request = new RestedRequest(incomingRequest);
    request = await receive_content(request);
    if(request.status > 399) { return; }

    int index = getResourceIndex(request.path);

    if (index != -1) {
      if (resources[index].path.contains('{')) {
        request.createPathArgumentMap(resources[index].uri_parameters,
            PathParser.get_uri_keys(resources[index].path));
      }
      resources[index].doMethod(request.method, request);
    } else {
      if(nopath != null) {
        nopath!(request);
      } else {
        Errors.raise(request, 404);
      }
    }
  }

  void addResource(RestedResource resource, String path) {
    int exists = getResourceIndex(path);
    if (exists == -1) {
      resource.setPath(path);
      resources.add(resource);
    } else
      error.raise("duplicate_resource", details: resource.path);
  }

  // Returns the index of the argument path in the resources list if present. Returns -1 if not present.
  int getResourceIndex(String path) {
    for (int i = 0; i < resources.length; i++) {
      if (resources[i].pathMatch(path)) {
        return i;
      }
    }
    return -1;
  }
}


