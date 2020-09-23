// Example 1: Webform API login
// Author: Thomas Sebastian Berge

import 'dart:io';
import 'dart:convert';
import 'package:rested/rested.dart';

// A remote server object we can communicate with. In this example the remote server happens
// to be the same server.
RestedRemoteServer api = new RestedRemoteServer("localhost", 8080);

// For handling JWT stuff
RestedJWT jwt_handler = new RestedJWT();

// This object basically holds the entire website, rest api and handles all the requests.
RestedRequestHandler rested;

// Make-shift "database"
Map<String, String> userdatabase = new Map();

// Webpages as string.
String loginpage = '<html><form action="/login" method="POST"><label for="username">Username:</label><br><input type="text" id="username" name="username"><br><label for="password">Password:</label><br><input type="text" id="password" name="password"><br><br><input type="submit" value="Submit"></form></html>';
String adminpage = '<html>Welcome mr. Administrator! You have a session_cookie with a valid access_token in your browser. Awesome! <a href="/logout">Remove cookie and see what happens.</a></html>';
String guestpage = '<html>Hello guest! Feel yourself at home or <a href="/logout">logout</a>.</html>';

main() async {

  // Create the user "admin" and "guest".
  userdatabase['admin'] = 'pass1234';
  userdatabase['guest'] = '';

  // Instantiate the RestedRequestHandler and add some resource endpoints with their respective addresses.
  rested = new RestedRequestHandler();
  rested.addResource(new resource_root(), "/");
  rested.addResource(new resource_login(), "/login");
  rested.addResource(new resource_logout(), "/logout");
  rested.addResource(new resource_database(), "/database/verify");

  // Create a server instance and start a single isolate testserver.
  RestedServer server = new RestedServer(rested);
  server.startTestServer("0.0.0.0", 8080);
}

// This resource serves the root '/' webpage. If you try to enter without a valid access_token you will
// be redirected to the login page. If you have a valid login it will serve you the webpage.
class resource_root extends RestedResource {
  String protected_redirect = "/login";

  resource_root(){
    require_token("get");
  }

  void get(RestedRequest request) {
    if(request.session['username'] == "admin") {
      request.response(type: 'html', data: adminpage);
    } else {
      request.response(type: 'html', data: guestpage);
    }
  }
}

// A simple make-shift database endpoint for verifying username/password and returning
// a JSON Web Token. This serves as the "api" in the example.
class resource_database extends RestedResource {
  void post(RestedRequest request) async {
    String username = request.body['username'];
    String password = request.body['password'];

    if(userdatabase.containsKey(username)) {
      if(userdatabase[username] == password) {
        Map claim_username = {"username": username};
        Map token = jwt_handler.generate_token(additional_claims: claim_username);
        request.response(type: "json", data: json.encode(token));
      } else {
        request.errorResponse(401);
      }
    } else {
      request.errorResponse(401);
    }
  } 
}

// Serves the login webpage (GET) and handles the external login form (POST) which
// in turn sets session data.
class resource_login extends RestedResource {

  void get(RestedRequest request) {
    request.response(type: "html", data: loginpage);
  }

  void post(RestedRequest request) async {
    Map formdata = request.body;

    Map logindata = {
      "username": formdata['username'],
      "password": formdata['password']
    };

    String loginresult = await api.post("/database/verify", json: logindata);
    if (loginresult.contains("access_token")) {
      Map result = json.decode(loginresult);
      request.session["access_token"] = result['access_token'];
      request.session["username"] = formdata["username"];
      Cookie session_cookie = rested.saveSession(request);
      request.addCookie(session_cookie);
      request.redirect('/');
    } else {
      request.redirect('/login');
    }
  }  
}

// Clears session data.
class resource_logout extends RestedResource {
  RestedRequest get(RestedRequest request) {
    request.removeCookie("session_cookie");
    request.redirect('/');
  }
}
