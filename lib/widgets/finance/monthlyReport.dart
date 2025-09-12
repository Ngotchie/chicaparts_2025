import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chicaparts_partner/api/api_finance.dart';
import 'package:chicaparts_partner/methods.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/widgets/menu/bottomMenu.dart';

class MonthlyReportWidget extends StatefulWidget {
  const MonthlyReportWidget({super.key, required this.user});
  final User user;
  @override
  State<MonthlyReportWidget> createState() => _MonthlyReportWidgetState();
}

class _MonthlyReportWidgetState extends State<MonthlyReportWidget> {
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
    Future<dynamic> getMonthlyReports(partner, filter) {
      return apiFinance.getMonthlyReports(partner, filter);
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
          "MONTHLY REPORTS",
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
                      getMonthlyReports(widget.user.thirdParty["id"], filter),
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
                                          var reports =
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
                                                  itemCount: reports.length,
                                                  itemBuilder: (context, j) {
                                                    return GestureDetector(
                                                        onTap: () {
                                                          showMonthlyReport(
                                                              context,
                                                              reports[j]['id']);
                                                        },
                                                        child: Container(
                                                          height: 70,
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
                                                                  child: Row(
                                                                children: [
                                                                  Text(
                                                                    DateFormat.yMMMM(
                                                                            'en_US')
                                                                        .format(DateTime.parse(reports[j]
                                                                            [
                                                                            'start_date'])),
                                                                    style: const TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold),
                                                                  ),
                                                                ],
                                                              )),
                                                              const SizedBox(
                                                                  height: 15),
                                                              Flexible(
                                                                  child: Row(
                                                                children: [
                                                                  const Text(
                                                                      "Period: "),
                                                                  Text(
                                                                    "${DateFormat('dd-MM').format(DateTime.parse(reports[j]['start_date']))} => ${DateFormat('dd-MM').format(DateTime.parse(reports[j]['end_date']))}",
                                                                    style: const TextStyle(
                                                                        fontWeight:
                                                                            FontWeight.bold),
                                                                  ),
                                                                  const Spacer(),
                                                                  const Text(
                                                                      "Status: "),
                                                                  Text(
                                                                      methods.allWordsCapitilize(
                                                                          reports[j]
                                                                              [
                                                                              'status']),
                                                                      style: const TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold)),
                                                                ],
                                                              )),
                                                            ],
                                                          ),
                                                        ));
                                                  })
                                            ],
                                          );
                                        }),
                                  )
                                ],
                              ),
                            )
                          : Container(
                              margin: const EdgeInsets.only(top: 20),
                              child: const Center(
                                child: Text("Noting to display"),
                              ));
                    }
                  }),
            ],
          ),
        ),
      ),
    );
  }

  Widget label(label) {
    return Flexible(
        child: Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.grey)));
  }

  showMonthlyReport(context, id) {
    ApiFinance apiFinance = ApiFinance();
    Future<dynamic> getOneReport(id) {
      return apiFinance.getOneReport(id);
    }

    final methods = Methods();
    return showDialog(
        context: context,
        builder: (context) {
          return Center(
              child: Material(
                  child: SingleChildScrollView(
                      child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.white,
                          ),
                          padding: const EdgeInsets.all(5),
                          width: MediaQuery.of(context).size.width * 0.9,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                FutureBuilder(
                                    future: getOneReport(id),
                                    builder: (context, AsyncSnapshot snap) {
                                      if (snap.data == null) {
                                        return Container(
                                          child: const Center(
                                            child: Text("Loading..."),
                                          ),
                                        );
                                      } else {
                                        var report = snap.data;
                                        return Container(
                                          child: Column(
                                            children: [
                                              Card(
                                                child: Column(children: [
                                                  ListTile(
                                                    tileColor: Colors.grey[200],
                                                    title: const Text(
                                                      "Accommodation",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(5),
                                                    child: Column(
                                                      children: [
                                                        Row(
                                                          children: [
                                                            label(
                                                                "Accommodation name:"),
                                                            const SizedBox(
                                                              width: 0,
                                                            ),
                                                            methods.element(report
                                                                    .accommodationRef +
                                                                "-" +
                                                                report
                                                                    .externalName),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            label(
                                                                "Accommodation type:"),
                                                            methods.element(methods
                                                                .allWordsCapitilize(
                                                                    report
                                                                        .accommodationType))
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            label(
                                                                "Accommodation address:"),
                                                            methods.element(report
                                                                    .address1 +
                                                                ", " +
                                                                report
                                                                    .address2 +
                                                                ", " +
                                                                report.address3)
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            label(
                                                                "Description:"),
                                                            const SizedBox(
                                                              width: 30,
                                                            ),
                                                            methods.elementText(
                                                                report
                                                                    .accommodationDescription)
                                                          ],
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ]),
                                              ),
                                              Card(
                                                  child: Column(children: [
                                                ListTile(
                                                  tileColor: Colors.grey[200],
                                                  title: const Text(
                                                    "Report",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                Container(
                                                  padding:
                                                      const EdgeInsets.all(5),
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          label(
                                                              "Monthly report Reference:"),
                                                          const SizedBox(
                                                            width: 5,
                                                          ),
                                                          methods.element(
                                                              report.monthlyRef)
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          label("Period:"),
                                                          const SizedBox(
                                                            width: 65,
                                                          ),
                                                          methods.element(report
                                                                  .startDate +
                                                              " - " +
                                                              report.endDate)
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          label("Offer:"),
                                                          const SizedBox(
                                                            width: 75,
                                                          ),
                                                          methods.element(
                                                              report.offer)
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ])),
                                              if (report.offer != "Chic'Zen")
                                                Card(
                                                    child: Column(children: [
                                                  ListTile(
                                                    tileColor: Colors.grey[200],
                                                    title: const Text(
                                                      "Bookings",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                  Scrollbar(
                                                    child:
                                                        SingleChildScrollView(
                                                      scrollDirection:
                                                          Axis.horizontal,
                                                      child: Container(
                                                        alignment:
                                                            Alignment.topLeft,
                                                        margin: const EdgeInsets
                                                            .all(5),
                                                        child: DataTable(
                                                          columns: [
                                                            const DataColumn(
                                                                label: Text(
                                                                    'Confirmation Code',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold))),
                                                            const DataColumn(
                                                                label: Text(
                                                                    'Platform',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold))),
                                                            const DataColumn(
                                                                label: Text(
                                                              'Status',
                                                              style: TextStyle(
                                                                  fontSize: 12,
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold),
                                                            )),
                                                            const DataColumn(
                                                                label: Text(
                                                                    'Guest Name',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold))),
                                                            const DataColumn(
                                                                label: Text(
                                                                    'Adults',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold))),
                                                            const DataColumn(
                                                                label: Text(
                                                                    'Children',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold))),
                                                            const DataColumn(
                                                                label: Text(
                                                                    'Infant',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold))),
                                                            const DataColumn(
                                                                label: Text(
                                                                    'Start date',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold))),
                                                            const DataColumn(
                                                                label: Text(
                                                                    'End date',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold))),
                                                            const DataColumn(
                                                                label: Text(
                                                                    'Nights',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold))),
                                                            const DataColumn(
                                                                label: Text(
                                                                    'Nightly rate',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold))),
                                                            const DataColumn(
                                                                label: Text(
                                                                    'Booking date',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold))),
                                                            if (report.offer
                                                                .contains(
                                                                    "Full"))
                                                              const DataColumn(
                                                                  label: Text(
                                                                      'Seller',
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          fontWeight:
                                                                              FontWeight.bold))),
                                                            if (report.offer
                                                                .contains(
                                                                    "Full"))
                                                              const DataColumn(
                                                                  label: Text(
                                                                      'Payment Handler',
                                                                      style: TextStyle(
                                                                          fontSize:
                                                                              12,
                                                                          fontWeight:
                                                                              FontWeight.bold))),
                                                            const DataColumn(
                                                                label: Text(
                                                                    'Total amount',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold))),
                                                            const DataColumn(
                                                                label: Text(
                                                                    'Price Multiplier',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold))),
                                                            const DataColumn(
                                                                label: Text(
                                                                    'City taxes',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold))),
                                                            const DataColumn(
                                                                label: Text(
                                                                    'Booking fees',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold))),
                                                            const DataColumn(
                                                                label: Text(
                                                                    'Promotion fees',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold))),
                                                            const DataColumn(
                                                                label: Text(
                                                                    'Transaction fees',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold))),
                                                            const DataColumn(
                                                                label: Text(
                                                                    'Chicaparts fees',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold))),
                                                            const DataColumn(
                                                                label: Text(
                                                                    'Cleaning fees',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold))),
                                                            const DataColumn(
                                                                label: Text(
                                                                    'Chic partner',
                                                                    style: TextStyle(
                                                                        fontSize:
                                                                            12,
                                                                        fontWeight:
                                                                            FontWeight.bold))),
                                                          ],
                                                          rows: [
                                                            for (var item
                                                                in report
                                                                    .reportLine)
                                                              DataRow(cells: [
                                                                DataCell(Text(item[
                                                                    'confirmation_code'])),
                                                                DataCell(Text(item[
                                                                    'platform'])),
                                                                DataCell(Text(item[
                                                                    'status'])),
                                                                DataCell(Text(item[
                                                                    'guest_name'])),
                                                                DataCell(Text(item[
                                                                        'adults']
                                                                    .toString())),
                                                                DataCell(Text(item[
                                                                        'children']
                                                                    .toString())),
                                                                DataCell(Text(item[
                                                                        'infants']
                                                                    .toString())),
                                                                DataCell(Text(item[
                                                                    'start_date'])),
                                                                DataCell(Text(item[
                                                                    'end_date'])),
                                                                DataCell(Text(item[
                                                                        'nights']
                                                                    .toString())),
                                                                DataCell(Text(
                                                                    "${item['nightly_rate']} " +
                                                                        report
                                                                            .currency)),
                                                                DataCell(Text(item[
                                                                    'booking_date'])),
                                                                if (report.offer
                                                                    .contains(
                                                                        "Full"))
                                                                  DataCell(Text(
                                                                      item[
                                                                          'seller'])),
                                                                if (report.offer
                                                                    .contains(
                                                                        "Full"))
                                                                  DataCell(Text(
                                                                      item[
                                                                          'payment_handler'])),
                                                                DataCell(Text(
                                                                    "${item['total_amount']} " +
                                                                        report
                                                                            .currency)),
                                                                DataCell(!item
                                                                        .containsKey(
                                                                            'price_multiplier')
                                                                    ? const Text(
                                                                        "Not defined")
                                                                    : item['price_multiplier'] ==
                                                                            0
                                                                        ? const Text(
                                                                            "0%")
                                                                        : Text(item[
                                                                            'price_multiplier'])),
                                                                DataCell(Text(
                                                                    "${item['city_taxes']} " +
                                                                        report
                                                                            .currency)),
                                                                DataCell(Text(
                                                                    "${item['booking_fees']} " +
                                                                        report
                                                                            .currency)),
                                                                DataCell(Text(
                                                                    "${item['promotion_fees']} " +
                                                                        report
                                                                            .currency)),
                                                                DataCell(Text(
                                                                    "${item['transaction_fees']} " +
                                                                        report
                                                                            .currency)),
                                                                DataCell(Text(
                                                                    "${item['chicaparts']} " +
                                                                        report
                                                                            .currency)),
                                                                DataCell(Text(
                                                                    "${item['cleaning_fees']} " +
                                                                        report
                                                                            .currency)),
                                                                DataCell(Text(
                                                                    "${item['chic_partner']} " +
                                                                        report
                                                                            .currency)),
                                                              ]),
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ])),
                                              if (report
                                                      .occasionalGains.length >
                                                  0)
                                                Card(
                                                    child: Column(children: [
                                                  ListTile(
                                                    tileColor: Colors.grey[200],
                                                    title: const Text(
                                                      "Occasional gains",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.all(5),
                                                    child: Column(
                                                      children: [
                                                        for (var item in report
                                                            .occasionalGains)
                                                          Row(
                                                            children: [
                                                              Flexible(
                                                                  flex: 2,
                                                                  child: Text(
                                                                      item[
                                                                          "title"],
                                                                      style: const TextStyle(
                                                                          fontSize:
                                                                              12))),
                                                              Flexible(
                                                                  flex: 1,
                                                                  child:
                                                                      Padding(
                                                                    padding:
                                                                        const EdgeInsets
                                                                            .all(
                                                                            8.0),
                                                                    child: Text(
                                                                      item["price"] +
                                                                          " " +
                                                                          item[
                                                                              "currency"],
                                                                    ),
                                                                  ))
                                                            ],
                                                          ),
                                                      ],
                                                    ),
                                                  )
                                                ])),
                                              if (report.occasionalFees.length >
                                                  0)
                                                Card(
                                                    child: Column(children: [
                                                  ListTile(
                                                    tileColor: Colors.grey[200],
                                                    title: const Text(
                                                      "Occasional fees",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                  Container(
                                                    margin:
                                                        const EdgeInsets.all(5),
                                                    child: Column(
                                                      children: [
                                                        for (var item in report
                                                            .occasionalFees)
                                                          Row(
                                                            children: [
                                                              label(item[
                                                                  "title"]),
                                                              const Spacer(),
                                                              Text(item[
                                                                      "price"] +
                                                                  " " +
                                                                  item[
                                                                      "currency"])
                                                            ],
                                                          ),
                                                      ],
                                                    ),
                                                  )
                                                ])),
                                              Card(
                                                  child: Column(children: [
                                                ListTile(
                                                  tileColor: Colors.grey[200],
                                                  title: const Text(
                                                    "Summary",
                                                    style: TextStyle(
                                                        fontWeight:
                                                            FontWeight.bold),
                                                  ),
                                                ),
                                                Container(
                                                  margin:
                                                      const EdgeInsets.all(5),
                                                  child: Column(
                                                    children: [
                                                      Row(
                                                        children: [
                                                          label(
                                                              "Chic partner total:"),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          methods.element(
                                                              "${report.chicPartner} " +
                                                                  report
                                                                      .currency),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          label(
                                                              "Occasional gains:"),
                                                          const SizedBox(
                                                            width: 10,
                                                          ),
                                                          methods.element(
                                                              "${report.totalOccasionalGain} " +
                                                                  report
                                                                      .currency),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          label(
                                                              "Occasional fees:"),
                                                          const SizedBox(
                                                            width: 15,
                                                          ),
                                                          methods.element(
                                                              "${report.totalOccasionalFees} " +
                                                                  report
                                                                      .currency),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          label("Supplies:"),
                                                          const SizedBox(
                                                            width: 55,
                                                          ),
                                                          methods.element(
                                                              "${report.supplies} " +
                                                                  report
                                                                      .currency),
                                                        ],
                                                      ),
                                                      Row(
                                                        children: [
                                                          label(
                                                              "Available nights:"),
                                                          const SizedBox(
                                                            width: 20,
                                                          ),
                                                          methods.element(report
                                                              .availableNight
                                                              .toString()),
                                                        ],
                                                      ),
                                                      if (report.offer !=
                                                          "Chic'Zen")
                                                        Row(
                                                          children: [
                                                            label(
                                                                "Occupied nights:"),
                                                            const SizedBox(
                                                              width: 20,
                                                            ),
                                                            methods.element(report
                                                                .occupiedNight
                                                                .toString()),
                                                          ],
                                                        ),
                                                      Row(
                                                        children: [
                                                          label(
                                                              "Blocked nights:"),
                                                          const SizedBox(
                                                            width: 25,
                                                          ),
                                                          methods.element(report
                                                              .blockedNight
                                                              .toString()),
                                                        ],
                                                      ),
                                                      if (report.offer !=
                                                          "Chic'Zen")
                                                        Row(
                                                          children: [
                                                            label(
                                                                "Occupacy rate:"),
                                                            const SizedBox(
                                                              width: 25,
                                                            ),
                                                            methods.element(
                                                                "${report.occupationRate} %"),
                                                          ],
                                                        ),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                      Row(
                                                        children: [
                                                          const Flexible(
                                                              child: Text(
                                                                  "Total Payout:",
                                                                  style: TextStyle(
                                                                      fontSize:
                                                                          14,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .bold))),
                                                          const SizedBox(
                                                            width: 15,
                                                          ),
                                                          Flexible(
                                                              flex: 2,
                                                              child: Padding(
                                                                padding:
                                                                    const EdgeInsets
                                                                        .all(
                                                                        8.0),
                                                                child: Text(
                                                                    '${report.totalPayout} ' +
                                                                        report
                                                                            .currency,
                                                                    style: const TextStyle(
                                                                        fontSize:
                                                                            14,
                                                                        fontWeight:
                                                                            FontWeight.bold)),
                                                              )),
                                                        ],
                                                      ),
                                                      const SizedBox(
                                                        height: 20,
                                                      ),
                                                    ],
                                                  ),
                                                )
                                              ])),
                                              Card(
                                                child: Column(children: [
                                                  ListTile(
                                                    tileColor: Colors.grey[200],
                                                    title: const Text(
                                                      "Bank account",
                                                      style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.bold),
                                                    ),
                                                  ),
                                                  Container(
                                                    padding:
                                                        const EdgeInsets.all(5),
                                                    child: Column(
                                                      children: [
                                                        Row(
                                                          children: [
                                                            label("IBAN:"),
                                                            const SizedBox(
                                                              width: 10,
                                                            ),
                                                            methods.element(
                                                                report.iban),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            label("BIC:"),
                                                            const SizedBox(
                                                              width: 20,
                                                            ),
                                                            methods.element(
                                                                report.bic),
                                                          ],
                                                        ),
                                                        Row(
                                                          children: [
                                                            label("Owner:"),
                                                            const SizedBox(
                                                              width: 0,
                                                            ),
                                                            methods.element(
                                                                report
                                                                    .bankOwner),
                                                          ],
                                                        )
                                                      ],
                                                    ),
                                                  ),
                                                ]),
                                              ),
                                            ],
                                          ),
                                        );
                                      }
                                    })
                              ])))));
        });
  }
}
