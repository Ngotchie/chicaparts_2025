import 'dart:convert';

import 'package:chicaparts_partner/api/traveler/api_booking_traveler.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:chicaparts_partner/widgets/traveler/book/payment_logic.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TipPaymentProcessingPage extends StatefulWidget {
  final double amount;
  final String currency;
  final String customerEmail;
  final int bookingId;
  final String stayLabel; // ex : "Séjour du 12 au 15 mars"

  const TipPaymentProcessingPage({
    super.key,
    required this.amount,
    required this.currency,
    required this.customerEmail,
    required this.bookingId,
    required this.stayLabel,
  });

  @override
  State<TipPaymentProcessingPage> createState() =>
      _TipPaymentProcessingPageState();
}

class _TipPaymentProcessingPageState extends State<TipPaymentProcessingPage> {
  String selectedMethod = "Credit Card";

  User? _currentUser;

  /// Charge le user local
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson == null) {
      _currentUser = null;
      return;
    }

    _currentUser = User.fromJson(jsonDecode(userJson));
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Scaffold(
      appBar: AppBar(title: Text(lang.t('tip'))),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.favorite, color: Colors.pink, size: 70),
            const SizedBox(height: 10),
            Text(
              lang.t('thank_stay'),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              lang.t('tip_msg'),
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 8),
            Text(
              widget.stayLabel,
              style: const TextStyle(
                fontStyle: FontStyle.italic,
                color: Colors.black54,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Méthodes de paiement
            _paymentButton(context, "Credit Card", 'assets/payment/cartes.png'),
            _paymentButton(context, "PayPal", 'assets/payment/paypal.png'),
            _paymentButton(
                context, "Mobile Money", 'assets/payment/mobile.jpeg'),

            const SizedBox(height: 20),

            // Bouton payer
            ElevatedButton(
              onPressed: () async {
                final result = await processPaymentTransaction(
                  bookingId: widget.bookingId,
                  amount: widget.amount,
                  currency: widget.currency,
                  customerEmail: widget.customerEmail,
                  method: selectedMethod,
                  checkInFormatted: widget.stayLabel, // ou date check-in
                );

                if (result != null) {
                  final transactionId =
                      result["id"]; // dépend de ton retour exact
                  final api = ApiBooking(); // ou ton APITip

                  await api.sendTip(
                    bookingId: widget.bookingId,
                    transactionId: transactionId,
                    amount: widget.amount.toInt(),
                    currency: widget.currency,
                    percentage: 0,
                    userId: _currentUser!.id, // depuis SharedPreferences
                    message: null,
                  );
                  await handlePaymentResponse(context, result, selectedMethod);
                } else {
                  showErrorDialog(
                    context,
                    "Error during task proceding",
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF244B6B),
              ),
              child: Text(
                "${lang.t('pay_tip')} (${widget.amount.toStringAsFixed(2)} ${widget.currency})",
                style: const TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _paymentButton(BuildContext context, String method, String assetPath) {
    return InkWell(
      onTap: () {
        setState(() {
          selectedMethod = method;
        });
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        margin: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: selectedMethod == method ? Colors.blue[50] : Colors.white,
          border: Border.all(
            color:
                selectedMethod == method ? Colors.blue : Colors.grey.shade300,
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Image.asset(assetPath, height: 32),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                method,
                style: const TextStyle(fontSize: 16),
              ),
            ),
            Radio<String>(
              value: method,
              groupValue: selectedMethod,
              onChanged: (_) {
                setState(() {
                  selectedMethod = method;
                });
              },
            ),
          ],
        ),
      ),
    );
  }
}
