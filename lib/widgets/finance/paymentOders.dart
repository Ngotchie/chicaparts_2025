import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chicaparts_partner/api/api_finance.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/widgets/menu/bottomMenu.dart';

import '../../methods.dart';

class PaymentOrderWidget extends StatefulWidget {
  const PaymentOrderWidget({super.key, required this.user});
  final User user;
  @override
  State<PaymentOrderWidget> createState() => _PaymentOrderWidgetState();
}

class _PaymentOrderWidgetState extends State<PaymentOrderWidget> {
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
    Future<dynamic> getPaymentOrders(partner, filter) {
      return apiFinance.getPaymentOrders(partner, filter);
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
          "PAYMENT ORDERS",
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
                    future:
                        getPaymentOrders(widget.user.thirdParty["id"], filter),
                    builder: (context, AsyncSnapshot snap) {
                      List<String> accommodations = [];
                      if (snap.data == null) {
                        return const Center(
                          child: Text("Loading..."),
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
                                              var orders =
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
                                                      itemCount: orders.length,
                                                      itemBuilder:
                                                          (context, j) {
                                                        return GestureDetector(
                                                            onTap: () {
                                                              showPaymentOrder(
                                                                  context,
                                                                  orders[j]);
                                                            },
                                                            child: Container(
                                                              height: orders[j][
                                                                          'payment_date'] !=
                                                                      null
                                                                  ? 165
                                                                  : 150,
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
                                                                    child: Container(
                                                                        child: RichText(
                                                                            maxLines: 1,
                                                                            overflow: TextOverflow.ellipsis,
                                                                            text: TextSpan(
                                                                              text: orders[j]['ref'] + " - " + orders[j]['title'],
                                                                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black),
                                                                            ))),
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          15),
                                                                  Flexible(
                                                                      child:
                                                                          Row(
                                                                    children: [
                                                                      const Text(
                                                                          "Accounting date: "),
                                                                      Text(
                                                                        orders[j]
                                                                            [
                                                                            'start_date'],
                                                                        style: const TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                      ),
                                                                      const Spacer(),
                                                                      const Text(
                                                                          "Type: "),
                                                                      Text(
                                                                        methods.allWordsCapitilize(orders[j]
                                                                            [
                                                                            'type']),
                                                                        style: const TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                      ),
                                                                    ],
                                                                  )),
                                                                  const SizedBox(
                                                                      height:
                                                                          15),
                                                                  Flexible(
                                                                      child:
                                                                          Text(
                                                                    "Amount: ${orders[j]['amount']} " +
                                                                        orders[j]
                                                                            [
                                                                            'code'],
                                                                    style: const TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold),
                                                                  )),
                                                                  const SizedBox(
                                                                      height:
                                                                          15),
                                                                  Flexible(
                                                                      child:
                                                                          Row(
                                                                    children: [
                                                                      const Text(
                                                                          "Payment status: "),
                                                                      Text(
                                                                        methods.allWordsCapitilize(orders[j]
                                                                            [
                                                                            'payment_status']),
                                                                        style: const TextStyle(
                                                                            fontWeight:
                                                                                FontWeight.bold),
                                                                      ),
                                                                    ],
                                                                  )),
                                                                  orders[j]['payment_date'] !=
                                                                          null
                                                                      ? const SizedBox(
                                                                          height:
                                                                              15)
                                                                      : Container(),
                                                                  orders[j]['payment_date'] !=
                                                                          null
                                                                      ? Flexible(
                                                                          child:
                                                                              Row(
                                                                          children: [
                                                                            const Text("Payment date: "),
                                                                            Text(
                                                                              DateFormat('yyyy-MM-dd').format(DateTime.parse(
                                                                                orders[j]['payment_date'],
                                                                              )),
                                                                              style: const TextStyle(fontWeight: FontWeight.bold),
                                                                            )
                                                                          ],
                                                                        ))
                                                                      : const Text(
                                                                          ""),
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
            )),
      ),
    );
  }

  showPaymentOrder(context, order) {
    final methods = Methods();
    String partner = order['partner_ref'];
    order['first_name'] != null
        ? partner = "$partner - " + order['first_name']
        : partner = partner;
    order['last_name'] != null
        ? partner = "$partner " + order['last_name']
        : partner = partner;
    order['business_name'] != null
        ? partner = "$partner - " + order['business_name']
        : partner = partner;
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
                  const Text("Payment Order Details",
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
                  Column(
                    children: [
                      Row(
                        children: [
                          methods.label("Reference:"),
                          const SizedBox(
                            width: 0,
                          ),
                          methods.element(order['ref'])
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          methods.label("Title:"),
                          const SizedBox(
                            width: 35,
                          ),
                          methods.element(order['title'])
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          methods.label("Partner:"),
                          const SizedBox(
                            width: 15,
                          ),
                          methods.element(partner)
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          methods.label("Accommodation:"),
                          const SizedBox(
                            width: 0,
                          ),
                          methods.element(order['accommodation_ref'] +
                              " - " +
                              order['internal_name'])
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          methods.label("Type:"),
                          const SizedBox(
                            width: 55,
                          ),
                          methods.element(
                              methods.allWordsCapitilize(order['type']))
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          methods.label("Amount:"),
                          const SizedBox(
                            width: 35,
                          ),
                          methods.element("${order['amount']} " + order['code'])
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          methods.label("Accounting date:"),
                          const SizedBox(
                            width: 0,
                          ),
                          methods.element(order['start_date'])
                        ],
                      ),
                      const SizedBox(
                        height: 5,
                      ),
                      Row(
                        children: [
                          methods.label("Payment date:"),
                          const SizedBox(
                            width: 0,
                          ),
                          order['payment_date'] != null
                              ? methods.element(DateFormat('yyyy-MM-dd')
                                  .format(DateTime.parse(
                                  order['payment_date'],
                                )))
                              : const Text("")
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          methods.label("Payment status:"),
                          const SizedBox(
                            width: 0,
                          ),
                          methods.element(methods
                              .allWordsCapitilize(order['payment_status']))
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Row(
                        children: [
                          methods.label("Comment:"),
                          const SizedBox(
                            width: 20,
                          ),
                          order['comment'] != null
                              ? methods.element(order['comment'])
                              : const Text("")
                        ],
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                    ],
                  )
                ],
              ),
            )))));
  }
}
