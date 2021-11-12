// Part of Rested Web Framework
// www.restedwf.com
// © 2021 Thomas Sebastian Berge

import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'consolemessages.dart';
import 'restedrequesthandler.dart';
import 'restedsettings.dart';

class RestedServer {
  RestedRequestHandler request_handler;

  RestedServer(this.request_handler);

  void start(String _address, int _port) async {
    request_handler.address = _address;
    request_handler.port = _port;
    var server = await HttpServer.bind(_address, _port);
    print("\n\u001b[31mServer listening on " + _address + ":" + _port.toString() + "\u001b[0m\n");

    await for (HttpRequest request in server) {
      request_handler.handle(request);
    }    
  }
}