import 'dart:convert';

import 'package:chicaparts_partner/api/traveler/api_booking_traveler.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/exchange_rate_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/services/traveler_payment_flow.dart';
import 'package:chicaparts_partner/utils/currency_converter.dart';
import 'package:flutter/material.dart';
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
  bool _isProcessing = false;
  final TravelerPaymentFlow _paymentFlow = TravelerPaymentFlow();

  User? _currentUser;
  String? _customerPhoneNumber;

  /// Charge le user local
  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    _customerPhoneNumber = _extractPhoneNumber(prefs);

    if (userJson == null) {
      _currentUser = null;
      return;
    }

    _currentUser = User.fromJson(jsonDecode(userJson));
    _customerPhoneNumber ??= _extractUserPhoneNumber(_currentUser);
  }

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final selectedCurrency = context.watch<CurrencyProvider>().currency;
    final exchangeRates = context.watch<ExchangeRateProvider>().rates;
    final displayedAmount = CurrencyConverter.format(
      widget.amount,
      from: widget.currency,
      to: selectedCurrency,
      rates: exchangeRates,
    );
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
              onPressed: _isProcessing ? null : () => _payTip(lang),
              /*() async {
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
                  await handlePaymentResponse(
                    context,
                    result,
                    selectedMethod,
                    bookingId: widget.bookingId,
                  );
                } else {
                  showErrorDialog(
                    context,
                    "Error during task proceding",
                  );
                }
              },*/
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF244B6B),
              ),
              child: Text(
                _isProcessing
                    ? lang.t('saving')
                    : "${lang.t('pay_tip')} ($displayedAmount)",
                style: const TextStyle(color: Colors.white),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _payTip(LanguageProvider lang) async {
    if (_currentUser == null) {
      await _loadUser();
    }

    if (!mounted || _currentUser == null) {
      showErrorDialog(context, lang.t('login_required_text'));
      return;
    }

    setState(() => _isProcessing = true);
    try {
      final result = await _paymentFlow.startOrResume(
        context,
        TravelerPaymentRequest(
          bookingId: widget.bookingId,
          amount: widget.amount,
          currency: widget.currency,
          customerEmail: widget.customerEmail,
          customerPhoneNumber: _customerPhoneNumber,
          method: selectedMethod,
          label: widget.stayLabel,
          paymentItemType: 'tip',
          allowNewAttemptWhenExisting: true,
          checkExistingBeforeCheckout: false,
        ),
        showSuccessDialog: false,
      );

      if (!result.isPaid) {
        if (result.message != null && mounted) {
          showErrorDialog(context, result.message!);
        }
        return;
      }

      final transactionId = _extractTransactionId(
        result.transaction ?? result.order?.raw,
      );
      if (transactionId == null) {
        showErrorDialog(context, lang.t('payment_processing_error'));
        return;
      }

      final api = ApiBooking();
      await api.sendTip(
        bookingId: widget.bookingId,
        transactionId: transactionId,
        amount: widget.amount.toInt(),
        currency: widget.currency,
        percentage: 0,
        userId: _currentUser!.id,
        message: null,
      );

      if (!mounted) return;
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(lang.t('payment_success_title')),
          content: Text(lang.t('tip_msg')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/my-account',
                  (route) => false,
                );
              },
              child: Text(lang.t('close')),
            ),
          ],
        ),
      );
    } catch (e) {
      debugPrint('Tip payment error: $e');
      if (mounted) showErrorDialog(context, lang.t('payment_processing_error'));
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  int? _extractTransactionId(dynamic result) {
    if (result is! Map) return null;

    final data = result['data'];
    final candidates = [
      result['transaction_id'],
      result['id'],
      result['transactionId'],
      if (data is Map) data['transaction_id'],
      if (data is Map) data['id'],
      if (data is Map) data['transactionId'],
    ];

    for (final value in candidates) {
      if (value is int && value > 0) return value;
      if (value is num && value > 0) return value.toInt();
      final parsed = int.tryParse('$value');
      if (parsed != null && parsed > 0) return parsed;
    }

    return null;
  }

  String? _extractPhoneNumber(SharedPreferences prefs) {
    final billingPhone = prefs.getString('billing_phone')?.trim();
    if (billingPhone != null && billingPhone.isNotEmpty) {
      return billingPhone;
    }

    return null;
  }

  String? _extractUserPhoneNumber(User? user) {
    final thirdParty = user?.thirdParty;
    if (thirdParty is Map) {
      final candidates = [
        thirdParty['mobile_phone_number'],
        thirdParty['phone'],
        thirdParty['mobile'],
      ];

      for (final value in candidates) {
        final phone = value?.toString().trim();
        if (phone != null && phone.isNotEmpty) return phone;
      }
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
