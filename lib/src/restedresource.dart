import 'dart:io';

import 'restedfiles.dart';
import 'restedschema.dart';
import 'restedrequest.dart';
import 'pathparser.dart';
import 'restedsettings.dart';
import 'external.dart';
import 'restedresponse.dart';
import 'restedsession.dart';
import 'errors.dart';

class RestedResource {
  bool validateAllQueryParameters = false;

  String path = null;

  // Only used for pattern matching in pathMatch function
  String uri_parameters = null;

  Map<String, dynamic> _uri_parameters_schemas = {};
  Map<String, Map<String, dynamic>> _query_parameters_schemas = {};
  FileCollection _files = FileCollection();

  // Stores schemas for each HTTP method.
  Map schemas = Map<String, RestedSchema>();

  // Stored functions for each HTTP method. Example <'Get', get> can be used as _functions['get](request);
  Map functions = Map<String, Function>();

  // Stored function for each HTTP error code. Returns standard error if not overridden with a function
  Map onError = Map<int, Function>();

  // Storage of bool determining if access_token is required for the http method (_functions). Use method
  // instead of setting the variable directly.
  Map _token_required = Map<String, bool>();

  // Stores operationId on resources imported from YAML. This is in order to link it to an external function.
  Map operationId = Map<String, String>();


  Map<String, dynamic> getRequestSchema = null;

  Map<String, Map<String, dynamic>> getQueryParams() {
    return _query_parameters_schemas;
  }

  bool validateSchema(String method, RestedRequest request) {
    if(request.form != {}) {
        return schemas[method.toLowerCase()].validate(request.form);
    } else if(request.body != {}) {
        return schemas[method.toLowerCase()].validate(request.body);
    } else {
        Errors.raise(request, 400);
        return false;
    }
  }

  String validateUriParameters(Map<String, String> params) {
    for(MapEntry e in params.entries) {
      if(_uri_parameters_schemas.containsKey(e.key)) {
        String result = _uri_parameters_schemas[e.key].validate(e.value);
        if(result != "OK") {
          return result;
        }
      }
    }
    return "OK";
  }

  addFiles(String directory) {
    _files.addFiles(directory);
  }

  String getFile(String requestpath) {
    return _files.getFile(requestpath);
  }

  Map<String, String> getFiles() {
    return _files.getFiles();
  }

  String validateQueryParameters(String method, Map<String, String> params) {
    
    if(_query_parameters_schemas.length < 1) {
      return "OK";
    }
    method = method.toLowerCase();
    for(MapEntry e in params.entries) {
      print(e.key);
      if(_query_parameters_schemas[method].containsKey(e.key)) {
        String result = _query_parameters_schemas[method][e.key].validate(e.value);
        if(result != "OK") {
          return result;
        }
      } else {
        if(validateAllQueryParameters) {
          return "UNDEFINED QUERY PARAMETER";
        }
      }
    }
    return "OK";
  }

  void require_token(String _method, {String redirect_url = null}) {
    _token_required[_method] = true;
  }

  String toString() {
    return path;
  }

  // If access to method is protected by an access_token then instead of retuning 401 Unauthorized it is
  // possible to return a redirect instead by setting the URL in this variable.
  String protected_redirect = null;

  void addUriParameters(Map<String, dynamic> new_schemas) {
    _uri_parameters_schemas = new_schemas;
  }

  void addUriParameterSchema(dynamic schema) {
    _uri_parameters_schemas[schema.name] = schema;
  }

  void addQueryParameters(String method, Map<String, dynamic> new_schemas) {
    _query_parameters_schemas[method] = new_schemas;
  }

  void addQueryParameterSchema(String method, dynamic schema) {
    _query_parameters_schemas[method][schema.name] = schema;
  }

  void invalid_token_redirect(String _url) {
    protected_redirect = _url;
  }

  void setPath(String resourcepath) {
    path = resourcepath;
    _files.resource_path = resourcepath;
    if (resourcepath.contains('{')) {
      uri_parameters = PathParser.get_uri_parameters(path);
    }
  }

  bool pathMatch(String requested_path) {
    if (path == requested_path) {
      return true;
    } else {
      if (uri_parameters != null && requested_path != null) {
        List<String> requested_path_segments = requested_path
            .substring(1)
            .split('/'); // substring in order to remove leading slash
        List<String> uri_parameters_segments =
            uri_parameters.substring(1).split('/');
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
          if (uri_parameters_segments.join() ==
              requested_path_segments.join()) {
            return true;
          }
          return false;
        }
      } else {
        return false; // returning false because paths are null
      }
    }
  }

  RestedResource() {
    //disk = new RestedVirtualDisk();
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

    schemas['get'] = null;
    schemas['post'] = null;
    schemas['put'] = null;
    schemas['patch'] = null;
    schemas['delete'] = null;
    schemas['copy'] = null;
    schemas['head'] = null;
    schemas['options'] = null;
    schemas['link'] = null;
    schemas['unlink'] = null;
    schemas['purge'] = null;
    schemas['lock'] = null;
    schemas['unlock'] = null;
    schemas['propfind'] = null;
    schemas['view'] = null;

    for (String value in rsettings.getVariable('allowed_methods')) {
      _token_required[value] = false;
    }

    Map<String, String> _envVars = Platform.environment;
    if(_envVars.containsKey('VALIDATE_ALL_QUERY_PARAMETERS')) {
      if(_envVars['VALIDATE_ALL_QUERY_PARAMETERS'].toUpperCase() == 'TRUE') {
        validateAllQueryParameters = true;
      }
    }
  }

  setExternalFunctions() {
    /*
        All external functions are defined with operationId key 'string' and 'function' in xfunctions map in external.dart
        
        Map<String, Function(RestedRequest)> xfunctions = {
          'list-users': listusers
        };

        When .yaml is read OAPI3 object defined in openapi3.dart, this Resource is created and returned to the requesthandler.
        In that process, the operationId <String, String> map in this Resource is updated with http-method and xfunction key
        references.

        Map<String, String> operationId = {
          'get': 'list-users'
        }

        All Resources have a functions<String, Function> map containing all of the http methods:

        Map<String, Function> functions = {
          'get': get,
          'post': post,
          ...
        }

        This setExternalFunctions will read through all of the operationId entries and set the function[key] = xfunctions[key]
    */
    for(MapEntry e in operationId.entries) {
      functions[e.key] = xfunctions[e.value];
      print("Imported operationId " + e.value + " for " + e.key.toUpperCase() + " " + path);

      if(xfunctions_require_token.contains(e.value)) {
        print("Token required on " + e.key + " " + path);
        require_token(e.key);
      }
    }
  }

  void setSchema(String method, RestedSchema schema) {
    method = method.toLowerCase();
    if(schemas.containsKey(method)) {
      schemas[method.toLowerCase()] = schema;
    }
  }

  void get(RestedRequest request) { request.response(status: 501); }
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

  void wrapper(String method, RestedRequest request) async {

    if(request == null) {
      print("Error in wrapper(): request is null");
    }
/*
    // If the resource method has a schema requirement
    if(schemas[method] != null) {
      if(schemas[method].validate(request.body)) {
        await functions[method](request);
        await callback(request);
      } else {
        request.response(type: "error", status: 400);
      }
    } 
    // If the resource method does NOT have a schema requirement
    else {*/
      if(functions[method] == null) {
        request.response(status: 501);
      } else {
        await functions[method](request);
      }
      await callback(request);
    //}

    if (request.session.containsKey('delete')) {
      if (request.session['delete']) {
        sessions.deleteSession(request.session['id']);
        request.request.response.headers
            .add("Set-Cookie", "session=; Path=/; Max-Age=0; HttpOnly");
      }
    } else {
      if (request.session.length > 0) {
        sessions.saveSession(request);
      }
    }
  }

  // If the request contains an access_token then it has already been verified before this function
  // is executed. If the corresponding http method protection variable is set to true then this
  // function will check if access_token is set (and hence verified). If it is then it will allow
  // the http method to execute. If access_token is null it will return an 401 Unathorized error
  // response. If the http method protection variable is set to false however then it will execute
  // the corresponding method without any checks.
  void doMethod(String method, RestedRequest request) async {
    String result = validateUriParameters(request.uri_parameters);
    if(result == "OK") {
      result = validateQueryParameters(method, request.query_parameters);
    }
    
    if(result != "OK") {
        Errors.raise(request, 400);
        return;
    }

    if(schemas.containsKey(method.toLowerCase())) {
        if(schemas[method.toLowerCase()] != null) {
            if(validateSchema(method, request) == false) {
                Errors.raise(request, 400);
                return;
            }
        }
    }

    method = method.toLowerCase();
    if (_token_required[method]) {
      if (request.access_token != null) {
        await wrapper(method, request);
        RestedResponse response = RestedResponse(request);
        response.respond();
      } else {
        if (protected_redirect != null) {
          request.response(type: "redirect", data: protected_redirect);
          RestedResponse response = RestedResponse(request);
          response.respond();
        } else {
          request.response(data: "401 error somethingsomething");
          RestedResponse response = RestedResponse(request);
          response.respond();
        }
      }
    } else {
      await wrapper(method, request);
      RestedResponse response = RestedResponse(request);
      response.respond();
    }
  }
}