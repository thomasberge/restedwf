class RestedSchema {
    
    Map<String, String> _fields = {};
    Map<String, String> _requiredFields = {};

    RestedSchema();

    void setField(String key, String type, {bool requiredField = false}) {
        if(_requiredFields.containsKey(key) == false && _fields.containsKey(key) == false) {
            if(requiredField) {
                _requiredFields[key] = type;
            } else {
                _fields[key] = type;
            }
        } else {
            print("Error: Tried adding duplicate key " + key + " to schema.");
        }
    }

    bool validate(Map<String, dynamic> body) {
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
    }
}