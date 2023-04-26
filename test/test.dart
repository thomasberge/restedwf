/* 
    Rested Web Framework Core Test Server
*/

import 'dart:io';
import 'dart:convert';
import 'core.dart';

main() async {
    ServerCore admin_server = ServerCore(threads: 2);
    admin_server.start(TestServer(), '', 80);
}

void listusers(RestedRequest request) async {
  request.response(data: "list users here");
}

class TestServer extends RestedRequestHandler {
  TestServer() {

    this.addResource(Root(), "/");
    this.addResource(Login(), "/login");
  }
}

class Root extends RestedResource {

  void get(RestedRequest request) async {
    request.response(data: "User logged in successfully.");
  }
}

class Login extends RestedResource {

  void get(RestedRequest request) async {
    request.response(data: 'Please log in by using POST /login with { "username": <username>, "password": <password> }');
  }

  void post(RestedRequest request) async {

    if(request.body.containsKey("username") == false) {
      request.response(status: 400, data: '{ "error": "missing required field <username>" }');
      return;
    }

    if(request.body.containsKey("password") == false) {
      request.response(status: 400, data: '{ "bad request": "missing required field <password>" }');
      return;
    }

    if(request.body["username"] == "admin" && request.body["password"] == "pass123") {
      request.redirect("/");
    } else {
      request.response(status: 401, data: '{ "error": "the supplied <username> and/or <password> failed validation" }');
    }
  }
}