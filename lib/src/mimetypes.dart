// Part of Rested Web Framework
// www.restedwf.com
// © 2020 Thomas Sebastian Berge

import 'dart:io';

class Mimetypes {
  Map<String, ContentType> contentTypes = new Map();
  Map<String, bool> binary = new Map();

  Mimetypes() {
    contentTypes['.html'] = new ContentType("text", "html", charset: "utf-8");
    contentTypes['.css'] = new ContentType("text", "css", charset: "utf-8");
    contentTypes['.css.br'] = new ContentType("text", "css", charset: "utf-8");
    contentTypes['.txt'] = new ContentType("text", "text", charset: "utf-8");
    contentTypes['.text'] = new ContentType("text", "text", charset: "utf-8");
    contentTypes['.json'] =
        new ContentType("application", "json", charset: "utf-8");
    contentTypes['.ico'] = new ContentType("image", "vnd.microsoft.icon");
    contentTypes['.mp4'] = new ContentType("video", "mp4");
    contentTypes['.mkv'] = new ContentType("video", "mkv");
    contentTypes['.mov'] = new ContentType("video", "mov");
    contentTypes['.m4v'] = new ContentType("video", "m4v");
    contentTypes['.jpg'] = new ContentType("image", "jpeg");
    contentTypes['.jpeg'] = new ContentType("image", "jpeg");
    contentTypes['.png'] = new ContentType("image", "png");
    contentTypes['.gif'] = new ContentType("image", "gif");
    contentTypes['.js'] = new ContentType("application", "javascript");
    contentTypes['.js.br'] = new ContentType("application", "javascript");
    binary['.html'] = false;
    binary['.css'] = false;
    binary['.txt'] = false;
    binary['.text'] = false;
    binary['.json'] = false;
    binary['.ico'] = true;
    binary['.mp4'] = true;
    binary['.mkv'] = true;
    binary['.mov'] = true;
    binary['.m4v'] = true;
    binary['.jpg'] = true;
    binary['.jpeg'] = true;
    binary['.png'] = true;
    binary['.gif'] = true;
  }

  bool isBinary(String type) {
    if (binary.containsKey(type)) {
      return binary[type];
    } else {
      return true;
    }
  }

  ContentType getContentType(String type) {
    return contentTypes[type];
  }
}
