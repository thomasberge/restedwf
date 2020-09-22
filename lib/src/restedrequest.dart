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
import 'package:encrypt/encrypt.dart';

import 'restedscript.dart';
import 'responses.dart';
import 'parser.dart';
import 'restedsettings.dart';
import 'restedsession.dart';
import 'mimetypes.dart';

Responses error_responses = new Responses();
Mimetypes mimetypes = new Mimetypes();

class CookieCollection {
  List<Cookie> cookies = null;

  CookieCollection(this.cookies);

  void add(Cookie newcookie) {
    cookies.add(newcookie);
  }

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
  //  Request actions too be performed
  String responseType = ""; // redirect/html/json/file
  String responseResource = ""; // /some/resource  /path/to/somefile.jpg   <html>somedata</html>
  //
  HttpRequest request;
  String method;
  String path;
  String access_token;
  Map body = new Map();
  //RestedSession session = null;
  CookieCollection cookies = null;
  RestedSettings rsettings;
  Map<String, dynamic> session = new Map();
  //bool deleteSessionCookie = false;
  //List<String> removeCookie = new List();

  // rscript variables are stored per request
  RestedScriptArguments rscript_args = new RestedScriptArguments();
  RestedScript rscript = new RestedScript();

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
    console.debug("Content: " + body.toString());
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
    request.response.cookies.add(newcookie);
  }

  void addCookie(Cookie newcookie) {
    request.response.cookies.add(newcookie);
  }

  void removeCookie(String name) {
    Cookie newcookie = new Cookie(name, "");
    newcookie.path = "/";
    newcookie.maxAge = 0;
    request.response.cookies.add(newcookie);
  }

  RestedRequest(HttpRequest this.request, RestedSettings server_settings) {
    rsettings = server_settings;
    
    if (rsettings.cookies_enabled) {
      cookies = new CookieCollection(request.cookies);
    }

    // By splitting by hostname the full request path will reside in temp[1] while the protocol will reside in temp[0]
    //List temp = request.requestedUri.toString().split(request.headers.host);
    path = request.requestedUri.path;

    // In case the path is ":<port>/<path>" we need to remove the port part of the path.
    //if (path.contains(':')) {
    //  path = '/' + path.split('/')[1];
    //}

    method = request.method.toString().toUpperCase();

    console.debug(method + " " + path);
  }

  Map<String, String> path_arguments = new Map();

  void createPathArgumentMap(String tagged_path, List<String> keys) {
    List<String> path_segments = path.substring(1).split('/');
    List<String> tagged_path_segments = tagged_path.substring(1).split('/');
    int i = 0;
    int x = 0;
    for (String segment in tagged_path_segments) {
      if (segment == '<var>') {
        path_arguments[keys[x]] = path_segments[i];
        x++;
      }
      i++;
    }
  }

  void response({
      String type = "text", 
      String data = "", 
      File file = null, 
      bool stream = false
      }) {

    // Headers
    request.response.headers.contentType = mimetypes.getContentType(type);
    request.response.statusCode = HttpStatus.ok;

    if(stream) {
      request.response.headers.set(HttpHeaders.ACCEPT_RANGES, "bytes");
    }

    // Writing data and closing
    if(stream) {
      Future f = file.readAsBytes();
      request.response.addStream(f.asStream()).whenComplete(() {
        request.response.close();
      });
    } else {
      if(data != ""){
        request.response.write(data);
      }
      request.response.close();
    }
  }

  void redirect(String resource) {
    request.response.redirect(Uri.http(request.requestedUri.host, resource));
  }

  void fileResponse(String path) async {
    bool isBinary = true;
    String fileExtension = path.split('.')[1];
    request.response.headers.contentType = mimetypes.getContentType(fileExtension);
    if (fileExtension == 'html' ||
        fileExtension == 'css' ||
        fileExtension == 'txt') {
      isBinary = false;
    }

    if (fileExtension == "html" && rsettings.open_html_as_rscript) {
      path = path.substring("bin/resources/".length);
      rscriptResponse(path, from_url: true);
    } else {
      if (isBinary == null) {
        console.error("Unsupported file type: " + fileExtension);
        errorResponse(404);
      } else if (isBinary) {
        var file = new File(path);
        var rangeheadervalue = request.headers.value(HttpHeaders.rangeHeader);
        if (rangeheadervalue != null && true == false) {
          // true == false to avoid this ¤%"#&¤/( rangerequest garbage for now
          //if(true){
          print("------- rangeHeader=" + rangeheadervalue.toString());
          Map<String, int> ranges =
              getRanges(rangeheadervalue.substring(6), file.lengthSync());
          request.response.statusCode = HttpStatus.partialContent;
          request.response.headers.set(HttpHeaders.ACCEPT_RANGES, "bytes");
          request.response.headers.contentType = ContentType.parse("video/mp4");
          request.response.headers.set(
              "Content-Range",
              "bytes " +
                  ranges["bytesFrom"].toString() +
                  "-" +
                  ranges["bytesTo"].toString() +
                  "/" +
                  ranges["bytesTotal"].toString());
          print("bytesFrom=" + ranges["bytesFrom"].toString());
          print("bytesTo=" + ranges["bytesTo"].toString());
          //RandomAccessFile raf= file.openSync(mode: FileMode.read);
          //raf.setPositionSync(ranges["bytesFrom"]);
          //Uint8List data = raf.readSync((ranges["bytesTo"] - ranges["bytesFrom"]));
          //request.response.add(data);
          //request.response.close();
          //Future f = raf.read((ranges["bytesTo"] - ranges["bytesFrom"]));
          //request.response.addStream(raf.asStream()).whenComplete(() {
          //  request.response.close();
          //       });
          //Stream<List<int>> stream = file.openRead(ranges["bytesFrom"], ranges["bytesTo"]);
          //var bytestream = ByteStream.fromBytes(stream);
          //await request.response.addStream(file.openRead(ranges["bytesFrom"], ranges["bytesTo"]));
          //await request.response.addStream(stream);
          //request.response.addStream(stream).whenComplete(() {
          //            request.response.close();
          //        });
          //request.response.close();

          // If request does not contain range header
        } else {
          request.response.statusCode = HttpStatus.ok;
          request.response.headers.contentType = ContentType.parse("video/mp4");
          request.response.headers.set(HttpHeaders.ACCEPT_RANGES, "bytes");
          Future f = file.readAsBytes();
          request.response.addStream(f.asStream()).whenComplete(() {
            request.response.close();
          });
        }
      } else {
        String textdata = File(path).readAsStringSync(encoding: utf8);
        request.response.write(textdata);
        request.response.close();
      }
    }
  }

  Map<String, int> getRanges(String rangeheader, int fileLength) {
    Map<String, int> values = new Map();
    List<String> ranges = rangeheader.split(',');
    if (ranges.length > 1) {
      console.error("Multi-range request not supported!");
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

  void rscriptResponse(String filepath,
      {bool from_url = false,
      List<dynamic> list = null,
      Map<dynamic, dynamic> map = null}) {
    request.response.headers.contentType =
        new ContentType("text", "html", charset: "utf-8");
    if (from_url == true) {
      //filepath = 'bin/resources/' + filepath;
    }
    rscript_args.list = list;
    rscript_args.map = map;
    String html = rscript.createDocument(filepath, rscript_args);
    request.response.write(html);
    request.response.close();
  }

  void errorResponse(int code) {
    request.response.headers.contentType =
        new ContentType("text", "plain", charset: "utf-8");
    request.response.statusCode = code;
    request.response.write(error_responses.text(code));
    request.response.close();
  }
}
