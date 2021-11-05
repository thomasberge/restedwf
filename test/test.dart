/* 
    Rested Web Framework test script
*/

import 'dart:io';
import 'dart:convert';
import 'rested.dart';

main() async {
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
    String result = await RestedRequests.post("http://0.0.0.0/json");
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
    request.response(data: request.body.toString());
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