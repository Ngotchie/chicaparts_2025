import 'package:flutter/material.dart';
import 'package:chicaparts_partner/widgets/finance/monthlyReport.dart';
import 'package:chicaparts_partner/widgets/finance/paymentOders.dart';
import 'package:chicaparts_partner/widgets/finance/payouts.dart';
import 'package:chicaparts_partner/widgets/finance/yearlyPayouts.dart';
import 'package:chicaparts_partner/widgets/operation/maintenance.dart';
import 'package:chicaparts_partner/widgets/operation/sinister.dart';

Widget drawer(user, context) {
  return Drawer(
      elevation: 10.0,
      child: ListView(
        children: <Widget>[
          SizedBox(
            height: 110,
            child: DrawerHeader(
              padding: const EdgeInsets.all(5),
              decoration: const BoxDecoration(color: Color(0xFF244B6B)),
              child: Column(children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    const SizedBox(
                      height: 50,
                      width: 50,
                      child: CircleAvatar(
                        backgroundColor: Colors.white,
                        backgroundImage: AssetImage("assets/images/avatar.png"),
                        radius: 40.0,
                      ),
                    ),
                    const SizedBox(
                      width: 5,
                    ),
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          user.name,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                              fontSize: 16.0),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  user.email,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14.0),
                ),
              ]),
            ),
          ),
          const Divider(height: 3.0),
          ListTile(
            leading: const Icon(Icons.home_sharp),
            title: const Text('Accommodations', style: TextStyle(fontSize: 18)),
            onTap: () {
              Navigator.pushNamed(context, '/accommodation');
            },
          ),
          const Divider(height: 3.0),
          ListTile(
            leading: const Icon(Icons.ballot_outlined),
            title: const Text('Bookings', style: TextStyle(fontSize: 18)),
            onTap: () {
              Navigator.pushNamed(context, '/booking');
            },
          ),
          const Divider(height: 3.0),
          ListTile(
            leading: const Icon(Icons.monetization_on_outlined),
            title:
                const Text('Monthly reports', style: TextStyle(fontSize: 18)),
            onTap: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => MonthlyReportWidget(user: user)));
            },
          ),
          const Divider(height: 3.0),
          ListTile(
            leading: const Icon(Icons.money),
            title: const Text('Payment orders', style: TextStyle(fontSize: 18)),
            onTap: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => PaymentOrderWidget(user: user)));
            },
          ),
          const Divider(height: 3.0),
          ListTile(
            leading: const Icon(Icons.attach_money),
            title: const Text('Payouts', style: TextStyle(fontSize: 18)),
            onTap: () {
              Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => PayoutWidget(user: user)));
            },
          ),
          const Divider(height: 3.0),
          ListTile(
            leading: const Icon(Icons.payments_outlined),
            title: const Text('Yearly payout reports',
                style: TextStyle(fontSize: 18)),
            onTap: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => YearlyPayoutWidget(user: user)));
            },
          ),
          const Divider(height: 3.0),
          ListTile(
            leading: const Icon(Icons.settings_suggest_sharp),
            title: const Text('Maintenance', style: TextStyle(fontSize: 18)),
            onTap: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => MaintenanceWidget(user: user)));
            },
          ),
          const Divider(height: 3.0),
          ListTile(
            leading: const Icon(Icons.bug_report),
            title: const Text('Sinisters', style: TextStyle(fontSize: 18)),
            onTap: () {
              Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SinisterWidget(user: user)));
            },
          ),
        ],
      ));
}
