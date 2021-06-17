// Part of Rested Web Framework
// www.restedwf.com
// © 2021 Thomas Sebastian Berge

import 'dart:io';
import 'dart:async';
import 'dart:isolate';
import 'consolemessages.dart';
import 'restedrequesthandler.dart';
import '../server.dart';
import 'restedsettings.dart';

RestedSettings rsettings = new RestedSettings();
ConsoleMessages console = new ConsoleMessages(debug_level: rsettings.message_level);

class RestedServer {
  List<Thread> workers = new List();

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

  void keepAlive() async {
    while(true){
      await Future.delayed(Duration(seconds: 1));
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
