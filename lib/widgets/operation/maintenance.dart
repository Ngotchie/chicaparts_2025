import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chicaparts_partner/api/api_operation.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/widgets/menu/bottomMenu.dart';

import 'package:percent_indicator/percent_indicator.dart';

import '../../methods.dart';

class MaintenanceWidget extends StatefulWidget {
  const MaintenanceWidget({super.key, required this.user});
  final User user;
  @override
  State<MaintenanceWidget> createState() => _MaintenanceWidgetState();
}

class _MaintenanceWidgetState extends State<MaintenanceWidget> {
  bool isSwitched = false;
  bool pending = false;
  String? natureValue;
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    final apiOperation = ApiOperation();
    Future<dynamic> getMaintenances(partner, pending, nature) {
      nature ??= '';
      return apiOperation.getMaintenances(partner, pending, nature);
    }

    var natures = [
      'clear',
      'masonry',
      'plumbing',
      'electricity',
      'renovation',
      'maintenance',
      'carpentry',
      'equipment',
      'other',
    ];

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF244B6B),
        leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFFFFFFFF)),
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const BottomMenu(index: 3)));
            }),
        title: const Text(
          "MAINTENANCE",
          style: TextStyle(color: Color(0xFFFFFFFF)),
        ),
      ),
      body: SingleChildScrollView(
        child: Container(
          padding: const EdgeInsets.all(5),
          width: MediaQuery.of(context).size.width,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  Container(
                      width: 170,
                      height: 35,
                      margin: const EdgeInsets.only(left: 10, top: 10),
                      child: DropdownButtonFormField(
                        decoration: InputDecoration(
                          labelText: "Filter by nature",
                          contentPadding: const EdgeInsets.all(5.0),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15.0)),
                        ),
                        value: natureValue,
                        onChanged: (String? newValue) {
                          setState(() {
                            natureValue = newValue!;
                            loading = true;
                          });
                        },
                        items: natures
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(allWordsCapitilize(value)),
                          );
                        }).toList(),
                      )),
                  const Spacer(),
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: Switch(
                      value: isSwitched,
                      onChanged: (value) {
                        pending = pending ? false : true;
                        setState(() {
                          isSwitched = value;
                          loading = true;
                        });
                      },
                      activeTrackColor: Colors.grey,
                      activeColor: const Color(0xFF244B6B),
                    ),
                  ),
                  Container(
                      margin: const EdgeInsets.only(top: 10),
                      child: const Text("Only pending")),
                ],
              ),
              Container(
                margin: const EdgeInsets.only(top: 10),
                child: const Divider(
                  height: 1,
                  thickness: 2,
                  indent: 10,
                  endIndent: 0,
                  color: Colors.grey,
                ),
              ),
              FutureBuilder(
                  future: getMaintenances(
                      widget.user.thirdParty["id"], pending, natureValue),
                  builder: (context, AsyncSnapshot snap) {
                    List<String> accommodations = [];

                    if (snap.data == null ||
                        snap.connectionState == ConnectionState.waiting) {
                      return Container(
                        child: const Center(
                          child: Text("Loading..."),
                        ),
                      );
                    } else {
                      // Map<dynamic, dynamic> values = snap.data;
                      if (snap.data.length > 0) {
                        snap.data.forEach((key, values) {
                          accommodations.add(key);
                        });
                      }
                      return snap.data.length > 0
                          ? SizedBox(
                              height: MediaQuery.of(context).size.height * 0.8,
                              child: Column(
                                children: [
                                  Expanded(
                                      child: ListView.builder(
                                          physics:
                                              const BouncingScrollPhysics(),
                                          shrinkWrap: true,
                                          scrollDirection: Axis.vertical,
                                          itemCount: accommodations.length,
                                          itemBuilder: (context, i) {
                                            var maintenances =
                                                snap.data[accommodations[i]];
                                            return ExpansionTile(
                                              title: Text(accommodations[i]),
                                              children: [
                                                ListView.builder(
                                                    physics:
                                                        const NeverScrollableScrollPhysics(),
                                                    shrinkWrap: true,
                                                    scrollDirection:
                                                        Axis.vertical,
                                                    itemCount:
                                                        maintenances.length,
                                                    itemBuilder: (context, j) {
                                                      return GestureDetector(
                                                          onTap: () {
                                                            showMaintenance(
                                                                context,
                                                                maintenances[j]
                                                                    ["id"]);
                                                          },
                                                          child: Container(
                                                            height: 145,
                                                            decoration:
                                                                BoxDecoration(
                                                              border: Border.all(
                                                                  color: Colors
                                                                      .grey,
                                                                  width: 0.5),
                                                              borderRadius:
                                                                  const BorderRadius
                                                                      .all(
                                                                      Radius.circular(
                                                                          5.0) //         <--- border radius here
                                                                      ),
                                                            ),
                                                            margin:
                                                                const EdgeInsets
                                                                    .all(8),
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(10),
                                                            child: Column(
                                                              mainAxisAlignment:
                                                                  MainAxisAlignment
                                                                      .start,
                                                              crossAxisAlignment:
                                                                  CrossAxisAlignment
                                                                      .start,
                                                              children: [
                                                                Flexible(
                                                                  child:
                                                                      Container(
                                                                    child: RichText(
                                                                        overflow: TextOverflow.ellipsis,
                                                                        text: TextSpan(
                                                                          text: maintenances[j]['ref'] +
                                                                              " - " +
                                                                              maintenances[j]['title'],
                                                                          style:
                                                                              const TextStyle(
                                                                            fontSize:
                                                                                15,
                                                                            color:
                                                                                Colors.black,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                          ),
                                                                        )),
                                                                  ),
                                                                ),
                                                                const SizedBox(
                                                                  height: 10,
                                                                ),
                                                                Flexible(
                                                                    child:
                                                                        Container(
                                                                  child: Row(
                                                                    children: [
                                                                      const Text(
                                                                          "Status: "),
                                                                      Text(
                                                                          allWordsCapitilize(maintenances[j]
                                                                              [
                                                                              'status']),
                                                                          style: const TextStyle(
                                                                              fontSize: 12,
                                                                              fontWeight: FontWeight.bold)),
                                                                      // Container(
                                                                      //   child: Text(
                                                                      //       maintenances[
                                                                      //               j]
                                                                      //           [
                                                                      //           'status'],
                                                                      //       style: TextStyle(
                                                                      //           fontSize:
                                                                      //               12,
                                                                      //           color:
                                                                      //               Colors.white)),
                                                                      //   padding:
                                                                      //       EdgeInsets
                                                                      //           .all(
                                                                      //               5),
                                                                      //   decoration:
                                                                      //       BoxDecoration(
                                                                      //     shape: BoxShape
                                                                      //         .rectangle,
                                                                      //     color: Colors
                                                                      //         .grey,
                                                                      //     borderRadius:
                                                                      //         BorderRadius.circular(
                                                                      //             10),
                                                                      //   ),
                                                                      // ),
                                                                      const Spacer(),
                                                                      const Text(
                                                                          "Priority: "),
                                                                      Text(
                                                                          maintenances[j]
                                                                              [
                                                                              'priority'],
                                                                          style: const TextStyle(
                                                                              fontSize: 12,
                                                                              fontWeight: FontWeight.bold))
                                                                      // Container(
                                                                      //   child: Text(
                                                                      //       maintenances[
                                                                      //               j]
                                                                      //           [
                                                                      //           'priority'],
                                                                      //       style: TextStyle(
                                                                      //           fontSize:
                                                                      //               12,
                                                                      //           color:
                                                                      //               Colors.white)),
                                                                      //   padding:
                                                                      //       EdgeInsets
                                                                      //           .all(
                                                                      //               5),
                                                                      //   decoration:
                                                                      //       BoxDecoration(
                                                                      //     shape: BoxShape
                                                                      //         .rectangle,
                                                                      //     color: Colors
                                                                      //         .grey,
                                                                      //     borderRadius:
                                                                      //         BorderRadius.circular(
                                                                      //             10),
                                                                      //   ),
                                                                      // ),
                                                                    ],
                                                                  ),
                                                                )),
                                                                const SizedBox(
                                                                  height: 10,
                                                                ),
                                                                Flexible(
                                                                    child:
                                                                        Container(
                                                                  child: Text(
                                                                      "Log date: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(maintenances[j]['log_date']))}"),
                                                                )),
                                                                const SizedBox(
                                                                  height: 10,
                                                                ),
                                                                Flexible(
                                                                  child:
                                                                      LinearPercentIndicator(
                                                                    width: MediaQuery.of(context)
                                                                            .size
                                                                            .width -
                                                                        50,
                                                                    animation:
                                                                        true,
                                                                    lineHeight:
                                                                        20.0,
                                                                    animationDuration:
                                                                        2500,
                                                                    percent:
                                                                        int.parse(maintenances[j]['fixed_percentage']) /
                                                                            100,
                                                                    center:
                                                                        Text(
                                                                      maintenances[j]
                                                                              [
                                                                              'fixed_percentage'] +
                                                                          " %",
                                                                      style: const TextStyle(
                                                                          color:
                                                                              Colors.white),
                                                                    ),
                                                                    // ignore: deprecated_member_use
                                                                    linearStrokeCap:
                                                                        // ignore: deprecated_member_use
                                                                        LinearStrokeCap
                                                                            .roundAll,
                                                                    progressColor:
                                                                        const Color(
                                                                            0xFF244B6B),
                                                                  ),
                                                                )
                                                              ],
                                                            ),
                                                          ));
                                                    })
                                              ],
                                            );
                                          }))
                                ],
                              ),
                            )
                          : Container(
                              margin: const EdgeInsets.only(top: 20),
                              child: const Center(
                                child: Text("Noting to display"),
                              ));
                    }
                  })
            ],
          ),
        ),
      ),
    );
  }

  Color colorPriority(prty) {
    Color color;
    switch (prty) {
      case 'Normal':
        color = Colors.green;
        break;
      case 'Low':
        color = Colors.greenAccent;
        break;
      case 'Negligible':
        color = Colors.grey;
        break;
      case 'High':
        color = Colors.redAccent;
        break;
      default:
        color = Colors.red;
    }
    return color;
  }

  String allWordsCapitilize(String str) {
    return str.toLowerCase().split(' ').map((word) {
      String leftText = (word.length > 1) ? word.substring(1, word.length) : '';
      return word[0].toUpperCase() + leftText;
    }).join(' ');
  }

  showMaintenance(context, id) {
    final apiOperation = ApiOperation();
    Future<dynamic> callApiOperation(id) {
      return apiOperation.getOneMaintenance(id);
    }

    final methods = Methods();
    return showDialog(
        context: context,
        builder: (context) => Center(
                child: Material(
                    child: SingleChildScrollView(
                        child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.white,
              ),
              padding: const EdgeInsets.all(15),
              width: MediaQuery.of(context).size.width * 0.8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text("Maintenance Details",
                      style:
                          TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    child: const Divider(
                      height: 1,
                      thickness: 2,
                      indent: 10,
                      endIndent: 0,
                      color: Colors.grey,
                    ),
                  ),
                  FutureBuilder(
                      future: callApiOperation(id),
                      builder: (context, AsyncSnapshot snap) {
                        var maintenance = snap.data;

                        if (snap.data == null) {
                          return Container(
                            child: const Center(
                              child: Text("Loading..."),
                            ),
                          );
                        } else {
                          return Column(
                            children: [
                              Row(children: <Widget>[
                                methods.label("Reference: "),
                                const SizedBox(
                                  width: 20,
                                ),
                                methods.element(maintenance.ref),
                                const SizedBox(
                                  height: 10,
                                ),
                              ]),
                              Row(
                                children: [
                                  methods.label("Accommodation:"),
                                  const SizedBox(
                                    width: 0,
                                  ),
                                  methods.element(maintenance.refAccommodation +
                                      " - " +
                                      maintenance.accommodation),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  methods.label("Title:"),
                                  const SizedBox(
                                    width: 60,
                                  ),
                                  methods.element(maintenance.title),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  methods.label("Estimation:"),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  methods.element("${maintenance.estimation} " +
                                      maintenance.currency),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  methods.label("Real cost:"),
                                  const SizedBox(
                                    width: 30,
                                  ),
                                  methods.element("${maintenance.realCost} " +
                                      maintenance.currency),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  methods.label("Handler:"),
                                  const SizedBox(
                                    width: 35,
                                  ),
                                  methods.element(
                                      allWordsCapitilize(maintenance.handler)),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  methods.label("Priority:"),
                                  const SizedBox(
                                    width: 40,
                                  ),
                                  methods.element(maintenance.priority),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  methods.label("Step:"),
                                  const SizedBox(
                                    width: 55,
                                  ),
                                  methods.element(maintenance.step),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  methods.label("Nature:"),
                                  const SizedBox(
                                    width: 40,
                                  ),
                                  methods.element(
                                      allWordsCapitilize(maintenance.nature)),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  methods.label("Status:"),
                                  const SizedBox(
                                    width: 45,
                                  ),
                                  methods.element(
                                      allWordsCapitilize(maintenance.status)),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  methods.label("Fixed date:"),
                                  const SizedBox(
                                    width: 25,
                                  ),
                                  if (maintenance.fixedDate != "")
                                    methods.element(DateFormat('yyyy-MM-dd')
                                        .format(DateTime.parse(
                                            maintenance.fixedDate))),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  methods.label("Completion:"),
                                  const SizedBox(
                                    width: 15,
                                  ),
                                  methods
                                      .element("${maintenance.completion} %"),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  methods.label("Log date:"),
                                  const SizedBox(
                                    width: 35,
                                  ),
                                  methods.element(DateFormat('yyyy-MM-dd')
                                      .format(
                                          DateTime.parse(maintenance.logDate))),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                              Row(
                                children: [
                                  methods.label("Description:"),
                                  const SizedBox(
                                    width: 20,
                                  ),
                                  methods.elementText(maintenance.description),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ],
                              ),
                            ],
                          );
                        }
                      })
                ],
              ),
            )))));
  }
}
