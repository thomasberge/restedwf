import 'patterns.dart';

class ArrayParameter {
    String _name;
    String _type = "array";
    bool uniqueItems = false;
    int minItems;
    int maxItems;
    List<String> _items = ["String", "Boolean", "Integer", "Number", "Object", "Array"];

    String get name {
        return _name;
    }

    ArrayParameter(this._name);

    String validate(String input) {
        return "OK";
    }

}