/* 
    Rested Web Framework test script
*/

import 'dart:io';
import 'dart:convert';
import 'rested.dart';

main() async {
    RestedServer admin_server = RestedServer(TestServer());
    admin_server.start("0.0.0.0", 800);
}

class TestServer extends RestedRequestHandler {
  TestServer() {
    this.addResource(Root(), "/");
    this.addResource(Login(), "/login");
    this.addResource(Redirect(), "/g");
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