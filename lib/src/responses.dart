class Responses {
  Map responses = new Map<int, String>();
  //{"404", "Not Found"};

  Responses() {
    responses[400] = "Bad Request";
    responses[401] = "Unauthorized";
    responses[402] = "Payment Required";
    responses[403] = "Forbidden";
    responses[404] = "Not Found";
    responses[405] = "Method Not Allowed";
    responses[406] = "Not Acceptable";
    responses[407] = "Proxy Authentication Required";
    responses[408] = "Request Timeout";
    responses[409] = "Conflict";
    responses[410] = "Gone";
    responses[411] = "Length Required";
    responses[412] = "Precondition Failed";
    responses[413] = "Payload Too Large";
    responses[414] = "URI Too Long";
    responses[415] = "Unsupported Media Type";
    responses[416] = "Range Not Satisfiable";
    responses[417] = "Expectation Failed";
    responses[418] = "I'm a sleepy teapot";
    responses[421] = "Misdirected Request";
    responses[422] = "Unprocessable Entity";
    responses[423] = "Locked";
    responses[424] = "Failed Dependency";
    responses[425] = "Too Early";
    responses[426] = "Upgrade Required";
    responses[428] = "Precondition Required";
    responses[429] = "Too Many Requests";
    responses[431] = "Request Header Fields Too Large";
    responses[451] = "Unavailable For Legal Reasons";
    responses[452] = "Access Token Expired";
    responses[453] = "Failed Custom Token Verification";
  }

  String text(int code) {
    if (responses.containsKey(code)) {
      return (code.toString() + " " + responses[code]);
    } else {
      return null;
    }
  }
}
