import 'dart:convert';

import 'package:chicaparts_partner/models/user/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrentUser {
  static final CurrentUser _instance = CurrentUser._internal();
  // passes the instantiation to the user object
  factory CurrentUser() => _instance;

  //initialize variables in here
  CurrentUser._internal() {
    user = null;
  }

  var user;
  Future<User> getCurrentUser() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    var currentEmail = prefs.getString('email') ?? "";
    if (currentEmail != "") {
      String currentUser = prefs.getString('user') ?? "";
      var jsonData = jsonDecode(currentUser);
      // print(jsonData);
      user = User(jsonData["id"], jsonData["name"], jsonData["email"],
          jsonData["third_party"]);
    }
    return user;
  }
}
