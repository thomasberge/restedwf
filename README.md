![GitHub Logo](images/logo_small.png)

# Alpha release 0.3.0

An work-in-progress web framework written in dart. The aim is to create a one-stop-shop for just about anything web app related, such as websites, webapps and even Restful APIs. Rested Web Framework comes with its own serverside scripting language, RestedScript. Although it is in its infancy and only supports a handful of features it already has some unique capabilities that can prove quite powerful in a html/css development setting.

A word of caution: This framework is still very much in development. Structural and functional changes can and most likely will occur. Not all aspects are fully implemented yet. Important and perhaps even basic features may not be implemented at all. Please only use this for testing - and use it at your own risk. If you would like to throw me a comment or two then by all means contact me at restedwf@gmail.com. If there is anything in particular that you would like me to work on then by all means ask.

The source is being developed on a private repo. I will update this repo from time to time.

### Features

These are the main features currently supported
- Multi-threaded, scalable server.
- Class-oriented code pattern. Each /resource is its own class with each HTTP method being a function.
- Sessions & Cookies. Who doesn't like cookies?
- Automatic JSON Web Token implementation, seemlessly integrated with Session & Cookie support. JWT requirement per method in a /resource. Optional redirect if token doesn't validate.
- Automatic parsing of incoming body for JSON and webforms.
- Support for easy HTTP requests.
- Text/binary file server support, although with limited streaming capabilities.
- RestedScript, a serverside scripting language.
- Settings from either code, environment or json file.

### Example

In the example there is a server example that does the following:
- Creates a multi-threaded server, although default config is 1 thread
- Adds a root page that can only be accessed with a session that contains an access_token
- Sets automatic forwarding to /login webpage with login form if access_token is missing from session, invalid or expired
- Example of GET/POST webform for handling forms and getting data from request as json
- Example of doing a request to a remote server - in this case the login post endpoint sends a request to an external resource with username/password in order to get the access_token. That external resource is in reality justlocalhost, so the webserver is sending the request to itself.
- Example of a database (in this case just a Map dictionary) login with JWT access_token, along with example of adding custom claim.
- Example of creating a session and settings session variables.

### Mini-documentation

The following needs to be in a file called 'server.dart', which in turn must reside in the same level as 'rested.dart'.

```
import 'rested.dart';
```

Create a Resource class. You create these for each /resource. Supports all standard HTTP methods as functions.

```
class Resource_root extends RestedResource {
  void get(RestedRequest request) {
    request.response(type: 'html', data: "<html>I am a glorious website!</html>");
  }

  void post(RestedRequest request) {
    // This function would handle post requests.
  }
}

```


Create a class called Rested that extends RestedRequestHandler. This class' constructor serves as your applications main().

```
class Rested extends RestedRequestHandler {
  
  Rested() {
    this.address = "127.0.0.1";
    this.port = 8080;
    this.addResource(Resource_root(), "/");
  }
}
```

Instantiate and start a server. The server will in turn instantiate Rested classes in isolates. Use keepAlive for the application to not exit prematurely, or code your own function.

```
main() async {
  RestedServer server = new RestedServer();
  await server.start();
  server.keepAlive();
}
```
