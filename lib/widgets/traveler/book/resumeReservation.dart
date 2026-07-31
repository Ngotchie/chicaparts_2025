import 'dart:convert';

import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/exchange_rate_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/utils/currency_converter.dart';
import 'package:chicaparts_partner/widgets/traveler/book/book_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final colors = Theme.of(context).colorScheme;

    if (reservation == null) {
      return Scaffold(
        backgroundColor: colors.surface,
        appBar: buildBookAppBar(lang.t('resume_booking')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final selectedCurrency = context.watch<CurrencyProvider>().currency;
    final exchangeRates = context.watch<ExchangeRateProvider>().rates;
    final reservationCurrency = reservation!['currency']?.toString() ?? 'EUR';
    String money(dynamic amount) => CurrencyConverter.format(
          _toDouble(amount),
          from: reservationCurrency,
          to: selectedCurrency,
          rates: exchangeRates,
        );

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: buildBookAppBar(lang.t('booking_details')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _info(lang.t('property_id'), reservation!['propId']),
            _info(lang.t('room'), reservation!['roomId']),
            _info(
              lang.t('stay'),
              "${lang.t('from')} ${reservation!['firstNight']} ${lang.t('to')} ${reservation!['lastNight']}",
            ),
            _info(
              lang.t('adults_children'),
              "${reservation!['numAdult']} ${lang.t('adults')}, ${reservation!['numChild']} ${lang.t('children')}",
            ),
            const Divider(height: 30),
            _info(
              lang.t('guest'),
              "${reservation!['guestTitle']} ${reservation!['guestFirstName']} ${reservation!['guestName']}",
            ),
            _info(lang.t('email'), reservation!['guestEmail']),
            _info(lang.t('phone'), reservation!['guestPhone']),
            _info(
              lang.t('address_label'),
              "${reservation!['guestAddress']}, ${reservation!['guestCity']} ${reservation!['guestPostcode']}, ${reservation!['guestCountry']}",
            ),
            if (reservation!['guestArrivalTime'] != null)
              _info(lang.t('arrival_time'), reservation!['guestArrivalTime']),
            const Divider(height: 30),
            _info(lang.t('stay_price'), money(reservation!['price'])),
            _info(lang.t('taxes'), money(reservation!['tax'])),
            _info(lang.t('commission'), money(reservation!['commission'])),
            _info(
              lang.t('cleaning_fees'),
              money(reservation!['cleaning_fees_partner']),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.payment),
                label: Text(lang.t('resume_payment')),
                onPressed: () {
                  Navigator.pushNamed(
                    context,
                    "/payment",
                    arguments: reservation,
                  );
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

  double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  Widget _info(String label, dynamic value) {
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
            child: Text(
              value?.toString() ?? '',
              style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
            ),
          )
        ],
      ),
    );
  }
}
