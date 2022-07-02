import 'dart:io';
import 'dart:convert';
import 'dart:async';

class RestedRequests {

    RestedRequests();

    static Future<dynamic> get(String _url, { Map<String, String> headers = const {}, String data = ""}) async {
        return await _doRequest("GET", _url, headers, data);
    }

    static Future<dynamic> post(String _url, { Map<String, String> headers = const {}, String data = ""}) async {
        return await _doRequest("POST", _url, headers, data);
    }

    static Future<dynamic> put(String _url, { Map<String, String> headers = const {}, String data = ""}) async {
        return await _doRequest("PUT", _url, headers, data);
    }

    static Future<dynamic> delete(String _url, { Map<String, String> headers = const {}, String data = ""}) async {
        return await _doRequest("DELETE", _url, headers, data);
    }

    static Future<dynamic> _doRequest(String _method, String _url, Map<String, String> _headers, String _data) async {

        HttpClient client = new HttpClient();
        Map<String, dynamic> responseobj = {};
        
        if(_url.substring(0,4) != "http") {
            _url = "http://" + _url;
        } 

        HttpClientRequest request = await client.openUrl(_method, Uri.parse(_url));

        for(MapEntry header in _headers.entries) {
            request.headers.add(header.key, header.value);
        }

        // Currently only writes JSON format or defaults to standard text
        if(_data != "") {
            if(_headers.containsKey("Content-Type")) {

                if(_headers["Content-Type"].contains("application/json")) {
                    String jsondata = json.encode(_data);
                    List<int> bytes = utf8.encode(jsondata);
                    request.headers.add(HttpHeaders.contentLengthHeader, bytes.length);
                    String encoded_data = Uri.encodeFull(jsondata);
                    await request.write(encoded_data);

                } else if (_headers["Content-Type"].contains("text/plain")) {
                    print("RestedRequests text/plain data=" + _data.toString());
                    List<int> bytes = utf8.encode(_data);
                    request.headers.add(HttpHeaders.contentLengthHeader, bytes.length);
                    String encoded_data = Uri.encodeFull(_data);
                    await request.write(encoded_data);    
                } else {
                    print("RestedRequests defaulting to text/plain data=" + _data.toString());
                    List<int> bytes = utf8.encode(_data);
                    request.headers.add(HttpHeaders.contentLengthHeader, bytes.length);
                    String encoded_data = Uri.encodeFull(_data);
                    await request.write(encoded_data);    
                }
            } else {
                await request.write(_data);
            }
        }

        HttpClientResponse response = await request.close();

        var data = await _readResponse(response);
        responseobj["data"] = data;
        responseobj["status"] = response.statusCode;
        return responseobj;
        //});
        //data = data + result;
        //return data;
    }

    static Future<dynamic> _readResponse(HttpClientResponse response) async {
        final completer = Completer<String>();
        final contents = StringBuffer();

        //Map<String, String> _headers = {};

        var contentType = response.headers.value(HttpHeaders.contentTypeHeader);
        if(contentType == null) {
            print("ERROR: Response missing Content-Type header. Currently not supported.");
        } else {
            String responseHandling = _getResponseHandling(contentType);

            switch(responseHandling) {
                case "TEXT": {
                    print("Requests handling TEXT response ...");
                    if(response.headers.value(HttpHeaders.contentTypeHeader).contains("ISO-8859-1")) {
                        response.transform(latin1.decoder).listen((data) {
                            contents.write(data);
                        }, onDone: () => completer.complete(contents.toString()));
                        return completer.future;
                    } else { // assume UTF-8
                        response.transform(utf8.decoder).listen((data) {
                            contents.write(data);
                        }, onDone: () => completer.complete(contents.toString()));
                        return completer.future;
                    }
                } break;
                case "BINARY": {
                    //File file = new File("");   // pid-cache area
                    //var rangeheadervalue = request.request.headers.value(HttpHeaders.rangeHeader);
                    //if (rangeheadervalue != null) {
                    //    request.request.response.statusCode = HttpStatus.partialContent;
                    //}
                    /*Future f = file.readAsBytes();
                    request.request.response
                        .addStream(f.asStream())
                        .whenComplete(() {
                    request.request.response.close();
                    });                   */
                    print("Binary file download not supported in Requests yet");
                } break;
            }
        }
        

        return "";
    }

    static String _getResponseHandling(String _contentType) {

        _contentType = _contentType.split(';')[0];

        print(" ----> _contentType=" + _contentType);
        Map<String,String> mimes = {
            "text/plain": "TEXT",
            "text/html": "TEXT",
            "application/json": "TEXT"
        };

        if(mimes.containsKey(_contentType)) {
            return mimes[_contentType];
        } else {
            return "BINARY";
        }
    }
}
