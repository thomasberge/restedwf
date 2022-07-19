/* 
    Rested Web Framework testing playground
*/

import 'dart:io';
import 'dart:convert';
import 'rested.dart';
import 'package:jaguar_jwt/jaguar_jwt.dart';
import 'src/restedsettings.dart';


main() async {
    xfunctions['authenticate'] = testing;
    xfunctions['list-users'] = listusers;
    RestedServer admin_server = RestedServer(TestServer());
    admin_server.start("0.0.0.0", 80);
}

void listusers(RestedRequest request) async {
  request.response(data: "list users here");
}

class TestServer extends RestedRequestHandler {
  TestServer() {
    RestedSchema userschema = RestedSchema();
    userschema.addField(StringParameter("username"), requiredField: true);
    StringParameter email = StringParameter("email");
    email.minLength = 12;
    userschema.addField(email);
    this.setGlobalSchema("User", userschema);

    this.addResource(Root(), "/");
    this.addResource(Login(), "/login");
    this.addResource(Redirect(), "/g");
    this.addResource(Dump(), "/dump");
    this.addResource(GetPage(), "/get");
    this.addResource(JsonTest(), "/json");
    this.addResource(Claims(), "/claims");
    this.addResource(SettingsTest(), "/settings");
    this.addResource(PathParam(), "/t/{test}/{test2}");
    this.addResource(SchemaTest(), "/validate");
    this.addResource(JWTClaims(), "/allclaims");
    this.addResource(GETJWTClaims(), "/getclaims");
    this.addResource(Files(), "/{param}/test");
  }
}

class Files extends RestedResource {
  Files() {
    addFiles("bin/files");
  }

  void get(RestedRequest request) async {
    request.response(data: "filedir");
  }
}

class SchemaTest extends RestedResource {
  void post(RestedRequest request) async {
    print(RestedSchema.isEmail('test@test.no').toString());
    request.response(data: "TEST");
  }
}

class User extends RestedResource {
  void get(RestedRequest request) async {
    request.response(data: "get user");
  }

  void put(RestedRequest request) async {
    request.response(data: "update user");
  }

  void delete(RestedRequest request) async {
    request.response(data: "delete user");
  }
}

void testing(RestedRequest request) {
  request.response(data: "test");
}

class PathParam extends RestedResource {
  PathParam() {
    StringParameter test = StringParameter("test");
    test.maxLength = 7;
    IntegerParameter test2 = IntegerParameter("test2");

    this.addUriParameterSchema(test);
    this.addUriParameterSchema(test2);
  }

  void get(RestedRequest request) async {
    request.response(data: request.uri_parameters["test"].toString());
  }
}

class SettingsTest extends RestedResource {
  void get(RestedRequest request) async {
    request.response(data: rsettings.variables.toString());
  }
}

class Claims extends RestedResource {
  void get(RestedRequest request) async {
    RestedJWT jwthandler = RestedJWT();
    Map claims = { "somevariable": "somevalue" };
    Map token = jwthandler.generate_token(additional_claims: claims);
    Map result = json.decode(json.encode(token));
    String tokenstring = result["access_token"];
    String somevariable = RestedJWT.getClaim(tokenstring, "somevariable");
    request.response(data: somevariable);
  }
}

class GETJWTClaims extends RestedResource {
  void get(RestedRequest request) {
    RestedJWT jwthandler = RestedJWT();
    Map claims = { "somevariable": "somevalue" };
    Map token = jwthandler.generate_token(additional_claims: claims);
    Map result = json.decode(json.encode(token));
    request.response(data: result.toString());
  }
}

class JWTClaims extends RestedResource {
  void get(RestedRequest request) async {
    request.response(data: request.claims.toString());
  }
}

class GetPage extends RestedResource {
  void get(RestedRequest request) async {
    String temp = await RestedRequests.get("www.google.com");
    request.response(type: "html", data: temp);
  }
}

class JsonTest extends RestedResource {
  void get(RestedRequest request) async {
    Map<String, dynamic> _data = { "SomeKey": "SomeValue", "AnotherKey": 14, "YetAnotherKey": true };
    Map result = await RestedRequests.post("http://0.0.0.0/json", json: json.encode(_data));
    Map resultmap = json.decode(result['data']);
    request.response(data: resultmap["AnotherKey"].toString());
  }

  void post(RestedRequest request) async {
    Map<String, dynamic> map = { "SomeKey": "SomeValue", "AnotherKey": 14, "YetAnotherKey": true };
    request.response(type: "json", data: json.encode(map));
  }
}

class Dump extends RestedResource {
  void post(RestedRequest request) {
    request.response(data: request.text);
  }
}

class Root extends RestedResource {
  String protected_redirect = "/login";

  Root() {
    require_token("get");
  }  

  void get(RestedRequest request) async {
    request.response(data: "test");
  }
}

class Login extends RestedResource {

  Login() {
    RestedSchema userlogin = RestedSchema();
    userlogin.addField(StringParameter("username"), requiredField: true);
    StringParameter password = StringParameter("password");
    password.minLength = 12;
    userlogin.addField(password, requiredField: true);
    setSchema("POST", userlogin);
  }

  void get(RestedRequest request) async {
      String loginpage = '<html><form action="/login" method="POST"><label for="username">Username:</label><br><input type="text" id="username" name="username"><br><label for="password">Password:</label><br><input type="password" id="password" name="password"><br><br><input type="submit" value="Submit"></form></html>';
      request.response(type: "html", data: loginpage);
  }

  void post(RestedRequest request) async {
    request.redirect('/login');
  }
}

class Redirect extends RestedResource {
  void get(RestedRequest request) async {
      request.redirect("http://www.google.com");
  }
}