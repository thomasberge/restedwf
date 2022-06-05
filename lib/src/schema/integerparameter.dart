import 'patterns.dart';

class IntegerParameter {
    String _name;
    String _type = "integer";
    String _style = "none";
    String _format = "none";
    int minimum;
    int maximum;
    bool exclusiveMin = false;
    bool exclusiveMax = false;

    List<String> _implemented_formats = ["none"];
    List<String> _implemented_styles = ["none"];

    String get name {
        return _name;
    }

    IntegerParameter(this._name);

    void set style(String stringStyle) {
        if(_implemented_styles.contains(stringStyle)) {
            _style = stringStyle;
        } else {
            print("Error setting StringParameter style. " + stringStyle + " is not supported. Reverting to 'none'.");
            _style = "none";
        }
    }

    String get type {
        return _type;
    }

    String get style {
        return _style;
    }

    void set format(String input) {
        if(_implemented_formats.contains(input)) {
            _format = input;
        } else {
            print("Error setting StringParameter format. " + input + " is not supported. Reverting to 'none'.");
            _format = 'none';
        }
    }

    String get format {
        return _format;
    }

    String validate(String input) {
        // style
        // --

        // format
        // --

        // Conversion
        int val = int.tryParse(input) ?? null;
        if(val == null) {
            return("Validation error for IntegerParameter " + _name + ": value '" + input + "' could not be parsed to integer.");
        }

        int min = minimum;
        int max = maximum;

        if(exclusiveMin) {
            min = minimum + 1;
        }

        if(exclusiveMax) {
            max = maximum - 1;
        }

        // lengths
        if(minimum != null) {
            if(int.tryParse(input) < min) {
                return("Validation error for IntegerParameter " + _name + ": input is less than specified minimum (" + minimum.toString() + ").");
            }
        }

        if(maximum != null) {
            if(int.tryParse(input) > max) {
                return("Validation error for IntegerParameter " + _name + ": input is more than specified maximum (" + maximum.toString() + ").");
            }
        }

        return "OK";
    }

}