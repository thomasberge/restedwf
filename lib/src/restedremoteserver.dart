// Part of Rested Web Framework
// www.restedwf.com
// © 2021 Thomas Sebastian Berge
 
import 'dart:io';
import 'dart:convert';
import 'package:crypto/crypto.dart' as crypto;
import 'dart:collection';
import 'dart:math';
import 'dart:typed_data';

class RemoteServer {
  String address;
  String port;

  Future<dynamic> get(RemoteRequest _req) async {

  }

  Future<dynamic> post(RemoteRequest _req) async {
    
  }

  Future<dynamic> put(RemoteRequest _req) async {

  }

  Future<dynamic> patch(RemoteRequest _req) async {

  }

  Future<dynamic> delete(RemoteRequest _req) async {

  }

  Future<dynamic> head(RemoteRequest _req) async {

  }

  Future<dynamic> options(RemoteRequest _req) async {

  }

  Future<dynamic> trace(RemoteRequest _req) async {
  /*  if(_req.headers != null) {
      for(MapEntry e in headers.entries) {
        api_request.headers.add(e.key.toString(), e.value.toString());
      }
    }*/
  }
}

class RemoteRequest {
Map<String, String> headers = {};

}

class RestedRemoteServer {
  String protocol;
  String address;
  int port;
  String endpoint;

  //OAUTH1
  String key;
  String secret;

  // Allows for urls such as https://www.someapp.com/apikey/, customhttp://ninja.hackzor.io:1337/
  RestedRemoteServer(this.address, this.port, {String this.protocol = "http", String this.endpoint = ""});

  String getFullUrlPath(String resource) {
    String port_text = "";
    if(port != 80) {
      port_text = ":" + port.toString();
    }
    return protocol + "://" + address + port_text + endpoint + resource;
  }

  // ---  GET -----------------------------------------------------

  Future<dynamic> get(String resource, {String text = "", bool oauth1 = false, Map<String, String> headers = null}) async {
    
    String url = getFullUrlPath(resource);

    if(oauth1) {
      if(key == null || secret == null) {
        print("ERROR: oauth1 failed. RestedRemoteServer <key> and/or <secret> variables are not set.");
        return null;
      }
      print("GET:" + url);
      url = _getOAuthURL("GET", url);
    }

    HttpClient client = new HttpClient();
    HttpClientRequest api_request = await client.getUrl(Uri.parse(url));

    if(headers != null) {
      for(MapEntry e in headers.entries) {
        api_request.headers.add(e.key.toString(), e.value.toString());
      }
    }

    dynamic result;
    if(text != "") {
      api_request.write(text);
    }
    HttpClientResponse api_response = await api_request.close();

    //print(api_response.headers.toString());

    

    if(api_response.headers.contentType.toString() == "application/json") {
      result = await utf8.decoder.bind(api_response).join();
    } else if(api_response.headers.contentType.toString() == "application/zip") {
      print("application/zip");
      List<int> zip = new List();
      await api_response.listen(zip.addAll, onDone: ()  {
        //zip.write
        //var data = api_response.
        //print(zip.toString());
      });
      Uint8List result = new Uint8List.fromList(zip);
      return result;
    } else {
      result = "Unsupported ContentType";
      print("RemoteServer response is of an unsupported ContentType:" + api_response.headers.contentType.toString());
    }

    //return result;
  }

  // ---  POST -----------------------------------------------------

  Future<dynamic> post(
    String resource, {
      String returntype = "body",   // body (returns body as string), binary (returns body as binary), response (returns entire response)
      String data = "", 
      Map jsondata = null, 
      bool oauth1 = false, 
      bool soap = false,
      List<String> soap_envelopes = null,
      String soap_username,
      String soap_password,
      String soap_body,
      Map<String, String> headers = null
      }) async {

    String url = getFullUrlPath(resource);

    if(oauth1) {
      if(key == null || secret == null) {
        print("ERROR: oauth1 failed. RestedRemoteServer <key> and/or <secret> variables are not set.");
        return null;
      }
      //print("OAUTHURL=" + url);
      print("POST:" + url);
      url = _getOAuthURL("POST", url); 
    }

    if(soap) {
      List<String> envelopes;
      soap_body = "<soapenv:Envelope {%envelope%}><soapenv:Header/><soapenv:Body>{%body%}</soapenv:Body></soapenv:Envelope>".replaceAll("{%body%}", soap_body);

      // Mye unødvendig tullete kode her rundt envelopes. Må ryddes og forkortes.
      if(soap_envelopes != null) {
        envelopes = soap_envelopes;
      } else {
        envelopes = new List();
      }
      envelopes.add("xmlns:soapenv=\"http://schemas.xmlsoap.org/soap/envelope/\"");
      String new_envelopes = "";
      for(String envelope in envelopes) {
        new_envelopes = new_envelopes + envelope + " ";
      }      
      soap_body = soap_body.replaceAll("{%envelope%}", new_envelopes);
    }

    HttpClient client = new HttpClient();
    print("Sending request to " + url.toString());
    HttpClientRequest api_request = await client.postUrl(Uri.parse(url));

    if(headers != null) {
      for(MapEntry e in headers.entries) {
        api_request.headers.add(e.key.toString(), e.value.toString());
        print("Request Headers:");
        print(api_request.headers.toString());
      }
    }

    if(soap) {
      api_request.headers.add(HttpHeaders.authorizationHeader, basicAuthenticationHeader(soap_username, soap_password));
      api_request.headers.contentType = new ContentType("application", "xml");
      List<int> bytes = utf8.encode(soap_body);
      api_request.headers.add(HttpHeaders.contentLengthHeader, bytes.length);
      api_request.headers.add("SOAPAction", "");
    } else {
      api_request.headers.contentType = new ContentType("application", "json; charset=UTF-8");
    }

    dynamic result;
    if(soap) {
      api_request.write(soap_body);
    } else if(data != "") {
      List<int> bytes = utf8.encode(data);
      api_request.headers.add(HttpHeaders.contentLengthHeader, bytes.length);
      api_request.write(data);
    } else if(jsondata != null) {
      List<int> bytes = utf8.encode(json.encode(jsondata));
      api_request.headers.add(HttpHeaders.contentLengthHeader, bytes.length);            
      api_request.write(json.encode(jsondata));
    }
    HttpClientResponse api_response = await api_request.close();
    //print("response-type: " + api_response.headers.contentType.toString());

    if(returntype == "body") {
      if(api_response.headers.contentType == ContentType("application", "json"))
      {
        //print("response-type: application/json");
        result = await utf8.decoder.bind(api_response).join();
      } else {
        //print("response-type: undefined");
        result = await utf8.decoder.bind(api_response).join();
      }
      return result;
    } else if(returntype == "binary") {
      print("binary returntype not yet implemented");
    } else if(returntype == "response") {
      return api_response;
    } else {
      print("RestedRemoteServer Error. Returntype " + returntype + " not supported. Valid returntypes: 'body', 'binary' or 'response'");
    }
  }

  String basicAuthenticationHeader(String username, String password) {
    return 'Basic ' + base64Encode(utf8.encode('$username:$password'));
  }

  String _randomString(int length) {
   var rand = new Random();
   var codeUnits = new List.generate(
      length, 
      (index){
         return rand.nextInt(26)+97;
      }
   );
   
   return new String.fromCharCodes(codeUnits);
  }

  /*
  Future<String> post(String url,
      {String token = null, Map json_data = null, String text = null}) async {
    //HttpClientRequest api_request;

    final client = HttpClient();
    final api_request = await client.post(address, port, url);

    if (json_data != null) {
      api_request.headers
          .set(HttpHeaders.contentTypeHeader, 'application/json');
      api_request.write(jsonEncode(json_data));
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
  }*/

  String _getOAuthURL(String method, String url, {String token = ""}) {

    String oauthstring = method + "&";
    bool hasArgs = false;
    String parameterString = "oauth_consumer_key=" + this.key + "&" + 
                         "oauth_nonce=" + _randomString(10) + "&" +
                         "oauth_signature_method=HMAC-SHA1&" +
                         "oauth_timestamp=" + ((DateTime.now().millisecondsSinceEpoch) / 1000).toString() + "&" +
                         "oauth_token=" + token + "&" +
                         "oauth_version=1.0";                         


    if(url.contains('?')) {
      hasArgs = true;
      parameterString = parameterString + "&oauth_parameters=" + url.split('?')[1];
    }

    oauthstring = oauthstring +
        Uri.encodeQueryComponent(
            hasArgs == true ? url.split("?")[0] : url) +
        "&" +
        Uri.encodeQueryComponent(parameterString);

    crypto.Hmac hmacSha1 = crypto.Hmac(crypto.sha1, utf8.encode(this.secret + "&" + token)); // HMAC-SHA1
    crypto.Digest signature = hmacSha1.convert(utf8.encode(oauthstring));
    String finalSignature = base64Encode(signature.bytes);
    String requestUrl = "";

    if (hasArgs) {
      requestUrl = url.split("?")[0];
    } else {
      requestUrl = url;
    }
     
    requestUrl = requestUrl + "?" + parameterString + "&oauth_signature=" + Uri.encodeQueryComponent(finalSignature);
    return requestUrl;
    
  }  
}
