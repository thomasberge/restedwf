import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'restedrequest.dart';
import 'restedglobals.dart';

Map<String, Function> content_types = {
    "application/json": receive_application_json,
    "not_implemented": not_implemented,
    "application/x-www-form-urlencoded": receive_application_x_www_form_urlencoded,
    "multipart/form-data": receive_multipart_formdata,
    "application/pdf": receive_application_pdf,
    "application/java-archive": not_implemented,
    "application/EDI-X12": not_implemented,
    "application/EDIFACT": not_implemented,
    "application/javascript": not_implemented,
    "application/octet-stream": not_implemented,
    "application/ogg": not_implemented,
    "application/xhtml+xml": not_implemented,
    "application/ld+json": not_implemented,
    "application/zip": not_implemented,
    "application/xml": receive_application_xml,
    "audio/mpeg": not_implemented,
    "audio/x-ms-wma": not_implemented,
    "audio/vnd.rn-realaudio": not_implemented,
    "audio/x-wav": not_implemented,
    "image/gif": not_implemented, 
    "image/jpeg": not_implemented,
    "image/png": not_implemented,
    "image/tiff": not_implemented,
    "image/vnd.microsoft.icon": not_implemented,
    "image/x-icon": not_implemented,
    "image/vnd.djvu": not_implemented,
    "image/svg+xml": not_implemented,
    "multipart/mixed": not_implemented,
    "multipart/alternative": not_implemented,
    "multipart/related": not_implemented,
    "text/css": not_implemented,
    "text/csv": not_implemented,
    "text/javascript": not_implemented,
    "text/xml": not_implemented,
    "text/plain": receive_text_plain,
    "text/html": receive_text_html,
    "video/mpeg": not_implemented,
    "video/mp4": not_implemented,
    "video/quicktime": not_implemented,
    "video/x-ms-wmv": not_implemented,
    "video/x-msvideo": not_implemented,
    "video/x-flv": not_implemented,
    "video/webm": not_implemented
};

Future<RestedRequest> receive_content(RestedRequest request) async {
    List<String> temp = request.request.headers.contentType.toString().split(';');
    String type = temp[0].toString();
    if(content_types.containsKey(type)) {
        return await content_types[type](request);
    } else if(type == "null"){
        return await content_types['text/plain'](request);
    } else {
        return await content_types['not_implemented'](request);
    }
}

Future<RestedRequest> receive_application_json(RestedRequest request) async {
    String jsonstring = await utf8.decoder.bind(request.request).join();
    request.raw = jsonstring;
    
    // dirty trick to manually change a json sent as string to a parsable string. Unelegant af
    Map jsonmap = {};
    if(jsonstring.length > 0) {
        if(jsonstring.substring(0,1) == '"') {
          jsonstring = jsonstring.substring(1, jsonstring.length -1);
          jsonstring = jsonstring.replaceAll(r'\"', '"');
        }

        try {
          jsonmap = json.decode(jsonstring);
        } catch(e) {
          print("--- error:" + e.toString());
          Errors.raise(request, 400);
          return request;
        }

        // some clients wrap body in a body-block. If this is the case here then the content of the
        // body block is extracted to become the new body.
        if (jsonmap.containsKey("body")) {
          jsonmap = jsonmap['body'];
        }        
    }
      request.setBody(jsonmap);
    return request;
}

Future<RestedRequest> receive_application_x_www_form_urlencoded(RestedRequest request) async {
    String urlencoded = await utf8.decoder.bind(request.request).join();
    request.raw = urlencoded;
    request.content_type = "form";

    urlencoded = urlencoded.replaceAll('+', '%20');

    Map<String, dynamic> form = {};
    if (urlencoded == null || urlencoded == "") {
        request.form = form;
        return request;
    }

    List<String> pairs = urlencoded.split('&');
    pairs.forEach((pair) {
        List<String> variable = pair.split('=');
        String key = "";
        String value = "";
        if(variable[0] != null) {
            key = Uri.decodeComponent(variable[0]);    
            if(variable.length > 1) {
                value = Uri.decodeComponent(variable[1]);
            }
            form[key] = value;
        }
    });

    if (form.containsKey("body")) {
        form = form['body'];
    }

    request.form = form;
    print(":::: URLENCODED " + urlencoded.toString());
    return request;
}

Future<RestedRequest> receive_application_pdf(RestedRequest request) async {
    print("Error: Content-Type currently not implemented (application/pdf).");
    Errors.raise(request, 501);
    return request;
}

Future<RestedRequest> receive_application_xml(RestedRequest request) async {
    print("Error: Content-Type currently not implemented (application/xml).");
    Errors.raise(request, 501);
    return request;
}

Future<RestedRequest> receive_text_plain(RestedRequest request) async {
    String data = await utf8.decoder.bind(request.request).join();
    request.raw = data;
    request.text = data;
    return request;
}

Future<RestedRequest> receive_text_html(RestedRequest request) async {
    print("Error: Content-Type currently not implemented (text/html).");
    return Errors.raise(request, 501);
}

Future<RestedRequest> receive_multipart_formdata(RestedRequest request) async {
    List<String> type = request.request.headers.contentType.toString().split(';');
    String data = await utf8.decoder.bind(request.request).join();
    request.raw = data;
    Map body = multipartFormDataToBodyMap(type.toString(), data);
    request.text = data;
    request.setBody(body);
    return request;
}

Future<RestedRequest> not_implemented(RestedRequest request) async {
    List<String> type = request.request.headers.contentType.toString().split(';');
    print("Error: Content-Type currently not implemented (" + type.toString() + ").");
    return await Errors.raise(request, 501);
}

  // Multipart formdata
  // file not supported yet, only works on text
  // https://ec.haxx.se/http/http-multipart
  Map<String, dynamic> multipartFormDataToBodyMap(String typeHeader, String data) {
    print("typeHeader=" + typeHeader.toString());
    print("data=" + data.toString());
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