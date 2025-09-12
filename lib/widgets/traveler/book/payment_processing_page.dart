import 'package:flutter/material.dart';
import 'package:chicaparts_partner/widgets/traveler/book/payment_logic.dart';

class PaymentProcessingPage extends StatefulWidget {
  final double amount;
  final String currency;
  final String customerEmail;
  final int bookingId;
  final String checkInFormatted;

  const PaymentProcessingPage({
    super.key,
    required this.amount,
    required this.currency,
    required this.customerEmail,
    required this.bookingId,
    required this.checkInFormatted,
  });

  @override
  State<PaymentProcessingPage> createState() => _PaymentProcessingPageState();
}

class _PaymentProcessingPageState extends State<PaymentProcessingPage> {
  String selectedMethod = "Credit Card";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("✅ Réservation enregistrée")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 70),
            const SizedBox(height: 10),
            const Text(
              "Merci pour l'intérêt que vous avez pour notre hébergement.",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              "Votre réservation a bien été enregistrée. Vous pouvez maintenant procéder au paiement via l'une des méthodes ci-dessous.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.black54),
            ),
            const SizedBox(height: 20),
            _paymentButton(context, "Credit Card", 'assets/payment/cartes.png'),
            _paymentButton(context, "PayPal", 'assets/payment/paypal.png'),
            _paymentButton(
                context, "Mobile Money", 'assets/payment/mobile.jpeg'),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                final result = await processPaymentTransaction(
                  bookingId: widget.bookingId,
                  amount: widget.amount,
                  currency: widget.currency,
                  customerEmail: widget.customerEmail,
                  method: selectedMethod,
                  checkInFormatted: widget.checkInFormatted,
                );
                if (result != null) {
                  await handlePaymentResponse(context, result, selectedMethod);
                } else {
                  showErrorDialog(
                      context, "Une erreur s’est produite lors du paiement.");
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF244B6B),
              ),
              child: const Text(
                "Payer maintenant",
                style: TextStyle(color: Colors.white),
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
