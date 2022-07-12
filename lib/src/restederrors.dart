library rested.errors;

RestedErrors error = RestedErrors();

class RestedErrors {

    Map<String, dynamic> _errors = {
        "exception_raising_error": {
            "message": "An error occured why trying to gather information about the error."
        },
        "unknown_error_code": {
            "message": "The error code raised is not defined as an error."
        },
        "missing_common_directory": {
            "message": "common is enabled but there is no common directory to parse files from. The directory needs to be at the same directory level as server.dart."
        },
        "file_not_found": {
            "message": "The requested file was not found on the server."
        }
    };

    RestedErrors();

    void raise(String code, { String details = ""}) {
        if(_errors.containsKey(code)) {
            try {
                print(  "\u001b[31mERROR " + 
                        "[" + code + "]\u001b[0m " + 
                        _errors[code]['message'] +
                        " (" + details + ")"
                );
            } catch(e) {
                raise("exception_raising_error", details: "code: " + code.toString() + " details: " + details.toString() + " exception: " + e.toString());
            }
        } else {
            raise("unknown_error_code");
        }
    }
}
