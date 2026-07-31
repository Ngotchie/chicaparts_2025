import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/widgets/traveler/book/billingInfos.dart';
import 'package:chicaparts_partner/widgets/traveler/book/selectBookingDetails.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

showPaymentDialog(
  BuildContext parentContext,
  BookingDetails bookingDetails,
  BillingInfo billingInfo,
  TimeOfDay? arrivalTime,
) {
  final lang = Provider.of<LanguageProvider>(parentContext, listen: false);

  showModalBottomSheet(
    context: parentContext,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
    ),
    isScrollControlled: true,
    builder: (context) {
      final selectedPaymentMethod = ValueNotifier("Credit Card");

      return StatefulBuilder(
        builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: ValueListenableBuilder<String>(
              valueListenable: selectedPaymentMethod,
              builder: (context, selected, _) {
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      lang.t('select_payment_method'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildPaymentOption(
                      selectedPaymentMethod,
                      "Credit Card",
                      lang,
                    ),
                    _buildPaymentOption(
                      selectedPaymentMethod,
                      "Mobile Money",
                      lang,
                    ),
                    _buildPaymentOption(selectedPaymentMethod, "PayPal", lang),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF244B6B),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        lang.t('continue'),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      );
    },
  );
}

Widget _buildPaymentOption(
  ValueNotifier<String> selected,
  String method,
  LanguageProvider lang,
) {
  return GestureDetector(
    onTap: () => selected.value = method,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected.value == method ? Colors.blue[50] : Colors.white,
        border: Border.all(
          color: selected.value == method ? const Color(0xFF244B6B) : Colors.grey,
        ),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(_methodLabel(method, lang), style: const TextStyle(fontSize: 16)),
          Radio<String>(
            value: method,
            groupValue: selected.value,
            onChanged: (value) => selected.value = method,
          ),
        ],
      ),
    ),
  );
}

String _methodLabel(String method, LanguageProvider lang) {
  switch (method) {
    case "Credit Card":
      return lang.t('credit_card');
    case "Mobile Money":
      return lang.t('mobile_money');
    case "PayPal":
      return lang.t('paypal');
    default:
      return method;
  }
}
