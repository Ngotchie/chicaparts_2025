import 'package:chicaparts_partner/api/traveler/api_payment_traveler.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/widgets/traveler/book/in_app_payment_webview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:provider/provider.dart';

final apiPayment = ApiPayment();

Future<dynamic> processPaymentTransaction({
  required int bookingId,
  required double amount,
  required String currency,
  required String customerEmail,
  required String checkInFormatted,
  required String method,
  String? customerPhoneNumber,
  String paymentItemType = 'booking',
}) async {
  final service = getPaymentService(method);

  return apiPayment.checkoutTransaction(
    service: service,
    amount: amount,
    currency: currency,
    name: "Checkin: $checkInFormatted",
    customerEmail: customerEmail,
    bookingId: bookingId,
    customerPhoneNumber: customerPhoneNumber,
    paymentItemType: paymentItemType,
  );
}

Future<Map<String, dynamic>?> checkExistingPaymentTransaction({
  required int bookingId,
  required String method,
  String paymentItemType = 'booking',
}) {
  return apiPayment.checkExistingTransaction(
    service: getPaymentService(method),
    bookingId: bookingId,
    paymentItemType: paymentItemType,
  );
}

Future<bool> handlePaymentResponse(
  BuildContext context,
  dynamic result,
  String paymentMethod,
  {
  required int bookingId,
  String paymentItemType = 'booking',
  bool showSuccessDialog = true,
}) async {
  final lang = Provider.of<LanguageProvider>(context, listen: false);

  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );

    if (paymentMethod == "Credit Card") {
      final response = result is Map ? result : const {};
      final data = response['data'];
      final clientSecret = response['clientSecret'] ??
          response['client_secret'] ??
          (data is Map ? data['clientSecret'] : null) ??
          (data is Map ? data['client_secret'] : null);

      if (clientSecret != null && clientSecret.toString().isNotEmpty) {
        final paymentIntentClientSecret = clientSecret.toString();

        await stripe.Stripe.instance.initPaymentSheet(
          paymentSheetParameters: stripe.SetupPaymentSheetParameters(
            paymentIntentClientSecret: paymentIntentClientSecret,
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

        Navigator.pop(context);

        final confirmed = await _confirmPaymentWithBackend(
          bookingId: bookingId,
          paymentMethod: paymentMethod,
          paymentItemType: paymentItemType,
        );

        if (confirmed) {
          if (showSuccessDialog && context.mounted) {
            _showSuccessDialog(context, lang);
          }
          return true;
        }

        if (context.mounted) {
          showErrorDialog(context, lang.t('payment_pending_message'));
        }
        return false;
      } else {
        Navigator.pop(context);
        showErrorDialog(context, lang.t('stripe_secret_missing'));
        return false;
      }
    } else {
      final paymentUrl = _extractPaymentUrl(result);
      if (paymentUrl != null && paymentUrl.isNotEmpty) {
        Navigator.pop(context);

        final completed = await Navigator.push<dynamic>(
          context,
          MaterialPageRoute(
            builder: (_) => InAppPaymentWebViewPage(
              paymentUrl: paymentUrl,
              service: getPaymentService(paymentMethod),
              bookingId: bookingId,
              orderId: _extractOrderId(result),
              paymentItemType: paymentItemType,
            ),
          ),
        );

        if ((completed == true || completed is Map) && context.mounted) {
          if (showSuccessDialog) {
            _showSuccessDialog(context, lang);
          }
          return true;
        }
        return false;
      } else {
        Navigator.pop(context);
        showErrorDialog(context, lang.t('payment_link_missing'));
        return false;
      }
    }
  } catch (e, stack) {
    Navigator.pop(context);
    debugPrint('Payment error: $e');
    debugPrint('Stacktrace: $stack');
    showErrorDialog(context, _paymentErrorMessage(e, lang));
    return false;
  }
}

Future<bool> _confirmPaymentWithBackend({
  required int bookingId,
  required String paymentMethod,
  required String paymentItemType,
}) async {
  final transaction = await checkExistingPaymentTransaction(
    bookingId: bookingId,
    method: paymentMethod,
    paymentItemType: paymentItemType,
  );

  return isSuccessfulPaymentTransaction(transaction);
}

bool isSuccessfulPaymentTransaction(Map<String, dynamic>? transaction) {
  if (transaction == null) return false;

  final status = transaction['status']?.toString().toUpperCase() ?? '';
  final data = transaction['data'];
  final dataStatus = data is Map ? data['status']?.toString().toUpperCase() : '';

  return transaction['success'] == true ||
      status == 'PAID' ||
      status == 'ACCEPTED' ||
      status == 'COMPLETED' ||
      status == 'SUCCESS' ||
      dataStatus == 'PAID' ||
      dataStatus == 'ACCEPTED' ||
      dataStatus == 'COMPLETED' ||
      dataStatus == 'SUCCESS';
}

void _showSuccessDialog(BuildContext context, LanguageProvider lang) {
  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(lang.t('payment_success_title')),
      content: Text(lang.t('payment_success_message')),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(lang.t('close')),
        ),
      ],
    ),
  );
}

String _paymentErrorMessage(Object error, LanguageProvider lang) {
  final message = error.toString().toLowerCase();

  if (message.contains('cancel') || message.contains('canceled')) {
    return lang.t('payment_cancelled_message');
  }

  if (message.contains('network') ||
      message.contains('socket') ||
      message.contains('connection') ||
      message.contains('timeout')) {
    return lang.t('payment_network_error');
  }

  if (message.contains('card') ||
      message.contains('payment_method') ||
      message.contains('declined')) {
    return lang.t('payment_method_error');
  }

  return lang.t('payment_processing_error');
}

String? _extractPaymentUrl(dynamic result) {
  if (result is! Map) return null;

  final data = result['data'];
  final candidates = [
    result['payment_url'],
    result['paymentUrl'],
    result['payment_link'],
    result['paymentLink'],
    result['checkout_url'],
    result['checkoutUrl'],
    result['redirect_url'],
    result['redirectUrl'],
    result['approval_url'],
    result['approvalUrl'],
    result['url'],
    if (data is Map) data['payment_url'],
    if (data is Map) data['paymentUrl'],
    if (data is Map) data['payment_link'],
    if (data is Map) data['paymentLink'],
    if (data is Map) data['checkout_url'],
    if (data is Map) data['checkoutUrl'],
    if (data is Map) data['redirect_url'],
    if (data is Map) data['redirectUrl'],
    if (data is Map) data['approval_url'],
    if (data is Map) data['approvalUrl'],
    if (data is Map) data['url'],
  ];

  for (final value in candidates) {
    final url = value?.toString().trim();
    if (url != null && url.isNotEmpty) return url;
  }

  return null;
}

String? _extractOrderId(dynamic result) {
  if (result is! Map) return null;

  final data = result['data'];
  final candidates = [
    result['transaction_id'],
    result['id'],
    result['order_id'],
    result['orderId'],
    if (data is Map) data['transaction_id'],
    if (data is Map) data['id'],
    if (data is Map) data['order_id'],
    if (data is Map) data['orderId'],
  ];

  for (final value in candidates) {
    final orderId = value?.toString().trim();
    if (orderId != null && orderId.isNotEmpty) return orderId;
  }

  return null;
}

void showErrorDialog(BuildContext context, String message) {
  final lang = Provider.of<LanguageProvider>(context, listen: false);

  showDialog(
    context: context,
    builder: (_) => AlertDialog(
      title: Text(lang.t('payment_error_title')),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(lang.t('close')),
        ),
      ],
    ),
  );
}

String getPaymentService(String paymentMethod) {
  switch (paymentMethod) {
    case "Credit Card":
      return "stripe";
    case "Mobile Money":
      return "cinetpay";
    case "PayPal":
      return "paypal";
    default:
      throw Exception("Unsupported payment method: $paymentMethod");
  }
}
