import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ExchangeRateProvider with ChangeNotifier {
  Map<String, double> _rates = {
    'EUR': 1.0,
    'XAF': 655.957,
    'USD': 1.1,
    'GBP': 0.85,
    'CAD': 1.45,
  };

  Map<String, double> get rates => _rates;

  Future<void> loadRates() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // ⚡ Charger depuis cache si dispo
      final cached = prefs.getString('exchange_rates');
      if (cached != null) {
        _rates = Map<String, double>.from(jsonDecode(cached));
        notifyListeners();
      }

      // 🌐 Requête en ligne
      final response = await http
          .get(Uri.parse("https://api.exchangerate.host/latest?base=EUR"));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rates = Map<String, double>.from(data['rates']);
        _rates = rates;

        // 💾 Cache
        prefs.setString('exchange_rates', jsonEncode(rates));
        notifyListeners();
      }
    } catch (e) {
      print("Erreur récupération taux : $e");
    }
  }

  double getRate(String currencyCode) {
    return _rates[currencyCode] ?? 1.0;
  }
}
