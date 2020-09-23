![GitHub Logo](images/logo_small.png)

# Alpha release 0.2.0

An work-in-progress dart web framework. The aim is for RestedWF to be your one-stop-shop for just about anything web app related such as Restful APIs and websites/website servers. RestedWF comes with its own serverside scripting language, RestedScript. Although it is in its infancy and only supports a handful of features it already has unique capabilities that can be quite powerful in a html/css development setting.

A word of caution: This framework is still very much in development. Structural and functional changes can and most likely will occur. Not all aspects are fully implemented yet. Important and perhaps even basic features may not be implemented at all. Please only use this for testing - and use it at your own risk. If you would like to throw me a comment or two then by all means contact me at restedwf@gmail.com. If there is anything in particular that you would like me to work on then by all means ask.

The source is being developed on a private repo. I will update this repo from time to time.

### Example

In the example there is a server example that does the following:
- Creates a single-threaded test server
- Adds a root page that can only be accessed with a session_cookie that contains an access_token
- Sets automatic forwarding to /login webpage with login form if access_token is missing, invalid or expired
- Example of GET/POST webform for handling forms and getting data from request as json
- Example of doing a request to a remote server - in this case the login post endpoint sends a request to an external resource with username/password in order to get the access_token. That external resource is in reality justlocalhost, so the webserver is sending the request to itself.
- Example of a database (in this case just a Map dictionary) login with JWT access_token, along with example of adding custom claim.
- Example of creating a session and settings session variables.

### Mini-documentation

Create a resource:

```
class resource_root extends RestedResource {
  void get(RestedRequest request) {
    request.response(type: 'html', data: "<html>I am a glorious website!</html>");
  }
}

```


Create a request handler at top level, then add the root resource and create a server:

```
RestedRequestHandler rested;

main() async {
  rested = new RestedRequestHandler();
  rested.addResource(new resource_root(), "/");

  RestedServer server = new RestedServer(rested);
  server.startTestServer("0.0.0.0", 8080);
}
```
