// Part of Rested Web Framework
// www.restedwf.com
// © 2022 Thomas Sebastian Berge

import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:convert';

//import 'package:jaguar_jwt/jaguar_jwt.dart';
//import 'package:path/path.dart' as p;
//import 'package:rested_script/rested_script.dart';
//import 'package:string_tools/string_tools.dart';

import 'pathparser.dart';
import 'restedsession.dart';
import 'restedsettings.dart';
import 'restedrequest.dart';
import 'responses.dart';
import 'mimetypes.dart';
import 'restedschema.dart';
import 'errors.dart';
import 'openapi3.dart';
import 'external.dart';
import 'contenttype.dart';
import 'restedfiles.dart';
import 'restederrors.dart';
import 'restedauth.dart';
import 'restedresponse.dart';
import 'restedresource.dart';

class RestedRequestHandler {
  String rootDirectory;
  String address = "127.0.0.1";
  int port = 8080;
  int threadid = 0;
  FileCollection common = FileCollection(path: "/");
  Map<String, List<String>> uri_patterns = {};
  RestedJWT jwt_handler = new RestedJWT();
  List<RestedResource> resources = new List();

  // All RestedResources and their files. Only used for GETs to map file paths and their respective resource.
  Map<String, RestedResource> files = {};

  RestedRequestHandler() {
    rootDirectory = Directory.current.path;

    if(rsettings.getVariable('common_enabled')) {
      if(Directory(rootDirectory + "/bin/common").existsSync()) {
        common.addFiles(rootDirectory + "/bin/common");
      } else {
        error.raise('missing_common_directory');
      }
    }

    Map<String, String> _envVars = Platform.environment;
    if (_envVars.containsKey("yaml_import_file")) {
      OAPI3 oapi = OAPI3(_envVars["yaml_import_file"]);
      resources = oapi.getResources();
      for(RestedResource _res in resources) {
        _res.setExternalFunctions();
      }
    }    
  }


  void findFile(String path) {
    print(":: FIND FILE " + path);
    for(MapEntry file in files.entries) {
      if(path.length >= file.key.length) {
        print(":: TESTING ON " + file.key);
        String testvalue = path.substring(path.length - file.key.length);
        print(":: TESTVALUE IS " + testvalue);
      }
    }
  }

  void set custom_JWT_verification(Function _custom_JWT_verification) {
    jwt_handler.setCustomVerificationMethod(_custom_JWT_verification);
  }


  void handle(HttpRequest incomingRequest) async {
    // 1 --- Build rested request from incoming request. Add session data if there is a session cookie in the request.
    RestedRequest request = new RestedRequest(incomingRequest, address, port);

    // Decrypts the session id and sets the session data in the request
    if (rsettings.getVariable('cookies_enabled') && rsettings.getVariable('sessions_enabled')) {
      if (request.cookies.containsKey('session')) {
        var session = sessions.getSession(request.cookies.getFirst('session').value);
        if (session != null) {
          if (request.deleteSession) {
            sessions.deleteSession(request.cookies.getFirst('session').value);
          } else {
            request.session = session;
          }
        } else {
          request.removeCookie("session"); // remove session cookie on client if there is no equivalent on server
        }
      }
    }

    // 2 --- Get access_token from either cookie or session
    // Get access_token from cookie. Gets overwritten by access_token from session if present.
    if (rsettings.getVariable('cookies_enabled')) {
      if (request.cookies.containsKey("access_token")) {
        request.unverified_access_token = request.cookies.getFirst("access_token").value;
      }
    }

    // Get access_token from session. Overwrites access_token from cookie if present.
    if (rsettings.getVariable('sessions_enabled')) {
      if (request.session.containsKey("access_token")) {
        request.unverified_access_token = request.session["access_token"];
      }
    }

    request = await jwt_handler.validateAuth(request);    //  Do the auth
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

    if (index != null) {
      if (resources[index].path.contains('{')) {
        request.createPathArgumentMap(resources[index].uri_parameters,
            PathParser.get_uri_keys(resources[index].path));
      }
      resources[index].doMethod(request.method, request);
    } else {
      if (rsettings.getVariable('files_enabled')) {
        String path;

        // Find out if a RestedResource has this path as a file
        //String filepath = resource_path + filepath.substring(resource_path.length);

        if(files.containsKey(request.path)) {
          path = files[request.path].getFile(request.path);
        }

        // If not, check the common directory
        if(common.containsKey(request.path)) {
          path = common.getFile(request.path);
        }

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

  String getFilePath(String path) {
    path = 'bin/resources' + path;
    if (File(path).existsSync()) {
      return path;
    } else {
      error.raise("file_not_found", details: path);
      return null;
    }
  }

  void addResource(RestedResource resource, String path) {
    int exists = getResourceIndex(path);
    if (exists == null) {
      resource.setPath(path);

      if(path.contains('{')) {
        List<String> elements = path.split('/');

        String new_pattern = "";
        List<String> uri_params = [];

        for(String element in elements) {
          if(element.contains('{')) {
            uri_params.add(element.substring(1, element.length-1));
            element = '*';
          }
          new_pattern = new_pattern + element + '/';
        }
        new_pattern = new_pattern.substring(0, new_pattern.length-1);
        print("Adding path >" + path + "< as uri_pattern  >" + new_pattern + "< with uri_params " + uri_params.toString());

        uri_patterns[new_pattern] = uri_params;
      }

      Map<String, String> resource_files = resource.getFiles();
      for(MapEntry e in resource_files.entries) {
        files[path + "/" + e.key] = resource;
        print("added >" + path + e.key + "<");
      }
      resources.add(resource);
    } else
      error.raise("duplicate_resource", details: resource.path);
  }

  // Returns the index of the argument path in the resources list if present. Returns null if not present.
  int getResourceIndex(String path) {
    for (int i = 0; i < resources.length; i++) {
      if (resources[i].pathMatch(path)) {
        return i;
      }
    }
    return null;
  }
}


