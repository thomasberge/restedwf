// Part of Rested Web Framework
// www.restedwf.com
// © 2021 Thomas Sebastian Berge

class Parser {

  int position = 0;
  int width = 1;
  String data;
  int start_mark = 0;
  int stop_mark = 0;
  bool eol = false;

  Parser(String value) {
    data = value;
  }

  // Counts forward until it finds the given value. Returns the position of the first
  // character of the value string. If the value is not found it returns -1.
  int countUntil(String value) {
    int old_position = position;
    bool value_not_found = true;

    while(value_not_found) {
      if((position + value.length) > data.length) {
        return -1;
      } else {
        String string_sample = data.substring(position, (position + value.length));
        if(string_sample == value) {
          int found_position = position;
          position = old_position;
          return found_position;
        } else {
          position++;
          checkEndOfLine();
        }
      }
    }
  }

  // Counts how many characters of provided string there are next to each other from
  // cursor position. If position is 0 and the parser data is "aaaarg!" then "a" will
  // return 4, "r" will return 0. If position is 4, "a" will return 0 and "r" will
  // return 1. Do not use more than 1 character in the string or ¤#"% will break.
  int countCharacterSequenze(String character) {
    int old_position = position;
    int count = 0;

    while(true) {
      if((position + 1) > data.length) {
        position = old_position;
        return count;
      } else {
        String string_sample = data.substring(position, (position + 1));
        if(string_sample == character) {
          count++;
          position++;
        } else {
          position = old_position;
          return count;
        }
      }
    }    
  }

  void checkEndOfLine() {
    if((data.length - 1) <= position) {
      eol = true;
    } else {
      eol = false;
    }
  }

  void move({int characters = 1}) {
    position = position + characters;
    checkEndOfLine();
  }

  void moveToEnd() {
    position = data.length + 1;
  }

  void insertAtPosition(String value) {
    String first = data.substring(0, position);
    String last = data.substring(position);
    data = first + value + last;
  }

  void replaceCharacters(int characters, String newcharacters) {
    String first = data.substring(0, position);
    String last = data.substring(position + characters);
    data = first + newcharacters + last;
  }  

  bool moveUntil(String value) {
    bool not_found = true;
    while(not_found) {
      if((position + value.length) > data.length) {
        return false;
      } else {
        String temp = data.substring(position, (position + value.length));
        if(temp == value) {
          return true;
        } else {
          position++;
          checkEndOfLine();
        }
      }
    }    
  }

  /* NOT YET DONE!!!! DOES NOT WORK! */
  bool moveBackwardsFromEndUntil(String value) {
    bool not_found = true;
    int previous_position = position;
    position = data.length - value.length;
    int width = value.length;

    print("Data: >" + data + "<");
    print("Position: " + position.toString());
    print("Width: " + width.toString());

    while(not_found) {
      position = data.length;
      if(position < previous_position) {
        position = previous_position;
        return false;
      }
      position--;
    }
  }

  bool moveBackwardsUntil(String value) {
    bool not_found = true;
    while(not_found) {
      if((position + value.length) > data.length) {
        return false;
      } else {
        String temp = data.substring(position, (position + value.length));
        if(temp == value) {
          return true;
        } else {
          if(position > -1) {
            position--;
          }
          //checkStartOfLine();
        }
      }
    }    
  }  

  String getBeforePosition() {
    return data.substring(0, position);
  }

  String getAfterPosition() {
    //print(data);
    return data.substring(position + 1);
  }

  String getFromPosition() {
    return data.substring(position);
  }  

  String moveToFirstInList(List<String> values) {
    while(true) {
      if((position + 1) > data.length) {
        eol = true;
        return null;
      } else {
        String temp = data.substring(position, (position + 1));
        if(values.contains(temp)) {
          return temp;
        } else {
          position++;
        }
      }
    }    
  }  

  String lookNext({int characters = 1}) {
    checkEndOfLine();
    if(eol) {
      return "";
    } else {
      return data.substring(position, (position + characters));
    }
  }

  String lookBefore({int characters = 1}) {
    return data.substring((position - 1 - characters), characters);
  }

  void deleteCharacters(int characters) {
    String first = data.substring(0, position);
    String last = data.substring(position + characters);
    data = first + last;
  }

  int findNextPosition(String value) {
    String read_data = data.substring(position, (data.length - position));
    return read_data.indexOf(value);
  }

  // "This is a sentence"
  // moveUntil('a');
  // getPreString() returns "This is "
  // getPostString() returns " sentence"
  String getPreString() {
    return data.substring(0, (position));
  }

  String getPostString() {
    //print("data= ->" + data + "<-");
    return data.substring((position +1));
  }

  void replaceInMarkedString(String replace, String replaceWith) {
    String first = data.substring(0, start_mark);
    String middle = data.substring(position, (stop_mark - start_mark));
    String last = data.substring(stop_mark);

    
  }

  void setStartMark({int value = -1, bool start_of_string = false}) {
    if (value != -1) {
      start_mark = value;
    } else if (start_of_string) {
      start_mark = 0;
    } else {
      start_mark = position;
    }
  }

  void setStopMark({int value = -1, bool end_of_string = false}) {
    if (value != -1) {
      stop_mark = value;
    } else if (end_of_string) {
      stop_mark = (data.length);
    } else {
      stop_mark = position;
    }
  }

  String getMarkedString() {
    if ((stop_mark - start_mark) > 0) {
      String test = data.substring(start_mark, stop_mark);
      return test;
    }
  }

  // Deletes the data between
  void deleteMarkedString({bool reset_marks = true}) {
    if (stop_mark - start_mark > 0) {
      String first = data.substring(0, start_mark);
      String last = data.substring(stop_mark);
      data = first + last;
      if (position > start_mark && position < stop_mark) {
        position = start_mark;
      } else if (position > stop_mark) {
        position = position - (stop_mark - start_mark);
      }
      if (reset_marks) {
        start_mark = 0;
        stop_mark = 0;
      }
      checkEndOfLine();
    } else {
      print("Parser error, tried to delete marked length of 0 or less.");
    }
  }
}