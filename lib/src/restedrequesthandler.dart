// Part of Rested Web Framework
// www.restedwf.com
// © 2022 Thomas Sebastian Berge

import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'pathparser.dart';
import 'restedsession.dart';
import 'restedsettings.dart';
import 'restedrequest.dart';
import 'responses.dart';
import 'mimetypes.dart';
import 'restedschema.dart';
import 'openapi3.dart';
import 'contenttype.dart';
import 'restedfiles.dart';
import 'restedauth.dart';
import 'restedresponse.dart';
import 'restedresource.dart';
import 'openapi3export.dart';
import 'restedglobals.dart';

class RestedRequestHandler {
  String rootDirectory;
  String address = "127.0.0.1";
  int port = 8080;
  int threadid = 0;
  FileCollection common = FileCollection(path: "/");
  RestedJWT jwt_handler = new RestedJWT();
  List<RestedResource> resources = new List();
  List<RestedResource> file_resources = new List(); // Resources that contain files
  Map<String, RestedSchema> _global_schemas = {};

  RestedRequestHandler() {
    rootDirectory = Directory.current.path;

    if(rsettings.getVariable('common_enabled')) {
      if(Directory(rootDirectory + "/bin/common").existsSync()) {
        common.addDirectory(rootDirectory + "/bin/common");
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

    for(MapEntry schema in _global_schemas.entries) {
      if(global_schemas.containsKey(schema.key)){
        error.raise("global_schema_already_exists", details: schema.key);
      } else {
        global_schemas[schema.key] = schema.value;
      }
    }
  }

  void export() {
    OAPI3Export('/app/bin/common/export.yaml', resources);
    common.refresh();
  }

  void set custom_JWT_verification(Function _custom_JWT_verification) {
    jwt_handler.setCustomVerificationMethod(_custom_JWT_verification);
  }

  void setGlobalSchema(String name, RestedSchema schema) {
    print("setGlobalSchema()");
    _global_schemas[name] = schema;
  }

  void handle(HttpRequest incomingRequest) async {
    // 1 --- Build rested request from incoming request. Add session data if there is a session cookie in the request.
    RestedRequest request = new RestedRequest(incomingRequest);

    // WEB
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
    }
    
    // WEB
        else {
          if (rsettings.getVariable('files_enabled')) {
            String path;

            for(RestedResource res in file_resources) {
              path = res.testforfile(request.path.split('/'));
              if(path != null) {
                break;
              }
            }

            // If not, check the common directory
            print("common=" + common.toString());
            print("request.path=" + request.path);
            if(path == null && common.containsKey(request.path)) {
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
      if (resources[i].pathMatch(path)) {
        return i;
      }
    }
    return null;
  }
}


