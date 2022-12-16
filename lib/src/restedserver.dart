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
}

/*
String getBaseUrl() {
  Map<String, String> envVars = Platform.environment;
  if(envVars.containsKey('BASE_URL')) {
    return(envVars['BASE_URL']);
  } else {
    return("localhost");
    print("BASE_URL environment parameter missing, defaulting to 'localhost'");
  }  
}*/

/*
class Server {
  List<Thread> workers = List();

  void start(dynamic request_handler, String _address, int _port, ReceivePort receivePort) async {
    int _threads = rsettings.getVariable('server_threads');
    int i = 0;

    // ADMIN WEB INTERFACE (currently not implemented, and just starts a standard server thead)
    if(rsettings.getVariable('module_admin_enabled')) {
      Map<String, dynamic> settings = { "requesthandler": AdminInterface() };
      settings['requesthandler'].address = _address;
      settings['requesthandler'].threadid = i;
      //settings['requesthandler'].port = _port;
      settings['requesthandler'].port = 8088;
      settings['requesthandler'].sendPort = receivePort.sendPort;
      settings['requesthandler'].servertype = "ADMIN";
      settings['requesthandler'].postSetup();
      workers.add(Thread(settings));
      await workers[i].start();
      i++;
      _threads++;
      print("\n\u001b[31mAdmin listening on " + settings['requesthandler'].address + ":" + settings['requesthandler'].port.toString() + "\u001b[0m\n");
    }

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

      settings["requesthandler"] = requesthandler_instance;
      settings['requesthandler'].address = _address;
      settings['requesthandler'].threadid = i;
      settings['requesthandler'].port = _port;
      settings['requesthandler'].postSetup();
      workers.add(Thread(settings));
      await workers[i].start();
      i++;
      //print("\n\u001b[31mServer thread #" + (settings["requesthandler"].threadid+1).toString() + " listening on " + settings['requesthandler'].address + ":" + settings['requesthandler'].port.toString() + "\u001b[0m\n");
    }

    for(RestedResource res in settings['requesthandler'].resources) {
      print(res.toString());
    }
  }
}
*/

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
}

class Thread {
  final int threadid;
  Isolate _isolate;

  Thread(this.threadid);

  Future<void> start() async {
      _isolate = await Isolate.spawn(
        _thread,
        threadid
      );
  }

  static _thread(int threadid) async {
    print("Thread #" + (threadid+1).toString() + " started.");

    Rested rested = new Rested();
    rested.threadid = threadid;
    var server = await HttpServer.bind(rested.address, rested.port, shared: true);

    await for (HttpRequest request in server) {
      rested.handle(request);
    }
  }
}