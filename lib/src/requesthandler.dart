// Part of Rested Web Framework
// www.restedwf.com
// © 2022 Thomas Sebastian Berge

import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:convert';
import 'dart:isolate';

import 'filecollection.dart';
import 'globals.dart';
import 'resource.dart';
import 'request.dart';
import 'contenttype.dart';
import 'response.dart';
import 'pathparser.dart';

class RestedRequestHandler {
  String rootDirectory = Directory.current.path;
  String address = "0.0.0.0";
  int port = 8080;
  int threadid = 0;
  FileCollection common = FileCollection(path: "/");
  List<RestedResource> resources = [];
  List<RestedResource> file_resources = []; // Resources that contain files
  SendPort sendPort;

  void handle(HttpRequest incomingRequest) async {
    print("thread #" + threadid.toString());
    
    // 1 --- Build rested request from incoming request. Add session data if there is a session cookie in the request.
    RestedRequest request = new RestedRequest(incomingRequest);

    request = await receive_content(request);             //  Download body content

    if(request.status > 399) {  // this should in reality check request.request.response.statusCode instead
      return;
    }

    // 4 --- ?

    // Creates the RestedRequest first. If the exception error code is set to 401 Token Expired
    // an "error" in rscript_args is added along with error description.
    // we reset error code and makes sure access_token is blank before we continue. After that,
    // if the error code is still not 0 we return an error response.

    int index = getResourceIndex(request.path);

    print("request.path=" + request.path);

    if (index != null) {
      if (resources[index].path.contains('{')) {
        request.createPathArgumentMap(resources[index].uri_parameters,
            PathParser.get_uri_keys(resources[index].path));
      }
      resources[index].doMethod(request.method, request);
    } else {
      if(rsettings.getVariable('module_web_enabled')) {
        if (rsettings.getVariable('files_enabled')) {
          String path;

          for(RestedResource res in file_resources) {
            path = res.testforfile(request.path.split('/'));
            if(path != null) {
              break;
            }
          }

          // If not, check the common directory
          //print("common=" + common.toString());
          /*
          print("request.path=" + request.path);
          if(path == null && common.containsKey(request.path)) {
            path = common.getFile(request.path);
          }*/

          // If all else fails, create a path out of the url and try your luck with the
          // file response
          if(path == null) {
            path = request.path;
            if (request.path.substring(0, 1) == '/') {
              path = request.path.substring(1);
            }
          }

          if (path != null) {
            request.response(type: "file", filepath: path);
            RestedResponse resp = new RestedResponse(request);
            resp.respond();
          } else {
            error.raise("file_not_found", details: request.path);
            request.response(status: 404);
          }
        } else {
          error.raise("resource_not_found", details: request.path);
          request.response(status: 404);
        }
      }
      }
  }

  void addResource(RestedResource resource, String path) {
    int exists = getResourceIndex(path);
    if (exists == null) {
      resource.setPath(path);
      if(resource.hasFiles()) {
        file_resources.add(resource);
      }
      resources.add(resource);
    } else
      error.raise("duplicate_resource", details: resource.path);
  }

  // Returns the index of the argument path in the resources list if present. Returns null if not present.
  int getResourceIndex(String path) {
    for (int i = 0; i < resources.length; i++) {
      print("looping resource index ...");
      if (resources[i].pathMatch(path)) {
        return i;
      }
    }
    return null;
  }
}


