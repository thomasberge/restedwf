/* 
    Rested Web Framework test script
*/

import 'dart:io';
import 'dart:convert';
import 'rested.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'src/restedsettings.dart';


main() async {
    xfunctions['authenticate'] = testing;
    RestedServer admin_server = RestedServer(TestServer());
    admin_server.start("0.0.0.0", 80);
}

class TestServer extends RestedRequestHandler {
  TestServer() {
    this.addResource(Root(), "/");
    this.addResource(Login(), "/login");
    this.addResource(Redirect(), "/g");
    this.addResource(Dump(), "/dump");
    this.addResource(GetPage(), "/get");
    this.addResource(JsonTest(), "/json");
    this.addResource(Claims(), "/claims");
    this.addResource(SettingsTest(), "/settings");
    this.addResource(PathParam(), "/t/{test}");
    this.addResource(SchemaTest(), "/validate");
    this.addResource(JWTClaims(), "/allclaims");
    this.addResource(GETJWTClaims(), "/getclaims");
  }
}

class SchemaTest extends RestedResource {
  void post(RestedRequest request) async {
    request.response(data: "TEST");
  }
}

void testing(RestedRequest request) {
  //print(request.uri_parameters["user_id"]);
  request.response(data: request.text.toString());
}

class PathParam extends RestedResource {
  PathParam() {
    StringParameter test = StringParameter("test");
    //test.format = "uuid";
    test.maxLength = 7;
    this.setUriParameterSchema(test);
  }

  void get(RestedRequest request) async {
    request.response(data: request.uri_parameters["test"].toString());
  }
}

class SettingsTest extends RestedResource {
  void get(RestedRequest request) async {
    RestedSettings testsettings = RestedSettings();
    request.response(data: testsettings.getSettingsFile().toString());
  }
}

class Claims extends RestedResource {
  void get(RestedRequest request) async {
    RestedJWT jwthandler = RestedJWT();
    Map claims = { "somevariable": "somevalue" };
    Map token = jwthandler.generate_token(additional_claims: claims);
    Map result = json.decode(json.encode(token));
    String tokenstring = result["access_token"];
    String somevariable = RestedJWT.getClaim(tokenstring, "somevariable");
    request.response(data: somevariable);
  }
}

class GETJWTClaims extends RestedResource {
  void get(RestedRequest request) {
    RestedJWT jwthandler = RestedJWT();
    Map claims = { "somevariable": "somevalue" };
    Map token = jwthandler.generate_token(additional_claims: claims);
    Map result = json.decode(json.encode(token));
    request.response(data: result.toString());
  }
}

class JWTClaims extends RestedResource {
  void get(RestedRequest request) async {
    request.response(data: request.claims.toString());
  }
}

class GetPage extends RestedResource {
  void get(RestedRequest request) async {
    String temp = await RestedRequests.get("www.google.com");
    request.response(type: "html", data: temp);
  }
}

class JsonTest extends RestedResource {
  void get(RestedRequest request) async {
    Map<String, String> _headers = { "Content-Type": "application/json" };
    Map<String, dynamic> _data = { "SomeKey": "SomeValue", "AnotherKey": 14, "YetAnotherKey": true };
    String result = await RestedRequests.post("http://0.0.0.0/json", headers: _headers, data: json.encode(_data));
    Map resultmap = json.decode(result);
    request.response(data: resultmap["AnotherKey"].toString());
  }

  void post(RestedRequest request) async {
    Map<String, dynamic> map = { "SomeKey": "SomeValue", "AnotherKey": 14, "YetAnotherKey": true };
    request.response(type: "json", data: json.encode(map));
  }
}

class Dump extends RestedResource {
  void post(RestedRequest request) {
    request.response(data: request.text);
  }
}

class Root extends RestedResource {
  String protected_redirect = "/login";

  Root() {
    require_token("get");
  }  

  void get(RestedRequest request) async {
    request.response(data: "test");
  }
}

class Login extends RestedResource {
  void get(RestedRequest request) async {
      request.response(data: "login");
  }
}

class Redirect extends RestedResource {
  void get(RestedRequest request) async {
      request.redirect("http://www.google.com");
  }
}