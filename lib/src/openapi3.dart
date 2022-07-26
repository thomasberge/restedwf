import 'dart:io';
import 'dart:async';
import 'dart:convert';

import 'package:yaml/yaml.dart';
import 'restedsettings.dart';
import 'restedschema.dart';
import 'restedresource.dart';
import 'restedglobals.dart';

class OAPI3 {

    Map yaml;
    Map<String, dynamic> global_path_parameters = {};
    Map<String, dynamic> global_query_parameters = {};
    List<RestedResource> resources = List<RestedResource>();

    OAPI3(String filepath) {
        String text = "";

        try {
            text = readfile(filepath);
        } on Exception catch (e) {
            print(e.toString());
        }

        print(":: OpenAPI 3.1 import of " + filepath);

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

    /*
     *  Start for the import

        1. File is loaded
        2. Globals are imported to their respective global dicts in this file, in case they are
            referenced on a path.
        3. importPath is run on each path in the file, which builds a single resource for each
            iteration and adds to the resources map.
            1.  if path has parameters they are imported to the resource

        4. The resources map is returned.


     */
    void import(String data) {

        try {
            yaml = loadYaml(data) as Map;

            if(yaml.containsKey('components')) {
                if(yaml['components'].containsKey('parameters')) {
                    importGlobalParameters(yaml['components']['parameters']);
                }
            }

            for(MapEntry e in global_path_parameters.entries) {
                print("Imported global path parameter <" + e.value.type + "> " + e.value.name);
            }
            for(MapEntry e in global_query_parameters.entries) {
                print("Imported global query parameter <" + e.value.type + "> " + e.value.name);
            }

            // Paths
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
        print("Imported path " + path);

        // Created the Resource
        RestedResource resource = RestedResource();

        // Populate the Resource fields
        resource.setPath(path);

        if(yaml['paths'][path].containsKey('parameters')) {
            resource.addUriParameters(importPathParameters(yaml['paths'][path]['parameters']));
        }

        for(MapEntry e in yaml['paths'][path].entries) {

            if(rsettings.getVariable('allowed_methods').contains(e.key.toLowerCase())) {
                resource.exportMethods.add(e.key.toLowerCase());

                if(yaml['paths'][path][e.key].containsKey('summary')) {
                    resource.summary[e.key.toLowerCase()] = yaml['paths'][path][e.key]['summary'];
                }

                if(yaml['paths'][path][e.key].containsKey('parameters')) {
                    Map<String,dynamic> queryparams = importQueryParameters(yaml['paths'][path][e.key]['parameters']);
                    resource.addQueryParameters(e.key, queryparams);
                }

                if(yaml['paths'][path][e.key].containsKey('operationId')) {
                    resource.operationId[e.key] = yaml['paths'][path][e.key]['operationId'];
                }

                if(yaml['paths'][path][e.key].containsKey('requestBody')) {
                    if(yaml['paths'][path][e.key]['requestBody'].containsKey('content')) {
                        if(yaml['paths'][path][e.key]['requestBody']['content'].containsKey('application/json')) {

                        }
                    }
                }                
            }
        }

        resources.add(resource);
    }

    Map<String, dynamic> importPathParameters(List<dynamic> params) {
        Map<String, dynamic> path_parameters = {};

        for(Map e in params) {
            if(e.containsKey(r'$ref')) {
                List<String> elements = e[r'$ref'].split('/');
                String param_key = elements[elements.length-1];
                if(global_path_parameters.containsKey(param_key)) {
                    path_parameters[param_key] = global_path_parameters[param_key];
                }
            } else {
                if(e.containsKey('schema') && e.containsKey('name')) {
                    if(e['schema'].containsKey('type')) {
                        if(e['schema']['type'] == 'string') {
                            StringParameter new_param = buildStringParameter(e);
                            path_parameters[e['name']] = new_param;
                        } else if(e['schema']['type'] == 'string') {
                            IntegerParameter new_param = buildIntegerParameter(e);
                            path_parameters[e['name']] = new_param;
                        }
                    }
                }
            }
        }

        return path_parameters;
    }

    Map<String, dynamic> importQueryParameters(List<dynamic> params) {
        //print("importQueryParameters()");
        Map<String, dynamic> query_parameters = {};
        if(params == null) {
            return query_parameters;
        }

        for(Map e in params) {
            if(e.containsKey(r'$ref')) {
                List<String> elements = e[r'$ref'].split('/');
                String param_key = elements[elements.length-1];
                if(global_query_parameters.containsKey(param_key)) {
                    query_parameters[param_key] = global_query_parameters[param_key];
                }
            } else {
                if(e.containsKey('schema') && e.containsKey('name')) {
                    if(e['schema'].containsKey('type')) {
                        if(e['schema']['type'] == 'string') {
                            StringParameter new_param = buildStringParameter(e);
                            query_parameters[e['name']] = new_param;
                        } else if(e['schema']['type'] == 'string') {
                            IntegerParameter new_param = buildIntegerParameter(e);
                            query_parameters[e['name']] = new_param;
                        }
                    }
                }
            }
        }
        //print("query_parameters=" + query_parameters.toString());

        return query_parameters;
    }

    void importGlobalParameters(Map params) {
        for(MapEntry e in params.entries) {
            if(e.value.containsKey('schema')) {
                if(e.value['schema'].containsKey('type')) {

                    // String parameters
                    if(e.value['schema']['type'].toLowerCase() == 'string') {

                        // String Path Parameters
                        if(e.value.containsKey('in')) {
                            if(e.value['in'].toLowerCase() == 'path') {
                                StringParameter param = buildStringParameter(e.value);
                                global_path_parameters[param.name] = param;
                            }
                            else if(e.value['in'].toLowerCase() == 'query') {
                                StringParameter param = buildStringParameter(e.value);
                                global_query_parameters[param.name] = param;
                            }
                        }
                    
                    // Integer parameters
                    } else if(e.value['schema']['type'].toLowerCase() == 'integer') {

                        // Integer Path Parameters
                        if(e.value.containsKey('in')) {
                            if(e.value['in'].toLowerCase() == 'path') {
                                IntegerParameter param = buildIntegerParameter(e.value);
                                global_path_parameters[param.name] = param;
                            }
                            else if(e.value['in'].toLowerCase() == 'query') {
                                IntegerParameter param = buildIntegerParameter(e.value);
                                global_query_parameters[param.name] = param;
                            }
                        }
                    }
                }
            }
        }
    }

    StringParameter buildStringParameter(Map params) {

        StringParameter new_param = StringParameter(params['name']);

        if(params['schema'].containsKey('format')) {
            new_param.format = params['schema']['format'];
        }

        if(params['schema'].containsKey('enum')) {
            for(String val in params['schema']['enum']) {
                new_param.addEnum(val);
            }
        }

        if(params['schema'].containsKey('minLength')) {
            new_param.minLength = params['schema']['minLength'];
        }

        if(params['schema'].containsKey('maxLength')) {
            new_param.maxLength = params['schema']['maxLength'];
        }

        if(params['schema'].containsKey('pattern')) {
            new_param.pattern = r"" + params['schema']['pattern'];
        }

        return new_param;
    }

    IntegerParameter buildIntegerParameter(Map params) {

        IntegerParameter new_param = IntegerParameter(params['name']);

        if(params['schema'].containsKey('minimum')) {
            new_param.minimum = params['schema']['minimum'];
        }

        if(params['schema'].containsKey('maximum')) {
            new_param.maximum = params['schema']['maximum'];
        }

        if(params['schema'].containsKey('exclusiveMinimum')) {
            new_param.exclusiveMin = params['schema']['exclusiveMinimum'];
        }

        if(params['schema'].containsKey('exclusiveMaximum')) {
            new_param.exclusiveMax = params['schema']['exclusiveMaximum'];
        }

        return new_param;
    }
}