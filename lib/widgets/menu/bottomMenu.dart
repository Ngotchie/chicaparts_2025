import 'package:circular_bottom_navigation/tab_item.dart';
import 'package:flutter/material.dart';
import 'package:chicaparts_partner/widgets/accommodation/accommodationIndex.dart';
import 'package:chicaparts_partner/services/user.dart';
import 'package:circular_bottom_navigation/circular_bottom_navigation.dart';
import 'package:chicaparts_partner/widgets/booking/bookingIndex.dart';
import 'package:chicaparts_partner/widgets/finance/financeIndex.dart';
import 'package:chicaparts_partner/widgets/operation/operationIndex.dart';

class BottomMenu extends StatefulWidget {
  const BottomMenu({super.key, required this.index});
  final int index;
  @override
  _BottomMenuState createState() => _BottomMenuState();
}

class _BottomMenuState extends State<BottomMenu> {
  CurrentUser currentUser = CurrentUser();
  var user;
  int selectedPos = 0;
  double bottomNavBarHeight = 60;
  String menuTitle = "";
  late StatefulWidget page;

  List<TabItem> tabItems = List.of([
    TabItem(Icons.home, "Accommodations", const Color(0xFF244B6B),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    TabItem(Icons.ballot_outlined, "Bookings", const Color(0xFF244B6B),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    TabItem(Icons.euro, "Finances", const Color(0xFF244B6B),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
    TabItem(Icons.assignment, "Operations", const Color(0xFF244B6B),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
  ]);

  late CircularBottomNavigationController _navigationController;
  @override
  void initState() {
    super.initState();
    currentUser.getCurrentUser().then((result) {
      print(result);
      setState(() {
        user = result;
      });
    });
    selectedPos = widget.index;
    _navigationController = CircularBottomNavigationController(selectedPos);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Stack(
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(bottom: bottomNavBarHeight),
              child: bodyContainer(),
            ),
            Align(alignment: Alignment.bottomCenter, child: bottomNav())
          ],
        ),
      ),
    );
  }

  Widget bodyContainer() {
    Color selectedColor = tabItems[selectedPos].circleColor;
    switch (selectedPos) {
      case 1:
        page = BookingIndexWidget(user: user);
        menuTitle = "BOOKINGS";
        break;
      case 2:
        page = FinanceIndexWidget(user: user);
        menuTitle = "FINANCES";
        break;
      case 3:
        page = OperationIndexWidget(user: user);
        menuTitle = "OPERATIONS";
        break;
      case 0:
        page = AccommodationIndexWidget(user: user);
        menuTitle = "ACCOMMODATIONS";
        break;
    }

    return GestureDetector(
      child: Container(
        width: double.infinity,
        height: double.infinity,
        color: selectedColor,
        child: Center(child: page),
      ),
      onTap: () {
        if (_navigationController.value == tabItems.length - 1) {
          _navigationController.value = 0;
        }
      },
    );
  }

  Widget bottomNav() {
    return CircularBottomNavigation(
      tabItems,
      controller: _navigationController,
      barHeight: bottomNavBarHeight,
      barBackgroundColor: Colors.white,
      animationDuration: const Duration(milliseconds: 300),
      selectedCallback: (int? selectedPos) {
        setState(() {
          this.selectedPos = selectedPos ?? 0;
        });
      },
    );
  }

  @override
  void dispose() {
    super.dispose();
    _navigationController.dispose();
  }
}
