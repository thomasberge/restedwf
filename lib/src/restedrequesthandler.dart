// Part of Rested Web Framework
// www.restedwf.com
// © 2020 Thomas Sebastian Berge

import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'restedsession.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'consolemessages.dart';
import 'restedsettings.dart';
import 'restedrequest.dart';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'pathparser.dart';
import 'restedresource.dart';

ConsoleMessages console = new ConsoleMessages(debug_level: 4);
Function _custom_JWT_verification;
RestedSettings rsettings;

class RestedRequestHandler {
  List<RestedResource> resources = new List();
  RestedSessionManager sessions;

  Cookie saveSession(RestedRequest request) {
    if(request.session.containsKey('id')){
      sessions.updateSession(request.session);
      return sessions.getSessionCookie(request.session['id']);
    } else {
      String id = sessions.createSession(request.session);
      return sessions.getSessionCookie(id);
    }
  }

  void redirect(RestedRequest request, String url) {
    request.request.response.redirect(Uri.http(request.request.requestedUri.host, url));
  }

  RestedRequestHandler() {
    rsettings = new RestedSettings();
    _custom_JWT_verification = custom_JWT_verification;

    if(rsettings.cookies_enabled && rsettings.sessions_enabled) {
      sessions = new RestedSessionManager();
    }
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
  //            body then they will be dropped when body = body['body']; is performed. ////////////////////////////////////////////////////////////////////////
  void handle(HttpRequest incomingRequest) async {
    RestedRequest request = new RestedRequest(incomingRequest, rsettings);

    if (rsettings.cookies_enabled && rsettings.sessions_enabled) {
      if(request.cookies.containsKey('session_cookie')) {

        // Decrypt the session id
        var session_id = sessions.decryptSessionId(request.cookies.getFirst('session_cookie').value);

        // If decrypt fails then return error 400 bad request
        if(session_id == null) {
          request.errorResponse(400);
          return;
        }

        // Check if session exists in session manager
        if(sessions.containsKey(session_id)) {
          
          // Get the session data from the session manager and set it in the request
          request.session = null;
          request.session = sessions.getSessionData(session_id);
          console.debug("Session data:" + request.session.toString());
        }


        //var session = sessions.getSession(request.cookies.getFirst('session_cookie').value);
        //if(session != null) {
        //  request.session = session;
        //}
      }
    }

    String access_token = null;
    String unverified_access_token = null;
    bool expired_token = false;
    int exception = 0;
    Map body = new Map();

    // If sessions (and cookies) are enable, access_token needs to be in the session.
    if (rsettings.cookies_enabled) {
      if (rsettings.sessions_enabled) {
          if(request.session.containsKey("access_token")) {
            unverified_access_token = request.session["access_token"];
          }
      } else {
        if (request.cookies.containsKey("access_token")) {
          unverified_access_token =
              request.cookies.getFirst("access_token").value;
        }
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

      // Unsure if this even triggers
      if (body.containsKey("body")) {
        body = body['body'];
      }

      request.setBody(body);

      // Grab urlencoded variables and convert to Map. If it contains a key 'body' then
      // most likely the structure is body { <data> }. Extract the data and set it as body.
      // This can potentially lead to &/¤#-ups so a method to check if there is a singular
      // root element "body" should replace this garbage.
    } else if (type.contains("application/x-www-form-urlencoded")) {
      var urlencoded = await utf8.decoder.bind(incomingRequest).join();
      body = _convertUrlVariablesToMap(urlencoded);

      if (body.containsKey("body")) {
        body = body['body'];
      }

      request.setBody(body);

      // If body isn't specified
    } else {
      console.alert("UNSUPPORTED HEADER TYPE: " + type.toString());
      body['body'] = await utf8.decoder.bind(incomingRequest).join();
    }

    // Creates the RestedRequest first. If the exception error code is set to 452 Token Expired
    // an "error" in rscript_args is added along with error description.
    // we reset error code and makes sure access_token is blank before we continue. After that,
    // if the error code is still not 0 we return an error response.

    if (exception == 452) {
      request.rscript_args.setString("error", "Token has expired.");
      access_token = null;
      exception = 0;
      expired_token = true;
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