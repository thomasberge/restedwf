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

Function _custom_JWT_verification;
SessionManager manager;
String rootDirectory = null;
String resourcesDirectory = null;
Errors error_handler = Errors();

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

          if (unverified_access_token != null) {
            List<String> authtype = unverified_access_token.split(' ');
            List<String> valid_auths = ['BEARER', 'ACCESS_TOKEN', 'TOKEN', 'REFRESH_TOKEN', 'JWT'];
            if (valid_auths.contains(authtype[0].toUpperCase())) {
              unverified_access_token = authtype[1];
            } else {
              error_handler.raise(request, 401);
              return;
            }
          }
        }

        if (unverified_access_token != null) {
          // Verify that the token is valid. Raise exception it it is not.
          RestedJWT jwt_handler = new RestedJWT();
          int verify_result = jwt_handler.verify_token(unverified_access_token);
          if (verify_result == 401) {
            error_handler.raise(request, 401);
            return;
          } else {
            access_token = unverified_access_token;
          }
        }

      } on Exception catch (e) {
        console.error(e.toString());
        error_handler.raise(request, 400);
        return;
      }
    }

    // 3 --- Identify the contentType so we can create the body map of the request correctly.

    // Splitting as a list in order to check each element instead of doing a literal.
    // Example: application/json; charset=utf-8
    // Each bodymap conversion function should return NULL if conversion fails for some reason.
    // If the data is empty however it should return an empty map.
    List<String> type = incomingRequest.headers.contentType.toString().split(';');

    if (type.contains("application/json")) {

      String jsonstring = await utf8.decoder.bind(incomingRequest).join();

      // dirty trick to manually change a json sent as string to a parsable string. Unelegant af
      if(jsonstring.substring(0,1) == '"') {
        jsonstring = jsonstring.substring(1, jsonstring.length -1);
        jsonstring = jsonstring.replaceAll(r'\"', '"');
      }

      Map jsonmap = {};

      try {
        jsonmap = json.decode(jsonstring);
      } catch(e) {
        error_handler.raise(request, 400);
        return;
      }


      // some clients wrap body in a body-block. If this is the case here then the content of the
      // body block is extracted to become the new body.
      if (jsonmap.containsKey("body")) {
        jsonmap = jsonmap['body'];
      }
      request.setBody(jsonmap);

    } else if (type.contains("application/x-www-form-urlencoded")) {
      String urlencoded = await utf8.decoder.bind(incomingRequest).join();
      Map body = queryParametersToBodyMap(urlencoded);
      request.setBody(body);

    } else if (type.contains("multipart/form-data")) {
      String data = await utf8.decoder.bind(incomingRequest).join();
      Map body = multipartFormDataToBodyMap(type.toString(), data);
      request.text = data;
      request.setBody(body);

    } else if (type.contains("text/plain")) {
      String data = await utf8.decoder.bind(incomingRequest).join();
      request.text = data;

    } else {
      if (type.toString() != "[null]") {
      String data = await utf8.decoder.bind(incomingRequest).join();
      Map body = {};
      request.setBody(body);
        console.alert("UNSUPPORTED HEADER TYPE: " + type.toString());
      }
    }

    if (request.body == null) {
        error_handler.raise(request, 400);
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

  // Multipart formdata
  // file not supported yet, only works on text
  // https://ec.haxx.se/http/http-multipart
  Map<String, dynamic> multipartFormDataToBodyMap(
      String typeHeader, String data) {
    Map<String, dynamic> bodymap = new Map();

    String boundary = typeHeader.split('boundary=')[1];
    boundary = boundary.substring(0, boundary.length - 1);

    List<String> form = data.split(boundary);
    for (String item in form) {
      if (item.contains("Content-Disposition")) {
        List<String> split = item.split('name="');
        List<String> split2 = split[1].split('"');
        String name = split2[0];

        LineSplitter ls = new LineSplitter();
        List<String> lines = ls.convert(split2[1]);

        // First two are always blank. Last is always two dashes. We remove those and
        // are left with a multiline-supported thingamajiggy
        lines.removeAt(0);
        lines.removeAt(0);
        lines.removeLast();
        String value = "";
        if (lines.length > 1) {
          for (String line in lines) {
            value = value + line + '\n';
          }
        } else {
          value = lines[0];
        }
        bodymap[name] = value;
      }
    }
    return bodymap;
  }

  // Grab urlencoded variables and convert to Map. If it contains a key 'body' then
  // most likely the structure is body { <data> }. Extract the data and set it as body.
  // This can potentially lead to &/¤#-ups so a method to check if there is a singular
  // root element "body" should replace this garbage.
  Map queryParametersToBodyMap(String urlencoded) {
    Map bodymap = new Map();
    if (urlencoded == null || urlencoded == "") {
      return bodymap;
    } else {
      List<String> pairs = urlencoded.split('&');
      pairs.forEach((pair) {
        List<String> variable = pair.split('=');
        bodymap[variable[0]] = variable[1];
      });

      if (bodymap.containsKey("body")) {
        bodymap = bodymap['body'];
      }

      return bodymap;
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
        String host = request.request.requestedUri.host + ":" + request.hostPort.toString();
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
  String path = null;
  String uri_parameters = null;
  List<String> uri_parameters_list = new List();

  void setPath(String resourcepath) {
    path = resourcepath;
    if (resourcepath.contains('{')) {
      uri_parameters = PathParser.get_uri_parameters(path);
    }
    console.debug("uri_parameters for path '" +
        path.toString() +
        "' is " +
        uri_parameters.toString());
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

  void require_token(String _method, {String redirect_url = null}) {
    _token_required[_method] = true;
  }

  // If access to method is protected by an access_token then instead of retuning 401 Unauthorized it is
  // possible to return a redirect instead by setting the URL in this variable.
  String protected_redirect = null;

  void invalid_token_redirect(String _url) {
    protected_redirect = _url;
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
  }

  setExternalFunctions() {
    for(MapEntry e in operationId.entries) {
        Function _func = xfunctions[e.value];
        functions[e.key] = _func;
        print("Imported operationId " + e.value + " for " + e.key.toUpperCase() + " " + path);
    }
    //print(functions.toString());
  }

  void setSchema(String method, RestedSchema schema) {
    if(schemas.containsKey(method.toLowerCase())) {
      schemas[method.toLowerCase()] = schema;
    }
  }

  Map<String, dynamic> error404 = { "error": "not implemented" };

  void get(RestedRequest request) { request.response(type: "json", data: json.encode(error404)); }
  void post(RestedRequest request) { request.response(type: "json", data: json.encode(error404)); }
  void put(RestedRequest request) { request.response(type: "json", data: json.encode(error404)); }
  void patch(RestedRequest request) { request.response(type: "json", data: json.encode(error404)); }
  void delete(RestedRequest request) { request.response(type: "json", data: json.encode(error404)); }
  void copy(RestedRequest request) { request.response(type: "json", data: json.encode(error404)); }
  void head(RestedRequest request) { request.response(type: "json", data: json.encode(error404)); }
  void options(RestedRequest request) { request.response(type: "json", data: json.encode(error404)); }
  void link(RestedRequest request) { request.response(type: "json", data: json.encode(error404)); }
  void unlink(RestedRequest request) { request.response(type: "json", data: json.encode(error404)); }
  void purge(RestedRequest request) { request.response(type: "json", data: json.encode(error404)); }
  void lock(RestedRequest request) { request.response(type: "json", data: json.encode(error404)); }
  void unlock(RestedRequest request) { request.response(type: "json", data: json.encode(error404)); }
  void propfind(RestedRequest request) { request.response(type: "json", data: json.encode(error404)); }
  void view(RestedRequest request) { request.response(type: "json", data: json.encode(error404)); }

  void callback(RestedRequest request) {}

  Map<String, dynamic> getRequestSchema = null;

  void wrapper(String method, RestedRequest request) async {

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
      await functions[method](request);
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
    method = method.toLowerCase();
    if (_token_required[method]) {
      if (request.access_token != null) {
        await wrapper(method, request);
        RestedResponse response = RestedResponse(request);
        response.respond();
      } else {
        if (protected_redirect != null) {
          console.debug("PROTECTED REDIRECT!");
          request.response(type: "redirect", data: protected_redirect);
          RestedResponse response = RestedResponse(request);
          //request.request.response.statusCode = response.responsedata['status'];
          response.respond();
        } else {
          request.response(data: "401 error somethingsomething");
        }
      }
    } else {
      await wrapper(method, request);
      RestedResponse response = RestedResponse(request);
      response.respond();
    }
  }
}