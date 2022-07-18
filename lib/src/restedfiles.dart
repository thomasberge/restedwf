// Part of Rested Web Framework
// www.restedwf.com
// © 2022 Thomas Sebastian Berge

import 'dart:io';
import 'restederrors.dart';

class FileCollection {

  String resource_path;
  String root;
  Map<String, String> files = {};

  FileCollection({String path = ""}) {
    if(path != "") {
      resource_path = path;
    }
  }

  String toString() {
    return files.toString();
  }

  String getFile(String filepath) {
    if(files.containsKey(filepath)) {
      return files[filepath];
    } else {
      return null;
    }
  }

  bool containsKey(String key) {
    return files.containsKey(key);
  }

  Map<String, String> getFiles() {
    return files;
  }

  // Adds all files in path (recursively by default)
  void addFiles(String path, {recursive: true}) async {
    Directory dir = new Directory(path);
    try {
      List<FileSystemEntity> files = dir.listSync(recursive: recursive, followLinks: false);
      for(FileSystemEntity file in files) {
        FileSystemEntity file_with_absolute_path = file.absolute;

        String resource_path = file.path.replaceAll('/./', '/');
        resource_path = resource_path.substring(path.length);
        String absolute_path = file_with_absolute_path.path.replaceAll('/./', '/');

        if(resource_path.substring(0,1) == '.') {
          resource_path = resource_path.substring(1);
        }

        addFile(resource_path, absolute_path);
      }
    } catch(e) {
      print("FileCollection.addFiles error:\n" + e.toString());
    }
    //print(path + " added to FileCollection (recursive=" + recursive.toString() + ")");
  }

  void addFile(String resource_path, String absolute_path) {
   // print("...adding resource " + resource_path.toString());
   // print("using file " + absolute_path.toString());
   // print("\n");

    if(files.containsKey(resource_path) && files.containsValue(absolute_path)) {
     // print(":: *** WARNING ***   File already exists with same resource path.");
     // print(":: Resource: " + resource_path);
     // print(":: Path: " + absolute_path);      
    }

    else if(files.containsKey(resource_path)) {
     // print(":: *** WARNING ***");
     // print(":: Overwriting resource with new path.");
    //  print(":: Old path: " + files[resource_path]);
    }

    else if(files.containsValue(absolute_path)) {
      //print(":: *** WARNING ***");
      //print(":: Adding duplicate file for different resource.");
      //print(":: Duplicate path: " + files[absolute_path]);      
    }

    files[resource_path] = absolute_path;
  }

}