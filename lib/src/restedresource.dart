// Part of Rested Web Framework
// www.restedwf.com
// © 2020 Thomas Sebastian Berge

import 'pathparser.dart';
import 'restedrequest.dart';

class RestedResource {
  String path = null;
  String tagged_path = null;

  void setPath(String resourcepath) {
    path = resourcepath;
    if (resourcepath.contains('<')) {
      tagged_path = PathParser.get_tagged_path(path);
    }
  }

  bool pathMatch(String requested_path) {
    if (path == requested_path) {
      return true;
    } else {
      if (tagged_path != null && requested_path != null) {
        List<String> requested_path_segments = requested_path
            .substring(1)
            .split('/'); // substring in order to remove first /
        List<String> tagged_path_segments = tagged_path.substring(1).split('/');
        if (requested_path_segments.length != tagged_path_segments.length) {
          return false;
        } else {
          int i = 0;
          for (String segment in tagged_path_segments) {
            if (segment == '<var>') {
              requested_path_segments[i] = '<var>';
            }
            i++;
          }
          if (tagged_path_segments.join() == requested_path_segments.join()) {
            return true;
          }
          return false;
        }
      } else {
        return false; // returning false because paths are null
      }
    }
  }

  // Stored functions for each HTTP method. Example <'Get', get> can be used as _functions['get](request);
  Map functions = new Map<String, Function>();

  // Stored function for each HTTP error code. Returns standard error if not overridden with a function
  Map onError = new Map<int, Function>();

  // Storage of bool determining if access_token is required for the http method (_functions). Use method
  // instead of setting the variable directly.
  Map _token_required = new Map<String, bool>();

  void require_token(String method, {String redirect_url = null}) {
    _token_required[method] = true;
  }

  // If access to method is protected by an access_token then instead of retuning 401 Unauthorized it is
  // possible to return a redirect instead by setting the URL in this variable.
  String protected_redirect = null;

  void invalid_token_redirect(String url) {
    protected_redirect = url;
  }

  RestedResource() {
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
    _token_required['get'] = false;
    _token_required['post'] = false;
    _token_required['put'] = false;
    _token_required['patch'] = false;
    _token_required['delete'] = false;
    _token_required['copy'] = false;
    _token_required['head'] = false;
    _token_required['options'] = false;
    _token_required['link'] = false;
    _token_required['unlink'] = false;
    _token_required['purge'] = false;
    _token_required['lock'] = false;
    _token_required['unlock'] = false;
    _token_required['propfind'] = false;
    _token_required['view'] = false;
  }

  //void addPath(String path) {
  //  this.path = path;
  //}

  void get(RestedRequest request) {}
  void post(RestedRequest request) {}
  void put(RestedRequest request) {}
  void patch(RestedRequest request) {}
  void delete(RestedRequest request) {}
  void copy(RestedRequest request) {}
  void head(RestedRequest request) {}
  void options(RestedRequest request) {}
  void link(RestedRequest request) {}
  void unlink(RestedRequest request) {}
  void purge(RestedRequest request) {}
  void lock(RestedRequest request) {}
  void unlock(RestedRequest request) {}
  void propfind(RestedRequest request) {}
  void view(RestedRequest request) {}

  // If the request contains an access_token then it has already been verified before this function
  // is executed. If the corresponding http method protection variable is set to true then this
  // function will check if access_token is set (and hence verified). If it is then it will allow
  // the http method to execute. If access_token is null it will return an 401 Unathorized error
  // response. If the http method protection variable is set to false however then it will execute
  // the corresponding method without any checks.
  void doMethod(String method, RestedRequest request) {
    method = method.toLowerCase();
    if (_token_required[method]) {
      if (request.access_token != null) {
        functions[method](request);
      } else {
        if (protected_redirect != null) {
          print("PROTECTED REDIRECT!");
          request.redirect(protected_redirect);
        } else {
          request.errorResponse(401);
        }
      }
    } else {
      functions[method](request);
    }
  }
}