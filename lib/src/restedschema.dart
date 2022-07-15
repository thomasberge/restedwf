import 'schema/stringparameter.dart';
export 'schema/stringparameter.dart';
import 'schema/integerparameter.dart';
export 'schema/integerparameter.dart';
import 'schema/booleanparameter.dart';
export 'schema/booleanparameter.dart';
import 'schema/patterns.dart' as patterns;

void testSchema() {
    RestedSchema userlogin = RestedSchema();
    StringParameter username = StringParameter("username");
    userlogin.addField(username);
    userlogin.addField(StringParameter("password"));
    print(userlogin.toString());
}

class RestedSchema {
    
    bool active = false;
    Map<String, dynamic> _fields = {};
    List<String> _required_fields = [];
    
    bool isSupported(dynamic parameter) {
        bool result = false;
        if(parameter is StringParameter) {
            result = true;
        } else if (parameter is IntegerParameter) {
            result = true;
        }
        return result;
    }

    void addField(dynamic parameter, {bool requiredField = false}) {
        if(isSupported(parameter)) {
            String name = parameter.name;
            _fields[name] = parameter;
            if(requiredField) {
                _required_fields.add(parameter.name);
            }
        } else {
            print("Error, tried to add an unsupported field to schema: " + parameter.toString());
        }
    }

    String toString() {
        return _fields.toString();
    }

    bool validate(Map<String, dynamic> data) {
        bool result = true;
        String errorMessage = "";

        for(String field in _required_fields) {
            if(data.containsKey(field) == false) {
                errorMessage = errorMessage + "Required field '" + field + "' is missing.\r\n";
                result = false;
            }
        }

        for(MapEntry field in data.entries) {
            if(_fields.containsKey(field.key)) {
                String fieldValidation = _fields[field.key].validate(field.value);
                if(fieldValidation != 'OK') {
                    errorMessage = errorMessage + fieldValidation + "\r\n";
                    result = false;
                } else {
                    print("Validated OK.(" + field.key.toString() + ":" + field.value.toString() + ")");
                }
            }
        }

        if(result == false) {
            print("Error validating schema:\r\n" + errorMessage);
        }
        return result;
    }

    RestedSchema();

    static bool isUUID(String _inc) {
        return patterns.isUUID(_inc);
    }

    static bool isEmail(String _inc) {
        return patterns.isEmail(_inc);
    }

    static bool isAlphanumeric(String _inc) {
        return patterns.isAlphanumeric(_inc);
    }

    static bool isNumeric(String _inc) {
        return patterns.isNumeric(_inc);
    }

    /*
    void setFields(Map<String, dynamic> _incomingFields) {
        if(active) {
            print("Error setting schema fields, ignoring. Schema already set. Incoming data: " + _incomingFields.toString());
        } else {
            _fields = _incomingFields;
            active = true;
        }
    }*/

    //Map<String, String> _fields = {};
    //Map<String, String> _requiredFields = {};

    /*void setField(String key, String type, {bool requiredField = false}) {
        if(_requiredFields.containsKey(key) == false && _fields.containsKey(key) == false) {
            if(requiredField) {
                _requiredFields[key] = type;
            } else {
                _fields[key] = type;
            }
        } else {
            print("Error: Tried adding duplicate key " + key + " to schema.");
        }
    }*/

    /*bool validate(Map<String, dynamic> body) {
        bool valid = true;

        for(MapEntry field in _fields.entries) {
            if(body.containsKey(field.key)) {
                // only invalidate if the field is present but the type is wrong
            }
        }

        for(MapEntry requiredField in _requiredFields.entries) {
            if(body.containsKey(requiredField.key) == false) {
                valid = false;
            } else {
                // validate field type here
            }
        }

        return valid;
    }*/
}
