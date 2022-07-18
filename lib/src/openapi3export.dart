import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:yaml/yaml.dart';
import 'restedsettings.dart';
import 'restedschema.dart';
import 'restedresource.dart';

class OAPI3Export {
    List<String> document = [];

    OAPI3Export(String filepath, List<RestedResource> resources) {
        addHeaders();
        addPaths(resources);
        addComponents();
        String doc = "";
        for(String s in document) {
            doc = doc + s + "\r\n";
        }

        File(filepath).writeAsStringSync(doc, encoding: utf8);
    }

    void addHeaders() {
        document.add("openapi: 3.1.0");
        document.add("info:");
        document.add("  title: alpha4");
        document.add("  version: '1.0'");
        document.add("servers:");
        document.add("  - url: 'http://localhost:3000'");
    }

    void addPaths(List<RestedResource> resources) {
        document.add("paths:");
        for(RestedResource resource in resources) {
            document.add("  " + resource.path + ":");
            for(MapEntry e in resource.functions.entries) {
                if(e.value == null) {
                    document.add("    " + e.key + ":");
                }
                //document.add(e.key + ":" + e.value.toString());
            }
        }
    }

    void addComponents() {
        document.add("components:");
    }
}