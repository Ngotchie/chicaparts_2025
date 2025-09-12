import 'package:chicaparts_partner/api/traveler/api_booking_traveler.dart';
import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/exchange_rate_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/utils/currency_converter.dart';
import 'package:chicaparts_partner/widgets/traveler/book/billingInfos.dart';
import 'package:chicaparts_partner/widgets/traveler/book/viewBookingDetails.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shimmer/shimmer.dart';
import 'package:table_calendar/table_calendar.dart';

class SelectBookingDetailsPage extends StatefulWidget {
  final double pricePerNight;
  final int idAcc;
  final String currency;
  final double cleaningFees;
  final int roomId;
  final int propId;

  const SelectBookingDetailsPage(
      {super.key,
      required this.pricePerNight,
      required this.idAcc,
      required this.currency,
      required this.cleaningFees,
      required this.roomId,
      required this.propId});

  @override
  _SelectBookingDetailsPageState createState() =>
      _SelectBookingDetailsPageState();
}

class _SelectBookingDetailsPageState extends State<SelectBookingDetailsPage> {
  DateTime? _checkInDate;
  DateTime? _checkOutDate;
  int _adults = 1;
  int _children = 0;
  double _totalPrice = 0.0;
  DateTime _focusedDay = DateTime.now(); // ✅ Conserve le mois actif
  final apiBooking = ApiBooking();
  List<DateTime> availableDates = [];
  Map<DateTime, double> availablePrices = {};
  bool _isLoading = true;

  String displayPrice = "";
  var exchangeRates;

  @override
  void initState() {
    super.initState();
    _getAvailibilities();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(
        title: Text("📅 ${lang.t('select_stay')}",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📆 Calendrier amélioré avec correction du retour auto au mois courant
            _buildCalendar(),

            const SizedBox(height: 20),

            // 🔹 Sélection des voyageurs (design compact)
            Text("👥 ${lang.t('travelers')}",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildTravelerSelector(lang.t('adults'), _adults,
                    (value) => setState(() => _adults = value)),
                const SizedBox(width: 5),
                _buildTravelerSelector(lang.t('children'), _children,
                    (value) => setState(() => _children = value)),
              ],
            ),

            const SizedBox(height: 20),

            // 💰 Montant total affiché immédiatement
            if (_totalPrice > 0)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Color(0xFF244B6B),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Total: $displayPrice",
                  style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
              ),

            const SizedBox(height: 30),

            // ✅ Bouton "Continue"
            ElevatedButton(
              onPressed: () {
                if (_checkInDate == null || _checkOutDate == null) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(lang.t('select_checkin_checkout')),
                    backgroundColor: Colors.redAccent,
                  ));
                  return;
                }
                BookingDetails booking = BookingDetails(
                    checkIn: _checkInDate!,
                    checkOut: _checkOutDate!,
                    adults: _adults,
                    children: _children,
                    totalPrice: _totalPrice,
                    cleaningFees: widget.cleaningFees,
                    cityTaxe: _totalPrice * 0.12,
                    propId: widget.propId,
                    roomId: widget.roomId);
                // Aller à la page de récapitulatif
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BillingInfoPage(
                      bookingDetails: booking,
                    ),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF244B6B),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Center(
                child: Text(lang.t('continue'),
                    style: const TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _getAvailibilities() async {
    setState(() {
      _isLoading = true; // 🔥 Active le loader
    });
    try {
      final response = await apiBooking.fetchAvailabilities(widget.idAcc);
      // 🔥 Vérifie si la réponse est bien un `Map`
      // ✅ Pas besoin de reparser les dates, car elles sont déjà en DateTime
      setState(() {
        availableDates = response.keys.toList(); // Extraire les dates
        availablePrices = response; // Pas besoin de transformer
        _isLoading = false;
      });
    } catch (e) {
      print("Error fetching availabilities: $e");
    }
  }

  // 📅 **Calendrier qui garde le mois actif sélectionné**
  Widget _buildCalendar() {
    exchangeRates = context.watch<ExchangeRateProvider>().rates;
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
              color: Colors.grey.shade300, spreadRadius: 1, blurRadius: 5),
        ],
      ),
      padding: const EdgeInsets.all(8),
      child: _isLoading
          ? _buildShimmerLoader()
          : TableCalendar(
              focusedDay: _focusedDay,
              firstDay: DateTime.now(),
              lastDay: DateTime.now().add(const Duration(days: 365)),
              selectedDayPredicate: (date) =>
                  date == _checkInDate || date == _checkOutDate,
              calendarFormat: CalendarFormat.month,
              availableGestures: AvailableGestures.horizontalSwipe,
              rangeSelectionMode: RangeSelectionMode.toggledOn,
              rangeStartDay: _checkInDate,
              rangeEndDay: _checkOutDate,

              // 🔥 Gestion de la sélection des dates
              onDaySelected: (selectedDay, focusedDay) {
                if (!_isAvailable(selectedDay)) {
                  return; // ✅ Bloque les jours indisponibles
                }
                setState(() {
                  _focusedDay = focusedDay;
                  if (_checkInDate == null ||
                      (selectedDay.isBefore(_checkInDate!) &&
                          _checkOutDate == null)) {
                    _checkInDate = selectedDay;
                    _checkOutDate = null;
                  } else if (_checkOutDate == null &&
                      selectedDay.isAfter(_checkInDate!)) {
                    _checkOutDate = selectedDay;
                  } else {
                    _checkInDate = selectedDay;
                    _checkOutDate = null;
                  }
                  _updateTotalPrice();
                });
              },

              // 🔥 Style du calendrier
              calendarStyle: CalendarStyle(
                rangeHighlightColor: const Color(0xFF244B6B),
                rangeStartDecoration: const BoxDecoration(
                    color: Colors.green, shape: BoxShape.circle),
                rangeEndDecoration: const BoxDecoration(
                    color: Colors.orange, shape: BoxShape.circle),
                selectedDecoration: const BoxDecoration(
                    color: Color(0xFF244B6B), shape: BoxShape.circle),
                todayDecoration: const BoxDecoration(
                    color: Colors.blueGrey, shape: BoxShape.circle),

                // ✅ Style des jours non disponibles
                disabledTextStyle: TextStyle(color: Colors.grey.shade400),
              ),

              // ✅ Désactiver les jours non disponibles
              enabledDayPredicate: (date) => _isAvailable(date),

              headerStyle: const HeaderStyle(
                formatButtonVisible: false,
                titleCentered: true,
                titleTextStyle:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
    );
  }

  Widget _buildShimmerLoader() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        height: 350, // Hauteur du calendrier
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

// 🔹 Fonction pour vérifier si une date est disponible
  bool _isAvailable(DateTime date) {
    return availableDates.contains(date);
  }

  void _updateTotalPrice() {
    if (_checkInDate != null && _checkOutDate != null) {
      double basePrice = 0.0; // 🔥 Initialisation du prix de base

      // 🔹 Parcourir toutes les dates sélectionnées et additionner les prix
      DateTime currentDate = _checkInDate!;
      while (currentDate.isBefore(_checkOutDate!)) {
        //||currentDate.isAtSameMomentAs(_checkOutDate!)
        if (availablePrices.containsKey(currentDate)) {
          basePrice += availablePrices[currentDate]!;
        }
        currentDate = currentDate.add(const Duration(days: 1));
      }

      // 🔹 Calcul du supplément pour les voyageurs supplémentaires
      int extraTravelers =
          (_adults + _children) > 2 ? (_adults + _children - 2) : 0;
      double extraCost =
          extraTravelers * 10; // ✅ 10€ par voyageur supplémentaire

      // 🔹 Mise à jour du total
      setState(() {
        _totalPrice = basePrice + extraCost;
        displayPrice = CurrencyConverter.format(_totalPrice,
            from: 'EUR',
            to: context.read<CurrencyProvider>().currency,
            rates: exchangeRates);
      });
    }
  }

  // 👥 **Sélecteur de voyageurs compact**
  Widget _buildTravelerSelector(
      String label, int value, Function(int) onChanged) {
    return Expanded(
      // Permet à ce widget de s'adapter automatiquement à la largeur disponible
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey.shade300),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.remove_circle_outline,
                      color: Color(0xFF244B6B)),
                  onPressed: () {
                    if (value > 0) {
                      onChanged(value - 1);
                      _updateTotalPrice();
                    }
                  },
                ),
                Text(
                  value.toString(),
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline,
                      color: Color(0xFF244B6B)),
                  onPressed: () {
                    onChanged(value + 1);
                    _updateTotalPrice();
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class BookingDetails {
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final double totalPrice;
  final double cleaningFees;
  final double cityTaxe;
  final double chicapartsFees;
  final int propId;
  final int roomId;

  BookingDetails(
      {required this.checkIn,
      required this.checkOut,
      required this.adults,
      required this.children,
      required this.totalPrice,
      required this.cleaningFees,
      required this.cityTaxe,
      required this.propId,
      required this.roomId})
      : chicapartsFees = totalPrice * 0.10;

  double get finalPrice =>
      totalPrice + cleaningFees + cityTaxe + chicapartsFees;

  Map<String, dynamic> toJson() => {
        "propId": propId,
        "roomId": roomId,
        "firstNight": checkIn.toIso8601String().split('T')[0],
        "lastNight": checkOut.toIso8601String().split('T')[0],
        "numAdult": adults,
        "numChild": children,
        "price": totalPrice.toStringAsFixed(2),
        "tax": cityTaxe.toStringAsFixed(2),
        "commission": chicapartsFees.toStringAsFixed(2),
        "cleaning_fees_partner": cleaningFees.toStringAsFixed(2),
      };
}
