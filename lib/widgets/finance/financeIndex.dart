import 'package:flutter/material.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/widgets/finance/monthlyReport.dart';
import 'package:chicaparts_partner/widgets/finance/paymentOders.dart';
import 'package:chicaparts_partner/widgets/finance/payouts.dart';
import 'package:chicaparts_partner/widgets/finance/yearlyPayouts.dart';
import 'package:chicaparts_partner/widgets/menu/appBar.dart';
import 'package:chicaparts_partner/widgets/menu/drawer.dart';

class FinanceIndexWidget extends StatefulWidget {
  const FinanceIndexWidget({super.key, required this.user});
  final User user;
  @override
  _FinanceIndexWidgetState createState() => _FinanceIndexWidgetState();
}

class _FinanceIndexWidgetState extends State<FinanceIndexWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: appBar("FINANCES", context, 1),
        drawer: drawer(widget.user, context),
        body: SingleChildScrollView(
          child: Center(
              child: Container(
            padding: const EdgeInsets.all(15),
            width: MediaQuery.of(context).size.width * 0.8,
            child: Column(
              children: [
                const SizedBox(
                  height: 40,
                ),
                SizedBox(
                  height: 50,
                  width: 250,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.money, color: Color(0xFFFFFFFF)),
                    label: const Text(
                      'Payment Orders',
                      style: TextStyle(color: Color(0xFFFFFFFF)),
                    ),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                          const Color(0xFFFBD107)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  PaymentOrderWidget(user: widget.user)));
                    },
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                SizedBox(
                  height: 50,
                  width: 250,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.monetization_on_outlined,
                        color: Color(0xFFFFFFFF)),
                    label: const Text('Monthly Reports',
                        style: TextStyle(color: Color(0xFFFFFFFF))),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                          const Color(0xFF244B6B)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  MonthlyReportWidget(user: widget.user)));
                    },
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                SizedBox(
                  height: 50,
                  width: 250,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.attach_money,
                        color: Color(0xFFFFFFFF)),
                    label: const Text('Payouts',
                        style: TextStyle(color: Color(0xFFFFFFFF))),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                          const Color(0xFF8B1FA9)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => PayoutWidget(user: widget.user)));
                    },
                  ),
                ),
                const SizedBox(
                  height: 40,
                ),
                SizedBox(
                  height: 50,
                  width: 250,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.payments_outlined,
                        color: Color(0xFFFFFFFF)),
                    label: const Text('Yearly Payouts Reports',
                        style: TextStyle(color: Color(0xFFFFFFFF))),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                          const Color(0xFF54bf31)),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  YearlyPayoutWidget(user: widget.user)));
                    },
                  ),
                ),
              ],
            ),
          )),
        ));
  }
}
