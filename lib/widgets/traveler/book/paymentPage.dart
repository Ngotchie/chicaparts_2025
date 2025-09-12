import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/widgets/traveler/book/payment_processing_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:chicaparts_partner/api/traveler/api_booking_traveler.dart';
import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/exchange_rate_provider.dart';
import 'package:chicaparts_partner/utils/currency_converter.dart';
import 'package:chicaparts_partner/widgets/traveler/book/billingInfos.dart';
import 'package:chicaparts_partner/widgets/traveler/book/selectBookingDetails.dart';

class PaymentPage extends StatefulWidget {
  final BookingDetails bookingDetails;
  final BillingInfo billingInfo;

  const PaymentPage(
      {Key? key, required this.bookingDetails, required this.billingInfo})
      : super(key: key);

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  TimeOfDay? _arrivalTime;
  final ApiBooking apiBooking = ApiBooking();
  bool isLoading = false;
  bool _showFullLoader = false;

  @override
  Widget build(BuildContext context) {
    var exchangeRates = context.watch<ExchangeRateProvider>().rates;
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text('💳 Payment',
                style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: Padding(
            padding: const EdgeInsets.all(16),
            child: ListView(
              children: [
                _sectionTitle("📌 ${lang.t('bookong_details')}"),
                _buildDetailRow(
                    "Check-in", _formatDate(widget.bookingDetails.checkIn)),
                _buildDetailRow(
                    "Check-out", _formatDate(widget.bookingDetails.checkOut)),
                _buildDetailRow(lang.t('travelers'),
                    "${widget.bookingDetails.adults} ${lang.t('adults')}, ${widget.bookingDetails.children} ${lang.t('children')}"),
                if (_arrivalTime != null)
                  _buildDetailRow(
                      lang.t('arrival_time'), _formatTime(_arrivalTime!)),
                const SizedBox(height: 10),
                _buildArrivalTimeSelector(),
                _sectionTitle("💰 ${lang.t('payment_sommary')}"),
                _buildDetailRow(
                    "🏠 ${lang.t('base_price')}",
                    CurrencyConverter.format(widget.bookingDetails.totalPrice,
                        from: 'EUR',
                        to: context.read<CurrencyProvider>().currency,
                        rates: exchangeRates)),
                _buildDetailRow(
                    "🧹 ${lang.t('cleaning_fees')}",
                    CurrencyConverter.format(widget.bookingDetails.cleaningFees,
                        from: 'EUR',
                        to: context.read<CurrencyProvider>().currency,
                        rates: exchangeRates)),
                _buildDetailRow(
                    "🏙 ${lang.t('city_taxe')}",
                    CurrencyConverter.format(widget.bookingDetails.cityTaxe,
                        from: 'EUR',
                        to: context.read<CurrencyProvider>().currency,
                        rates: exchangeRates)),
                _buildDetailRow(
                    "🏡 ${lang.t('chicaparts_fees')}",
                    CurrencyConverter.format(
                        widget.bookingDetails.chicapartsFees,
                        from: 'EUR',
                        to: context.read<CurrencyProvider>().currency,
                        rates: exchangeRates)),
                Divider(thickness: 1, color: Colors.grey[400]),
                _buildDetailRow(
                    lang.t('total_price'),
                    CurrencyConverter.format(widget.bookingDetails.finalPrice,
                        from: 'EUR',
                        to: context.read<CurrencyProvider>().currency,
                        rates: exchangeRates),
                    isTotal: true),
                const SizedBox(height: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: isLoading
                      ? null
                      : () async {
                          setState(() {
                            isLoading = true;
                            _showFullLoader = true;
                          });

                          try {
                            final bookingResult =
                                await apiBooking.submitReservation(
                              booking: widget.bookingDetails,
                              billing: widget.billingInfo,
                              arrivalTime: _arrivalTime?.format(context),
                            );

                            if (bookingResult != null &&
                                bookingResult['id'] != null) {
                              final int bookingId = bookingResult['id'];

                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PaymentProcessingPage(
                                    bookingId: bookingId,
                                    amount: widget.bookingDetails.finalPrice,
                                    currency: context
                                        .read<CurrencyProvider>()
                                        .currency,
                                    customerEmail: widget.billingInfo.email,
                                    checkInFormatted: _formatDate(
                                        widget.bookingDetails.checkIn),
                                  ),
                                ),
                              );
                            } else {
                              _showError(context,
                                  "Impossible d'enregistrer la réservation.");
                            }
                          } catch (e) {
                            _showError(
                                context, "Erreur lors de la réservation: $e");
                          } finally {
                            setState(() {
                              isLoading = false;
                              _showFullLoader = false;
                            });
                          }
                        },

                  /// ✅ Ajouté ici :
                  child: isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : Text(
                          lang.t('confirm_pay'),
                          style: const TextStyle(color: Colors.white),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showError(BuildContext context, String msg) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lang.t('error')),
        content: Text(msg),
        actions: [
          TextButton(
            child: Text(lang.t('close')),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  Widget _sectionTitle(String title) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(title,
            style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.blueAccent)),
      );

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) =>
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text(value,
                style: TextStyle(
                  color: isTotal ? Colors.green : Colors.black,
                  fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
                )),
          ],
        ),
      );

  Widget _buildArrivalTimeSelector() => InkWell(
        onTap: () async {
          final picked = await showTimePicker(
            context: context,
            initialTime: _arrivalTime ?? const TimeOfDay(hour: 14, minute: 0),
          );
          if (picked != null) {
            setState(() => _arrivalTime = picked);
          }
        },
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: Colors.grey[200],
          ),
          child: const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("⏰ Select Arrival Time"),
              Icon(Icons.access_time),
            ],
          ),
        ),
      );

  String _formatDate(DateTime date) => DateFormat("dd MMM yyyy").format(date);

  String _formatTime(TimeOfDay time) => time.format(context);
}
