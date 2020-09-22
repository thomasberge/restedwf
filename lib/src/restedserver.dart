// Part of Rested Web Framework
// www.restedwf.com
// © 2020 Thomas Sebastian Berge

import 'dart:io';
import 'dart:async';
import 'consolemessages.dart';
import 'restedrequesthandler.dart';

ConsoleMessages console = new ConsoleMessages(debug_level: 4);

class RestedServer {
  RestedRequestHandler request_handler;

  RestedServer(this.request_handler);

  void startTestServer(String address, int port) async {
    var server = await HttpServer.bind(address, port);
    console.message("Test server listening on " + address + ":" + port.toString());
    await for (HttpRequest request in server) {
      request_handler.handle(request);
    }    
  }
}