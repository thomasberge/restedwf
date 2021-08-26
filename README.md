![GitHub Logo](images/logo_small.png)

# Alpha release 0.4.2

A work-in-progress web framework written in dart. The aim is to create a one-stop-shop for just about anything web app related, such as websites, webapps and even Restful APIs. Rested Web Framework comes with its own serverside scripting language, RestedScript. Although it is in its infancy and only supports a handful of features it already has some unique capabilities that can prove quite powerful in a html/css development setting.

A word of caution: This framework is still very much in development. Structural and functional changes can and most likely will occur. Not all aspects are fully implemented yet. Important and perhaps even basic features may not be implemented at all. Please only use this for testing - and use it at your own risk. If you would like to throw me a comment or two then by all means contact me at restedwf@gmail.com. If there is anything in particular that you would like me to work on then by all means ask.

The source is being developed on a private repo. I will update this repo from time to time.

### 0.4.0 Main changes

The focus of this release have been to remove elements that either didn't belong or should be an extension. The parser have gotten its own release through StringTools, which is usable out-of-the-box. RestedScript has been isolated and made into its own project as it will serve as an optional extension to RestedWF. Both these projects are available from my github as their own repos. RestedWF will focus on core functionality such as serving a standard REST API. The server implementation in v0.3 was out of place and should really have been part of an implementation of RestedWF, not in RestedWF itself. The old single-threaded development server has been reimplemented instead and will now display a warning when run.

### 0.4.1 fixes
- Fixed missing rested_script reference in pubspec.
- Fixed version error in pubspec.
- Fixed error in readme example.

### 0.4.2 fixes
- Changed rested_script dependency to follow dev branch.

### Features

This is the core module that adds the basic functionality. Add-ons will give optional functionality. The main features in this module are:
- Class-oriented code pattern. Each /resource is its own class with each HTTP method being a function.
- Sessions & Cookies. Who doesn't like cookies?
- Automatic JSON Web Token implementation, seemlessly integrated with Session & Cookie support. JWT requirement per method in a /resource. Optional redirect if token doesn't validate.
- Automatic parsing of incoming body for JSON and webforms.
- Text/binary file server support, although with limited streaming capabilities.
- Settings from either code, environment or json file.
- Test development server server.

### Add-ons

RestedWF have exclusive, optional add-ons that will give you more tools in your HTTP toolbelt:
- RestedScript, a serverside scripting language.

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
import 'package:restedwf/rested.dart';
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


Create a class called Rested that extends RestedRequestHandler. This is where you add your endpoints.

```
class Rested extends RestedRequestHandler {
  
  Rested() {
    this.addResource(Resource_root(), "/");
  }
}
```

Instantiate and start a development test server at the specified address and port.

```
main() async {
  RestedServer server = RestedServer(Rested());
  server.start("127.0.0.1", 80);
}
```
