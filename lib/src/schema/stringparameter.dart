import 'patterns.dart';

class StringParameter {
    String _name;
    String _type = "string";
    String _style = "none";
    String _format = "none";
    List<String> enums = [];
    String example = "";
    String pattern;
    int minLength;
    int maxLength;

    List<String> _implemented_formats = ["none", "email", "uuid"];
    List<String> _implemented_styles = ["none"];

    String get name {
        return _name;
    }

    StringParameter(this._name);

    String get type {
        return _type;
    }

    void set style(String stringStyle) {
        if(_implemented_styles.contains(stringStyle)) {
            _style = stringStyle;
        } else {
            print("Error setting StringParameter style. " + stringStyle + " is not supported. Reverting to 'none'.");
            _style = "none";
        }
    }

    String get style {
        return _style;
    }

    void addEnums(List<String> enums) {
        for(String val in enums) {
            addEnum(val);
        }
    }

    void addEnum(String input) {
        enums.add(input.toUpperCase());
    }

    void set format(String input) {
        if(_implemented_formats.contains(input)) {
            _format = input;
            pattern = null;
        } else {
            print("Error setting StringParameter format. " + input + " is not supported. Reverting to 'none'. Perhaps try to set pattern to a fitting regex in the meantime?");
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
        if(pattern == null) {
            if(format == 'email') {
                if(isEmail(input) == false) {
                    return("Validation error for StringParameter " + _name + ": input is not matching format 'email'.");
                }
            }

            if(format == 'uuid') {
                if(isUUID(input) == false) {
                    return("Validation error for StringParameter " + _name + ": input is not matching format 'uuid'.");
                }
            }
        // pattern
        } else {
            if(RegExp(pattern).hasMatch(input) == false) {
                return("Validation error for StringParameter " + _name + ": input is not matching pattern " + pattern + ".");
            }            
        }

        // enums
        if(enums.length > 0) {
            if(enums.contains(input.toUpperCase()) == false) {
                return("Validation error for StringParameter " + _name + ": input is not matching enum criteria. Valid input is " + enums.toString());
            }
        }

        // lengths
        if(minLength != null) {
            if(input.length < minLength) {
                return("Validation error for StringParameter " + _name + ": input has less characters than specified minimum length (" +minLength.toString() + " characters).");
            }
        }

        if(maxLength != null) {
            if(input.length > maxLength) {
                return("Validation error for StringParameter " + _name + ": input has more characters than specified maximum length (" +maxLength.toString() + " characters).");
            }
        }

        return "OK";
    }

}