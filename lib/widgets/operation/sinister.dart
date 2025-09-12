import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chicaparts_partner/api/api_operation.dart';
import 'package:chicaparts_partner/methods.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/widgets/menu/bottomMenu.dart';

class SinisterWidget extends StatefulWidget {
  const SinisterWidget({super.key, required this.user});
  final User user;
  @override
  State<SinisterWidget> createState() => _SinisterWidgetState();
}

class _SinisterWidgetState extends State<SinisterWidget> {
  bool isSwitched = false;
  bool pending = false;

  TextEditingController searchController = TextEditingController();
  String filter = "";

  @override
  void initState() {
    searchController.addListener(() {
      setState(() {
        filter = searchController.text;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final apiOperation = ApiOperation();
    Future<dynamic> getSinisters(partner, filter) {
      return apiOperation.getSinisters(partner, pending, filter);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF244B6B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFFFFF)),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BottomMenu(index: 3)));
          },
        ),
        title: const Text(
          "SINISTERS",
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
                SizedBox(
                  width: 200,
                  height: 55,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          filter = value.toLowerCase();
                        });
                      },
                      controller: searchController,
                      decoration: InputDecoration(
                        hintText: 'Search',
                        contentPadding:
                            const EdgeInsets.fromLTRB(10.0, 10.0, 10.0, 10.0),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10.0)),
                      ),
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  margin: const EdgeInsets.only(top: 0),
                  child: Switch(
                    value: isSwitched,
                    onChanged: (value) {
                      pending = pending ? false : true;
                      setState(() {
                        isSwitched = value;
                      });
                    },
                    activeTrackColor: Colors.grey,
                    activeColor: const Color(0xFF244B6B),
                  ),
                ),
                Container(
                    margin: const EdgeInsets.only(top: 0),
                    child: const Text(
                      "Only pending",
                      style: TextStyle(fontSize: 12),
                    )),
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
                future: getSinisters(widget.user.thirdParty["id"], filter),
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
                                        physics: const BouncingScrollPhysics(),
                                        shrinkWrap: true,
                                        scrollDirection: Axis.vertical,
                                        itemCount: accommodations.length,
                                        itemBuilder: (context, i) {
                                          var sinisters =
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
                                                  itemCount: sinisters.length,
                                                  itemBuilder: (context, j) {
                                                    return GestureDetector(
                                                        onTap: () {
                                                          showSinister(
                                                              context,
                                                              sinisters[j]
                                                                  ['id']);
                                                        },
                                                        child: Container(
                                                          height: 130,
                                                          decoration:
                                                              BoxDecoration(
                                                            border: Border.all(
                                                                color:
                                                                    Colors.grey,
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
                                                                        text: sinisters[j]['ref'] +
                                                                            " - " +
                                                                            sinisters[j]['title'],
                                                                        style: const TextStyle(
                                                                            fontSize:
                                                                                15,
                                                                            fontWeight:
                                                                                FontWeight.bold,
                                                                            color: Colors.black),
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
                                                                        allWordsCapitilize(sinisters[j]
                                                                            [
                                                                            'status']),
                                                                        style: const TextStyle(
                                                                            fontSize:
                                                                                12,
                                                                            fontWeight:
                                                                                FontWeight.bold)),
                                                                    const Spacer(),
                                                                    const Text(
                                                                        "Paiment status: "),
                                                                    Text(
                                                                        allWordsCapitilize(sinisters[j]
                                                                            [
                                                                            'payment_status']),
                                                                        style: const TextStyle(
                                                                            fontSize:
                                                                                12,
                                                                            fontWeight:
                                                                                FontWeight.bold))
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
                                                                    "Found date: ${DateFormat('yyyy-MM-dd').format(DateTime.parse(sinisters[j]['found_date']))}"),
                                                              )),
                                                              const SizedBox(
                                                                height: 10,
                                                              ),
                                                              Flexible(
                                                                  child:
                                                                      Container(
                                                                child: Text(
                                                                    "Request amount: ${sinisters[j]['required_amount']} " +
                                                                        sinisters[j]
                                                                            [
                                                                            'code'],
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold)),
                                                              )),
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
      )),
    );
  }

  String allWordsCapitilize(String str) {
    return str.toLowerCase().split(' ').map((word) {
      String leftText = (word.length > 1) ? word.substring(1, word.length) : '';
      return word[0].toUpperCase() + leftText;
    }).join(' ');
  }

  showSinister(context, id) {
    final apiOperation = ApiOperation();
    Future<dynamic> callApiOperation(id) {
      return apiOperation.getOneSinister(id);
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
                  FutureBuilder(
                      future: callApiOperation(id),
                      builder: (context, AsyncSnapshot snap) {
                        if (snap.data == null) {
                          return Container(
                            child: const Center(
                              child: Text("Loading..."),
                            ),
                          );
                        } else {
                          var sinister = snap.data;
                          var notes = jsonDecode(sinister.actions);
                          return Column(
                            children: [
                              ExpansionTile(
                                title: const Text("Sinister Details"),
                                children: [
                                  Row(children: <Widget>[
                                    methods.label("Reference:"),
                                    const SizedBox(
                                      width: 30,
                                    ),
                                    methods.element(sinister.ref),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ]),
                                  Row(children: <Widget>[
                                    methods.label("Requester:"),
                                    const SizedBox(
                                      width: 30,
                                    ),
                                    methods.element(
                                        allWordsCapitilize(sinister.requester)),
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
                                      methods.element(
                                          sinister.refAccommodation +
                                              " - " +
                                              sinister.accommodation),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      methods.label("Booking:"),
                                      const SizedBox(
                                        width: 45,
                                      ),
                                      methods.element(sinister.referer +
                                          " - " +
                                          sinister.apiReference +
                                          " - " +
                                          sinister.guestFirstName +
                                          " - " +
                                          sinister.guestName +
                                          " - " +
                                          DateFormat('yyyy-MM-dd').format(
                                              DateTime.parse(
                                                  sinister.firstNight)) +
                                          " -> " +
                                          DateFormat('yyyy-MM-dd').format(
                                              DateTime.parse(
                                                  sinister.lastNight))),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                  Row(children: <Widget>[
                                    methods.label("Currency:"),
                                    const SizedBox(
                                      width: 40,
                                    ),
                                    methods.element(sinister.currency),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ]),
                                  Row(children: <Widget>[
                                    methods.label("Title:"),
                                    const SizedBox(
                                      width: 65,
                                    ),
                                    methods.element(sinister.title),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ]),
                                  Row(children: <Widget>[
                                    methods.label("Status:"),
                                    const SizedBox(
                                      width: 55,
                                    ),
                                    methods.element(
                                        allWordsCapitilize(sinister.status)),
                                    const SizedBox(
                                      height: 10,
                                    ),
                                  ]),
                                  Row(
                                    children: [
                                      methods.label("Found date:"),
                                      const SizedBox(
                                        width: 30,
                                      ),
                                      methods.element(DateFormat('yyyy-MM-dd')
                                          .format(DateTime.parse(
                                              sinister.foundDate))),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      methods.label("Folder link:"),
                                      const SizedBox(
                                        width: 40,
                                      ),
                                      methods.element(sinister.folderLink),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      methods.label("Description:"),
                                      const SizedBox(
                                        width: 30,
                                      ),
                                      methods.elementText(sinister.description),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      methods.label("Guarantee type:"),
                                      const SizedBox(
                                        width: 0,
                                      ),
                                      methods.element(allWordsCapitilize(
                                          sinister.guaranteeType)),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      methods.label("Payment status:"),
                                      const SizedBox(
                                        width: 0,
                                      ),
                                      methods.element(allWordsCapitilize(
                                          sinister.paymentStatus)),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      methods.label("Refunded amount:"),
                                      const SizedBox(
                                        width: 0,
                                      ),
                                      methods.element(
                                          "${sinister.refundedAmount} " +
                                              sinister.currency),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              ExpansionTile(
                                title: const Text("Ticket Details"),
                                children: [
                                  Row(
                                    children: [
                                      methods.label("Ticket reference:"),
                                      const SizedBox(
                                        width: 0,
                                      ),
                                      methods.element(sinister.ticketRef),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      methods.label("Ticket link:"),
                                      const SizedBox(
                                        width: 25,
                                      ),
                                      methods.element(sinister.ticketLink),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      methods.label("Requested amount:"),
                                      const SizedBox(
                                        width: 0,
                                      ),
                                      methods.element(
                                          "${sinister.refundedAmount} " +
                                              sinister.currency),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      methods.label("Start date:"),
                                      const SizedBox(
                                        width: 30,
                                      ),
                                      methods.element(DateFormat('yyyy-MM-dd')
                                          .format(DateTime.parse(
                                              sinister.startDate))),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                  Row(
                                    children: [
                                      methods.label("Close date:"),
                                      const SizedBox(
                                        width: 30,
                                      ),
                                      methods.element(DateFormat('yyyy-MM-dd')
                                          .format(DateTime.parse(
                                              sinister.closeDate))),
                                      const SizedBox(
                                        height: 10,
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              ExpansionTile(
                                title: const Text("Follow-up"),
                                children: [
                                  notes.length > 0
                                      ? Container(
                                          child: ListView.builder(
                                            reverse: true,
                                            itemCount: notes.length,
                                            shrinkWrap: true,
                                            padding: const EdgeInsets.only(
                                                top: 10, bottom: 10),
                                            physics:
                                                const NeverScrollableScrollPhysics(),
                                            itemBuilder: (context, j) {
                                              return Column(
                                                children: [
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 0,
                                                            right: 0,
                                                            top: 0,
                                                            bottom: 0),
                                                    child: Align(
                                                      alignment:
                                                          (Alignment.topRight),
                                                      child: Container(
                                                        decoration: BoxDecoration(
                                                            borderRadius:
                                                                BorderRadius
                                                                    .circular(
                                                                        20),
                                                            color: Colors
                                                                .grey.shade200),
                                                        padding:
                                                            const EdgeInsets
                                                                .all(16),
                                                        child: Text(
                                                          notes[j]
                                                              ["description"],
                                                          style:
                                                              const TextStyle(
                                                                  fontSize: 15),
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.only(
                                                            left: 10,
                                                            right: 10,
                                                            bottom: 10),
                                                    child: Align(
                                                      alignment:
                                                          Alignment.topRight,
                                                      child: Text(DateFormat(
                                                              'yyyy-MM-dd')
                                                          .format(DateTime
                                                              .parse(notes[j][
                                                                  "timestamp"]))),
                                                    ),
                                                  ),
                                                ],
                                              );
                                            },
                                          ),
                                        )
                                      : Container(
                                          margin: const EdgeInsets.only(
                                              top: 5, bottom: 5),
                                          child: const Center(
                                            child: Text("Nothing to display."),
                                          ),
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
