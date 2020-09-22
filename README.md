![GitHub Logo](images/logo_small.png)

# Alpha release 0.2.0

An incomplete, disorganized and heavily disfunctional web framework. A work-in-progress with the goal of making something great. If you stumbled upon this and would like to throw me a comment or two then by all means contact me at restedwf@gmail.com

If you'd like to test this then here is a short single-threaded example server:

```
main() async {
  var server = await HttpServer.bind("0.0.0.0", 8080);
  print("Serving at ${server.address}:${server.port}");

  request_handler rested = new request_handler();

  await for (HttpRequest request in server) {
    rested.handle(request);
  }
}

class request_handler extends Rested {
  request_handler() {
    this.addResource(new page_root(), "/");
  }
}

class page_root extends RestedResource {
  void get(RestedRequest request) {
    String contents = new File('bin/login.html').readAsStringSync();
    request.htmlResponse(contents);
  }

  void post(RestedRequest request) {
    Map formdata = request.body;
    if (formdata['username'] == "admin" && formdata['password'] == "pass1234") {
      request.textResponse("Login successful!");
    } else {
      request.textResponse("Wrong username or password");
    }
  }
}
```

If you go beyond this example then expect lots of bugs. The source is being developed on a private repo. I will update this repo from time to time.
