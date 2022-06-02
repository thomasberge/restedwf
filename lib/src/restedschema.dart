import 'schema/stringparameter.dart';
export 'schema/stringparameter.dart';
import 'schema/integerparameter.dart';
export 'schema/integerparameter.dart';
import 'schema/patterns.dart';

//Map<String, dynamic> pathparams = {};

class RestedSchema {
    
    bool active = false;
    Map<String, dynamic> _fields = {};
    
    RestedSchema();

    static bool isUUID(String _inc) {
        return isUUID(_inc);
    }

    static bool isEmail(String _inc) {
        return isEmail(_inc);
    }

    bool isAlphanumeric(String _inc) {
        return isAlphanumeric(_inc);
    }

    bool isNumeric(String _inc) {
        return isNumeric(_inc);
    }

    void setFields(Map<String, dynamic> _incomingFields) {
        if(active) {
            print("Error setting schema fields, ignoring. Schema already set. Incoming data: " + _incomingFields.toString());
        } else {
            _fields = _incomingFields;
            active = true;
        }
    }

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
