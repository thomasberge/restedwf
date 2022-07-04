import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'dart:convert';

import 'restedrequest.dart';
import 'errors.dart';
/*  BACKLOG
    application/java-archive
    application/EDI-X12   
    application/EDIFACT   
    application/javascript   
    application/octet-stream   
    application/ogg   
    application/pdf  
    application/xhtml+xml   
    application/x-shockwave-flash    
    application/json  
    application/ld+json  
    application/xml   
    application/zip  
    application/x-www-form-urlencoded  
    audio/mpeg   
    audio/x-ms-wma   
    audio/vnd.rn-realaudio   
    audio/x-wav   
    image/gif   
    image/jpeg   
    image/png   
    image/tiff    
    image/vnd.microsoft.icon    
    image/x-icon   
    image/vnd.djvu   
    image/svg+xml    
    multipart/mixed    
    multipart/alternative   
    multipart/related (using by MHTML (HTML mail).)  
    multipart/form-data  
    text/css    
    text/csv    
    text/html    
    text/javascript (obsolete)    
    text/plain    
    text/xml    
    video/mpeg    
    video/mp4    
    video/quicktime    
    video/x-ms-wmv    
    video/x-msvideo    
    video/x-flv   
    video/webm   
*/

Future<RestedRequest> receive_application_json(RestedRequest request) async {
    Map jsonmap = {};
      String jsonstring = await utf8.decoder.bind(request.request).join();
      request.raw = jsonstring;

      // dirty trick to manually change a json sent as string to a parsable string. Unelegant af
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