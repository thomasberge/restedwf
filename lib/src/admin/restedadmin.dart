import 'dart:io';
import '../../rested.dart';
import 'package:rested_script/rested_script.dart';

class AdminInterface extends RestedRequestHandler {
    AdminInterface() {
        this.addResource(Dashboard(), "/");
        this.addResource(Login(), "/login");
    }
}

class Dashboard extends RestedResource {
    void get(RestedRequest request) {
        request.response(data: "Admin Page Goes Here");
    }
}

class Login extends RestedResource {
  void get(RestedRequest request) async {
    //String login_page = await rscript.createDocument("login.html");
    //request.response(type: "html", data: login_page);

    String loginpage = '<html><form action="/login" method="POST"><label for="username">Username:</label><br><input type="text" id="username" name="username"><br><label for="password">Password:</label><br><input type="password" id="password" name="password"><br><br><input type="submit" value="Submit"></form></html>';
    request.response(type: "html", data: loginpage);
  }

  void post(RestedRequest request) async {
    //String login_username = request.form['username'];
    //String login_password = request.form['password'];

    Map<String, String> envVars = Platform.environment;

    if(envVars.containsKey('ADMIN_USERNAME')) {
        if(request.form['username'] == envVars['ADMIN_USERNAME']) {
            if(envVars.containsKey('ADMIN_PASSWORD')) {
                if(request.form['password'] == envVars['ADMIN_PASSWORD']) {
                    Map token = jwt_handler.generate_token();
                    request.session['access_token'] = token['access_token'];
                    print("Successfully logged in");
                    request.redirect('/login');
                } else {
                    request.response(status: 401);
                }
            } else {
                request.response(status: 401);
            }
        } else {
            request.response(status: 401);
        }
    } else {
        request.response(status: 401);
    }
    /*
    Map token = jwt_handler.generate_token(additional_claims: claim_username);
    if(result['data'].contains("access_token")) {
      Map resultmap = json.decode(result['data']);
      request.session['access_token'] = resultmap['access_token'];
      request.session['username'] = login_username;
      request.redirect('/u/' + login_username);      
    } else {
      print("error 401");  
      request.response(data: "401");
      // handle login error
    }*/
  } 
}