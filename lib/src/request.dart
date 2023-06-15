import 'dart:io';
import 'dart:convert';

import 'package:rested_script/rested_script.dart';
import 'package:string_tools/string_tools.dart';

import 'cookiecollection.dart';
import 'globals.dart';

class RestedRequest {
  String content_type = "text";   // text, json, xml, form, binary
  int status = 0;
  bool deleteSession = false;
  HttpRequest request;
  late String method;
  late String path;
  String access_token = "";

  Map body = Map<String, dynamic>();
  String text = "";
  CookieCollection cookies = CookieCollection([]);
  Map<String, dynamic> session = {};
  Map<String, String> headers = {};
  Map<String, dynamic> claims = {};
  Map<String, String> uri_parameters = {};
  Map<String, String> query_parameters = {};
  Map<String, dynamic> restedresponse = {};
  Map<String, dynamic> form = {};
  String raw = "";

  void dump() {
    print("content_type:" + content_type.toString());
    print("status:" + status.toString());
    print("deleteSession:" + deleteSession.toString());
    print("request:" + request.toString());
    print("method:" + method.toString());
    print("path:" + path.toString());
    print("access_token:" + access_token.toString());
    print("body:" + body.toString());
    print("text:" + text.toString());
    print("cookies:" + cookies.toString());
    print("session:" + session.toString());
    print("headers:" + headers.toString());
    print("claims:" + claims.toString());
    print("uri_parameters:" + uri_parameters.toString());
    print("query_parameters:" + query_parameters.toString());
    print("restedresponse:" + restedresponse.toString());
    print("form:" + form.toString());
    print("raw:" + raw.toString());
  }

  bool checkSession(String key, dynamic value) {
    if(session.containsKey(key)) {
      if(session[key] == value) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  bool checkHeaders(String key, String value) {
    if(headers.containsKey(key)) {
      if(headers[key] == value) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  bool checkClaims(String key, dynamic value) {
    if(claims.containsKey(key)) {
      if(claims[key] == value) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

  bool checkUriParameters(String key, String value) {
    if(uri_parameters.containsKey(key)) {
      if(uri_parameters[key] == value) {
        return true;
      } else {
        return false;
      }
    } else {
      return false;
    }
  }

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

  
  
  void setHeaders() {
    LineSplitter ls = new LineSplitter();
    List<String> lines = ls.convert(request.headers.toString());
    for(String line in lines) {
      StringTools cursor = new StringTools(line);
      cursor.find(':');
      String key = cursor.getAllBeforePosition();
      if(cursor.getAfterPosition() == ' ') {
        cursor.next();
      }

      // If key is already present, append the value to existing value as comma separated string
      // IMPROVEMENT: Check each header type and append accordingly. See https://stackoverflow.com/questions/29549299/how-to-split-header-values
      if(headers.containsKey(key)) {
        if(headers[key] == null || headers[key] == "") {
          headers[key] = cursor.getAllAfterPosition();
        } else {
          headers[key] = headers[key]! + "," + cursor.getAllAfterPosition();
        }
      } else {
        headers[key] = cursor.getAllAfterPosition();
      }

      //print("headers = " + headers.toString());
    }
  }

  void setBody(Map bodymap) {
    body = bodymap;
    print("Content: " + body.toString());
  }

  void createCookie(String name, String value, {String domain = "", String path = "/", int maxAge = -1}) {
    Cookie newcookie = new Cookie(name, value);
    if (domain != "") {
      newcookie.domain = domain;
    }
    if (path != "") {
      newcookie.path = path;
    }
    if (maxAge > -1) {
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

  RestedRequest(HttpRequest this.request) {

    if (rsettings.getVariable('cookies_enabled')) {
      cookies = new CookieCollection(request.cookies);
    }

    // By splitting by hostname the full request path will reside in temp[1] while the protocol will reside in temp[0]
    //List temp = request.requestedUri.toString().split(request.headers.host);
    path = request.requestedUri.path;
    method = request.method.toString().toUpperCase();
    setHeaders();
    extractQueryParameters();
    print(method + " " + path);
  }

  void createPathArgumentMap(String tagged_path, List<String> keys) {
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

  void extractQueryParameters() {
    if(this.request.uri.toString().contains('?')) {
      List<String> qparams = (this.request.uri.toString().split('?')[1]).split('&');
      for(String param in qparams) {
        if(param.contains('=')) {
          String key = Uri.decodeComponent(param.split('=')[0]);
          String value = Uri.decodeComponent(param.split('=')[1]);
          query_parameters[key] = value;
        }
      }
    }
  }

  void response({
    String type = "text",
    String data = "",
    bool stream = false,
    int status = 200
  }) {
    restedresponse['type'] = type;
    restedresponse['data'] = data;
    restedresponse['isStream'] = stream;
    restedresponse['status'] = status;
  }

  void redirect(String resource) {
    restedresponse['type'] = "redirect";
    restedresponse['data'] = resource;
  }

  Map<String, int> getRanges(String rangeheader, int fileLength) {

    Map<String, int> values = {};
    List<String> ranges = rangeheader.split(',');

    if (ranges.length > 1) {
      print("Multi-range request not supported!");
      return values;
    } else {
      List<String> range = ranges[0].split('-');
      values["bytesFrom"] = int.parse(range[0]);
      values["bytesTotal"] = fileLength;
      try {
        values["bytesTo"] = int.parse(range[1]);
      } on Exception {
        values["bytesTo"] = values["bytesTotal"]!;
      }
      return values;
    }
  }
}

