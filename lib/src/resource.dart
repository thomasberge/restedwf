import 'dart:mirrors';
import 'globals.dart';
import 'request.dart';
import 'pathparser.dart';
import 'response.dart';

class RestedResource {

  late String class_name;
  Map<String, String> summary = {};
  List<String> implementedMethods = [];
  String path = "";
  List<String> pathElements = [];
  String uri_parameters = "";
  Map functions = Map<String, Function>();
  Map onError = Map<int, Function>();
  Map _token_required = Map<String, bool>();
  Map operationId = Map<String, String>();
  Map<String, dynamic> getRequestSchema = {};
  String protected_redirect = "";

  RestedResource() {
    class_name = reflect(this).type.toString().split("'")[1];

    functions['get'] = get;
    functions['post'] = post;
    functions['put'] = put;
    functions['patch'] = patch;
    functions['delete'] = delete;
    functions['copy'] = copy;
    functions['head'] = head;
    functions['options'] = options;
    functions['link'] = link;
    functions['unlink'] = unlink;
    functions['purge'] = purge;
    functions['lock'] = lock;
    functions['unlock'] = unlock;
    functions['propfind'] = propfind;
    functions['view'] = view;

    for (String value in rsettings.getVariable('allowed_methods')) {
      _token_required[value] = false;
    }
  }

  /* void require_token(String _method, {String redirect_url = null}) {
    _token_required[_method] = true;
  }*/

  String toString() {
    return path;
  }

  void invalid_token_redirect(String _url) {
    protected_redirect = _url;
  }

  void setPath(String resourcepath) {
    path = resourcepath;
    pathElements = resourcepath.split('/');
    if (resourcepath.contains('{')) {
      uri_parameters = PathParser.get_uri_parameters(path);
    }
  }

  bool pathMatch(String requested_path) {
    if (path == requested_path) {
      return true;
    } else {
      if (uri_parameters != "" && requested_path != null) {
        List<String> requested_path_segments = requested_path
            .substring(1)
            .split('/'); // substring in order to remove leading slash
        List<String> uri_parameters_segments = uri_parameters.substring(1).split('/');
        if (requested_path_segments.length != uri_parameters_segments.length) {
          return false;
        } else {
          int i = 0;
          for (String segment in uri_parameters_segments) {
            if (segment == '{var}') {
              requested_path_segments[i] = '{var}';
            }
            i++;
          }
          if (uri_parameters_segments.join() == requested_path_segments.join()) {
            return true;
          } else {
            return false;
          }
        }
      } else {
        return false; // returning false because paths are null
      }
    }
  }

  void get(RestedRequest request) { int testing = 123; request.response(status: 501); }
  void post(RestedRequest request) { request.response(status: 501); }
  void put(RestedRequest request) { request.response(status: 501); }
  void patch(RestedRequest request) { request.response(status: 501); }
  void delete(RestedRequest request) { request.response(status: 501); }
  void copy(RestedRequest request) { request.response(status: 501); }
  void head(RestedRequest request) { request.response(status: 501); }
  void options(RestedRequest request) { request.response(status: 501); }
  void link(RestedRequest request) { request.response(status: 501); }
  void unlink(RestedRequest request) { request.response(status: 501); }
  void purge(RestedRequest request) { request.response(status: 501); }
  void lock(RestedRequest request) { request.response(status: 501); }
  void unlock(RestedRequest request) { request.response(status: 501); }
  void propfind(RestedRequest request) { request.response(status: 501); }
  void view(RestedRequest request) { request.response(status: 501); }

  void callback(RestedRequest request) {}

  void doMethod(String method, RestedRequest request) async {

    method = method.toLowerCase();

    if (_token_required[method]) {
      if (request.access_token == "") {
        if (protected_redirect != "") {
          request.response(type: "redirect", data: protected_redirect);
          RestedResponse response = RestedResponse(request);
          response.respond();
          return;
        } else {
          request.response(data: "401 error somethingsomething");
          RestedResponse response = RestedResponse(request);
          response.respond();
          return;
        }
      }
    }

    await functions[method](request);
    callback(request);
    RestedResponse response = RestedResponse(request);
    response.respond();
  }
}