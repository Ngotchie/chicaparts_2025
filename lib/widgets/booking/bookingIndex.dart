import 'package:flutter/material.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/widgets/booking/bookingAccommodation.dart';
import 'package:chicaparts_partner/widgets/booking/myBookings.dart';
import 'package:chicaparts_partner/widgets/login/login.dart';
import 'package:chicaparts_partner/widgets/menu/drawer.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingIndexWidget extends StatefulWidget {
  const BookingIndexWidget({super.key, required this.user});
  final User user;
  @override
  _BookingIndexWidgetState createState() => _BookingIndexWidgetState();
}

class _BookingIndexWidgetState extends State<BookingIndexWidget> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        drawer: drawer(widget.user, context),
        appBar: AppBar(
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
          // GestureDetector(
          //   onTap: () {},
          //   child: Icon(Icons.menu_rounded),
          // ),
          title: const Row(
            children: [
              Text(
                "BOOKINGS",
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFFFFFFFF)),
              ),
            ],
          ),
          actions: <Widget>[
            PopupMenuButton(
              color: const Color(0xFFFFFFFF),
              itemBuilder: (BuildContext bc) => [
                const PopupMenuItem(value: "/logout", child: Text("Logout")),
              ],
              onSelected: (route) async {
                if (route == "/logout") {
                  SharedPreferences prefs =
                      await SharedPreferences.getInstance();
                  prefs.remove('user');
                  prefs.remove('email');
                  Navigator.pushReplacement(context,
                      MaterialPageRoute(builder: (_) => const LoginPage()));
                }
              },
            ),
          ],
          bottom: TabBar(
            indicatorColor: Colors.white,
            tabs: <Widget>[
              Tab(
                child: Container(
                  child: const Text(
                    'All Bookings',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFFFFFF)),
                  ),
                ),
              ),
              const Tab(
                child: Text(
                  'My Bookings',
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFFFFF)),
                ),
              ),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // AllBookingWidget(user: widget.user),
            BookingAccommodationWidget(user: widget.user),
            // CalendarWidget(user: widget.user),
            MyBookingWidget(user: widget.user)
          ],
        ),
      ),
    );
  }
}
