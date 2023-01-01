// Part of Rested Web Framework
// www.restedwf.com
// © 2022 Thomas Sebastian Berge

import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'requesthandler.dart';
import 'globals.dart';
import 'resource.dart';

class ServerCore {
  List<Thread> workers = [];

  void start(RestedRequestHandler requesthandler, String _address, int _port, ReceivePort receivePort) async {
    int _threads = rsettings.getVariable('server_threads');
    int i = 0;

    Map<String, String> envVars = Platform.environment;
    Map<String, dynamic> settings = {};
    settings['server'] = requesthandler;

    while(i < _threads) {
      
      if(envVars.containsKey('BASE_URL')) {
        settings['server'].address = envVars['BASE_URL'] + _address;
      } else {
        settings['server'].address = "0.0.0.0" + _address;
      }

      settings["server"] = requesthandler;
      settings['server'].threadid = i;
      settings['server'].port = _port;

      // start a new thread for all but the last
      if(i < (_threads -1)) {
        workers.add(Thread(settings));
        await workers[i].start();
      }
      i++;
    }

    for(RestedResource res in settings['server'].resources) {
      print(res.toString());
    }

    // Last thread started in the initialization thread, keeping the application from exiting.
    var server = await HttpServer.bind(settings['server'].address, settings['server'].port, shared: true);
    await for (HttpRequest request in server) {
        settings['requesthandler'].handle(request);
    }
  }
}

class Thread {
  final Map<String, dynamic> settings;
  ReceivePort receivePort;

  Thread(this.settings);

  Future<void> start() async {
    await Isolate.spawn(_thread, settings);
  }

  static _thread(Map<String, dynamic> settings) async {
    var server = await HttpServer.bind(settings['server'].address, settings['server'].port, shared: true);
    await for (HttpRequest request in server) {
        settings['server'].handle(request);
    }
  }
}