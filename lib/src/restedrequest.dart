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

import 'restedscript.dart';
import 'responses.dart';
import 'parser.dart';
import 'restedsettings.dart';
import 'restedcookie.dart';

Responses error_responses = new Responses();
RestedSettings rsettings = null;

class RestedRequest {
  HttpRequest request;
  String method;
  String path;
  String access_token;
  Map body = new Map();
  List<HttpHeaders> response_headers = new List();
  RestedCookie cookie = null;

  // rscript variables are stored per request
  RestedScriptArguments rscript_args = new RestedScriptArguments();
  RestedScript rscript = new RestedScript();

  void setBody(Map bodymap) {
    body = bodymap;
    console.debug("Content: " + body.toString());
  }

  // USED FOR TESTING, DELETE WHEN NOT NEEDED
  String getSetting() {
    return rsettings.cookies_enabled.toString();
  }

  /*
  void createCookie() {
    cookie = new RestedCookie(request.cookies);
    request.cookies.add(cookie.create());
  }

  */
  void clearCookie() {
    request.response.cookies.clear();
    request.response.cookies.add(cookie.remove());
  }

  void saveCookie() {
    //request.cookies.add(cookie.create());
    //List<Cookie> cookies = new List();
    Cookie newcookie =
        cookie.create(rsettings.cookies_key, rsettings.cookies_max_age);
    //request.cookies = cookies;
  }

  RestedRequest(HttpRequest this.request, RestedSettings server_settings) {
    rsettings = server_settings;

    if (rsettings.cookies_enabled) {
      cookie = new RestedCookie(rsettings.cookies_key, request.cookies);
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

  void redirect(String resource) {
    saveCookie();
    request.response.redirect(Uri.http(request.requestedUri.host, resource));
  }

  ContentType getContentType(String fileExtension) {
    switch (fileExtension) {
      case "html":
        {
          request.response.headers.contentType =
              new ContentType("text", "html", charset: "utf-8");
        }
        break;
      case "css":
        {
          request.response.headers.contentType =
              new ContentType("text", "css", charset: "utf-8");
        }
        break;
      case "txt":
        {
          request.response.headers.contentType =
              new ContentType("text", "text", charset: "utf-8");
        }
        break;
      case "ico":
        {
          request.response.headers.contentType =
              new ContentType("image", "vnd.microsoft.icon");
        }
        break;
      case "mp4":
        {
          request.response.headers.contentType =
              new ContentType("video", "mp4");
        }
        break;
      case "mkv":
        {
          request.response.headers.contentType =
              new ContentType("video", "mkv");
        }
        break;
      case "mov":
        {
          request.response.headers.contentType =
              new ContentType("video", "mov");
        }
        break;
      case "m4v":
        {
          request.response.headers.contentType =
              new ContentType("video", "m4v");
        }
        break;
      case "jpg":
        {
          request.response.headers.contentType =
              new ContentType("image", "jpeg");
        }
        break;
      case "png":
        {
          request.response.headers.contentType =
              new ContentType("image", "png");
        }
        break;
     }
   }

  void fileResponse(String path) async {
    bool isBinary = true;
    String fileExtension = path.split('.')[1];
    request.response.headers.contentType = getContentType(fileExtension);
    if(fileExtension == 'html' || fileExtension == 'css' || fileExtension == 'txt') {
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
        if (rangeheadervalue != null && true == false) { // true == false to avoid this ¤%"#&¤/( rangerequest garbage for now
          //if(true){
          print("------- rangeHeader=" + rangeheadervalue.toString());
          Map<String,int> ranges = getRanges(rangeheadervalue.substring(6), file.lengthSync());
          request.response.statusCode = HttpStatus.partialContent;
          request.response.headers.set(HttpHeaders.ACCEPT_RANGES, "bytes");
          request.response.headers.contentType = ContentType.parse("video/mp4");
          request.response.headers.set("Content-Range", "bytes " + ranges["bytesFrom"].toString() + "-" + ranges["bytesTo"].toString() + "/" + ranges["bytesTotal"].toString());
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

  Map<String,int> getRanges(String rangeheader, int fileLength) {
    Map<String,int> values = new Map();
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

  void textResponse(String text) {
    request.response.headers.contentType =
        new ContentType("text", "plain", charset: "utf-8");
    saveCookie();
    request.response.write(text);
    request.response.close();
  }

  void jsonResponse(String json) {
    request.response.headers.contentType =
        new ContentType("application", "json", charset: "utf-8");
    saveCookie();
    final cleanJson = jsonDecode(jsonEncode(json));
    request.response.write(cleanJson);
    request.response.close();
  }

  void htmlResponse(String html) {
    request.response.headers.contentType =
        new ContentType("text", "html", charset: "utf-8");
    saveCookie();
    request.response.write(html);
    request.response.close();
  }

  void rscriptResponse(String filepath, {bool from_url = false}) {
    request.response.headers.contentType =
        new ContentType("text", "html", charset: "utf-8");
    saveCookie();
    if (from_url == true) {
      //filepath = 'bin/resources/' + filepath;
    }
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
