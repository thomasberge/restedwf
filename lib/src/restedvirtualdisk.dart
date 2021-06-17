// Part of Rested Web Framework
// www.restedwf.com
// © 2020 Thomas Sebastian Berge

import 'dart:io';

class RestedVirtualDisk {

  String root;
  Map<String, String> files = new Map();

  RestedVirtualDisk();

  String getFile(String resource_path) {
    print("File request: " + resource_path.toString());
    if(files.containsKey(resource_path)) {
      print("File found");
      return files[resource_path];
    } else {
      print("File not found");
      return null;
    }
  }

  // Adds all files in path (recursively by default)
  void addFiles(String path, {recursive: true}) {
    Directory dir = new Directory(path);
    try {
      List<FileSystemEntity> files = dir.listSync(recursive: recursive, followLinks: false);
      for(FileSystemEntity file in files) {
        FileSystemEntity file_with_absolute_path = file.absolute;

        // remove /./  and ./ which indicates darts current position and add file
        if(FileSystemEntity.isFileSync(file_with_absolute_path.path))
        {
          String resource_path = file.path.replaceAll('/./', '/');
          resource_path = resource_path.substring(path.length);
          String absolute_path = file_with_absolute_path.path.replaceAll('/./', '/');

          if(resource_path.substring(0,1) == '.') {
            resource_path = resource_path.substring(1);
          }

          addFile(resource_path, absolute_path);
        }
      }
    } catch(e) {
      print("RestedVirtualDisk.addFilesFromPath error:\n" + e.toString());
    }
    print(path + " added to VirtualDisk (recursive=" + recursive.toString() + ")");
  }

  void addFile(String resource_path, String absolute_path) {
    print("...adding resource " + resource_path.toString());
    print("using file " + absolute_path.toString());
    print("\n");

    if(files.containsKey(resource_path) && files.containsValue(absolute_path)) {
      print(":: *** WARNING ***   File already exists with same resource path.");
      print(":: Resource: " + resource_path);
      print(":: Path: " + absolute_path);      
    }

    else if(files.containsKey(resource_path)) {
      print(":: *** WARNING ***");
      print(":: Overwriting resource with new path.");
      print(":: Old path: " + files[resource_path]);
    }

    else if(files.containsValue(absolute_path)) {
      print(":: *** WARNING ***");
      print(":: Adding duplicate file for different resource.");
      print(":: Duplicate path: " + files[absolute_path]);      
    }

    files[resource_path] = absolute_path;
  }

}