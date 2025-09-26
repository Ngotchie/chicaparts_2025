import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chicaparts_partner/api/api_finance.dart';
import 'package:chicaparts_partner/models/model_finance.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/services/api.dart';
import 'package:chicaparts_partner/widgets/menu/bottomMenu.dart';
import 'package:syncfusion_flutter_pdf/pdf.dart';
// import 'package:open_file/open_file.dart';
import 'package:open_filex/open_filex.dart';

import 'package:http/http.dart' show get;
import 'package:path_provider/path_provider.dart';

class YearlyPayoutWidget extends StatefulWidget {
  const YearlyPayoutWidget({super.key, required this.user});
  final User user;
  @override
  State<YearlyPayoutWidget> createState() => _YearlyPayoutWidgetState();
}

class _YearlyPayoutWidgetState extends State<YearlyPayoutWidget> {
  TextEditingController searchController = TextEditingController();
  String filter = "";
  bool isLoading = false;

  @override
  void initState() {
    searchController.addListener(() {
      setState(() {
        filter = searchController.text;
      });
    });
    super.initState();
  }

  int _seletedPage = 0;
  bool change = false;
  late PageController _pageController;
  // final ScrollController _scrollController = ScrollController();
  void _changePage(int pageNum) {
    setState(() {
      _seletedPage = pageNum;
      _pageController.animateToPage(pageNum,
          duration: const Duration(microseconds: 1000),
          curve: Curves.fastLinearToSlowEaseIn);
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> loadPdfFromUrl(contract, year) async {
    ApiUrl url = ApiUrl();
    String apiUrl = url.getUrl();
    var link =
        '${'${apiUrl}tools/document/download?document=DOC00006&object=$contract&year=' + year}&save=true';
    var response = await get(Uri.parse(link));
    var data = response.bodyBytes;
    //Create a new PDF document
    PdfDocument document = PdfDocument(inputBytes: data);
    //Save and launch the document
    final List<int> bytes = document.save() as List<int>;
    //Dispose the document.
    document.dispose();

    final Directory directory = await getApplicationDocumentsDirectory();
    final String path = directory.path;
    final File file = File('$path/Flutter_Succinctly.pdf');
    await file.writeAsBytes(bytes, flush: true);
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    //Open the fine.
    OpenFilex.open('$path/Flutter_Succinctly.pdf');
  }

  @override
  Widget build(BuildContext context) {
    final apiFinance = ApiFinance();
    Future<dynamic> getYearlyPayouts(partner, filter) {
      return apiFinance.getYearlyPayouts(partner, filter);
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
          "YEARLY PAYOUT REPORTS",
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
                    future: getYearlyPayouts(widget.user.id, filter),
                    builder: (context, AsyncSnapshot snap) {
                      List<String> accommodations = [];
                      List<String> years = [];
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
                            values.forEach((item) {
                              if (!years.contains(item['year'])) {
                                years.add(item['year']);
                              }
                            });
                          });
                        }
                        years.sort((a, b) => a.compareTo(b));
                        _pageController =
                            PageController(initialPage: years.length - 1);
                        if (!change) _seletedPage = years.length - 1;
                        return snap.data.length > 0
                            ? SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.8,
                                child: Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 1),
                                      child: SingleChildScrollView(
                                        scrollDirection: Axis.horizontal,
                                        child: Row(
                                          children: [
                                            for (int i = 0;
                                                i < years.length;
                                                i++)
                                              TabButton(
                                                title: years[i],
                                                pageNumber: i,
                                                selectedPage: _seletedPage,
                                                onPressed: () {
                                                  change = true;
                                                  _changePage(i);
                                                },
                                              ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Container(
                                      height:
                                          MediaQuery.of(context).size.height *
                                              0.7,
                                      constraints: BoxConstraints(
                                          minHeight: 100,
                                          minWidth: double.infinity,
                                          maxHeight: MediaQuery.of(context)
                                              .size
                                              .height),
                                      child: PageView(
                                        onPageChanged: (int page) {
                                          setState(() {
                                            _seletedPage = page;
                                          });
                                        },
                                        controller: _pageController,
                                        scrollDirection: Axis.horizontal,
                                        children: [
                                          for (var i = 0; i < years.length; i++)
                                            yearlyReports(
                                                context,
                                                accommodations,
                                                snap.data,
                                                years[i]),
                                        ],
                                      ),
                                    ),
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

  Widget yearlyReports(context, accommodations, data, year) {
    return ListView.builder(
        physics: const BouncingScrollPhysics(),
        shrinkWrap: true,
        scrollDirection: Axis.vertical,
        itemCount: accommodations.length,
        itemBuilder: (context, i) {
          var payouts =
              data[accommodations[i]].where((i) => i['year'] == year).toList();
          return payouts.length > 0
              ? ExpansionTile(
                  leading: TextButton(
                      onPressed: () async {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Load data...'),
                            duration: Duration(seconds: 30),
                          ),
                        );
                        loadPdfFromUrl(payouts[0]["contract_id"], year);
                      },
                      child: const Icon(
                        Icons.download,
                        size: 20,
                        color: Colors.black,
                      )),
                  title: Text(accommodations[i]),
                  children: [
                    ListView.builder(
                        physics: const NeverScrollableScrollPhysics(),
                        shrinkWrap: true,
                        scrollDirection: Axis.vertical,
                        itemCount: payouts.length,
                        itemBuilder: (context, j) {
                          return payouts[j]['year'] == year
                              ? GestureDetector(
                                  onTap: () {},
                                  child: Container(
                                    height: 150,
                                    decoration: BoxDecoration(
                                      border: Border.all(
                                          color: Colors.grey, width: 0.5),
                                      borderRadius: const BorderRadius.all(
                                          Radius.circular(
                                              5.0) //         <--- border radius here
                                          ),
                                    ),
                                    margin: const EdgeInsets.all(8),
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Flexible(
                                            child: Row(children: [
                                          Text(
                                            "${"Rental income " + payouts[j]['offer']} ${DateFormat.MMMM('en_US').format(DateTime.parse(payouts[j]['period_start']))}",
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        ])),
                                        const SizedBox(height: 15),
                                        Flexible(
                                            child: Row(children: [
                                          const Text("Amount: "),
                                          Text(
                                            "${payouts[j]['amount']} " +
                                                payouts[j]['code'],
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        ])),
                                        const SizedBox(height: 15),
                                        Flexible(
                                            child: Row(
                                          children: [
                                            const Text("Payment date: "),
                                            Text(
                                              DateFormat('dd.MM.yyyy').format(
                                                  DateTime.parse(payouts[j]
                                                      ['payout_date'])),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.bold),
                                            ),
                                          ],
                                        )),
                                        const SizedBox(height: 15),
                                        const Flexible(
                                            child: Row(children: [
                                          Text("Payment method: "),
                                          Text(
                                            "Bank transfert",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          )
                                        ])),
                                      ],
                                    ),
                                  ))
                              : Container();
                        })
                  ],
                )
              : Container();
        });
  }

  // Future<Uint8List> _generatePdf(
  //     PdfPageFormat format, dynamic payouts, data) async {
  //   final pdf = pw.Document(version: PdfVersion.pdf_1_5, compress: true);
  //   final font = await PdfGoogleFonts.nunitoExtraLight();
  //   var assetImage = pw.MemoryImage(
  //     (await rootBundle.load("assets/images/logo-chicaparts.png"))
  //         .buffer
  //         .asUint8List(),
  //   );
  //   num total = 0;
  //   for (var item in payouts) total = total + item["amount"];
  //   pdf.addPage(
  //     pw.Page(
  //       pageFormat: format,
  //       build: (context) {
  //         String firstName =
  //             data["first_name"] != null ? data["first_name"] : "";
  //         String lastName = data["last_name"] != null ? data["last_name"] : "";
  //         String businessName =
  //             data["business_name"] != null ? data["business_name"] : "";

  //         String a1 = data["address1"] != null ? data["address1"] : "";
  //         String a2 = data["address2"] != null ? data["address2"] : "";
  //         String a3 = data["address3"] != null ? data["address3"] : "";

  //         String ad1 = data["p_a1"] != null ? data["p_a1"] : "";
  //         String ad2 = data["p_a2"] != null ? data["p_a2"] : "";
  //         String ad3 = data["p_a3"] != null ? data["p_a3"] : "";

  //         String partner = firstName + " " + lastName + "" + businessName;
  //         String accommodationAddress = a1 + ", " + a2 + ", " + a3;
  //         String partnerAddress = ad1 + ", " + ad2 + ", " + ad3;

  //         String email = data["email"] != null ? data["email"] : "";
  //         String phone = data["mobile_phone_number"];
  //         String year = DateFormat('yyyy')
  //             .format(DateTime.parse(payouts[0]['period_start']));

  //         String bankName = data["bank_name"] != null ? data["bank_name"] : "";
  //         String bankOwner =
  //             data["bank_owner"] != null ? data["bank_owner"] : "";
  //         String iban = data["iban"] != null ? data["iban"] : "";
  //         String bic = data["bic"] != null ? data["bic"] : "";

  //         return pw.Container(
  //             width: double.infinity,
  //             padding: pw.EdgeInsets.all(5),
  //             decoration: pw.BoxDecoration(
  //               border: pw.Border.all(
  //                   width: 0.5), //         <--- border radius here
  //             ),
  //             child: pw.Column(
  //               children: [
  //                 pw.Row(children: [
  //                   pw.Container(
  //                       child: pw.Column(
  //                           crossAxisAlignment: pw.CrossAxisAlignment.start,
  //                           children: [
  //                         pw.Container(height: 50, child: pw.Image(assetImage)),
  //                         pw.Text("1 Boulevard de la Commune de Paris",
  //                             style: pw.TextStyle(fontSize: 10)),
  //                         pw.Text("93200 Saint-Denis",
  //                             style: pw.TextStyle(fontSize: 10)),
  //                         pw.Text("R.C.S. Bobigny 831 023 775",
  //                             style: pw.TextStyle(fontSize: 10)),
  //                         pw.Text("N°TVA : FR35831023775",
  //                             style: pw.TextStyle(fontSize: 10)),
  //                         pw.Text("Tél : +33175476118",
  //                             style: pw.TextStyle(fontSize: 10)),
  //                         pw.Text("Email: contact@chic-aparts.com",
  //                             style: pw.TextStyle(fontSize: 10))
  //                       ])),
  //                   pw.Spacer(),
  //                   pw.Container(
  //                       child: pw.Column(
  //                           crossAxisAlignment: pw.CrossAxisAlignment.end,
  //                           children: [
  //                         pw.Text(partner,
  //                             style: pw.TextStyle(
  //                                 fontSize: 15,
  //                                 fontWeight: pw.FontWeight.bold)),
  //                         pw.Text("Phone: " + phone,
  //                             style: pw.TextStyle(fontSize: 10)),
  //                         pw.Text(partnerAddress,
  //                             style: pw.TextStyle(fontSize: 10)),
  //                         pw.Text("Email: " + email,
  //                             style: pw.TextStyle(fontSize: 10))
  //                       ])),
  //                 ]),
  //                 pw.SizedBox(
  //                   height: 20,
  //                 ),
  //                 pw.Text("Chicaparts annual payout report",
  //                     style: pw.TextStyle(
  //                         fontSize: 15, fontWeight: pw.FontWeight.bold)),
  //                 pw.SizedBox(
  //                   height: 20,
  //                 ),
  //                 pw.Row(children: [
  //                   pw.Container(
  //                       width: 40,
  //                       child: pw.Column(
  //                           crossAxisAlignment: pw.CrossAxisAlignment.start,
  //                           children: [
  //                             pw.Row(children: [
  //                               pw.Text("Accommodation: ",
  //                                   style: pw.TextStyle(
  //                                       fontSize: 10,
  //                                       fontWeight: pw.FontWeight.bold)),
  //                               pw.Text(
  //                                   data["acc_ref"] +
  //                                       " | " +
  //                                       data["external_name"],
  //                                   style: pw.TextStyle(fontSize: 10))
  //                             ]),
  //                             pw.Row(children: [
  //                               pw.Text("Description: ",
  //                                   style: pw.TextStyle(
  //                                       fontSize: 10,
  //                                       fontWeight: pw.FontWeight.bold)),
  //                               pw.Text(
  //                                   data["description"] != null
  //                                       ? data["description"]
  //                                       : "",
  //                                   style: pw.TextStyle(fontSize: 10))
  //                             ]),
  //                             pw.Row(children: [
  //                               pw.Text("Address: ",
  //                                   style: pw.TextStyle(
  //                                       fontSize: 10,
  //                                       fontWeight: pw.FontWeight.bold)),
  //                               pw.Text(accommodationAddress,
  //                                   style: pw.TextStyle(fontSize: 10)),
  //                             ]),
  //                           ])),
  //                   pw.Spacer(),
  //                   pw.Column(
  //                       crossAxisAlignment: pw.CrossAxisAlignment.end,
  //                       children: [
  //                         pw.Row(children: [
  //                           pw.Text("Type: ",
  //                               style: pw.TextStyle(
  //                                   fontSize: 10,
  //                                   fontWeight: pw.FontWeight.bold)),
  //                           pw.Text(
  //                               data["type_accommodation"] != null
  //                                   ? data["type_accommodation"]
  //                                   : "",
  //                               style: pw.TextStyle(fontSize: 10))
  //                         ]),
  //                         pw.Row(children: [
  //                           pw.Text("Contract ref: ",
  //                               style: pw.TextStyle(
  //                                   fontSize: 10,
  //                                   fontWeight: pw.FontWeight.bold)),
  //                           pw.Text(data["contract_ref"],
  //                               style: pw.TextStyle(fontSize: 10))
  //                         ]),
  //                         pw.Row(children: [
  //                           pw.Text("Period: ",
  //                               style: pw.TextStyle(
  //                                   fontSize: 10,
  //                                   fontWeight: pw.FontWeight.bold)),
  //                           pw.Text("01.01." + year + " - " + "31.12." + year,
  //                               style: pw.TextStyle(fontSize: 10))
  //                         ])
  //                       ])
  //                 ]),
  //                 pw.SizedBox(
  //                   height: 20,
  //                 ),
  //                 pw.Table(
  //                     border: pw.TableBorder.all(
  //                         style: pw.BorderStyle.solid, width: 2),
  //                     children: [
  //                       pw.TableRow(children: [
  //                         pw.Column(children: [
  //                           pw.Container(
  //                               padding: pw.EdgeInsets.all(5),
  //                               child: pw.Text('Object',
  //                                   style: pw.TextStyle(
  //                                       fontSize: 10,
  //                                       fontWeight: pw.FontWeight.bold)))
  //                         ]),
  //                         pw.Column(children: [
  //                           pw.Container(
  //                               padding: pw.EdgeInsets.all(5),
  //                               child: pw.Text('Payment date',
  //                                   style: pw.TextStyle(
  //                                       fontSize: 10,
  //                                       fontWeight: pw.FontWeight.bold)))
  //                         ]),
  //                         pw.Column(children: [
  //                           pw.Container(
  //                               padding: pw.EdgeInsets.all(5),
  //                               child: pw.Text('Payment method',
  //                                   style: pw.TextStyle(
  //                                       fontSize: 10,
  //                                       fontWeight: pw.FontWeight.bold)))
  //                         ]),
  //                         pw.Column(children: [
  //                           pw.Container(
  //                               padding: pw.EdgeInsets.all(5),
  //                               child: pw.Text(
  //                                   'Amount(' + payouts[0]['code'] + ')',
  //                                   style: pw.TextStyle(
  //                                       fontSize: 10,
  //                                       fontWeight: pw.FontWeight.bold)))
  //                         ]),
  //                       ]),
  //                       for (var item in payouts)
  //                         pw.TableRow(children: [
  //                           pw.Column(
  //                               crossAxisAlignment: pw.CrossAxisAlignment.start,
  //                               children: [
  //                                 pw.Container(
  //                                     padding: pw.EdgeInsets.all(5),
  //                                     child: pw.Text(
  //                                         "Rental income " +
  //                                             item['offer'] +
  //                                             " " +
  //                                             DateFormat.MMMM('en_US').format(
  //                                                 DateTime.parse(
  //                                                     item['period_start'])),
  //                                         style: pw.TextStyle(fontSize: 10)))
  //                               ]),
  //                           pw.Column(children: [
  //                             pw.Container(
  //                                 padding: pw.EdgeInsets.all(5),
  //                                 child: pw.Text(
  //                                     DateFormat('dd.MM.yyyy').format(
  //                                         DateTime.parse(item['payout_date'])),
  //                                     style: pw.TextStyle(fontSize: 10)))
  //                           ]),
  //                           pw.Column(children: [
  //                             pw.Container(
  //                                 padding: pw.EdgeInsets.all(5),
  //                                 child: pw.Text("Bank transfert",
  //                                     style: pw.TextStyle(fontSize: 10)))
  //                           ]),
  //                           pw.Column(
  //                               crossAxisAlignment: pw.CrossAxisAlignment.end,
  //                               children: [
  //                                 pw.Container(
  //                                     padding: pw.EdgeInsets.all(5),
  //                                     child: pw.Text(item["amount"].toString(),
  //                                         style: pw.TextStyle(fontSize: 10)))
  //                               ]),
  //                         ])
  //                     ]),
  //                 pw.SizedBox(
  //                   height: 25,
  //                 ),
  //                 pw.Text(
  //                     "Total: " + total.toString() + " " + payouts[0]['code'],
  //                     style: pw.TextStyle(
  //                         fontSize: 15, fontWeight: pw.FontWeight.bold)),
  //                 pw.SizedBox(
  //                   height: 25,
  //                 ),
  //                 pw.Container(
  //                   decoration: pw.BoxDecoration(
  //                     border: pw.Border.all(
  //                         width: 0.5), //         <--- border radius here
  //                   ),
  //                   padding: pw.EdgeInsets.all(5),
  //                   child: pw.Column(
  //                       crossAxisAlignment: pw.CrossAxisAlignment.start,
  //                       children: [
  //                         pw.Text("Titulaire: " + bankOwner,
  //                             style: pw.TextStyle(fontSize: 10)),
  //                         pw.Text("Banque:    " + bankName,
  //                             style: pw.TextStyle(fontSize: 10)),
  //                         pw.Text("IBAN:      " + iban,
  //                             style: pw.TextStyle(fontSize: 10)),
  //                         pw.Text("BIC:       " + bic,
  //                             style: pw.TextStyle(fontSize: 10)),
  //                       ]),
  //                 ),
  //                 pw.SizedBox(
  //                   height: 30,
  //                 ),
  //                 pw.Text(
  //                     "Chicaparts est une marque SD Season, SAS au capital de 10 000 euro immatriculée 831 023 775 RCS Bobigny",
  //                     style: pw.TextStyle(fontSize: 8))
  //               ],
  //             ));
  //       },
  //     ),
  //   );
  //   return pdf.save();
  // }
}
