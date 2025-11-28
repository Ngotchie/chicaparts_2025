import 'dart:convert';
import 'package:chicaparts_partner/api/traveler/api_booking_traveler.dart';
import 'package:chicaparts_partner/models/model_booking.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/account_class.dart';
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
  User? user;

  ApiBooking apiResa = ApiBooking();

  late Future<List<Booking>> _allBookings;
  Booking? _currentReservation;

  @override
  void initState() {
    super.initState();
    loadUserAndReservations();
  }

  // -----------------------------------------------------------------------------
  // 🔹 CHARGEMENT UTILISATEUR + RÉSERVATIONS
  // -----------------------------------------------------------------------------
  Future<void> loadUserAndReservations() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson != null && userJson.isNotEmpty) {
      user = User.fromJson(jsonDecode(userJson));

      setState(() {
        _allBookings = _fetchAllBookings();
      });
    }
  }

  // -----------------------------------------------------------------------------
  // 🔹 Récupère toutes les réservations + détecte la réservation en cours
  // -----------------------------------------------------------------------------
  Future<List<Booking>> _fetchAllBookings() async {
    if (user == null) return [];

    final list = await apiResa.getUserReservations(user!);

    // Tri descendant par date de création
    list.sort((a, b) {
      final da = DateTime.tryParse(a.bookedAt ?? '') ?? DateTime(2000);
      final db = DateTime.tryParse(b.bookedAt ?? '') ?? DateTime(2000);
      return db.compareTo(da);
    });

    // Détecter la réservation en cours
    _detectCurrentReservation(list);

    return list;
  }

  // -----------------------------------------------------------------------------
  // 🔹 Détection automatique de la réservation en cours
  // -----------------------------------------------------------------------------
  void _detectCurrentReservation(List<Booking> all) {
    final now = DateTime.now();

    for (var b in all) {
      final start = DateTime.tryParse(b.firstNight ?? '');
      final end = DateTime.tryParse(b.lastNight ?? '');

      if (start != null && end != null) {
        if (now.isAfter(start) &&
            now.isBefore(end.add(const Duration(days: 1)))) {
          setState(() => _currentReservation = b);
          return;
        }
      }
    }

    // Sinon aucune en cours
    setState(() => _currentReservation = null);
  }

  // -----------------------------------------------------------------------------
  // 🔹 Refresh global
  // -----------------------------------------------------------------------------
  Future<void> _loadAllBookings() async {
    setState(() {
      _allBookings = _fetchAllBookings();
    });
  }

  // -----------------------------------------------------------------------------
  // 🔹 Changer les dates (TODO ou navigation)
  // -----------------------------------------------------------------------------
  void _changeDates(Booking b) {
    // TODO : ouvrir un date picker / nouvelle page
    print("Changer les dates de : ${b.id}");
  }

  // -----------------------------------------------------------------------------
  // 🔹 BUILD
  // -----------------------------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Container(height: 1, color: Colors.grey[300]),
            Expanded(
              child: user == null
                  ? Center(child: Text(lang.t('booking_connect_text')))
                  : RefreshIndicator(
                      onRefresh: _loadAllBookings,
                      child: CustomScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        slivers: [
                          // ------------------------------------------------------------------
                          // 🔥 RÉSERVATION EN COURS (grosse carte)
                          // ------------------------------------------------------------------
                          if (_currentReservation != null)
                            SliverToBoxAdapter(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 8),
                                child: ReservationInProgressCard(
                                  title:
                                      _currentReservation!.accommodation ?? "—",
                                  city: _currentReservation!.city ?? "",
                                  firstNight: DateTime.parse(
                                      _currentReservation!.firstNight),
                                  lastNight: DateTime.parse(
                                      _currentReservation!.lastNight),
                                  currency: _currentReservation!.currency,
                                  totalAmount: _currentReservation!.price ?? 0,
                                  travelers: (_currentReservation!.adult ?? 1) +
                                      (_currentReservation!.child ?? 0),
                                  paymentStatus:
                                      _currentReservation!.validationStatus,
                                  statusLabel:
                                      _currentReservation!.validationStatus ==
                                              "confirmed"
                                          ? lang.t('confirmed')
                                          : lang.t('waitting'),
                                  imageUrl: _currentReservation!.img,
                                  onChangeDates: () =>
                                      _changeDates(_currentReservation!),
                                  onTip: () => Navigator.pushNamed(context,
                                      '/tips/${_currentReservation!.id}'),
                                  onMore: () => Navigator.pushNamed(
                                    context,
                                    '/reservations/${_currentReservation!.id}',
                                  ),
                                  onReview: () {},
                                ),
                              ),
                            ),

                          // ------------------------------------------------------------------
                          // 🔹 CHARGEMENT / ERREUR / LISTE
                          // ------------------------------------------------------------------
                          FutureBuilder<List<Booking>>(
                            future: _allBookings,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return const SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: Center(
                                      child: CircularProgressIndicator()),
                                );
                              }

                              if (snapshot.hasError) {
                                return SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: Center(
                                    child: Text(
                                      "${lang.t('error')}: ${lang.t('error_network')}",
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                );
                              }

                              final bookings = snapshot.data ?? [];

                              // Retirer la réservation en cours
                              final list = bookings.where((b) {
                                if (_currentReservation == null) return true;
                                return b.id != _currentReservation!.id;
                              }).toList();

                              if (list.isEmpty) {
                                return SliverFillRemaining(
                                  hasScrollBody: false,
                                  child: Center(
                                    child: Text(lang.t('no_booking')),
                                  ),
                                );
                              }

                              return SliverList.builder(
                                itemCount: list.length,
                                itemBuilder: (_, i) {
                                  final b = list[i];
                                  final first = DateTime.parse(b.firstNight);
                                  final last = DateTime.parse(b.lastNight);

                                  return BookingTile(
                                    title: b.accommodation,
                                    city: b.city,
                                    dates:
                                        "${DateFormat('dd MMM').format(first)} – ${DateFormat('dd MMM yyyy').format(last)}",
                                    status: b.validationStatus,
                                    imageUrl: b.img,
                                    onTap: () => Navigator.pushNamed(
                                      context,
                                      '/reservations/${b.id}',
                                    ),
                                  );
                                },
                              );
                            },
                          ),

                          const SliverToBoxAdapter(child: SizedBox(height: 24)),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  // -----------------------------------------------------------------------------
  // 🔹 HEADER
  // -----------------------------------------------------------------------------
  Widget _buildHeader() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 12, right: 8),
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
                    style: const TextStyle(
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
          IconButton(
            icon: const Icon(Icons.sync, size: 28, color: Color(0xFF244B6B)),
            onPressed: () => showSyncReservationsSheet(context, apiResa, user!),
          )
        ],
      ),
    );
  }

  void showSyncReservationsSheet(
    BuildContext context,
    ApiBooking api,
    User user,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SyncReservationsWidget(api: api, user: user);
      },
    );
  }
}
