// Part of Rested Web Framework
// www.restedwf.com
// © 2021 Thomas Sebastian Berge

import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'restedrequesthandler.dart';
import 'restedsettings.dart';
import 'restedglobals.dart';
import 'admin/restedadmin.dart';
import 'dart:mirrors';
import 'restedresource.dart';

/*
class RestedServer {
  dynamic request_handler;

  RestedServer(this.request_handler);

  void start(String _address, int _port) async {
    //MinimalServer server = MinimalServer();
    ReceivePort receivePort = ReceivePort();
    receivePort.listen((message) {
      if(message == 'EXIT') {
        receivePort.close();
      }
    });

    Server server = Server();
    server.start(request_handler, _address, _port, receivePort);
  }

}*/
/*
class RestedServer {
  List<Thread> workers = [];

  RestedServer();

  void start() async {
    int i = 0;
    while(i < 1) {
      print("Thread #" + (i+1).toString() + " starting ...");
      workers.add(new Thread(i));
      await workers[i].start();
      i++;
    }
  }

  void keepAlive() {
    while(true){}
  }
}*/


class ServerCore {
  List<Thread> workers = [];

  void start(dynamic request_handler, String _address, int _port, ReceivePort receivePort) async {
    int _threads = rsettings.getVariable('server_threads');
    int i = 0;

    // SESSION SERVER
    if(rsettings.getVariable('sessions_enabled') && rsettings.getVariable('server_threads') > 1) {
      //print("START SESSION SERVER HERE");
    }

    // MAIN SERVER THREADS
    Map<String, dynamic> settings = {};
    while(i < _threads) {
      var instanceMirror = reflect(request_handler);
      var classMirror = instanceMirror.type;
      //var test = reflectClass(classMirror.reflectedType);
      //var temp = test.newInstance(new Symbol(''), []).reflectee;
      var requesthandler_instance = classMirror.newInstance(new Symbol(''), []).reflectee;

      settings["server"] = requesthandler_instance;
      settings['server'].address = _address;
      settings['server'].threadid = i;
      settings['server'].port = _port;
      settings['server'].postSetup();
      workers.add(Thread(settings));
      await workers[i].start();
      i++;
      //print("\n\u001b[31mServer thread #" + (settings["requesthandler"].threadid+1).toString() + " listening on " + settings['requesthandler'].address + ":" + settings['requesthandler'].port.toString() + "\u001b[0m\n");
    }

    for(RestedResource res in settings['server'].resources) {
      print(res.toString());
    }
  }
}


/*
class Thread {
  final Map<String, dynamic> settings;
  Isolate _isolate;
  ReceivePort receivePort;

  Thread(this.settings);

  Future<void> start() async {
      _isolate = await Isolate.spawn(_thread, settings);
  }

  static _thread(Map<String, dynamic> settings) async {
    //settings['requesthandler'].rested.address = getBaseUrl();
    var server = await HttpServer.bind("0.0.0.0", settings['requesthandler'].port, shared: true);
    await for (HttpRequest request in server) {
      settings['requesthandler'].handle(request);
    }
  }
}*/

class Thread {
  final Map<String, dynamic> settings;
  ReceivePort receivePort;

  Thread(this.settings);

  Future<void> start() async {
    await Isolate.spawn(_thread, settings);
  }

  static _thread(Map<String, dynamic> settings) async {
    Map<String, String> envVars = Platform.environment;
    
    if(envVars.containsKey('BASE_URL')) {
      settings['server'].address = envVars['BASE_URL'] + settings['server'].address;
    } else {
      settings['server'].address = "0.0.0.0" + settings['server'].address;
    }

    var server = await HttpServer.bind(settings['server'].address, settings['server'].port, shared: true);
    await for (HttpRequest request in server) {
        settings['requesthandler'].handle(request);
    }
  }
}