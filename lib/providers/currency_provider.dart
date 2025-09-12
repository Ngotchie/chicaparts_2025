import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyProvider extends ChangeNotifier {
  String _currency = "EUR";

  String get currency => _currency;

  Future<void> initCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    _currency = prefs.getString('app_currency') ?? "EUR";
    notifyListeners();
  }

  Future<void> setCurrency(String value) async {
    _currency = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_currency', value);
    notifyListeners();
  }
}
