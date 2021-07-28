// Part of Rested Web Framework
// www.restedwf.com
// © 2021 Thomas Sebastian Berge

import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'consolemessages.dart';
import 'restedrequesthandler.dart';
import 'restedsettings.dart';

RestedSettings rsettings = new RestedSettings();
ConsoleMessages console = new ConsoleMessages(debug_level: rsettings.message_level);

class RestedServer {
  RestedRequestHandler request_handler;

  RestedServer(this.request_handler);

  void start(String address, int port) async {
    var server = await HttpServer.bind(address, port);
    print("Test server listening on " + address + ":" + port.toString());
    print("\n\u001b[31mThis is only a test server and is not suited for production.\u001b[0m\n");
    await for (HttpRequest request in server) {
      request_handler.handle(request);
    }    
  }
} 