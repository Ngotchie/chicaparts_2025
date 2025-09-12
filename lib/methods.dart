import 'package:datetime_picker_formfield/datetime_picker_formfield.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:chicaparts_partner/widgets/booking/myBookings.dart';
import 'package:url_launcher/url_launcher.dart';

import 'api/api_accommodation.dart';
import 'api/api_booking.dart';

class Methods {
  Widget label(label) {
    return Flexible(
        child: Text(
      label,
      style: const TextStyle(fontSize: 12, color: Colors.grey),
    ));
  }

  Widget element(elt) {
    return Flexible(
        flex: 2,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            elt,
          ),
        ));
  }

  Widget elementText(elt) {
    return Flexible(
        flex: 2,
        child: Padding(padding: const EdgeInsets.all(8.0), child: elt));
  }

  Widget elementHyperLink(elt) {
    return Flexible(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: RichText(
          text: TextSpan(
            text: elt.toString(),
            style: const TextStyle(color: Colors.blue),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                final url = Uri.encodeFull(elt);

                await launch(
                  url,
                  forceSafariVC: false,
                );
              },
          ),
        ),
      ),
    );
  }

  Widget labelFlex(label) {
    return Flexible(
        flex: 2,
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ));
  }

  Widget elementCheck(label, controller, context) {
    final ButtonStyle flatButtonStyle = TextButton.styleFrom(
      backgroundColor: Colors.black87,
      minimumSize: const Size(5, 5),
      // padding: EdgeInsets.symmetric(horizontal: 1.0),
      // shape: const RoundedRectangleBorder(
      //   borderRadius: BorderRadius.all(Radius.circular(2.0)),
      // ),
    );
    return Flexible(
        child: Container(
      padding: const EdgeInsets.fromLTRB(0, 5, 0, 15),
      child: TextFormField(
        obscureText: false,
        //style: style,
        readOnly: true,
        minLines: 1,
        maxLines: 20,
        keyboardType: TextInputType.multiline,
        controller: controller,
        decoration: InputDecoration(
          icon: SizedBox(
              width: 20,
              child: TextButton(
                  style: flatButtonStyle,
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: controller.text))
                        .then((value) {
                      //only if ->
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Copied')),
                      );
                    });
                  },
                  child: const Icon(
                    Icons.copy,
                    size: 20,
                  )
                  // Column(
                  //   children: [Icon(Icons.copy), Text("Copy")],
                  // ),
                  )),
          // prefixIconConstraints: BoxConstraints(maxHeight: 50, maxWidth: 50),
          isCollapsed: true,
          contentPadding: const EdgeInsets.fromLTRB(5, 20, 5, 10),
          labelText: label,
          labelStyle:
              const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(15)),
        ),
      ),
    ));
  }

  Widget elementAdresseMap(elt) {
    return Flexible(
      flex: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: RichText(
          text: TextSpan(
            text: elt,
            style: const TextStyle(color: Colors.blue),
            recognizer: TapGestureRecognizer()
              ..onTap = () async {
                String googleUrl =
                    "https://www.google.com/maps/search/?api=1&query=$elt";
                print(googleUrl);
                final url = Uri.encodeFull(googleUrl);
                await launch(
                  url,
                  forceSafariVC: true,
                );
              },
          ),
        ),
      ),
    );
  }

  String toAvatar(String input) {
    List<String> splitStr = input.split(' ');
    if (splitStr.length >= 2) {
      for (int i = 0; i < 2; i++) {
        splitStr[i] = splitStr[i].substring(0, 1);
      }

      splitStr.removeRange(2, splitStr.length);
    }
    if (splitStr.length == 1) {
      try {
        splitStr[0] = splitStr[0].substring(0, 2);
      } catch (e) {
        splitStr[0] = splitStr[0].substring(0, 1);
      }
    }

    if (splitStr.isEmpty) {
      splitStr[0] = "P";
    }

    final output = splitStr.join('');

    return output;
  }

  showBooking(context, book, edit, partner) {
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
                  padding: const EdgeInsets.all(15),
                  width: MediaQuery.of(context).size.width * 0.8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          ExpansionTile(
                            title: const Text("Channel Reference",
                                style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold)),
                            children: [
                              Row(children: <Widget>[
                                methods.label("Referer: "),
                                const SizedBox(
                                  width: 20,
                                ),
                                methods.element(book.referer),
                                const SizedBox(
                                  height: 10,
                                ),
                              ]),
                              Row(children: <Widget>[
                                methods.label("Booking ID: "),
                                methods.element(book.bookId.toString()),
                                const SizedBox(
                                  height: 10,
                                ),
                              ]),
                            ],
                          ),
                          ExpansionTile(
                            title: const Text("Booking Details",
                                style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold)),
                            children: [
                              Row(children: <Widget>[
                                methods.label("Booked At: "),
                                const SizedBox(
                                  width: 0,
                                ),
                                methods.element(DateFormat('dd-MM-yyyy')
                                    .format(DateTime.parse(book.bookedAt))),
                                const SizedBox(
                                  height: 10,
                                ),
                              ]),
                              Row(children: <Widget>[
                                methods.label("Check-In: "),
                                const SizedBox(
                                  width: 10,
                                ),
                                methods.element(DateFormat('dd-MM-yyyy')
                                    .format(DateTime.parse(book.firstNight))),
                                const SizedBox(
                                  height: 10,
                                ),
                              ]),
                              Row(children: <Widget>[
                                methods.label("Check-Out: "),
                                const SizedBox(
                                  width: 0,
                                ),
                                methods.element(DateFormat('dd-MM-yyyy')
                                    .format(DateTime.parse(book.lastNight))),
                                const SizedBox(
                                  height: 10,
                                ),
                              ]),
                              if (edit == 0)
                                Row(children: <Widget>[
                                  methods.label("Adults: "),
                                  const SizedBox(
                                    width: 30,
                                  ),
                                  methods.element(book.adult.toString()),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ]),
                              if (edit == 0)
                                Row(children: <Widget>[
                                  methods.label("Children: "),
                                  const SizedBox(
                                    width: 15,
                                  ),
                                  methods.element(book.child.toString()),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ]),
                              if (edit == 0)
                                Row(children: <Widget>[
                                  methods.label("Arrival Time: "),
                                  const SizedBox(
                                    width: 0,
                                  ),
                                  methods.element(book.arriveTime),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ]),
                              if (edit == 1)
                                Row(children: <Widget>[
                                  methods.label("Booking Notes: "),
                                  const SizedBox(
                                    width: 0,
                                  ),
                                  methods.elementText(book.note),
                                  const SizedBox(
                                    height: 10,
                                  ),
                                ]),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      ((edit == 1) &&
                                  (DateTime.now()
                                          .difference(
                                              DateTime.parse(book.lastNight))
                                          .inDays <
                                      0)) &&
                              (book.validationStatus != "accepted")
                          ? Container(
                              margin: const EdgeInsets.only(right: 10, top: 10),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(20)),
                              child: TextButton(
                                style: ButtonStyle(
                                  backgroundColor:
                                      WidgetStateProperty.all<Color>(
                                          Colors.green),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  viewEditBlockDate(context, book, partner);
                                },
                                child: const Text(
                                  ' Edit ',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 12),
                                ),
                              ),
                            )
                          : Container(),
                    ],
                  ),
                ),
              ),
            ),
          );
        });
  }

  viewEditBlockDate(context, book, partner) {
    ApiAccommodation apiAcc = ApiAccommodation();
    Future<dynamic> getProperties(partner) {
      return apiAcc.getAccommodations(partner);
    }

    final format = DateFormat("yyyy-MM-dd");

    var formkey = GlobalKey<FormState>();
    final bookedAtController = TextEditingController();
    bookedAtController.text = DateFormat('yyyy-MM-dd')
        .format(DateTime.parse(book.bookedAt))
        .toString();
    final startController = TextEditingController();
    startController.text = DateFormat('yyyy-MM-dd')
        .format(DateTime.parse(book.firstNight))
        .toString();
    final endController = TextEditingController();
    endController.text = DateFormat('yyyy-MM-dd')
        .format(DateTime.parse(book.lastNight))
        .toString();
    final noteController = TextEditingController();
    noteController.text = book.note.data;

    var listStatus = ['Black'];
    int? propertyValue;
    String statusValue = "Black";
    return showDialog(
        context: context,
        builder: (context) => AlertDialog(
              contentPadding: const EdgeInsets.all(6.0),
              title: Container(
                color: const Color(0xfffff37540),
                child: const Center(
                  child: Text(
                    "Edit Block Date",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
              content: Center(
                child: Material(
                  child: SingleChildScrollView(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white,
                      ),
                      padding: const EdgeInsets.all(15),
                      width: MediaQuery.of(context).size.width * 1.2,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              FutureBuilder(
                                  future: getProperties(partner),
                                  builder: (context, AsyncSnapshot snap) {
                                    if (snap.data == null) {
                                      return Container(
                                        child: const Center(
                                          child: Text("Loading..."),
                                        ),
                                      );
                                    } else {
                                      var data = snap.data["accommodations"];
                                      var properties = [];
                                      for (var item in data) {
                                        if (item["propId"] != null) {
                                          Property pt = Property(
                                              item["id"],
                                              item["internal_name"],
                                              item["ref"],
                                              item["propId"],
                                              item["roomId"]);
                                          properties.add(pt);
                                        }
                                        if ((book.roomId == item["roomId"]) &&
                                            book.propId == item["propId"]) {
                                          propertyValue = item["id"];
                                        }
                                      }
                                      final propertyField = IgnorePointer(
                                          ignoring: true,
                                          child: DropdownButtonFormField(
                                            onChanged: (value) => {},
                                            isExpanded: true,
                                            decoration: InputDecoration(
                                              labelText: "Choose property...",
                                              contentPadding:
                                                  const EdgeInsets.all(10.0),
                                              border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15.0)),
                                            ),
                                            value: propertyValue,
                                            items: properties
                                                .map<DropdownMenuItem<int>>(
                                                    (item) {
                                              return DropdownMenuItem(
                                                value: item.id,
                                                child: Text(item.ref +
                                                    "-" +
                                                    item.internalName),
                                              );
                                            }).toList(),
                                          ));
                                      final bookedAtFormField = IgnorePointer(
                                          ignoring: true,
                                          child: DateTimeField(
                                            readOnly: true,
                                            format: format,
                                            controller: bookedAtController,
                                            decoration: InputDecoration(
                                              labelText: "Booked at...",
                                              contentPadding:
                                                  const EdgeInsets.all(10),
                                              border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15)),
                                            ),
                                            onShowPicker:
                                                (context, currentValue) {
                                              return showDatePicker(
                                                  context: context,
                                                  currentDate: DateTime.now(),
                                                  firstDate: DateTime(2022),
                                                  initialDate: currentValue ??
                                                      DateTime.now(),
                                                  lastDate: DateTime(2100));
                                            },
                                          ));
                                      final startFormField = DateTimeField(
                                        format: format,
                                        controller: startController,
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.all(10),
                                          labelText: "Choose start date...",
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15)),
                                        ),
                                        onShowPicker: (context, currentValue) {
                                          return showDatePicker(
                                              context: context,
                                              firstDate: DateTime(2022),
                                              initialDate: currentValue ??
                                                  DateTime.now(),
                                              lastDate: DateTime(2100));
                                        },
                                      );
                                      final endFormField = DateTimeField(
                                        format: format,
                                        controller: endController,
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.all(10),
                                          labelText: "Choose end date...",
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15)),
                                        ),
                                        onShowPicker: (context, currentValue) {
                                          return showDatePicker(
                                              context: context,
                                              firstDate: DateTime(1900),
                                              initialDate: currentValue ??
                                                  DateTime.now(),
                                              lastDate: DateTime(2100));
                                        },
                                      );

                                      final statusField = IgnorePointer(
                                          ignoring: true,
                                          child: DropdownButtonFormField(
                                            onChanged: (value) => {},
                                            decoration: InputDecoration(
                                              labelText: "Status...",
                                              contentPadding:
                                                  const EdgeInsets.all(10.0),
                                              border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          15.0)),
                                            ),
                                            value: statusValue,
                                            items: listStatus
                                                .map<DropdownMenuItem<String>>(
                                                    (String value) {
                                              return DropdownMenuItem<String>(
                                                value: value,
                                                child: Text(value),
                                              );
                                            }).toList(),
                                          ));
                                      final noteField = TextFormField(
                                        minLines: 3,
                                        maxLines: 8,
                                        keyboardType: TextInputType.multiline,
                                        controller: noteController,
                                        decoration: InputDecoration(
                                          contentPadding:
                                              const EdgeInsets.fromLTRB(
                                                  10, 20, 10, 10),
                                          labelText: "Booking note...",
                                          border: OutlineInputBorder(
                                              borderRadius:
                                                  BorderRadius.circular(15)),
                                        ),
                                        validator: null,
                                      );
                                      return Form(
                                        key: formkey,
                                        child: Column(
                                          children: [
                                            propertyField,
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            bookedAtFormField,
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            startFormField,
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            endFormField,
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            statusField,
                                            const SizedBox(
                                              height: 20,
                                            ),
                                            noteField,
                                          ],
                                        ),
                                      );
                                    }
                                  })
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              actions: <Widget>[
                // ignore: deprecated_member_use
                Container(
                  margin: const EdgeInsets.only(right: 10, top: 10),
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(20)),
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                          const Color(0xfffff37540)),
                    ),
                    onPressed: () {
                      if (formkey.currentState!.validate()) {
                        var formData = <String, dynamic>{
                          'firstNight': startController.text,
                          'lastNight': endController.text,
                          'notes': noteController.text,
                          'bookId': 0,
                          'propId': book.propId,
                          'roomId': book.roomId,
                          'unitId': 1,
                          'roomQty': 1,
                          'status': 4,
                          'substatus': 0,
                          'numAdult': 0,
                          'numChild': 0,
                          'guestTitle': 'Partenaire',
                          'guestFirstName': '',
                          'guestName': 'Partenaire',
                          'guestEmail': '',
                          'guestPhone': '',
                          'guestMobile': '',
                          'guestFax': '',
                          'guestCompany': '',
                          'guestAddress': '',
                          'guestCity': '',
                          'guestState': '',
                          'guestPostcode': '',
                          'guestCountry': '',
                          'guestArrivalTime': '',
                          'guestVoucher': '',
                          'guestComments': '',
                          'message': '',
                          'statusCode': 0,
                          'price': 0,
                          'deposit': 0,
                          'tax': 0,
                          'commission': 0,
                          'rateDescription': '',
                          'offerId': 0,
                          'referer': 'Partner',
                          'reference': '',
                          'apiSource': '0',
                          'apiMessage': '',
                          'apiReference': '',
                          'stripeToken': '',
                          'bookingTime': bookedAtController.text,
                          'modified': '',
                          'booking_fees': 0,
                          'transaction_fees': 0,
                          'currency_id': '47',
                          'converted_price': 0,
                          'validation_status': 'pending',
                          'cleaning_fees_partner': 0,
                          'seller': 'partner',
                          'payment_handler': 'partner',
                        };

                        editBlockDate(formData, context, book.id);
                      }
                    },
                    child: const Text(
                      ' Confirm ',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.only(right: 10, top: 10),
                  decoration:
                      BoxDecoration(borderRadius: BorderRadius.circular(20)),
                  child: TextButton(
                    style: ButtonStyle(
                      backgroundColor:
                          WidgetStateProperty.all<Color>(Colors.grey),
                    ),
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    child: const Text(
                      ' Cancel ',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ));
  }

  editBlockDate(formData, context, id) async {
    ApiBooking apiBooking = ApiBooking();
    var resp = await apiBooking.editBlockDate(formData, id);
    if (resp == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Operation done succefully')),
      );
      Navigator.pushNamed(context, '/booking');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error during this operation')),
      );
    }
  }

  String allWordsCapitilize(String str) {
    return str.toLowerCase().split(' ').map((word) {
      String leftText = (word.length > 1) ? word.substring(1, word.length) : '';
      return word[0].toUpperCase() + leftText;
    }).join(' ');
  }
}
