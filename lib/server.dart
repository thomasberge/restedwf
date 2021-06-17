import 'dart:io';
import 'dart:convert';
import 'rested.dart';

RestedRequestHandler rested;
main() async {
  RestedServer server = new RestedServer();
  await server.start();
  server.keepAlive();
}

class Rested extends RestedRequestHandler {
  Rested() {
    this.address = "0.0.0.0";
    this.port = 80;
    this.addResource(Resource_root(), "/");
  }
}

class Resource_root extends RestedResource {
  void get(RestedRequest request) {
    request.response(type: "file", filepath: "index.html");
  }
}
