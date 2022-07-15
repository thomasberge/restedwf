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
  Function _custom_JWT_verification;

  String address = "127.0.0.1";
  int port = 8080;
  int threadid = 0;
  FileCollection common = FileCollection(path: "/");
  Map<String, List<String>> uri_patterns = {};

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

    _custom_JWT_verification = custom_JWT_verification;

    Map<String, String> _envVars = Platform.environment;
    if (_envVars.containsKey("yaml_import_file")) {
      OAPI3 oapi = OAPI3(_envVars["yaml_import_file"]);
      resources = oapi.getResources();
      for(RestedResource _res in resources) {
        _res.setExternalFunctions();
      }
    }    
  }

  // This function can be overridden by server implementation to add custom JWT verification
  bool custom_JWT_verification(String token) {
    return true;
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

    //String access_token = "";
    //String unverified_access_token = null;
    //bool expired_token = false;

    // 2 --- Get access_token from either cookie or session, then verify it.

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

    // If there is an Authorization header, the token will be extracted if it is prefixed
    // in the header either as Bearer, access_token, token or jwt followed by a space and
    // the jwt token itself. The extracted token will be stored in the access_token variable
    // and passed to the RestedRequest object. If it fails it will set exception to true,
    // which in turn will trigger a 401 Unauthorized error response.

    try {
      if (request.unverified_access_token == null) {
        request.unverified_access_token = incomingRequest.headers.value(HttpHeaders.authorizationHeader);

        // Checks that the authorization header is formatted correctly.
        if (request.unverified_access_token != null) {
          List<String> authtype = request.unverified_access_token.split(' ');
          List<String> valid_auths = ['BEARER', 'ACCESS_TOKEN', 'TOKEN', 'REFRESH_TOKEN', 'JWT'];
          if (valid_auths.contains(authtype[0].toUpperCase())) {
            request.unverified_access_token = authtype[1];
          } else {
            Errors.raise(request, 400);
            return;
          }
        }
      }

      if (request.unverified_access_token != null) {
        RestedJWT jwt_handler = new RestedJWT();
        jwt_handler.setCustomVerificationMethod(_custom_JWT_verification);
        int verify_result = jwt_handler.verify_token(request.unverified_access_token);
        if (verify_result != 401) {
          request.access_token = request.unverified_access_token;
          request.claims = RestedJWT.getClaims(request.access_token);
        } else {
          Errors.raise(request, 401);
          return;
        }
      }

    } catch(e) {
      print(e.toString());
      Errors.raise(request, 500);
      return;
    }

    // 3 ---  Download whatever data is related to the Content-Type and parse it to their respective
    //        request data fields. If an error was raised (meaning the response has already been sent)
    //        then we simply return.
    //request.dump();
    request = await receive_content(request);
    if(request.status > 399) {
      return;
    }

    // 4 --- ?

    // Creates the RestedRequest first. If the exception error code is set to 401 Token Expired
    // an "error" in rscript_args is added along with error description.
    // we reset error code and makes sure access_token is blank before we continue. After that,
    // if the error code is still not 0 we return an error response.
      
    //if(access_token != "") {
    //  request.access_token = access_token;
    //}
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

        print("files=" + files.toString());

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


