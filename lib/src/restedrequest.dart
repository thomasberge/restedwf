// Part of Rested Web Framework
// www.restedwf.com
// © 2020 Thomas Sebastian Berge

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'dart:isolate';

import 'package:path/path.dart' as p;
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'package:rested_script/rested_script.dart';

import 'responses.dart';
import 'restedsettings.dart';
import 'restedsession.dart';
import 'mimetypes.dart';

Responses error_responses = new Responses();
Mimetypes mimetypes = new Mimetypes();

class CookieCollection {
  List<Cookie> cookies = null;

  CookieCollection(this.cookies);

  List<Cookie> get(String name) {
    List<Cookie> returnlist = new List();
    for (Cookie cookie in cookies) {
      if (cookie.name == name) {
        returnlist.add(cookie);
      }
    }
    return returnlist;
  }

  Cookie getFirst(String name) {
    for (Cookie cookie in cookies) {
      if (cookie.name == name) {
        return cookie;
      }
    }
    return null;
  }

  bool containsKey(String name) {
    bool containskey = false;
    for (Cookie cookie in cookies) {
      if (cookie.name == name) {
        containskey = true;
      }
    }
    return containskey;
  }
}

class RestedRequest {
  String hostAddress;
  int hostPort;
  
  int status = 0;
  String error = "";
  bool deleteSession = false;
  HttpRequest request;
  String method;
  String path;
  String access_token;
  Map body = Map<String, dynamic>();
  CookieCollection cookies = null;
  Map<String, dynamic> session = new Map();

  String toString() {
    Map<String, dynamic> restedrequest = new Map();
    Map<String, dynamic> httprequest = new Map();
    httprequest['cookies'] = request.cookies.toString();
    httprequest['headers'] = request.headers.toString();
    httprequest['certificate'] = request.certificate.toString();
    httprequest['connectionInfo'] = request.connectionInfo.toString();
    httprequest['contentLength'] = request.contentLength.toString();
    restedrequest['method'] = method.toString();
    restedrequest['path'] = path.toString();
    restedrequest['access_token'] = access_token.toString();
    restedrequest['body'] = body.toString();
    restedrequest['HttpRequest'] = httprequest;
    return restedrequest.toString();
  }

  void setBody(Map bodymap) {
    body = bodymap;
    print("Content: " + body.toString());
  }

  void createCookie(String name, String value,
      {String domain = "", String path = "/", int maxAge = null}) {
    Cookie newcookie = new Cookie(name, value);
    if (domain != "") {
      newcookie.domain = domain;
    }
    if (path != "") {
      newcookie.path = path;
    }
    if (maxAge != null) {
      newcookie.maxAge = maxAge;
    }
    print("Adding new cookie: " + newcookie.toString());
    request.response.cookies.add(newcookie);
  }

  void removeCookie(String name) {
    Cookie newcookie = new Cookie(name, "");
    newcookie.path = "/";
    newcookie.maxAge = 0;
    request.response.cookies.add(newcookie);
  }

  void removeSession() {
    removeCookie("session");
    deleteSession = true;
  }

  // Try to find a cookie.
  String getCookie(String name) {
    var temp = cookies.getFirst(name);
    if (temp != null) {
      return temp.value;
    } else {
      print("cookie not found: " + name);
      return "";
    }
  }

  RestedRequest(HttpRequest this.request, this.hostAddress, this.hostPort) {

    if (rsettings.cookies_enabled) {
      cookies = new CookieCollection(request.cookies);
    }

    // By splitting by hostname the full request path will reside in temp[1] while the protocol will reside in temp[0]
    //List temp = request.requestedUri.toString().split(request.headers.host);
    path = request.requestedUri.path;
    method = request.method.toString().toUpperCase();
    print(method + " " + path);
  }

  Map<String, String> uri_parameters = new Map();

  void createPathArgumentMap(String tagged_path, List<String> keys) {
    print("keys=" + keys.toString());
    print("tagged_path=" + tagged_path);

    List<String> path_segments = path.substring(1).split('/');
    List<String> tagged_path_segments = tagged_path.substring(1).split('/');
    int i = 0;
    int x = 0;
    for (String segment in tagged_path_segments) {
      if (segment == '{var}') {
        uri_parameters[keys[x]] = path_segments[i];
        x++;
      }
      i++;
    }
  }

  Map<String, dynamic> restedresponse = new Map();

  void response({
    String type = "text",
    String data = "",
    File file = null,
    bool stream = false,
    int status = 200,
    String filepath = null,
  }) {
    restedresponse['type'] = type;
    restedresponse['data'] = data;
    restedresponse['file'] = file;
    restedresponse['isStream'] = stream;
    restedresponse['filepath'] = filepath;
    restedresponse['status'] = status;
  }
/*
  void oldresponse(
      {String type = "text",
      String data = "",
      File file = null,
      bool stream = false}) {
    if (type == "redirect") {
      request.response.redirect(Uri.http(request.requestedUri.host, data));
    } else {
      // Headers
      print("Type=" + type.toString());
      request.response.headers.contentType = mimetypes.getContentType(type);
      request.response.statusCode = HttpStatus.ok;

      if (stream) {
        request.response.headers.set(HttpHeaders.ACCEPT_RANGES, "bytes");
      }

      // Writing data and closing
      if (stream) {
        Future f = file.readAsBytes();
        request.response.addStream(f.asStream()).whenComplete(() {
          request.response.close();
        });
      } else {
        if (data != "") {
          request.response.write(data);
        }
        request.response.close();
      }
    }
  }*/

  void redirect(String resource) {
    restedresponse['type'] = "redirect";
    restedresponse['data'] = resource;
  }

  Map<String, int> getRanges(String rangeheader, int fileLength) {
    Map<String, int> values = new Map();
    List<String> ranges = rangeheader.split(',');
    if (ranges.length > 1) {
      print("Multi-range request not supported!");
    } else {
      List<String> range = ranges[0].split('-');
      values["bytesFrom"] = int.parse(range[0]);
      values["butesTotal"] = fileLength; //file.lengthSync();
      try {
        values["bytesTo"] = int.parse(range[1]);
      } on Exception {
        values["bytesTo"] = values["butesTotal"];
      }
      return values;
    }
  }
}
