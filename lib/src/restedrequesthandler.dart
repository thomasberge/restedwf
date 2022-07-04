// Part of Rested Web Framework
// www.restedwf.com
// © 2021 Thomas Sebastian Berge

import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:path/path.dart' as p;
import 'package:rested_script/rested_script.dart';
import 'package:string_tools/string_tools.dart';

import 'consolemessages.dart';
import 'pathparser.dart';
import 'restedsession.dart';
import 'restedsettings.dart';
import 'restedrequest.dart';
import 'responses.dart';
import 'mimetypes.dart';
import 'restedvirtualdisk.dart';
import 'restedschema.dart';
import 'errors.dart';
import 'openapi3.dart';
import 'external.dart';
import 'contenttype.dart';

Function _custom_JWT_verification;
SessionManager manager;
String rootDirectory = null;
String resourcesDirectory = null;
//Errors error_handler = Errors();

void saveSession(RestedRequest request) {
  if (request.session.containsKey('id')) {
    manager.updateSession(request.session);
  } else {
    String encrypted_sessionid = manager.newSession(request.session);
    request.request.response.headers.add(
        "Set-Cookie",
        "session=" +
            encrypted_sessionid +
            "; Path=/; Max-Age=" +
            rsettings.cookies_max_age.toString() +
            "; HttpOnly");
  }
}

/*

The idea of the resource collection is to have a nice structure as such:

Map<String, RestedResource> pathmap = {
  "root": {
    "resource": RestedResource()
    "admin": {
      "resource": RestedResource()
    }
  }
};

pathmap["root"]["admin"].resource
*/  
/*
class RestedResourceCollection {
  Map<String, RestedResource> site = {};

  // Example:   /users/{user_id}/repos/{repo_id}
  void addPath(String path, RestedResource resource) {

    // [users,{user_id},repos,{repo_id}]
    List<String> elements = path.split('/');  

    for(String element in elements) {
      MapEntry e = getElement(site.entries);

      //if(site["root"].containsKey(element) == false) {
      //  site["root"][element] = {};
      }
    }
  }

  MapEntry getElement(List<MapEntry> map, String element) {

  }
}*/

class RestedRequestHandler {
  bool ignoreAuthorizationHeaders = false;
  String address = "127.0.0.1";
  int port = 8080;
  int threadid = 0;

  List<RestedResource> resources = new List();

  // This function can be overridden by server implementation to add custom JWT verification
  bool custom_JWT_verification(String token) {
    return true;
  }

  RestedRequestHandler() {
    ignoreAuthorizationHeaders = rsettings.ignoreAuthorizationHeaders;
    rootDirectory = Directory.current.path;
    console.debug("Rested rootDirectory:" + rootDirectory);
    resourcesDirectory = rootDirectory + ('/bin/resources/');
    console.debug("Rested resourcesDirectory:" + resourcesDirectory);
    _custom_JWT_verification = custom_JWT_verification;

    if (rsettings.cookies_enabled && rsettings.sessions_enabled) {
      manager = new SessionManager();
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

  // Validates the incoming request and passes it to the proper RestedResource object
  //
  // IMPORTANT: If body contains a first element called "body" then the contents of that
  //            element will become the entire body contents. Some applications seems to
  //            wrap the content like this { "body": { <actual content> }}. This means that
  //            if there is information outside the body tag that is part of the actual
  //            body then they will be dropped when body = body['body']; is performed.
  void handle(HttpRequest incomingRequest) async {

    // 1 --- Build rested request from incoming request. Add session data if there is a session cookie in the request.
    RestedRequest request = new RestedRequest(incomingRequest, address, port);

    // Decrypts the session id and sets the session data in the request
    if (rsettings.cookies_enabled && rsettings.sessions_enabled) {
      if (request.cookies.containsKey('session')) {
        var session = manager.getSession(request.cookies.getFirst('session').value);
        if (session != null) {
          if (request.deleteSession) {
            manager.deleteSession(request.cookies.getFirst('session').value);
          } else {
            request.session = session;
          }
        } else {
          request.removeCookie("session"); // remove session cookie on client if there is no equivalent on server
        }
      }
    }

    String access_token = null;
    String unverified_access_token = null;
    bool expired_token = false;

    // 2 --- Get access_token from either cookie or session, then verify it.

    // Get access_token from cookie. Gets overwritten by access_token from session if present.
    if (rsettings.cookies_enabled) {
      if (request.cookies.containsKey("access_token")) {
        unverified_access_token = request.cookies.getFirst("access_token").value;
      }
    }

    // Get access_token from session. Overwrites access_token from cookie if present.
    if (rsettings.sessions_enabled) {
      if (request.session.containsKey("access_token")) {
        unverified_access_token = request.session["access_token"];
      }
    }

    // If there is an Authorization header, the token will be extracted if it is prefixed
    // in the header either as Bearer, access_token, token or jwt followed by a space and
    // the jwt token itself. The extracted token will be stored in the access_token variable
    // and passed to the RestedRequest object. If it fails it will set exception to true,
    // which in turn will trigger a 401 Unauthorized error response.

    if (ignoreAuthorizationHeaders == false) {
      try {
        if (unverified_access_token == null) {
          unverified_access_token =
              incomingRequest.headers.value(HttpHeaders.authorizationHeader);

          // Checks that the authorization header is formatted correctly.
          if (unverified_access_token != null) {
            List<String> authtype = unverified_access_token.split(' ');
            List<String> valid_auths = ['BEARER', 'ACCESS_TOKEN', 'TOKEN', 'REFRESH_TOKEN', 'JWT'];
            if (valid_auths.contains(authtype[0].toUpperCase())) {
              unverified_access_token = authtype[1];
            } else {
              Errors.raise(request, 400);
              return;
            }
          }
        }

        if (unverified_access_token != null) {
          // Verify that the token is valid. Raise exception if it is not.
          RestedJWT jwt_handler = new RestedJWT();
          int verify_result = jwt_handler.verify_token(unverified_access_token);
          if (verify_result == 401) {
            //error_handler.raise(request, 401);
            //return;
            // REFACTORING: instead of returning 401, let the user pass until it
            // gets handled by the resource token requirement instead
          } else {
            access_token = unverified_access_token;
            request.claims = RestedJWT.getClaims(access_token);
          }
        }

      } on Exception catch (e) {
        console.error(e.toString());
        Errors.raise(request, 400);
        return;
      }
    }

    // 3 ---  Download whatever data is related to the Content-Type and parse it to their respective
    //        request data fields. If an error was raised (meaning the response has already been sent)
    //        then we simply return.
    request = await receive_content(request);
    if(request.status > 399) {
      return;
    }
    
    // 4 --- ?

    // Creates the RestedRequest first. If the exception error code is set to 401 Token Expired
    // an "error" in rscript_args is added along with error description.
    // we reset error code and makes sure access_token is blank before we continue. After that,
    // if the error code is still not 0 we return an error response.
      
    if(access_token != null) {
      request.access_token = access_token;
    }

    int index = getResourceIndex(request.path);

    if (index != null) {
      if (resources[index].path.contains('{')) {
        request.createPathArgumentMap(resources[index].uri_parameters,
            PathParser.get_uri_keys(resources[index].path));
      }
      resources[index].doMethod(request.method, request);
    } else {
      if (rsettings.files_enabled) {
        String path = request.path;
        if (request.path.substring(0, 1) == '/') {
          path = request.path.substring(1);
        }
        //path = disk.getFile(resourcesDirectory + request.path);
        if (path != null) {
          //request.fileResponse(path);
          //path = resourcesDirectory + path;
          request.response(
              type: "file",
              filepath:
                  path); //-----------------------------------------------------------------------------------------------
          RestedResponse resp = new RestedResponse(request);
          resp.respond();
        } else {
          console.debug("Resource not found at endpoint " + request.path);
          request.response(data: "404 error somethingsomething");
        }
      } else {
        console.debug("Resource not found at endpoint " + request.path);
        request.response(data: "404 error somethingsomething");
      }
    }
  }

  String getFilePath(String path) {
    path = 'bin/resources' + path;
    if (File(path).existsSync()) {
      return path;
    } else {
      console.error("Requested path " + path.toString() + " does not exist.");
      return null;
    }
  }

  // Predefines resource with supported HTTP verbs, schemas etc. from OAS3
  void defineResource(String path) {
    RestedResource resource = new RestedResource();
    int exists = getResourceIndex(path);
    if (exists == null) {
      resource.setPath(path);
      resources.add(resource);
    } else {
      console.error(
          "Attempt to add duplicate resource: " + resource.path.toString());
    }
  }

  void addResource(RestedResource resource, String path) {
    int exists = getResourceIndex(path);
    if (exists == null) {
      resource.setPath(path);
      resources.add(resource);
    } else
      console.error(
          "Attempt to add duplicate resource: " + resource.path.toString());
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

class RestedJWT {
  RestedJWT();

  String _randomString(int length) {
    var rand = new Random();
    var codeUnits = new List.generate(length, (index) {
      return rand.nextInt(33) + 89;
    });

    return new String.fromCharCodes(codeUnits);
  }

  JwtClaim _generateClaimset({Map additional_claims = null}) {
    // Horrible workaround to Dart Map -> Json problems, ref: https://github.com/flutter/flutter/issues/16589
    final cleanMap = jsonDecode(jsonEncode(additional_claims));

    final claimSet = new JwtClaim(
        issuer: rsettings.jwt_issuer,
        //subject: 'some_subject',
        //audience: ['client1.example.com', 'client2.example.com'],
        jwtId: _randomString(32),
        otherClaims: cleanMap,
        maxAge: Duration(minutes: rsettings.jwt_duration));
    return claimSet;
  }

  Map generate_token({Map additional_claims}) {
    JwtClaim claim_set = _generateClaimset(additional_claims: additional_claims);
    String token = issueJwtHS256(claim_set, rsettings.jwt_key);
    Map tokenmap = { "access_token": token };
    return tokenmap;
  }

  int verify_token(String token) {
    try {
      final JwtClaim decClaimSet = verifyJwtHS256Signature(token, rsettings.jwt_key);
      DateTime issued_at = DateTime.parse(decClaimSet['iat'].toString());
      DateTime expires = DateTime.parse(decClaimSet['exp'].toString());
      Duration duration = DateTime.now().difference(issued_at);
      if (duration.inMinutes >= rsettings.jwt_duration) {
        return (401);
      } else {
        if (_custom_JWT_verification(token)) {
          return (200); // "OK"
        } else {
          return (401);
        }
      }
    } on JwtException {
      return (401); // "Unauthorized"
    }
  }

  static String getClaim(String token, String key) {
    try {
      final JwtClaim decClaimSet = verifyJwtHS256Signature(token, rsettings.jwt_key);
      if(decClaimSet.containsKey(key)) {
        return decClaimSet[key];
      } else {
        return null;
      }
    } catch(e) {
      print("error: " + e.toString());
      return null;
    }
  }

  static Map<String, dynamic> getClaims(String token) {
    Map<String, dynamic> claims = {};
    try {
      final JwtClaim decClaimSet = verifyJwtHS256Signature(token, rsettings.jwt_key);        
        for(String name in decClaimSet.claimNames(includeRegisteredClaims: false)) {
          claims[name] = decClaimSet[name];
        }
      }
     catch(e) {
      print("error extracting claims from JWT: " + e.toString());
    }
    return claims;
  }
}

// ------------- RESTED RESPONSE ------------------------------------------------------//

class RestedResponse {
 
  Responses error_responses = new Responses();
  Mimetypes mimetypes = new Mimetypes();

  RestedRequest request;

  RestedResponse(this.request);

  void respond() async {
    if(request.restedresponse['status'] == null) {
      request.request.response.statusCode = 200;
    } else {
      request.request.response.statusCode = request.restedresponse['status'];
    }

    if(request.request.response.statusCode > 399 && request.request.response.statusCode < 600) {
      request.restedresponse['type'] = "error";
    }

    switch (request.restedresponse['type']) {
      case "error":
      {
        request.request.response.headers.contentType =
            new ContentType("application", "json", charset: "utf-8");        
        response(json.encode(Errors.getJson(request.request.response.statusCode)));
      }
      break;

      case "redirect":
      {
        String host = request.request.requestedUri.host;

        // Overwrite if host is specified in the http header
        if(request.headers.containsKey('host')) {
          print("Found in headers array");
          host = request.headers['host'];
        } else {
          print("Did not find in headers array, using " + host);
        }
        String path = request.restedresponse['data'];

        // If path contains :// then assume external host and use the entire path as redirect url
        if(path.contains('://')) {
          request.request.response.redirect(Uri.parse(path));
        } else {
          print("Redirecting to " + host);
          request.request.response.redirect(Uri.http(host, request.restedresponse['data']));  
        }
      }
      break;

      case "text":
      {
        console.debug(":: Textresponse()");
        request.request.response.headers.contentType =
            new ContentType("text", "plain", charset: "utf-8");
        response(request.restedresponse['data']);
      }
      break;

      case "html":
      {
        console.debug(":: Htmlresponse()");
        request.request.response.headers.contentType =
            new ContentType("text", "html", charset: "utf-8");
        response(request.restedresponse['data']);
      }
      break;

      case "json":
      {
        console.debug(":: Jsonresponse()");
        request.request.response.headers.contentType =
            new ContentType("application", "json", charset: "utf-8");
        response(request.restedresponse['data']);
      }
      break;

      case "file":
      {
        if (request.restedresponse['filepath'] != null) {
          String filepath =
              resourcesDirectory + request.restedresponse['filepath'];
          console.debug(":: Fileresponse() using path " + filepath);

          bool fileExists = await File(filepath).exists();
          if (fileExists) {
            String filetype = p.extension(filepath);
            console.debug(":: Filetype is " + filetype);

            // Set headers
            request.request.response.headers.contentType =
                mimetypes.getContentType(filetype);

            if (mimetypes.isBinary(filetype)) {
              File file = new File(filepath);
              var rangeheadervalue =
                  request.request.headers.value(HttpHeaders.rangeHeader);
              if (rangeheadervalue != null) {
                request.request.response.statusCode =
                    HttpStatus.partialContent;
              }
              Future f = file.readAsBytes();
              request.request.response
                  .addStream(f.asStream())
                  .whenComplete(() {
                request.request.response.close();
              });
            } else {
              String textdata = "";
              textdata = File(filepath).readAsStringSync(encoding: utf8);
              response(textdata);
            }
          } else {
            console.error("error 404");
            response("404 not found: " + filepath);
          }
        }
      }
      break;

    }
  }

  String filetypeFromPath(String path) {
    List<String> dirsplit = path.split('/');
  }

  void fileResponse(File file) {
    Future f = file.readAsBytes();
    request.request.response.addStream(f.asStream()).whenComplete(() {
      request.request.response.close();
    });
  }

  void fileStream() {
    /*
    Future f = file.readAsBytes();
    request.request.response.addStream(f.asStream()).whenComplete(() {
      request.request.response.close();
    });    */
  }

  void response(String data) async {
    if (data != "") {
      await request.request.response.write(data);
    }
    request.request.response.close();
  }
}

class RestedResource {
  bool validateAllQueryParameters = false;

  String path = null;

  // Only used for pattern matching in pathMatch function
  String uri_parameters = null;

  Map<String, dynamic> _uri_parameters_schemas = {};
  Map<String, Map<String, dynamic>> _query_parameters_schemas = {};

  // Stores schemas for each HTTP method.
  Map schemas = Map<String, RestedSchema>();

  // Stored functions for each HTTP method. Example <'Get', get> can be used as _functions['get](request);
  Map functions = Map<String, Function>();

  // Stored function for each HTTP error code. Returns standard error if not overridden with a function
  Map onError = Map<int, Function>();

  // Storage of bool determining if access_token is required for the http method (_functions). Use method
  // instead of setting the variable directly.
  Map _token_required = Map<String, bool>();

  // Stores operationId on resources imported from YAML. This is in order to link it to an external function.
  Map operationId = Map<String, String>();


  Map<String, dynamic> getRequestSchema = null;

  Map<String, Map<String, dynamic>> getQueryParams() {
    return _query_parameters_schemas;
  }

  String validateUriParameters(Map<String, String> params) {
    for(MapEntry e in params.entries) {
      if(_uri_parameters_schemas.containsKey(e.key)) {
        String result = _uri_parameters_schemas[e.key].validate(e.value);
        if(result != "OK") {
          return result;
        }
      }
    }
    return "OK";
  }

  String validateQueryParameters(String method, Map<String, String> params) {
    
    if(_query_parameters_schemas.length < 1) {
      return "OK";
    }
    method = method.toLowerCase();
    for(MapEntry e in params.entries) {
      print(e.key);
      if(_query_parameters_schemas[method].containsKey(e.key)) {
        String result = _query_parameters_schemas[method][e.key].validate(e.value);
        if(result != "OK") {
          return result;
        }
      } else {
        if(validateAllQueryParameters) {
          return "UNDEFINED QUERY PARAMETER";
        }
      }
    }
    return "OK";
  }

  void require_token(String _method, {String redirect_url = null}) {
    _token_required[_method] = true;
  }

  // If access to method is protected by an access_token then instead of retuning 401 Unauthorized it is
  // possible to return a redirect instead by setting the URL in this variable.
  String protected_redirect = null;

  void addUriParameters(Map<String, dynamic> new_schemas) {
    _uri_parameters_schemas = new_schemas;
  }

  void addUriParameterSchema(dynamic schema) {
    _uri_parameters_schemas[schema.name] = schema;
  }

  void addQueryParameters(String method, Map<String, dynamic> new_schemas) {
    _query_parameters_schemas[method] = new_schemas;
  }

  void addQueryParameterSchema(String method, dynamic schema) {
    _query_parameters_schemas[method][schema.name] = schema;
  }

  void invalid_token_redirect(String _url) {
    protected_redirect = _url;
  }

  void setPath(String resourcepath) {
    path = resourcepath;
    if (resourcepath.contains('{')) {
      uri_parameters = PathParser.get_uri_parameters(path);
    }
    /*console.debug("uri_parameters for path '" +
        path.toString() +
        "' is " +
        uri_parameters.toString());*/
  }

  bool pathMatch(String requested_path) {
    if (path == requested_path) {
      return true;
    } else {
      if (uri_parameters != null && requested_path != null) {
        List<String> requested_path_segments = requested_path
            .substring(1)
            .split('/'); // substring in order to remove leading slash
        List<String> uri_parameters_segments =
            uri_parameters.substring(1).split('/');
        if (requested_path_segments.length != uri_parameters_segments.length) {
          return false;
        } else {
          int i = 0;
          for (String segment in uri_parameters_segments) {
            if (segment == '{var}') {
              requested_path_segments[i] = '{var}';
            }
            i++;
          }
          if (uri_parameters_segments.join() ==
              requested_path_segments.join()) {
            return true;
          }
          return false;
        }
      } else {
        return false; // returning false because paths are null
      }
    }
  }

  RestedResource() {
    //disk = new RestedVirtualDisk();
    functions['get'] = get;
    functions['post'] = post;
    functions['put'] = put;
    functions['patch'] = patch;
    functions['delete'] = delete;
    functions['copy'] = copy;
    functions['head'] = head;
    functions['options'] = options;
    functions['link'] = link;
    functions['unlink'] = unlink;
    functions['purge'] = purge;
    functions['lock'] = lock;
    functions['unlock'] = unlock;
    functions['propfind'] = propfind;
    functions['view'] = view;

    schemas['get'] = null;
    schemas['post'] = null;
    schemas['put'] = null;
    schemas['patch'] = null;
    schemas['delete'] = null;
    schemas['copy'] = null;
    schemas['head'] = null;
    schemas['options'] = null;
    schemas['link'] = null;
    schemas['unlink'] = null;
    schemas['purge'] = null;
    schemas['lock'] = null;
    schemas['unlock'] = null;
    schemas['propfind'] = null;
    schemas['view'] = null;

    for (String value in rsettings.allowedMethods) {
      _token_required[value] = false;
    }

    Map<String, String> _envVars = Platform.environment;
    if(_envVars.containsKey('VALIDATE_ALL_QUERY_PARAMETERS')) {
      if(_envVars['VALIDATE_ALL_QUERY_PARAMETERS'].toUpperCase() == 'TRUE') {
        validateAllQueryParameters = true;
      }
    }
  }

  setExternalFunctions() {
    /*
        All external functions are defined with operationId key 'string' and 'function' in xfunctions map in external.dart
        
        Map<String, Function(RestedRequest)> xfunctions = {
          'list-users': listusers
        };

        When .yaml is read OAPI3 object defined in openapi3.dart, this Resource is created and returned to the requesthandler.
        In that process, the operationId <String, String> map in this Resource is updated with http-method and xfunction key
        references.

        Map<String, String> operationId = {
          'get': 'list-users'
        }

        All Resources have a functions<String, Function> map containing all of the http methods:

        Map<String, Function> functions = {
          'get': get,
          'post': post,
          ...
        }

        This setExternalFunctions will read through all of the operationId entries and set the function[key] = xfunctions[key]
    */
    for(MapEntry e in operationId.entries) {
      functions[e.key] = xfunctions[e.value];
      print("Imported operationId " + e.value + " for " + e.key.toUpperCase() + " " + path);

      if(xfunctions_require_token.contains(e.value)) {
        print("Token required on " + e.key + " " + path);
        require_token(e.key);
      }
    }
  }

  void setSchema(String method, RestedSchema schema) {
    if(schemas.containsKey(method.toLowerCase())) {
      schemas[method.toLowerCase()] = schema;
    }
  }

  void get(RestedRequest request) { request.response(status: 501); }
  void post(RestedRequest request) { request.response(status: 501); }
  void put(RestedRequest request) { request.response(status: 501); }
  void patch(RestedRequest request) { request.response(status: 501); }
  void delete(RestedRequest request) { request.response(status: 501); }
  void copy(RestedRequest request) { request.response(status: 501); }
  void head(RestedRequest request) { request.response(status: 501); }
  void options(RestedRequest request) { request.response(status: 501); }
  void link(RestedRequest request) { request.response(status: 501); }
  void unlink(RestedRequest request) { request.response(status: 501); }
  void purge(RestedRequest request) { request.response(status: 501); }
  void lock(RestedRequest request) { request.response(status: 501); }
  void unlock(RestedRequest request) { request.response(status: 501); }
  void propfind(RestedRequest request) { request.response(status: 501); }
  void view(RestedRequest request) { request.response(status: 501); }

  void callback(RestedRequest request) {}

  void wrapper(String method, RestedRequest request) async {

    if(request == null) {
      print("Error in wrapper(): request is null");
    }

    // If the resource method has a schema requirement
    if(schemas[method] != null) {
      if(schemas[method].validate(request.body)) {
        await functions[method](request);
        await callback(request);
      } else {
        request.response(type: "error", status: 400);
      }
    } 
    // If the resource method does NOT have a schema requirement
    else {
      if(functions[method] == null) {
        request.response(status: 501);
      } else {
        await functions[method](request);
      }
      await callback(request);
    }

    if (request.session.containsKey('delete')) {
      if (request.session['delete']) {
        manager.deleteSession(request.session['id']);
        request.request.response.headers
            .add("Set-Cookie", "session=; Path=/; Max-Age=0; HttpOnly");
      }
    } else {
      if (request.session.length > 0) {
        saveSession(request);
      }
    }
  }

  // If the request contains an access_token then it has already been verified before this function
  // is executed. If the corresponding http method protection variable is set to true then this
  // function will check if access_token is set (and hence verified). If it is then it will allow
  // the http method to execute. If access_token is null it will return an 401 Unathorized error
  // response. If the http method protection variable is set to false however then it will execute
  // the corresponding method without any checks.
  void doMethod(String method, RestedRequest request) async {
    String result = validateUriParameters(request.uri_parameters);
    if(result == "OK") {
      result = validateQueryParameters(method, request.query_parameters);
    }
    

    if(result != "OK") {
      request.response(data: "400 " + result.toString());
      RestedResponse response = RestedResponse(request);
      response.respond();
      return;
    }

    method = method.toLowerCase();
    if (_token_required[method]) {
      if (request.access_token != null) {
        await wrapper(method, request);
        RestedResponse response = RestedResponse(request);
        response.respond();
      } else {
        if (protected_redirect != null) {
          request.response(type: "redirect", data: protected_redirect);
          RestedResponse response = RestedResponse(request);
          response.respond();
        } else {
          request.response(data: "401 error somethingsomething");
          RestedResponse response = RestedResponse(request);
          response.respond();
        }
      }
    } else {
      await wrapper(method, request);
      RestedResponse response = RestedResponse(request);
      response.respond();
    }
  }
}