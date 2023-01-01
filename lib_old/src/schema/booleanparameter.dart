import 'patterns.dart';

class BooleanParameter {
    String _name;
    String _type = "boolean";
    bool _default = null;

    String get name {
        return _name;
    }

    BooleanParameter(this._name);

    void set defaultValue(bool _defaultValue) {
        _default = _defaultValue;
    }

    bool get defaultValue {
        return _default;
    }

    String validate(String input) {
        input = input.toUpperCase();
        if(input == 'TRUE' || input == 'FALSE') {
            return "OK";
        } else {
            return "Validation error for BooleanParameter " + _name + ": value '" + input + "' could not be parsed to boolean.";
        }
    }

}