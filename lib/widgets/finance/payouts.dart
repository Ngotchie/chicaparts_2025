import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chicaparts_partner/api/api_finance.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/widgets/menu/bottomMenu.dart';

import '../../methods.dart';

class PayoutWidget extends StatefulWidget {
  const PayoutWidget({super.key, required this.user});
  final User user;
  @override
  State<PayoutWidget> createState() => _PayoutWidgetState();
}

class _PayoutWidgetState extends State<PayoutWidget> {
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
    final methods = Methods();
    final apiFinance = ApiFinance();
    Future<dynamic> getPayouts(partner, filter) {
      return apiFinance.getPayouts(partner, filter);
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFF244B6B),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFFFFFFFF)),
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const BottomMenu(index: 2)));
          },
        ),
        title: const Text(
          "PAYOUTS",
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
                  Container(
                    alignment: Alignment.topRight,
                    width: 300,
                    height: 45,
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
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
                              const EdgeInsets.fromLTRB(10.0, 5.0, 5.0, 5.0),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10.0)),
                        ),
                      ),
                    ),
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
                      future: getPayouts(widget.user.thirdParty["id"], filter),
                      builder: (context, AsyncSnapshot snap) {
                        List<String> accommodations = [];
                        if (snap.data == null) {
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
                                  height:
                                      MediaQuery.of(context).size.height * 0.8,
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
                                                var payouts = snap
                                                    .data[accommodations[i]];
                                                return ExpansionTile(
                                                  title:
                                                      Text(accommodations[i]),
                                                  children: [
                                                    ListView.builder(
                                                        physics:
                                                            const NeverScrollableScrollPhysics(),
                                                        shrinkWrap: true,
                                                        scrollDirection:
                                                            Axis.vertical,
                                                        itemCount:
                                                            payouts.length,
                                                        itemBuilder:
                                                            (context, j) {
                                                          return GestureDetector(
                                                              onTap: () {
                                                                showPayout(
                                                                    context,
                                                                    payouts[j]
                                                                        ['id']);
                                                              },
                                                              child: Container(
                                                                height: 100,
                                                                decoration:
                                                                    BoxDecoration(
                                                                  border: Border.all(
                                                                      color: Colors
                                                                          .grey,
                                                                      width:
                                                                          0.5),
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
                                                                        .all(
                                                                        10),
                                                                child: Column(
                                                                  mainAxisAlignment:
                                                                      MainAxisAlignment
                                                                          .start,
                                                                  crossAxisAlignment:
                                                                      CrossAxisAlignment
                                                                          .start,
                                                                  children: [
                                                                    Flexible(
                                                                        child: Row(
                                                                            children: [
                                                                          const Text(
                                                                              "Offer: "),
                                                                          Text(
                                                                            payouts[j]['offer'],
                                                                            style:
                                                                                const TextStyle(
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          )
                                                                        ])),
                                                                    const SizedBox(
                                                                        height:
                                                                            15),
                                                                    Flexible(
                                                                        child: Row(
                                                                            children: [
                                                                          const Text(
                                                                              "Payout: "),
                                                                          Text(
                                                                            "${payouts[j]['amount']} " +
                                                                                payouts[j]['code'],
                                                                            style:
                                                                                const TextStyle(
                                                                              fontWeight: FontWeight.bold,
                                                                            ),
                                                                          )
                                                                        ])),
                                                                    const SizedBox(
                                                                        height:
                                                                            15),
                                                                    Flexible(
                                                                        child:
                                                                            Row(
                                                                      children: [
                                                                        const Text(
                                                                            "Périod: "),
                                                                        Text(
                                                                          "${DateFormat('dd.MM.yyyy').format(DateTime.parse(payouts[j]['period_start']))} - ${DateFormat('dd.MM.yyyy').format(DateTime.parse(payouts[j]['period_end']))}",
                                                                          style:
                                                                              const TextStyle(fontWeight: FontWeight.bold),
                                                                        ),
                                                                        const Spacer(),
                                                                        const Text(
                                                                            "Status: "),
                                                                        Text(
                                                                            methods.allWordsCapitilize(payouts[j][
                                                                                'status']),
                                                                            style:
                                                                                const TextStyle(fontWeight: FontWeight.bold)),
                                                                      ],
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
                ])),
      ),
    );
  }

  showPayout(context, id) {
    final methods = Methods();
    ApiFinance apiFinance = ApiFinance();
    Future<dynamic> getOnePayout(id) {
      return apiFinance.getOnePayout(id);
    }

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
                              const Text("Payout Details",
                                  style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold)),
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
                                future: getOnePayout(id),
                                builder: (context, AsyncSnapshot snapshot) {
                                  if (snapshot.data == null) {
                                    return Container(
                                      child: const Center(
                                        child: Text("Loading..."),
                                      ),
                                    );
                                  } else {
                                    var payout = snapshot.data;
                                    return Container(
                                      child: Column(
                                        children: [
                                          Row(
                                            children: [
                                              methods.label("Reference:"),
                                              const SizedBox(
                                                width: 20,
                                              ),
                                              methods.element(payout.ref),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 15,
                                          ),
                                          Row(
                                            children: [
                                              methods.label("Contract:"),
                                              const SizedBox(
                                                width: 30,
                                              ),
                                              methods.element(
                                                  payout.contractRef +
                                                      " - " +
                                                      payout.accommodationRef +
                                                      " - " +
                                                      payout.internalName),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 15,
                                          ),
                                          Row(
                                            children: [
                                              methods.label("Period start:"),
                                              const SizedBox(
                                                width: 15,
                                              ),
                                              methods.element(
                                                  DateFormat('yyyy-MM-dd')
                                                      .format(DateTime.parse(
                                                payout.periodStart,
                                              )))
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 15,
                                          ),
                                          Row(
                                            children: [
                                              methods.label("Period end:"),
                                              const SizedBox(
                                                width: 20,
                                              ),
                                              methods.element(
                                                  DateFormat('yyyy-MM-dd')
                                                      .format(DateTime.parse(
                                                payout.periodEnd,
                                              )))
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 15,
                                          ),
                                          Row(
                                            children: [
                                              methods.label("Payout:"),
                                              const SizedBox(
                                                width: 45,
                                              ),
                                              methods.element(
                                                  "${payout.amount} " +
                                                      payout.currency),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 15,
                                          ),
                                          Row(
                                            children: [
                                              methods.label("Supplies:"),
                                              const SizedBox(
                                                width: 35,
                                              ),
                                              methods.element(payout.supplies +
                                                  " " +
                                                  payout.currency),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 15,
                                          ),
                                          Row(
                                            children: [
                                              methods.label("Chic partner:"),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              methods.element(
                                                  "${payout.chicPartner} " +
                                                      payout.currency),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 15,
                                          ),
                                          Row(
                                            children: [
                                              methods.label("Occasional gain:"),
                                              const SizedBox(
                                                width: 0,
                                              ),
                                              methods.element(
                                                  "${payout.occasionalGain} " +
                                                      payout.currency),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 15,
                                          ),
                                          Row(
                                            children: [
                                              methods.label("Occasional fees:"),
                                              const SizedBox(
                                                width: 0,
                                              ),
                                              methods.element(
                                                  "${payout.occasionalFees} " +
                                                      payout.currency),
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 15,
                                          ),
                                          Row(
                                            children: [
                                              methods.label("Payout date:"),
                                              const SizedBox(
                                                width: 10,
                                              ),
                                              methods.element(
                                                  DateFormat('yyyy-MM-dd')
                                                      .format(DateTime.parse(
                                                payout.payoutDate,
                                              )))
                                            ],
                                          ),
                                          const SizedBox(
                                            height: 15,
                                          ),
                                        ],
                                      ),
                                    );
                                  }
                                },
                              )
                            ]))))));
  }
}
