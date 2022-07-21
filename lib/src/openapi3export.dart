import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:mirrors';

import 'package:yaml/yaml.dart';
import 'restedsettings.dart';
import 'restedschema.dart';
import 'restedresource.dart';
import 'restedglobals.dart';

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

            // PATH
            if(resource.exportMethods.length > 0) {
                document.add("  " + resource.path + ":");

                // METHOD
                for(String method in resource.exportMethods) {
                    document.add("    " + method.toLowerCase() + ":");

                    // SUMMARY
                    if(resource.summary.containsKey(method.toLowerCase()) == false) {
                        resource.summary[method.toLowerCase()] = method[0].toUpperCase() + method.toLowerCase().substring(1) + " " + resource.class_name;
                    }
                    document.add("      summary: " + resource.summary[method.toLowerCase()]);

                    // OPERATIONID
                    if(resource.operationId.containsKey(method.toLowerCase())) {
                        document.add("      operationId: " + resource.operationId[method.toLowerCase()]);
                    }
                }
            }

            //int defaultHash = resource.getHashForDefaultMethod();
            //document.add("  " + resource.path + ":");

           /* for(MapEntry e in resource.functions.entries) {

                // Imported endpoints have null value
                if(e.value == null) {
                    document.add("    " + e.key + ":");
                }

                // Non-overridden functions have default hashCode
                else if(e.value.hashCode != resource.functionsHash[e.key]) {
                    document.add("    " + e.key + ":");
                }*/

                //var reflectedFunction = reflect(e.value);
                //print(reflectedFunction.type.toString());
                //print(reflectedFunction.reflectee.toString());
                //print(reflectedFunction.reflectee.getField(#testing));
                //document.add(e.key + ":" + e.value.toString() + "  >>> " + e.value.hashCode.toString() + ">>>" + resource.functionsHash[e.key].toString());
                
                //print(e.key + ":" + e.value.toString());
            //}
        }
    }

    void addComponents() {
        document.add("components:");
        print("Global Schemas = " + global_schemas.toString());
    }
}