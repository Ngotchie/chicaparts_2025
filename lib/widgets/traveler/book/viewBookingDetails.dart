import 'package:chicaparts_partner/widgets/traveler/book/billingInfos.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ReviewReservationPage extends StatefulWidget {
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final double totalPrice;
  final double cleaningFees;
  final double cityTaxe;

  const ReviewReservationPage({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.totalPrice,
    required this.cleaningFees,
    required this.cityTaxe,
  });

  @override
  _ReviewReservationPageState createState() => _ReviewReservationPageState();
}

class _ReviewReservationPageState extends State<ReviewReservationPage> {
  TimeOfDay? _arrivalTime;

  @override
  Widget build(BuildContext context) {
    // 🔢 Calcul des frais de service (10% du prix de base)
    double chicapartsFees = widget.totalPrice * 0.10;
    double finalPrice = widget.totalPrice +
        widget.cleaningFees +
        widget.cityTaxe +
        chicapartsFees;

    return Scaffold(
      appBar: AppBar(
        title: const Text("📝 Review Your Booking",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📅 Dates sélectionnées
            _buildDetailRow("📆 Booking Date", _formatDate(DateTime.now())),
            _buildDetailRow("🏁 Check-in", _formatDate(widget.checkIn)),
            _buildDetailRow("📤 Check-out", _formatDate(widget.checkOut)),
            const SizedBox(height: 10),

            // 👥 Voyageurs
            _buildDetailRow("👨‍👩‍👧‍👦 Travelers",
                "${widget.adults} Adults, ${widget.children} Children"),
            const SizedBox(height: 10),

            if (_arrivalTime != null)
              _buildDetailRow("⏰ Arrival Time", _formatTime(_arrivalTime!)),
            const SizedBox(height: 10),
            // ⏰ Heure d'arrivée (modifiable)
            _buildArrivalTimeSelector(context),
            const SizedBox(height: 20),

            // 💰 Détail des prix
            const Text("💰 Payment Summary",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            _buildDetailRow(
                "🏠 Base Price", "\$${widget.totalPrice.toStringAsFixed(2)}"),
            _buildDetailRow("🧹 Cleaning Fees",
                "\$${widget.cleaningFees.toStringAsFixed(2)}"),
            _buildDetailRow(
                "🏙 City Taxe", "\$${widget.cityTaxe.toStringAsFixed(2)}"),
            _buildDetailRow("🏡 Chicaparts Fees (10%)",
                "\$${chicapartsFees.toStringAsFixed(2)}"),
            Divider(thickness: 1, color: Colors.grey[400]),
            _buildDetailRow("💵 Total", "\$${finalPrice.toStringAsFixed(2)}",
                isTotal: true),

            const SizedBox(height: 30),

            // ✅ Bouton "Proceed to Payment"
            ElevatedButton(
              onPressed: () {
                // Aller à la page de paiement
                BookingDetails1 booking = BookingDetails1(
                  checkIn: widget.checkIn,
                  checkOut: widget.checkOut,
                  adults: widget.adults,
                  children: widget.children,
                  totalPrice: widget.totalPrice,
                  cleaningFees: widget.cleaningFees,
                  cityTaxe: widget.cityTaxe,
                );

                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (context) =>
                //         BillingInfoPage(bookingDetails: booking),
                //   ),
                // );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF244B6B),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Center(
                child: Text("Proceed to Payment",
                    style: TextStyle(fontSize: 16, color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 📌 Fonction pour formater la date
  String _formatDate(DateTime date) {
    return DateFormat("dd MMMM yyyy").format(date);
  }

  // 📌 Fonction pour formater l'heure
  String _formatTime(TimeOfDay time) {
    return time.format(context);
  }

  // 📌 Fonction pour construire une ligne de détail
  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label,
              style: TextStyle(
                  fontSize: isTotal ? 18 : 16,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal)),
          Text(value,
              style: TextStyle(
                  fontSize: isTotal ? 18 : 16,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                  color: isTotal ? Colors.green : Colors.black)),
        ],
      ),
    );
  }

  // 📌 Sélecteur d'heure d'arrivée
  Widget _buildArrivalTimeSelector(BuildContext context) {
    return InkWell(
      onTap: () async {
        TimeOfDay? pickedTime = await showTimePicker(
          context: context,
          initialTime: _arrivalTime ?? const TimeOfDay(hour: 14, minute: 0),
        );
        if (pickedTime != null) {
          setState(() {
            _arrivalTime = pickedTime;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("⏰ Select Arrival Time",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            Icon(Icons.access_time, color: Colors.blueAccent),
          ],
        ),
      ),
    );
  }
}

class BookingDetails1 {
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final double totalPrice;
  final double cleaningFees;
  final double cityTaxe;
  final double chicapartsFees;

  BookingDetails1({
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.totalPrice,
    required this.cleaningFees,
    required this.cityTaxe,
  }) : chicapartsFees = totalPrice * 0.10;

  double get finalPrice =>
      totalPrice + cleaningFees + cityTaxe + chicapartsFees;
}
