import 'package:flutter/material.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/widgets/menu/appBar.dart';
import 'package:chicaparts_partner/widgets/menu/drawer.dart';
import 'package:chicaparts_partner/widgets/operation/maintenance.dart';
import 'package:chicaparts_partner/widgets/operation/sinister.dart';

class OperationIndexWidget extends StatefulWidget {
  const OperationIndexWidget({super.key, required this.user});
  final User user;

  @override
  _OperationIndexWidgetState createState() => _OperationIndexWidgetState();
}

class _OperationIndexWidgetState extends State<OperationIndexWidget> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: appBar("OPERATIONS", context, 1),
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
                    icon: const Icon(Icons.settings_suggest_sharp,
                        color: Color(0xFFFFFFFF)),
                    label: const Text(
                      'Maintenance',
                      style: TextStyle(color: Color(0xFFFFFFFF)),
                    ),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                          const Color(0xFF8B1FA9)), //0xFFd1b690
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  MaintenanceWidget(user: widget.user)));
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
                    icon:
                        const Icon(Icons.bug_report, color: Color(0xFFFFFFFF)),
                    label: const Text(
                      'Sinisters',
                      style: TextStyle(color: Color(0xFFFFFFFF)),
                    ),
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                          const Color(0xFF54bf31)), //0xFFd49f55
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  SinisterWidget(user: widget.user)));
                    },
                  ),
                ),
              ],
            ),
          )),
        ));
  }
}
