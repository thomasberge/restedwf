// Rested v0.1.0-alpha
// www.restedwf.com
// © 2020 Thomas Sebastian Berge

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:encrypt/encrypt.dart';

import 'src/consolemessages.dart';
import 'src/restedscript.dart';
import 'src/parser.dart';

import 'src/restedrequest.dart';
export 'src/restedrequest.dart';
import 'src/restedsettings.dart';

ConsoleMessages console = new ConsoleMessages(debug_level: 4);
RestedSettings rsettings;
Map responses = new Map();
Function _custom_JWT_verification;

class Rested {
  List<RestedResource> resources = new List();

  Rested() {
    rsettings = new RestedSettings();
    _custom_JWT_verification = custom_JWT_verification;
  }

  bool custom_JWT_verification(String token) {
    return true;
  }

  void set_jwt_key(String key) {
    rsettings.jwt_key = key;
  }

  void set_jwt_duration(int minutes) {
    rsettings.jwt_duration = minutes;
  }

  void set_jwt_issuer(String issuer) {
    rsettings.jwt_issuer = issuer;
  }

  Map _convertUrlVariablesToMap(String urlencoded) {
    Map map = new Map();
    List<String> pairs = urlencoded.split('&');
    pairs.forEach((pair) {
      List<String> variable = pair.split('=');
      map[variable[0]] = variable[1];
    });
    return map;
  }

  // Validates the incoming request and passes it to the proper RestedResource object
  //
  // IMPORTANT: If body contains a first element called "body" then the contents of that
  //            element will become the entire body contents. Some applications seems to
  //            wrap the content like this { "body": { <actual content> }}. This means that
  //            if there is information outside the body tag that is part of the actual
  //            body then they will be dropped when body = body['body']; is performed.
  void handle(HttpRequest incomingRequest) async {
    RestedRequest request = new RestedRequest(incomingRequest, rsettings);

    String access_token = null;
    String unverified_access_token = null;
    int exception = 0;
    Map body = new Map();

    if (rsettings.cookies_enabled) {
      if (request.cookie.containsKey("access_token")) {
        unverified_access_token = request.cookie.getKey("access_token");
      }
    }

    // Crude and to-be-improved method of extracring the access_token from a client cookie
    // and saving it as unverified.
    /*
      if (incomingRequest.cookies != '[]') {
        List<String> values = incomingRequest.cookies
            .toString()
            .substring(1, incomingRequest.cookies.toString().length - 1)
            .split(';');
        for (String value in values) {
          if (value.contains('access_token=')) {
            unverified_access_token = value.substring(13);
          }
        }
      }
    }*/

    // If there is an Authorization header, the token will be extracted if it is prefixed
    // in the header either as Bearer, access_token, token or jwt followed by a space and
    // the jwt token itself. The extracted token will be stored in the access_token variable
    // and passed to the RestedRequest object. If it fails it will set exception to true,
    // which in turn will trigger a 400 Bad Request error response.

    try {
      if (unverified_access_token == null) {
        unverified_access_token =
            incomingRequest.headers.value(HttpHeaders.authorizationHeader);

        if (unverified_access_token != null) {
          List<String> authtype = unverified_access_token.split(' ');
          if (authtype[0] == 'Bearer') {
            unverified_access_token =
                unverified_access_token.replaceAll('Bearer ', '');
          } else if (authtype[0] == 'access_token') {
            unverified_access_token =
                unverified_access_token.replaceAll('access_token ', '');
          } else if (authtype[0] == 'token') {
            unverified_access_token =
                unverified_access_token.replaceAll('token ', '');
          } else if (authtype[0] == 'jwt') {
            unverified_access_token =
                unverified_access_token.replaceAll('jwt ', '');
          } else {
            exception = 400;
            console.error("Malformed Authorization header");
          }
        }
      }

      if (exception == 0) {
        if (unverified_access_token != null) {
          console.debug("Verifying token ...");
          // Verify that the token is valid. Raise exception it it is not.
          RestedJWT jwt_handler = new RestedJWT();
          int verify_result = jwt_handler.verify_token(unverified_access_token);
          if (verify_result == 401) {
            console.debug("Token not valid!");
            exception = verify_result;
          } else if (verify_result == 452) {
            console.debug("Token expired!");
            exception = verify_result;
          } else {
            console.debug("Token verified!");
            access_token = unverified_access_token;
          }
        }
      }
    } on Exception catch (e) {
      console.error(e.toString());
      exception = 400;
    }

    // Splitting as a list in order to check each element instead of doing a literal.
    // Example: application/json; charset=utf-8
    List<String> type =
        incomingRequest.headers.contentType.toString().split(';');

    // If there are no headers (simplest GET request)
    if (type.toString() == "[null]") {
      // do nothing... or perhaps get variables from URL?

      // If body is JSON
    } else if (type.contains("application/json")) {
      String temp = await utf8.decoder.bind(incomingRequest).join();
      try {
        body = json.decode(temp);
      } on FormatException catch (e) {
        console.error(e.toString());
        exception = 400;
      }
      if (body.containsKey("body")) {
        body = body['body'];
        request.setBody(body);
      }

      // Grab urlencoded variables and convert to Map. If it contains a key 'body' then
      // most likely the structure is body { <data> }. Extract the data and set it as body.
      // This can potentially lead to &/¤#-ups so a method to check if there is a singular
      // root element "body" should replace this garbage.
    } else if (type.contains("application/x-www-form-urlencoded")) {
      var urlencoded = await utf8.decoder.bind(incomingRequest).join();
      body = _convertUrlVariablesToMap(urlencoded);
      if (body.containsKey("body")) {
        body = body['body'];
        request.setBody(body);
      } else {
        request.setBody(body);
      }

      // If body isn't specified
    } else {
      console.alert("UNSUPPORTED HEADER TYPE: " + type.toString());
      body['body'] = await utf8.decoder.bind(incomingRequest).join();
    }

    // Creates the RestedRequest first. If the exception error code is set to 452 Token Expired
    // an "error" in rscript_args is added along with error description.
    // we reset error code and makes sure access_token is blank before we continue. After that,
    // if the error code is still not 0 we return an error response.

    //request.cookie = cookie;

    if (exception == 452) {
      request.rscript_args.setString("error", "Token has expired.");
      access_token = null;
      exception = 0;
    }

    if (exception != 0) {
      request.errorResponse(exception);
    } else {
      request.access_token = access_token;

      int index = getResourceIndex(request.path);

      if (index != null) {
        if (resources[index].path.contains('<')) {
          request.createPathArgumentMap(resources[index].tagged_path,
              PathParser.get_keys(resources[index].path));
        }
        resources[index].doMethod(request.method, request);
      } else {
        if (rsettings.files_enabled) {
          String path = getFilePath(request.path);
          if (path != null) {
            request.fileResponse(path);
          } else {
            console.debug("Resource not found at endpoint " + request.path);
            request.errorResponse(404);
          }
        } else {
          console.debug("Resource not found at endpoint " + request.path);
          request.errorResponse(404);
        }
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

// A RestedRemoteServer is a collection of server information such as url and port
// as well as functions that make it easier to perform communication with the server.
class RestedRemoteServer {
  String address;
  int port;

  RestedRemoteServer(String inc_address, int inc_port) {
    address = inc_address;
    port = inc_port;
  }

  Future<String> get(String url, {String text = null}) async {
    HttpClientRequest api_request = await HttpClient().get(address, port, url)
      ..write(text);

    HttpClientResponse api_response = await api_request.close();
    String temp = await utf8.decoder.bind(api_response).join();
    return temp;
  }

  Future<String> post(String url,
      {String token = null, Map json = null, String text = null}) async {
    //HttpClientRequest api_request;

    final client = HttpClient();
    final api_request = await client.post(address, port, url);

    if (json != null) {
      api_request.headers
          .set(HttpHeaders.contentTypeHeader, 'application/json');
      api_request.write(jsonEncode(json));
      //api_request = await HttpClient().post(address, port, url)
      //..headers.contentType = ContentType.json
      //..write(jsonEncode(json));
    } else {
      api_request.headers.set(HttpHeaders.contentTypeHeader, 'text/plain');
      api_request.write(text);
      //api_request = await HttpClient().post(address, port, url)
      //  ..write(text);
    }

    HttpClientResponse api_response = await api_request.close();
    String temp = await utf8.decoder.bind(api_response).join();
    return temp;
  }
}

class RestedSchema {
  List<String> mandatory_strings = new List();
  List<String> mandatory_strings_label = new List();
  List<String> strings = new List();
  List<String> strings_label = new List();

  RestedSchema();

  void addString(String label, String data, {bool mandatory = false}) {
    if (mandatory) {
      mandatory_strings_label.add(label);
      mandatory_strings.add(data);
    } else {
      strings_label.add(label);
      strings.add(data);
    }
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

  JwtClaim generate_claimset({Map additional_claims = null}) {
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
    JwtClaim claim_set =
        generate_claimset(additional_claims: additional_claims);
    String token = issueJwtHS256(claim_set, rsettings.jwt_key);
    Map tokenmap = {"access_token": token};
    return tokenmap;
  }

  int verify_token(String token) {
    try {
      final JwtClaim decClaimSet =
          verifyJwtHS256Signature(token, rsettings.jwt_key);
      DateTime issued_at = DateTime.parse(decClaimSet['iat'].toString());
      DateTime expires = DateTime.parse(decClaimSet['exp'].toString());
      Duration duration = DateTime.now().difference(issued_at);
      if (duration.inMinutes >= rsettings.jwt_duration) {
        return (452); // "Token has expired"
      } else {
        if (_custom_JWT_verification(token)) {
          return (200); // "OK"
        } else {
          return (453);
        }
      }
    } on JwtException {
      return (401); // "Unauthorized"
    }
  }

  Map extract_claims(String token) {
    try {
      // Verify the signature and extract claimset
      final JwtClaim decClaimSet =
          verifyJwtHS256Signature(token, rsettings.jwt_key);

      // Validate the claimset
      decClaimSet.validate(issuer: rsettings.jwt_issuer);
      Map claims = json.decode(json.encode(decClaimSet.toString()));
      return (claims);
    } on JwtException {
      return (null);
    }
  }
}

class RestedResource {
  String path = null;
  String tagged_path = null;

  void setPath(String resourcepath) {
    path = resourcepath;
    if (resourcepath.contains('<')) {
      tagged_path = PathParser.get_tagged_path(path);
    }
  }

  bool pathMatch(String requested_path) {
    if (path == requested_path) {
      return true;
    } else {
      if (tagged_path != null && requested_path != null) {
        List<String> requested_path_segments = requested_path
            .substring(1)
            .split('/'); // substring in order to remove first /
        List<String> tagged_path_segments = tagged_path.substring(1).split('/');
        if (requested_path_segments.length != tagged_path_segments.length) {
          return false;
        } else {
          int i = 0;
          for (String segment in tagged_path_segments) {
            if (segment == '<var>') {
              requested_path_segments[i] = '<var>';
            }
            i++;
          }
          if (tagged_path_segments.join() == requested_path_segments.join()) {
            return true;
          }
          return false;
        }
      } else {
        return false; // returning false because paths are null
      }
    }
  }

  // Stored functions for each HTTP method. Example <'Get', get> can be used as _functions['get](request);
  Map _functions = new Map<String, Function>();

  // Storage of bool determining if access_token is required for the http method (_functions). Use method
  // instead of setting the variable directly.
  Map _token_required = new Map<String, bool>();

  void require_token(String method, {String redirect_url = null}) {
    _token_required[method] = true;
  }

  // If access to method is protected by an access_token then instead of retuning 401 Unauthorized it is
  // possible to return a redirect instead by setting the URL in this variable.
  String _protected_redirect = null;

  void invalid_token_redirect(String url) {
    _protected_redirect = url;
  }

  RestedResource() {
    _functions['get'] = get;
    _functions['post'] = post;
    _functions['put'] = put;
    _functions['patch'] = patch;
    _functions['delete'] = delete;
    _functions['copy'] = copy;
    _functions['head'] = head;
    _functions['options'] = options;
    _functions['link'] = link;
    _functions['unlink'] = unlink;
    _functions['purge'] = purge;
    _functions['lock'] = lock;
    _functions['unlock'] = unlock;
    _functions['propfind'] = propfind;
    _functions['view'] = view;
    _token_required['get'] = false;
    _token_required['post'] = false;
    _token_required['put'] = false;
    _token_required['patch'] = false;
    _token_required['delete'] = false;
    _token_required['copy'] = false;
    _token_required['head'] = false;
    _token_required['options'] = false;
    _token_required['link'] = false;
    _token_required['unlink'] = false;
    _token_required['purge'] = false;
    _token_required['lock'] = false;
    _token_required['unlock'] = false;
    _token_required['propfind'] = false;
    _token_required['view'] = false;
  }

  //void addPath(String path) {
  //  this.path = path;
  //}

  void get(RestedRequest request) {}
  void post(RestedRequest request) {}
  void put(RestedRequest request) {}
  void patch(RestedRequest request) {}
  void delete(RestedRequest request) {}
  void copy(RestedRequest request) {}
  void head(RestedRequest request) {}
  void options(RestedRequest request) {}
  void link(RestedRequest request) {}
  void unlink(RestedRequest request) {}
  void purge(RestedRequest request) {}
  void lock(RestedRequest request) {}
  void unlock(RestedRequest request) {}
  void propfind(RestedRequest request) {}
  void view(RestedRequest request) {}

  // If the request contains an access_token then it has already been verified before this function
  // is executed. If the corresponding http method protection variable is set to true then this
  // function will check if access_token is set (and hence verified). If it is then it will allow
  // the http method to execute. If access_token is null it will return an 401 Unathorized error
  // response. If the http method protection variable is set to false however then it will execute
  // the corresponding method without any checks.
  void doMethod(String method, RestedRequest request) {
    method = method.toLowerCase();
    if (_token_required[method]) {
      if (request.access_token != null) {
        _functions[method](request);
      } else {
        if (_protected_redirect != null) {
          request.redirect(_protected_redirect);
        } else {
          request.errorResponse(401);
        }
      }
    } else {
      _functions[method](request);
    }
  }
}

class PathParser {
  PathParser();

  static String get_tagged_path(String path) {
    if (path.contains('<')) {
      Parser parser = new Parser(path);
      int args = '<'.allMatches(path).length;
      while (args > 0) {
        parser.moveUntil('<');
        parser.move(); // add one more to not select the <
        parser.setStartMark();
        parser.moveUntil('>');
        parser.setStopMark();
        parser.position = parser.start_mark;
        parser.deleteMarkedString();
        parser.insertAtPosition('var');
        args--;
      }
      return parser.data;
    } else {
      return null;
    }
  }

  static List<String> get_keys(String path) {
    if (path.contains('<')) {
      List<String> varlist = new List();
      Parser parser = new Parser(path);
      int args = '<'.allMatches(path).length;
      while (args > 0) {
        parser.moveUntil('<');
        parser.move(); // add one more to not select the <
        parser.setStartMark();
        parser.moveUntil('>');
        parser.setStopMark();
        varlist.add(parser.getMarkedString());
        parser.position = parser.start_mark;
        parser.deleteMarkedString();
        args--;
      }
      return varlist;
    } else {
      return null;
    }
  }
}
