import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:chicaparts_partner/api/api_booking.dart';
import 'package:chicaparts_partner/methods.dart';
import 'package:chicaparts_partner/models/model_booking.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/widgets/menu/bottomMenu.dart';
import 'package:syncfusion_flutter_calendar/calendar.dart';

class CalendarWidget extends StatefulWidget {
  const CalendarWidget(
      {super.key, required this.user, required this.accommodation});
  final User user;
  final String accommodation;
  @override
  State<CalendarWidget> createState() => _CalendarWidgetState();
}

class _CalendarWidgetState extends State<CalendarWidget> {
  late DateTime _minDate, _maxDate;
  String currentAppt = '';
  bool margRight = false;

  @override
  void initState() {
    _minDate = DateTime.now().subtract(const Duration(days: 30));
    _maxDate = DateTime.now().add(const Duration(days: 60));
    super.initState();
  }

  final apiBooking = ApiBooking();
  Future<List<Booking>> getBooking(range) {
    return apiBooking.getBookings(
        widget.user.thirdParty["id"], range, 'others');
  }

  List<CalendarBooking> _getDataSource(data) {
    final List<CalendarBooking> bookings = <CalendarBooking>[];
    for (var item in data) {
      if (item.accommodation == widget.accommodation) {
        bookings.add(CalendarBooking(
            item.guestName + " " + item.guestFirstName,
            DateTime.parse(item.firstNight),
            DateTime.parse(item.lastNight),
            const Color(0xFF244B6B),
            false,
            item));
      }
    }

    return bookings;
  }

  _AppointmentDataSource _getCalendarDataSource(data) {
    Map<String, Color> bookColor = {
      "Airbnb": const Color(0xFFE47C73),
      "Booking.com": Colors.blue,
      "Chicaparts": const Color(0xFF8B1FA9),
      "black_booking": Colors.black,
      "ABRITEL": const Color(0xFF244B6B),
      "Abritel": const Color(0xFF244B6B),
      "VRBO": const Color(0xFF244B6B),
      "Vrbo": const Color(0xFF244B6B),
      "Homeaway": const Color(0xFF244B6B),
      "HomeAway": const Color(0xFF244B6B),
      "MorningCroissant": const Color(0xFF244B6B),
      "Morningcroissant": const Color(0xFF244B6B),
      "HomeLike": const Color(0xFF77b5fe),
      "Homelike": const Color(0xFF77b5fe),
      "Spotahome": const Color(0xFF0F8644),
      "Partner": const Color(0xFF636363),
      "HOMEAWAY_DE": const Color(0xFF244B6B)
    };
    final List<Appointment> bookings = <Appointment>[];
    for (var item in data) {
      Color color = bookColor[item.referer] != null
          ? bookColor[item.referer]!
          : const Color(0xFF582900);
      if (item.accommodation == widget.accommodation && item.status != 0) {
        bookings.add(Appointment(
            subject: item.guestName + " " + item.guestFirstName,
            startTime: DateTime.parse(item.firstNight),
            endTime: DateTime.parse(item.lastNight),
            color: color,
            isAllDay: true,
            id: item));
      }
    }
    return _AppointmentDataSource(bookings);
  }

  final String _range =
      '${DateFormat('yyyy-MM-dd').format(DateTime.now().subtract(const Duration(days: 30)))} => ${DateFormat('yyyy-MM-dd').format(DateTime.now().add(const Duration(days: 60)))}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
          backgroundColor: const Color(0xFF244B6B),
          leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Color(0xFFFFFFFF)),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const BottomMenu(index: 1)));
              }),
          title: Container(
            child: Column(children: [
              const Text(
                "CALENDAR VIEW",
                style: TextStyle(color: Color(0xFFFFFFFF)),
              ),
              Text("(${widget.accommodation})",
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Color(0xFFFFFFFF)))
            ]),
          )),
      body: FutureBuilder(
          future: getBooking(_range),
          builder: (BuildContext context, AsyncSnapshot snapshot) {
            if (snapshot.data == null) {
              return Container(
                child: const Center(
                  child: Text("Loading..."),
                ),
              );
            } else {
              return SfCalendar(
                showNavigationArrow: true,
                cellEndPadding: 15,
                minDate: _minDate,
                maxDate: _maxDate,
                view: CalendarView.month,
                allowAppointmentResize: true,
                // dataSource: BookingDataSource(_getDataSource(snapshot.data)),
                dataSource: _getCalendarDataSource(snapshot.data),
                monthViewSettings: const MonthViewSettings(
                    showTrailingAndLeadingDates: false,
                    dayFormat: 'EEE',
                    numberOfWeeksInView: 6,
                    appointmentDisplayCount: 2,
                    appointmentDisplayMode:
                        MonthAppointmentDisplayMode.appointment,
                    showAgenda: false,
                    navigationDirection: MonthNavigationDirection.horizontal,
                    monthCellStyle: MonthCellStyle(
                        textStyle: TextStyle(
                            fontFamily: 'Montserrat', color: Colors.black))),
                resourceViewSettings:
                    const ResourceViewSettings(showAvatar: true, size: 20),
                onTap: viewBooking,
                selectionDecoration: BoxDecoration(
                  color: Colors.transparent,
                  border: Border.all(color: Colors.transparent, width: 2),
                ),
                // monthCellBuilder: monthCellBuilder,
                appointmentBuilder: appointmentBuilder,
              );
            }
          }),
    );
  }

  void viewBooking(CalendarTapDetails details) {
    final methods = Methods();
    if (details.targetElement == CalendarElement.calendarCell) {
      final dynamic booking = details.appointments![0].id;
      methods.showBooking(context, booking, 0, widget.user.thirdParty["id"]);
    }
  }

  Widget monthCellBuilder(BuildContext context, MonthCellDetails details) {
    if (details.appointments.length == 2) {
      margRight = true;
      return Container(
        color: Colors.grey,
        child: Text(
          details.date.day.toString(),
        ),
      );
    }
    return Container(
      color: Colors.grey,
      child: Text(
        details.date.day.toString(),
      ),
    );
  }

  Widget appointmentBuilder(BuildContext context,
      CalendarAppointmentDetails calendarAppointmentDetails) {
    final Appointment appointment =
        calendarAppointmentDetails.appointments.first;
    bool margLeft;
    currentAppt == appointment.subject ? margLeft = false : margLeft = true;
    // if (currentAppt == '') marg = false;
    currentAppt = appointment.subject;
    return Container(
        constraints:
            BoxConstraints(minWidth: MediaQuery.of(context).size.width),
        decoration: BoxDecoration(
          color: appointment.color,
          shape: BoxShape.rectangle,
          borderRadius: const BorderRadius.all(Radius.circular(10)),
          // gradient: LinearGradient(
          //     colors: [Colors.red, Colors.cyan],
          //     begin: Alignment.centerRight,
          //     end: Alignment.centerLeft)
        ),
        //alignment: Alignment.center,
        padding: const EdgeInsets.all(5),
        margin:
            EdgeInsets.only(left: margLeft ? 20 : 0, right: margRight ? 2 : 0),
        width: calendarAppointmentDetails.bounds.width,
        height: calendarAppointmentDetails.bounds.height / 2,
        child: RichText(
            maxLines: 1,
            text: TextSpan(
                text: appointment.subject,
                style: const TextStyle(color: Colors.white))));
  }
}

class BookingDataSource extends CalendarDataSource {
  /// Creates a meeting data source, which used to set the appointment
  /// collection to the calendar
  BookingDataSource(List<CalendarBooking> source) {
    appointments = source;
  }

  @override
  DateTime getStartTime(int index) {
    return _getMeetingData(index).from;
  }

  @override
  DateTime getEndTime(int index) {
    return _getMeetingData(index).to;
  }

  @override
  String getSubject(int index) {
    return _getMeetingData(index).eventName;
  }

  @override
  Color getColor(int index) {
    return _getMeetingData(index).background;
  }

  // @override
  // bool isAllDay(int index) {
  //   return _getMeetingData(index).isAllDay;
  // }

  CalendarBooking _getMeetingData(int index) {
    final dynamic booking = appointments![index];
    late final CalendarBooking bookingData;
    if (booking is CalendarBooking) {
      bookingData = booking;
    }

    return bookingData;
  }
}

class CalendarBooking {
  /// Creates a meeting class with required details.
  CalendarBooking(this.eventName, this.from, this.to, this.background,
      this.isAllDay, this.booking);

  /// Event name which is equivalent to subject property of [Appointment].
  String eventName;

  /// From which is equivalent to start time property of [Appointment].
  DateTime from;

  /// To which is equivalent to end time property of [Appointment].
  DateTime to;

  /// Background which is equivalent to color property of [Appointment].
  Color background;

  /// IsAllDay which is equivalent to isAllDay property of [Appointment].
  bool isAllDay;

  Booking booking;
}

class _AppointmentDataSource extends CalendarDataSource {
  _AppointmentDataSource(List<Appointment> source) {
    appointments = source;
  }
}
