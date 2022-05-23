import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:yaml/yaml.dart';
import 'restedrequesthandler.dart' show RestedResource;
import 'restedsettings.dart';

class OAPI3 {

    Map yaml;
    List<RestedResource> resources = List<RestedResource>();

    OAPI3(String filepath) {
        String text = "";

        try {
            text = readfile(filepath);
        } on Exception catch (e) {
            print(e.toString());
        }

        import(text);
    }

    // Reads the supplied path
    String readfile(String filepath) {
        if (File(filepath).existsSync()) {
            String text = File(filepath).readAsStringSync(encoding: utf8);
            return text;
        } else {
            print("Specified YAML file in path " + filepath + " does not exist.");
        }
    }

    void import(String data) {

        try {
            yaml = loadYaml(data) as Map;

            if(yaml.containsKey('paths')) {
                for(MapEntry e in yaml['paths'].entries) {
                    importPath(e.key, e.value);
                }
            }

        } on Exception catch (e) {
            print("Error parsing YAML data, please check formatting.");
        }
    }

    List<RestedResource> getResources() {

        return resources;
    }

    void importPath(String path, Map value) {
        print("- Importing " + path);

        RestedResource resource = RestedResource();
        resource.path = path;

        for(MapEntry e in yaml['paths'][path].entries) {
            if(rsettings.allowedMethods.contains(e.key.toLowerCase())) {
                resource.operationId[e.key] = yaml['paths'][path][e.key]['operationId'];
            }
        }

        resources.add(resource);
    }
}