import 'package:flutter/material.dart';
import 'package:chicaparts_partner/widgets/traveler/book/payment_logic.dart';
import 'package:chicaparts_partner/widgets/traveler/book/selectBookingDetails.dart';
import 'package:chicaparts_partner/widgets/traveler/book/billingInfos.dart';

showPaymentDialog(BuildContext parentContext, BookingDetails bookingDetails,
    BillingInfo billingInfo, TimeOfDay? arrivalTime) {
  showModalBottomSheet(
    context: parentContext,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
    ),
    isScrollControlled: true,
    builder: (context) {
      // Utiliser une variable mutable via ValueNotifier
      final ValueNotifier<String> selectedPaymentMethod =
          ValueNotifier("Credit Card");

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
                    const Text("Select Payment Method",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    _buildPaymentOption(selectedPaymentMethod, "Credit Card"),
                    _buildPaymentOption(selectedPaymentMethod, "Mobile Money"),
                    _buildPaymentOption(selectedPaymentMethod, "PayPal"),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () async {
                        Navigator.pop(context);
                        // final result = await processPayment(
                        //   context,
                        //   bookingDetails,
                        //   billingInfo,
                        //   arrivalTime,
                        //   selectedPaymentMethod.value,
                        // );
                        // if (result != null) {
                        //   await handlePaymentResponse(parentContext, result,
                        //       selectedPaymentMethod.value);
                        // } else {
                        //   showErrorDialog(parentContext,
                        //       "An error occurred while processing your payment.");
                        // }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF244B6B),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                      ),
                      child: const Text("Continue",
                          style: TextStyle(color: Colors.white)),
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

Widget _buildPaymentOption(ValueNotifier<String> selected, String method) {
  return GestureDetector(
    onTap: () => selected.value = method,
    child: Container(
      margin: const EdgeInsets.symmetric(vertical: 5),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: selected.value == method ? Colors.blue[50] : Colors.white,
        border: Border.all(
            color: selected.value == method
                ? const Color(0xFF244B6B)
                : Colors.grey),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(method, style: const TextStyle(fontSize: 16)),
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
