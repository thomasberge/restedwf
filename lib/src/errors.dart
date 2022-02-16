class Errors {

    static Map<String, dynamic> getJson(int code) {

        Map<String, dynamic> message = {};
        message["code"] = code;

        switch(code) {
            case 400: {
                message["description"] = "Bad Request";
            }
            break;

            default: {
                
            }
            break;
        }
    }
}