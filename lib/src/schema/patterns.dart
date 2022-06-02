bool isUUID(String _inc) {
    return RegExp(r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$').hasMatch(_inc);
}

bool isEmail(String _inc) {
    return RegExp(r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+").hasMatch(_inc);
}

bool isAlphanumeric(String _inc) {
    return RegExp(r'^[a-zA-Z0-9]+$').hasMatch(_inc);
}

bool isNumeric(String _inc) {
    return RegExp(r'^[0-9]+$').hasMatch(_inc);
}