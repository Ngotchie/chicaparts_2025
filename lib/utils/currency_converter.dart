import 'package:intl/intl.dart';

class CurrencyConverter {
  // static const Map<String, double> _ratesToEUR = {
  //   'EUR': 1.0,
  //   'XAF': 655.957,
  //   'USD': 1.1,
  //   'GBP': 0.85,
  //   'CAD': 1.45,
  // };

  /// Convertit une devise source vers une devise cible
  static double convert({
    required double amount,
    required String from,
    required String to,
    required Map<String, double> rates,
  }) {
    if (from == to) return amount;

    final fromRate = rates[from] ?? 1.0;
    final toRate = rates[to] ?? 1.0;

    // Convertir vers EUR, puis vers target
    double amountInEUR = from == 'EUR' ? amount : amount / fromRate;
    return to == 'EUR' ? amountInEUR : amountInEUR * toRate;
  }

  /// Affichage propre formaté : 1 230 USD
  static String format(
    double amount, {
    required String from,
    required String to,
    required Map<String, double> rates,
  }) {
    final converted = convert(amount: amount, from: from, to: to, rates: rates);
    final formatted = to != "XAF"
        ? NumberFormat("#,##0.00", "fr_FR").format(converted)
        : NumberFormat("#,##0", "fr_FR").format(converted.round());
    return "$to $formatted";
  }
}
