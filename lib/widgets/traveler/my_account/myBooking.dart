import 'dart:convert';
import 'package:chicaparts_partner/api/traveler/api_booking_traveler.dart';
import 'package:chicaparts_partner/models/model_booking.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chicaparts_partner/models/user/user.dart';

class MyReservationsPage extends StatefulWidget {
  const MyReservationsPage({super.key});

  @override
  State<MyReservationsPage> createState() => _MyReservationsPageState();
}

class _MyReservationsPageState extends State<MyReservationsPage> {
  Map<String, dynamic>? pendingReservation;
  late Future<List<Booking>> futureBookings;
  User? user;
  ApiBooking apiResa = ApiBooking();

  @override
  void initState() {
    super.initState();
    loadUserAndReservations();
  }

  Future<void> loadUserAndReservations() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString('reservation_data');
    final userJson = prefs.getString('user');

    if (json != null) {
      setState(() {
        pendingReservation = jsonDecode(json);
      });
    }

    if (userJson != null) {
      final currentUser = User.fromJson(jsonDecode(userJson));
      user = currentUser;
      setState(() {
        futureBookings = apiResa.getUserReservations(currentUser);
      });
    }
  }

  Future<void> clearLocalReservation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('reservation_data');
    setState(() => pendingReservation = null);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 16.0, bottom: 12),
          child: Column(
            children: [
              _buildHeader(),
              if (pendingReservation != null) ...[
                _buildPendingCard(pendingReservation!),
                const SizedBox(height: 20),
              ],
              Expanded(
                child: user == null
                    ? Center(child: Text(lang.t('booking_connect_text')))
                    : FutureBuilder<List<Booking>>(
                        future: futureBookings,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return const Center(
                                child: CircularProgressIndicator());
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text(
                                    "${lang.t('error')}: ${lang.t('error_network')}"));
                          } else if (snapshot.data == null ||
                              snapshot.data!.isEmpty) {
                            return Center(child: Text(lang.t('booking_empty')));
                          }
                          final bookings = snapshot.data!;
                          return ListView.separated(
                            itemCount: bookings.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              return _buildBookingCard(bookings[index]);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Color(0xFF244B6B)),
                onPressed: () => Navigator.pop(context),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "📑 ${lang.t('my_bookings')}",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF244B6B)),
                  ),
                  const SizedBox(height: 2),
                  Text(lang.t('my_bookings_text'),
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
          const Icon(Icons.settings, size: 28, color: Color(0xFF244B6B)),
        ],
      ),
    );
  }

  Widget _buildPendingCard(Map<String, dynamic> res) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Card(
      color: Colors.yellow[100],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: Colors.orange),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("📌 ${lang.t('new_bookings')}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text("🛏️ ${lang.t('accommodation')} : ${res['propId'] ?? 'N/A'}"),
            Text(
                "📅 ${lang.t('from')} ${_formatDate(DateTime.parse(res['firstNight']))} au ${_formatDate(DateTime.parse(res['lastNight']).add(const Duration(days: 1)))}"),
            Text("👤 ${res['guestFirstName']} ${res['guestName']}"),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF244B6B)),
                  onPressed: () =>
                      Navigator.pushNamed(context, "/resume-reservation"),
                  icon: const Icon(Icons.play_arrow),
                  label: Text(lang.t('continue'),
                      style: TextStyle(color: Colors.white)),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: clearLocalReservation,
                  tooltip: lang.t('delete_booking'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBookingCard(Booking booking) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🏠 ${booking.accommodation}",
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
                "📅 ${lang.t('from')} ${_formatDate(DateTime.parse(booking.firstNight))} ${lang.t('to')} ${_formatDate(DateTime.parse(booking.lastNight).add(const Duration(days: 1)))}"),
            Text("👤 ${booking.guestFirstName} ${booking.guestName}"),
            Text("💰 ${booking.price} ${booking.currency}"),
            const SizedBox(height: 8),
            Text("📌 ${lang.t('status')}: ${booking.validationStatus}"),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => DateFormat("dd MMM yyyy").format(date);
}
