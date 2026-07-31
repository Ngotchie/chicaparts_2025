import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/exchange_rate_provider.dart';
import 'package:chicaparts_partner/utils/currency_converter.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class ReviewReservationPage extends StatefulWidget {
  final DateTime checkIn;
  final DateTime checkOut;
  final int adults;
  final int children;
  final double totalPrice;
  final String currency;
  final double cleaningFees;
  final double cityTaxe;

  const ReviewReservationPage({
    super.key,
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.totalPrice,
    this.currency = 'EUR',
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
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final selectedCurrency = context.watch<CurrencyProvider>().currency;
    final exchangeRates = context.watch<ExchangeRateProvider>().rates;
    final chicapartsFees = widget.totalPrice * 0.10;
    final finalPrice = widget.totalPrice +
        widget.cleaningFees +
        widget.cityTaxe +
        chicapartsFees;
    String money(double amount) => CurrencyConverter.format(
          amount,
          from: widget.currency,
          to: selectedCurrency,
          rates: exchangeRates,
        );

    return Scaffold(
      appBar: AppBar(
        title: Text(
          lang.t('review_booking'),
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow(
                lang.t('booking_date'), _formatDate(DateTime.now())),
            _buildDetailRow(lang.t('check_in'), _formatDate(widget.checkIn)),
            _buildDetailRow(lang.t('check_out'), _formatDate(widget.checkOut)),
            const SizedBox(height: 10),
            _buildDetailRow(
              lang.t('travelers'),
              "${widget.adults} ${lang.t('adults')}, ${widget.children} ${lang.t('children')}",
            ),
            const SizedBox(height: 10),
            if (_arrivalTime != null)
              _buildDetailRow(
                  lang.t('arrival_time'), _formatTime(_arrivalTime!)),
            const SizedBox(height: 10),
            _buildArrivalTimeSelector(context, lang),
            const SizedBox(height: 20),
            Text(
              lang.t('payment_summary'),
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            _buildDetailRow(
              lang.t('base_price'),
              money(widget.totalPrice),
            ),
            _buildDetailRow(
              lang.t('cleaning_fees'),
              money(widget.cleaningFees),
            ),
            _buildDetailRow(
              lang.t('city_taxe'),
              money(widget.cityTaxe),
            ),
            _buildDetailRow(
              "${lang.t('chicaparts_fees')} (10%)",
              money(chicapartsFees),
            ),
            Divider(thickness: 1, color: Colors.grey[400]),
            _buildDetailRow(
              lang.t('total_price'),
              money(finalPrice),
              isTotal: true,
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                BookingDetails1(
                  checkIn: widget.checkIn,
                  checkOut: widget.checkOut,
                  adults: widget.adults,
                  children: widget.children,
                  totalPrice: widget.totalPrice,
                  currency: widget.currency,
                  cleaningFees: widget.cleaningFees,
                  cityTaxe: widget.cityTaxe,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF244B6B),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Center(
                child: Text(
                  lang.t('proceed_to_payment'),
                  style: const TextStyle(fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    return DateFormat("dd MMMM yyyy").format(date);
  }

  String _formatTime(TimeOfDay time) {
    return time.format(context);
  }

  Widget _buildDetailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: isTotal ? 18 : 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
              color: isTotal ? Colors.green : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrivalTimeSelector(
    BuildContext context,
    LanguageProvider lang,
  ) {
    return InkWell(
      onTap: () async {
        final pickedTime = await showTimePicker(
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              lang.t('arrival_time'),
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const Icon(Icons.access_time, color: Colors.blueAccent),
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
  final String currency;
  final double cleaningFees;
  final double cityTaxe;
  final double chicapartsFees;

  BookingDetails1({
    required this.checkIn,
    required this.checkOut,
    required this.adults,
    required this.children,
    required this.totalPrice,
    this.currency = 'EUR',
    required this.cleaningFees,
    required this.cityTaxe,
  }) : chicapartsFees = totalPrice * 0.10;

  double get finalPrice =>
      totalPrice + cleaningFees + cityTaxe + chicapartsFees;
}
