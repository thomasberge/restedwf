import 'dart:io';
import 'dart:convert';

class OAS3Document {
  Map<String, dynamic> doc = new Map();   // contains the original OAS3 JSON document
  List<String> paths = new List();    // contains all the full paths
  List<RestedSchema> schema = new List();

  OAS3Document(String filepath) {
    File file = File(filepath);
    String filedata = file.readAsStringSync();
    doc = json.decode(filedata);
    paths = GetAllPaths();
  }

  List<String> GetAllPaths() {
    List<String> pathlist = new List();
    if(doc.containsKey("paths")) {
      Map<String, dynamic> paths = doc["paths"];
      paths.forEach((key, value) { 
        if(key.substring(0,1) == '/') {
          pathlist.add(key);
          List<String> pathmethods = GetAllPathMethods(key, value);

          // Grab all "parameters" and put them in their respective RestedSchema
          //Map<String, dynamic> endpoint = value;
          //endpoint.forEach((endpoint_key, endpoint_value) {
            //print(endpoint_key);
            /*
            switch (endpoint_key) {
              case "get":
                  
                break;
            }
            if(endpoint_key == "get") {
              //print("parameters for " + key + ": " + endpoint_value);
            }*/
          //});
        }
      });      
    }
    return pathlist;
  }
}

// Created a list of path/method combos used to identify each schema. Example "GET /users" or "DELETE /users/{userid}". Method is forced to uppercase and resource to lowercase.
List<String> GetAllPathMethods(String path, Map<String, dynamic> schema) {
  List<String> allowedMethods = ["get", "post", "put", "patch", "delete", "copy", "head", "options", "link", "unlink", "purge", "lock", "unlock", "propfind" "view"];
  List<String> methods = new List();

  schema.forEach((endpointKey, endpointValue) {
    if(allowedMethods.contains(endpointKey)) {
      String method = endpointKey.toUpperCase() + " " + path.toLowerCase();
      methods.add(method);
      print(method);
    }
  });
  
  return methods;
}

// A currently minimal-effort approach to schemas. Temporarily a schema-per-path-and-method approach.
class RestedSchema {
  Map<String, dynamic> schema = new Map();
  String path;

  RestedSchema(String path);

  void setFromString(String data) {
    schema = json.decode(data);
  }

  void setFromMap(Map<String, dynamic> _schema) {
    schema = _schema;
  }

  String describe(){
    return schema.toString();
  }

  bool compareWithString(){
    
  }

  bool compareWithMap(){
    
  }

  bool compareWithSchema(){
    
  }  
}