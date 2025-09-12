import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ResumeReservationPage extends StatefulWidget {
  const ResumeReservationPage({super.key});

  @override
  State<ResumeReservationPage> createState() => _ResumeReservationPageState();
}

class _ResumeReservationPageState extends State<ResumeReservationPage> {
  Map<String, dynamic>? reservation;

  @override
  void initState() {
    super.initState();
    _loadReservation();
  }

  Future<void> _loadReservation() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString('reservation_data');
    if (jsonString != null) {
      setState(() => reservation = jsonDecode(jsonString));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (reservation == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Reprise réservation"),
          backgroundColor: const Color(0xFF244B6B),
          foregroundColor: Colors.white,
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("🧾 Détails de la réservation"),
        backgroundColor: const Color(0xFF244B6B),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _info("📍 ID hébergement", reservation!['propId']),
            _info("🛏️ Chambre", reservation!['roomId']),
            _info("📅 Séjour",
                "Du ${reservation!['firstNight']} au ${reservation!['lastNight']}"),
            _info("👥 Adultes / Enfants",
                "${reservation!['numAdult']} adultes, ${reservation!['numChild']} enfants"),
            const Divider(height: 30),
            _info("👤 Invité",
                "${reservation!['guestTitle']} ${reservation!['guestFirstName']} ${reservation!['guestName']}"),
            _info("✉️ Email", reservation!['guestEmail']),
            _info("📱 Téléphone", reservation!['guestPhone']),
            _info("🏠 Adresse",
                "${reservation!['guestAddress']}, ${reservation!['guestCity']} ${reservation!['guestPostcode']}, ${reservation!['guestCountry']}"),
            if (reservation!['guestArrivalTime'] != null)
              _info("⏰ Heure d’arrivée", reservation!['guestArrivalTime']),
            const Divider(height: 30),
            _info("💰 Prix du séjour", "${reservation!['price']} €"),
            _info("💼 Taxes", "${reservation!['tax']} €"),
            _info("🔗 Commission", "${reservation!['commission']} €"),
            _info("🧽 Frais de ménage",
                "${reservation!['cleaning_fees_partner']} €"),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: const Text("Reprendre le paiement"),
                onPressed: () {
                  // ⏩ Tu peux renvoyer les données ici vers ta page de paiement
                  Navigator.pushNamed(context, "/payment",
                      arguments: reservation);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF244B6B),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _info(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label : ",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.black87)),
          )
        ],
      ),
    );
  }
}
