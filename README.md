![GitHub Logo](images/logo_small.png)

# Alpha release 0.5.0

A work-in-progress web framework written in dart. The aim is to create a one-stop-shop for just about anything web app related, such as websites, webapps and even Restful APIs. Rested Web Framework comes with its own serverside scripting language, RestedScript. Although it is in its infancy and only supports a handful of features it already has some unique capabilities that can prove quite powerful in a html/css development setting.

A word of caution: This framework is still very much in development. Structural and functional changes can and most likely will occur. Not all aspects are fully implemented yet. Important and perhaps even basic features may not be implemented at all. Please only use this for testing - and use it at your own risk. If you would like to throw me a comment or two then by all means contact me at restedwf@gmail.com. If there is anything in particular that you would like me to work on then by all means ask.

The source is being developed on a private repo. I will update this repo from time to time.

### 0.5.0 Main changes

- Created a new http error handler. Simple to use and effective.
- Added test server. To be used as test server on dev. No test script implemented yet.
- Added temporary 404 reply for non-implemented methods on paths.
- Added ignore_authorization_header server setting. Default obviously set to false.
- RestedSchema created. Rather simple for the time being. Implemented on resource level.
- Cleaned up unused dependencies and updated some of the used ones to latest version.
- Bugfix: Expired token rendered no response.
- Bugfix: Unsupported or malformed authorization header now returns 401 instead of 400.
- Documentation updated quite heavily.

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

#### The basics

Link this repo as a requirement in the `pubspec.yaml` file. If you leave out `ref: dev` then you will get the main, stable(ish) release.

```
  restedwf:
    git:
      url: https://github.com/thomasberge/restedwf
      ref: dev
```

Import the package to get access to all of its objects. There should be no need to reference other files internal to RestedWF.

```
import 'package:restedwf/rested.dart';
```

You define a resource as a `RestedResource` class. Supports all standard HTTP methods as functions within the class (yes, `get` as well even though its a reserved word).

```
class Resource_Root extends RestedResource {
  void get(RestedRequest request) {
    request.response(type: 'html', data: "<html>I am a glorious website!</html>");
  }

  void post(RestedRequest request) {
    // This function handles post requests.
  }
}
```

All resource classes are instantiated and added to a single `RestedRequestHandler` class and given a path.

```
class Rested extends RestedRequestHandler {
  
  Rested() {
    this.addResource(Resource_Root(), "/");
    this.addResource(Resource_Login(), "/login");
  }
}
```

Once you have a `RestedRequestHandler` clas defined you can start a `RestedServer` with the requesthandler as an argument. Start the server by specifying its address and port.

```
main() async {
  RestedServer server = RestedServer(Rested());
  server.start("127.0.0.1", 80);
}
```

If you are running this inside a docker container then use `0.0.0.0` instead of `127.0.0.1` or `localhost`.


#### The Request Object

Each RestedResource function needs a RestedRequest object as its argument. This object will contain information about the incoming request. It is a server-side HttpRequest object from dart:io wrapped in a RestedRequest object. You can directly access the HttpRequest object through request.request should you need to.

request.body is of type Map<String, dynamic> and will contain data if the incoming request was either a JSON or formdata.

request.text is of type String and contains text data if the incoming request has Content-Type text/plain.

There is currently no proper way to handle incoming binary stream nor XML.

```
class Resource_Login extends RestedResource {
  void post(RestedRequest request) {
    String login_username = request.body['username'];
    String login_password = request.body['password'];

    // do API login request
  }
}
```


#### The Response and Redirect Functions

Normally you will either respond to a request with some data, or you will redirect the user somewhere else.

```
class Resource_Login extends RestedResource {
  void get(RestedRequest request) {
    request.response(type: "html", data: "<html>Website goes here</html>");    
  }

  void post(RestedRequest request) {

    // do API login request, get token cookie, then redirect back to root

    request.redirect('/');
  }
}
```

The response function has two named arguments; type and data. Type is default `text`, but other allowed values are `json` and `html`.

Redirecting is as easy as running the function name with the path as an argument.


#### Protecting endpoints with JSON Web Tokens

First of all, this require some light setup before it can be used. In your environment you need the following variables set:

```
      - jwt_key=C4NN0NB477S!!!!?
      - jwt_issuer=yourwebsitegoeshere
      - jwt_duration=5000
      - cookies_max_age=1200
```

`jwt_key` need to be 16 characters. Any JWT created with this `jwt_key` by this `jwt_issuer` will validate. If you create a separate API server then those two values needs to be identical for the JWT token issued by the API to resolve on the website (or vice versa).

All JWT tokens have a server and a client expiration time. `jwt_duration` is checked by the server. The cookie containing the JWT token will also be deleted by the client when `cookies_max_age` expires, although that is up to the client to uphold.

Once this is set up then you need to instantiate the RestedJWT class in the root of the application (outside main).

```
import 'package:restedwf/rested.dart';

RestedJWT jwt_handler = new RestedJWT();

class Resource_Login extends RestedResource {
  // ...
```

A RestedResource can be protected by requiring a valid JWT. This is just about the first thing the RequestHandler checks when processing a request. In order to enable this you will need to add it in the RestedResources instantiate function. You need to explicitly set each method you want to protect.

The default behavior of a protected resource method is to return 403 Forbidden if the token is not valid or expired. You can however set a default forwarding URL as an alternative. This is set per resource however and will therefor work the same for all of the resource methods that are protected.

```
class Resource_Root extends RestedResource {
  String protected_redirect = "/login";

  Resource_Root() {
    require_token("get");
  }

  // ...
}
```

To create a token you simply let the jwt_handler generate it. You also have the option of adding custom claims to the token. Note that these are not encrypted claims. You can later extract claims for other purposes.

```
Map claims = {"role": "administrator"};
Map token = jwt_handler.generate_token(additional_claims: claims);
```

You can also add custom verification of JWT tokens by overriding the `custom_JWT_verification` function on the requesthandler. It needs to have a ´String token´ argument and return a bool signaling if its verified or not.

```
class Rested extends RestedRequestHandler {
  
  Rested() {
    this.addResource(Resource_Root(), "/");
    this.addResource(Resource_Login(), "/login");
  }

  bool custom_JWT_verification(String token) {
    // can be used to for example create a blacklist of tokens (not part of RestedWF)
    return !isBlacklisted(token);
  }
}
```


#### Server Sessions

... to be documented. Basically add a SessionManager and return session id in a cookie instead of JWT token. The requesthandler will automatically identify the session, look up the token and try to verify it. Examples to come.


#### Implementing restedscript for templating and scripting

... to be better documented. Here is a simple example:

Add to pubspec.yaml

```
  rested_script:
    git:
      url: https://github.com/thomasberge/rested_script
      ref: dev
```

```
// Instantiate this on root level (or per dart file)
RestedScript rscript = RestedScript(root: "/app/bin/resources/", debug: true);

// Build a document from any page with the createDocument command
class AdminPage extends RestedResource {
  void get(RestedRequest request) async {
    String index_page = await rscript.createDocument("admin/index.html");
    request.response(type: "html", data: index_page);
  }
}
```

RestedScript is documented here: https://github.com/thomasberge/rested_script


#### Doing REST requests

... to be documented properly. Here is a short example:

```
Map<String, String> _headers = { "Content-Type": "application/json" };
Map<String, dynamic> _data = { "username": login_username, "password": login_password };
String result = await RestedRequests.post('http://api.something.com/login', headers: _headers, data: json.encode(_data));
```

#### Handling HTTP errors

In case you want to raise a HTTP error from within a HTTP method you need to have instantiated an Errors object. Pass the request object as well as the error code, and a response will be sent back to the client. It is imperative that you then use the return statement, or else the rest of your code will be run.

```
Errors error_handler = Errors();

class CrashTest extends RestedResource {
  void get(RestedRequest request) async {
    errors.raise(request, 400);
    return;
  }
}
```

## Testing

There is a test script included in /test that runs a server and tests some functions. A report is written to console. The accompanying Dockerfile in this repo root can be run in order to run the test server.

```bash
docker build -t restedwf_test . && docker run --init -p 80:80 restedwf_test
```
