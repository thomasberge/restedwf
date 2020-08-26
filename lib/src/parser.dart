import 'consolemessages.dart';

class Parser {

  ConsoleMessages console = new ConsoleMessages(debug_level: 4);

  int position = 0;
  int width = 1;
  String data;
  int start_mark = 0;
  int stop_mark = 0;
  bool eol = false;

  Parser(String value) {
    data = value;
  }

  void checkEndOfLine() {
    if(position == (data.length - 1)) {
      eol = true;
    } else {
      eol = false;
    }
  }

  void move({int characters = 1}) {
    position = position + characters;
    checkEndOfLine();
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

  String getBeforePosition() {
    return data.substring(0, position);
  }

  String getAfterPosition() {
    print(data);
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
    return data.substring(position, (position + characters));
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

  String getPreString() {
    data.substring(0, (position - 1));
  }

  String getPostString() {
    data.substring((position + width), (data.length - position - width));
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
      console.error("Parser error, tried to delete marked length of 0 or less.");
    }
  }
}