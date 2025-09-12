import 'package:flutter/material.dart';
import 'package:chicaparts_partner/api/traveler/api_payment_traveler.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:url_launcher/url_launcher.dart';

final apiPayment = ApiPayment();

/// 🧠 Cette fonction appelle directement l'API de transaction
/// car la réservation est déjà enregistrée.
Future<dynamic> processPaymentTransaction({
  required int bookingId,
  required double amount,
  required String currency,
  required String customerEmail,
  required String checkInFormatted,
  required String method,
}) async {
  try {
    final service = _getPaymentService(method);

    final transactionResult = await apiPayment.checkoutTransaction(
      service: service,
      amount: amount,
      currency: currency,
      name: "Checkin: $checkInFormatted",
      customerEmail: customerEmail,
      bookingId: bookingId,
    );

    return transactionResult;
  } catch (e) {
    debugPrint('Error in processPaymentTransaction: $e');
    return null;
  }
}

/// 💳 Gère l'ouverture de Stripe ou d'une page de paiement tierce
Future<void> handlePaymentResponse(
    BuildContext context, dynamic result, String paymentMethod) async {
  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    if (paymentMethod == "Credit Card") {
      if (result['clientSecret'] != null) {
        String clientSecret = result['clientSecret'];

        await stripe.Stripe.instance.initPaymentSheet(
          paymentSheetParameters: stripe.SetupPaymentSheetParameters(
            paymentIntentClientSecret: Uri.decodeComponent(clientSecret),
            merchantDisplayName: 'Chicaparts',
            style: ThemeMode.system,
            appearance: const stripe.PaymentSheetAppearance(
              colors: stripe.PaymentSheetAppearanceColors(
                background: Colors.white,
                primary: Color(0xFF244B6B),
              ),
            ),
          ),
        );

        await stripe.Stripe.instance.presentPaymentSheet();

        Navigator.pop(context); // Ferme le loader

        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('✅ Paiement effectué'),
            content: const Text('Votre réservation est confirmée.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        Navigator.pop(context);
        showErrorDialog(context, "Stripe: code secret manquant.");
      }
    } else {
      print(result);
      if (result['payment_url'] != null) {
        String paymentUrl = result['payment_url'];
        Navigator.pop(context);

        Uri uri = Uri.parse(paymentUrl);
        if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
          showErrorDialog(context, "Impossible d'ouvrir la page de paiement.");
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "Vous avez été redirigé vers la page de paiement. Merci de finaliser la transaction.",
              ),
              backgroundColor: Color(0xFF244B6B),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } else {
        Navigator.pop(context);
        showErrorDialog(context, "Lien de paiement manquant.");
      }
    }
  } catch (e, stack) {
    Navigator.pop(context);
    print("❌ Stripe error: $e");
    print("Stacktrace: $stack");
    showErrorDialog(context, "Erreur lors du paiement: $e");
  }
}

void showErrorDialog(BuildContext context, String message) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: const Text(" ❌ Erreur"),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("OK"),
        ),
      ],
    ),
  );
}

String _getPaymentService(String paymentMethod) {
  switch (paymentMethod) {
    case "Credit Card":
      return "stripe";
    case "Mobile Money":
      return "cinetpay";
    case "PayPal":
      return "paypal";
    default:
      throw Exception("Méthode de paiement non supportée: $paymentMethod");
  }
}
