import 'package:flutter/material.dart';
import 'package:chicaparts_partner/api/api_accommodation.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/widgets/booking/calender.dart';

class BookingAccommodationWidget extends StatefulWidget {
  const BookingAccommodationWidget({super.key, required this.user});
  final User user;
  @override
  State<BookingAccommodationWidget> createState() =>
      _BookingAccommodationWidgetState();
}

class _BookingAccommodationWidgetState
    extends State<BookingAccommodationWidget> {
  final apiAcc = ApiAccommodation();

  Future<dynamic> callApiListAcc(partner) {
    return apiAcc.getAccommodations(partner);
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: FutureBuilder(
          future: callApiListAcc(widget.user.thirdParty["id"]),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.data == null) {
              return Container(
                child: const Center(
                  child: Text("Loading..."),
                ),
              );
            } else {
              return Container(
                margin: const EdgeInsets.only(top: 5),
                child: Center(
                  child: Wrap(
                    children: [
                      for (var i = 0;
                          i < snapshot.data["accommodations"].length;
                          i++)
                        card(snapshot.data["accommodations"][i], widget.user),
                    ],
                  ),
                ),
              );
            }
          }),
    );
  }

  Widget card(accommodation, user) {
    return Card(
      shadowColor: Colors.black,
      color: Colors.grey[350],
      child: SizedBox(
        width: 155,
        height: 170,
        child: Container(
          margin: const EdgeInsets.all(20),
          child: Column(
            children: [
              CircleAvatar(
                  backgroundColor: accommodation['status'] == 'exploiting'
                      ? const Color(0xFF05A8CF)
                      : const Color.fromARGB(255, 132, 146, 150),
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.home) //CircleAvatar
                  ), //CircleAvatar
              const SizedBox(
                height: 1,
              ), //SizedBox
              RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                    text: accommodation['internal_name'],
                    style: const TextStyle(
                        fontSize: 12,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat')), //Textstyle
              ), //Text
              const SizedBox(
                height: 5,
              ),
              RichText(
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                    text: accommodation['external_name'],
                    style: const TextStyle(
                        fontSize: 10,
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat')), //Textstyle
              ), ////SizedBox//Text
              const SizedBox(
                height: 5,
              ), //SizedBox
              SizedBox(
                width: 120,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                            builder: (_) => CalendarWidget(
                                  user: user,
                                  accommodation: accommodation['internal_name'],
                                )));
                  },
                  style: ButtonStyle(
                      backgroundColor: WidgetStateProperty.all<Color>(
                          accommodation['status'] == 'exploiting'
                              ? const Color(0xFF05A8CF)
                              : const Color.fromARGB(255, 132, 146, 150))),
                  child: Container(
                    child: const Row(
                      children: [
                        Icon(
                          Icons.touch_app,
                          color: Colors.white,
                          size: 14,
                        ),
                        Text(
                          'View bookings',
                          style: TextStyle(
                              fontSize: 9,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Montserrat'),
                        ),
                      ],
                    ), //Row
                  ), //Padding
                ), //RaisedButton
              ) //SizedBox
            ],
          ), //Column
        ), //Padding
      ), //SizedBox
    );
  }
}
