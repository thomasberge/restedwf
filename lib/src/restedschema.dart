class RestedSchema {
    
    bool active = false;
    Map<String, dynamic> _fields = {};
    
    RestedSchema();

    static bool isUUID(String _inc) {
        return RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$').hasMatch(_inc);
    }

    static bool isEmail(String _inc) {
        return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(_inc);
    }

    static bool isAlphanumeric(String _inc) {
        return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(_inc);
    }

    static bool isNumeric(String _inc) {
        return RegExp(r'^[0-9]+$').hasMatch(_inc);
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