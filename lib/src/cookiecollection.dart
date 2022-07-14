import 'dart:io';

class CookieCollection {
  List<Cookie> cookies = null;

  CookieCollection(this.cookies);

  List<Cookie> get(String name) {
    List<Cookie> returnlist = new List();
    for (Cookie cookie in cookies) {
      if (cookie.name == name) {
        returnlist.add(cookie);
      }
    }
    return returnlist;
  }

  Cookie getFirst(String name) {
    for (Cookie cookie in cookies) {
      if (cookie.name == name) {
        return cookie;
      }
    }
    return null;
  }

  bool containsKey(String name) {
    bool containskey = false;
    for (Cookie cookie in cookies) {
      if (cookie.name == name) {
        containskey = true;
      }
    }
    return containskey;
  }
}