import 'package:flutter/material.dart';
import 'package:chicaparts_partner/widgets/login/login.dart';
import 'package:shared_preferences/shared_preferences.dart';

PreferredSizeWidget? appBar(title, context, position) {
  return AppBar(
    backgroundColor: const Color(0xFF244B6B),
    leading: Builder(
      builder: (BuildContext context) {
        return IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFFFFFFFF)),
          onPressed: () {
            Scaffold.of(context).openDrawer();
          },
          tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
        );
      },
    ),
    title: Row(
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.bold,
              color: Color(0xFFFFFFFF)),
        ),
      ],
    ),
    // titleSpacing: 0,
    actions: <Widget>[
      PopupMenuButton(
        color: const Color(0xFFFFFFFF),
        itemBuilder: (BuildContext bc) => [
          const PopupMenuItem(value: "/logout", child: Text("Logout")),
        ],
        onSelected: (route) async {
          // Note You must create respective pages for navigation
          if (route == "/logout") {
            SharedPreferences prefs = await SharedPreferences.getInstance();
            prefs.remove('user');
            prefs.remove('email');
            prefs.remove('token');
            Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const LoginPage()));
          }
        },
      ),
    ],
  );
}
