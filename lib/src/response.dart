import 'dart:io';
import 'dart:convert';

import 'mimetypes.dart';
import 'request.dart';
import 'globals.dart';

class RestedResponse {
 
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
        request.request.response.headers.contentType = new ContentType("application", "json", charset: "utf-8");        
        response(json.encode(Errors.getJson(request.request.response.statusCode)));
      }
      break;

      case "redirect":
      {
        String host = request.request.requestedUri.host;

        // Overwrite if host is specified in the http header
        if(request.headers.containsKey('host')) {
            host = request.headers['host']!;
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
        request.request.response.headers.contentType = new ContentType("text", "plain", charset: "utf-8");
        response(request.restedresponse['data']);
      }
      break;

      case "html":
      {
        request.request.response.headers.contentType = new ContentType("text", "html", charset: "utf-8");
        response(request.restedresponse['data']);
      }
      break;

      case "json":
      {
        request.request.response.headers.contentType = new ContentType("application", "json", charset: "utf-8");
        response(request.restedresponse['data']);
      }
      break;

      case "file":
      {
        if (request.restedresponse['filepath'] != null) {
          String filepath = request.restedresponse['filepath'];

          bool fileExists = await File(filepath).exists();
          if (fileExists) {
            List<String> pathElements = filepath.split('.');
            String filetype = "." + pathElements[pathElements.length-1];

            if(filetype == ".br") {
              request.request.response.headers.add("Content-Encoding", "br");
              filetype = "." + pathElements[pathElements.length-2];
            }

            // Set headers
            request.request.response.headers.contentType = mimetypes.getContentType(filetype);

            if (mimetypes.isBinary(filetype)) {
              File file = new File(filepath);
              var rangeheadervalue =
                  request.request.headers.value(HttpHeaders.rangeHeader);
              if (rangeheadervalue != null) {
                request.request.response.statusCode =
                    HttpStatus.partialContent;
              }
              Future<List<int>> f = file.readAsBytes();
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
            Errors.raise(request, 404);
            error.raise("file_not_found", details: filepath );
            return;
          }
        }
      }
      break;

    }
  }

  /*
  String filetypeFromPath(String path) {
    List<String> dirsplit = path.split('/');
  }*/

  void fileResponse(File file) {
    Future<List<int>> f = file.readAsBytes();
    request.request.response.addStream(f.asStream()).whenComplete(() {
      request.request.response.close();
    });
  }

  void fileStream(File file) {
    Future<List<int>> f = file.readAsBytes();
    request.request.response.addStream(f.asStream()).whenComplete(() {
      request.request.response.close();
    });
  }

  void response(String data) async {
    if (data != "") {
      request.request.response.write(data);
    }
    request.request.response.close();
  }
}