library rested.errors;

import 'restedrequest.dart';

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
        },
        "resource_not_found": {
            "message": "The requested resource was not found on the server."
        },
        "duplicate_resource": {
            "message": "Tried to add a resource to a path that is already in use."
        },
        "exception_new_session": {
            "message": "Exception creating new session."
        },
        "exception_update_session": {
            "message": "Exception updating session."
        },
        "exception_delete_session": {
            "message": "Exception deleting session."
        },
        "exception_session_variables": {
            "message": "Exception accessing session variables."
        },
        "exception_retrieve_session": {
            "message": "Exception retrieveing session."
        },
        "global_schema_already_exists": {
            "message": "The Global Schema already exists."
        },
        "global_schema_not_found": {
            "message": "The Global Schema was not found."
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

class Errors {

    static Map<String, dynamic> getJson(int code) {

        print("-- HTTP STATUS " + code.toString() + " --");
        Map<String, dynamic> message = {};
        message["code"] = code;
        message["description"] = errorjson[code];
        return message;
    }

    static Map<int, String> errorjson = {
        400: "Bad Request",
        401: "Unauthorized",
        402: "Payment Required",
        403: "Forbidden",
        404: "Not Found",
        405: "Method Not Allowed",
        406: "Not Acceptable",
        407: "Proxy Authentication Required",
        408: "Request Timeout",
        409: "Conflict",
        410: "Gone",
        411: "Length Required",
        412: "Precondition Failed",
        413: "Payload Too Large",
        414: "URI Too Long",
        415: "Unsupported Media Type",
        416: "Range Not Satisfiable",
        417: "Expectation Failed",
        418: "I'm a teapot",
        421: "Misdirected Request",
        422: "Unprocessable Entity",
        423: "Locked",
        424: "Failed Dependency",
        425: "Too Early",
        426: "Upgrade Required",
        428: "Precondition Required",
        429: "Too Many Requests",
        431: "Request Header Fields Too Large",
        451: "Unavailable For Legal Reasons",
        500: "Internal Server Error",
        501: "Not Implemented",
        502: "Bad Gateway",
        503: "Service Unavailable",
        504: "Gateway Timeout",
        505: "HTTP Version Not Supported",
        506: "Variant Also Negotiates",
        507: "Insufficient Storage",
        508: "Loop Detected",
        510: "Not Extended",
        511: "Network Authentication Required"
    };

    static Future<RestedRequest> raise(RestedRequest request, int statuscode) async {
        request.status = statuscode;
        request.request.response.statusCode = statuscode;
        await request.request.response.write(errorjson[statuscode].toString());
        request.request.response.close();
        return request;
    }
}