import 'package:flutter/material.dart';
import 'package:chicaparts_partner/api/api_booking.dart';
import 'package:chicaparts_partner/models/model_booking.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import 'package:intl/intl.dart';

import '../../methods.dart';

class AllBookingWidget extends StatefulWidget {
  const AllBookingWidget({super.key, required this.user});
  final User user;

  @override
  _AllBookingWidgetState createState() => _AllBookingWidgetState();
}

class _AllBookingWidgetState extends State<AllBookingWidget>
    with TickerProviderStateMixin {
  final apiBooking = ApiBooking();
  String _selectedDate = '';
  String dateCount = '';
  String _range =
      '${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 30)))} => ${DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 30)))}';
  String rangeCount = '';
  bool visibility = false;
  bool visibility2 = false;
  String label = ""; //new DateFormat.yMMMMd('en_US').format(DateTime.now());
  int checkin = 0;
  int checkout = 0;
  void _onSelectionChanged(DateRangePickerSelectionChangedArgs args) {
    setState(() {
      if (args.value is PickerDateRange) {
        _range = '${DateFormat('yyyy-MM-dd').format(args.value.startDate)} =>'
            // ignore: lines_longer_than_80_chars
            ' ${DateFormat('yyyy-MM-dd').format(args.value.endDate ?? args.value.startDate)}';
        label = _label(_range);
      } else if (args.value is DateTime) {
        _selectedDate = args.value.toString();
        label = _selectedDate;
      } else if (args.value is List<DateTime>) {
        dateCount = args.value.length.toString();
      } else {
        rangeCount = args.value.length.toString();
      }
    });
  }

  String _label(range) {
    var split = _range.split("=>");
    if (split[0].replaceAll(' ', '') == split[1].replaceAll(' ', '')) {
      label = DateFormat.yMMMMd('en_US')
          .format(DateTime.parse(split[0].replaceAll(' ', '')));
    } else {
      label =
          "${DateFormat.yMMMMd('en_US').format(DateTime.parse(split[0].replaceAll(' ', '')))}=>${DateFormat.yMMMMd('en_US').format(DateTime.parse(split[1].replaceAll(' ', '')))}";
    }
    return label;
  }

  Future<List<Booking>> getBooking(range) {
    return apiBooking.getBookings(
        widget.user.thirdParty["id"], range, 'others');
  }

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
    label = _label(_range);
    return SingleChildScrollView(
      child: Container(
        color: Colors.white,
        child: Column(
          children: [
            Row(
              // alignment: Alignment.centerRight,
              // mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  iconSize: 25,
                  color: Colors.deepOrange[700],
                  icon: const Icon(Icons.search),
                  onPressed: () {
                    visibility2 ? visibility2 = false : visibility2 = true;
                    setState(() {});
                  },
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    color: Colors.deepOrange[700],
                    borderRadius: BorderRadius.circular(0),
                  ),
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  width: 45,
                  height: 40,
                  margin: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    border:
                        Border.all(color: const Color(0xFF244B6B), width: 4),
                    color: Colors.deepOrange[700],
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    color: Colors.white,
                    iconSize: 15,
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: () {
                      visibility ? visibility = false : visibility = true;
                      setState(() {});
                    },
                  ),
                ),
              ],
            ),
            Container(
              margin: const EdgeInsets.only(left: 30, right: 30),
            ),
            visibility
                ? SfDateRangePicker(
                    onSelectionChanged: _onSelectionChanged,
                    selectionMode: DateRangePickerSelectionMode.range,
                    initialSelectedRange: PickerDateRange(
                        DateTime.now().subtract(const Duration(days: 4)),
                        DateTime.now().add(const Duration(days: 3))),
                  )
                : FutureBuilder(
                    future: getBooking(_range),
                    builder: (BuildContext context, AsyncSnapshot snapshot) {
                      if (snapshot.data == null) {
                        return Container(
                          child: const Center(
                            child: Text("Loading..."),
                          ),
                        );
                      } else {
                        return SizedBox(
                          height: MediaQuery.of(context).size.height * 0.8,
                          child: Column(
                            children: [
                              visibility2
                                  ? SizedBox(
                                      height: 50,
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
                                            hintText: 'Search booking',
                                            contentPadding:
                                                const EdgeInsets.fromLTRB(
                                                    10.0, 10.0, 10.0, 10.0),
                                            border: OutlineInputBorder(
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        32.0)),
                                          ),
                                        ),
                                      ),
                                    )
                                  : Container(),
                              Expanded(
                                  child: snapshot.data.length > 0
                                      ? ListView.builder(
                                          shrinkWrap: true,
                                          scrollDirection: Axis.vertical,
                                          itemCount: snapshot.data.length,
                                          itemBuilder: (context, i) {
                                            String status = "";
                                            switch (snapshot.data[i].status) {
                                              case 0:
                                                status = "Cancelled";
                                                break;
                                              case 1:
                                                status = "Confirmed";
                                                break;
                                              case 2:
                                                status = "New";
                                                break;
                                              case 3:
                                                status = "Request";
                                                break;
                                              case 4:
                                                status = "Black";
                                                break;
                                              default:
                                                status = "";
                                            }
                                            int diff = DateTime.parse(
                                                    snapshot.data[i].lastNight)
                                                .difference(DateTime.parse(
                                                    snapshot
                                                        .data[i].firstNight))
                                                .inDays;
                                            return snapshot.data[i].referer
                                                        .toString()
                                                        .toLowerCase()
                                                        .contains(filter) ||
                                                    snapshot
                                                        .data[i].guestFirstName
                                                        .toString()
                                                        .toLowerCase()
                                                        .contains(filter) ||
                                                    snapshot.data[i].guestName
                                                        .toString()
                                                        .toLowerCase()
                                                        .contains(filter) ||
                                                    snapshot
                                                        .data[i].accommodation
                                                        .toString()
                                                        .toLowerCase()
                                                        .contains(filter)
                                                ? GestureDetector(
                                                    onTap: () {
                                                      methods.showBooking(
                                                          context,
                                                          snapshot.data[i],
                                                          0,
                                                          widget.user
                                                                  .thirdParty[
                                                              "id"]);
                                                    },
                                                    child: Container(
                                                      height: 130,
                                                      decoration: BoxDecoration(
                                                        border: Border.all(
                                                            color: Colors.grey,
                                                            width: 0.5),
                                                        borderRadius:
                                                            const BorderRadius
                                                                .all(
                                                                Radius.circular(
                                                                    5.0) //         <--- border radius here
                                                                ),
                                                      ),
                                                      margin:
                                                          const EdgeInsets.all(
                                                              8),
                                                      padding:
                                                          const EdgeInsets.all(
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
                                                            child: Container(
                                                              child: Text(
                                                                "Booking status: $status",
                                                                style:
                                                                    const TextStyle(
                                                                  fontWeight:
                                                                      FontWeight
                                                                          .bold,
                                                                ),
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                          Flexible(
                                                            child: Container(
                                                              child: Text(
                                                                  "${"From " + snapshot.data[i].referer} for " +
                                                                      snapshot
                                                                          .data[
                                                                              i]
                                                                          .accommodation),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                          Flexible(
                                                              child: Container(
                                                                  child: Row(
                                                                      children: [
                                                                Text(
                                                                    "${DateFormat.MMMd('en_US').format(DateTime.parse(snapshot.data[i].firstNight))}  -  "),
                                                                Text(DateFormat('MM').format(DateTime.parse(snapshot.data[i].firstNight)) ==
                                                                        DateFormat('MM').format(DateTime.parse(snapshot
                                                                            .data[
                                                                                i]
                                                                            .lastNight))
                                                                    ? DateFormat('d').format(DateTime.parse(snapshot
                                                                        .data[i]
                                                                        .lastNight))
                                                                    : DateFormat.MMMd(
                                                                            'en_US')
                                                                        .format(DateTime.parse(snapshot
                                                                            .data[i]
                                                                            .lastNight))),
                                                                Text(
                                                                    " ($diff nights)"),
                                                                const Spacer(),
                                                                Text(
                                                                    "Booked at: ${DateFormat('dd-MM-yyyy').format(DateTime.parse(snapshot.data[i].bookedAt))}"),
                                                              ]))),
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                          Container(
                                                            child: RichText(
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis,
                                                                text: TextSpan(
                                                                    style: const TextStyle(
                                                                        fontFamily:
                                                                            'Montserrat',
                                                                        fontWeight:
                                                                            FontWeight
                                                                                .bold,
                                                                        fontSize:
                                                                            18,
                                                                        color: Colors
                                                                            .black),
                                                                    text: snapshot
                                                                            .data[
                                                                                i]
                                                                            .guestFirstName +
                                                                        " " +
                                                                        snapshot
                                                                            .data[i]
                                                                            .guestName)),
                                                          ),
                                                          const SizedBox(
                                                            height: 10,
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  )
                                                : Container();
                                          })
                                      : Container(
                                          child: const Center(
                                              child: Text(
                                                  "No Bookings for this period")),
                                        ))
                            ],
                          ),
                        );
                      }
                    }),
          ],
        ),
      ),
    );
  }
}
