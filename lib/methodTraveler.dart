import 'dart:convert';

import 'package:chicaparts_partner/models/traveler/model_accommodation_traveler.dart';
import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/exchange_rate_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/services/favorite_repository.dart';
import 'package:chicaparts_partner/utils/currency_converter.dart';
import 'package:chicaparts_partner/widgets/traveler/accommodation/accommodationDetails.dart';
import 'package:chicaparts_partner/widgets/traveler/accommodation/optimized_network_image.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';

const String mapboxApiKey =
    "pk.eyJ1IjoibmEyYXhsIiwiYSI6ImNqZ21rb2licjF0eWQycXBqNHF0ZDk3ejYifQ.ddbMwUsUIfCAtOR_fpmSIQ"; // Remplace par ta clé API

class MethodsTraveler {
  Future<List<dynamic>> fetchSuggestions(String query) async {
    final url = Uri.parse(
        "https://api.mapbox.com/geocoding/v5/mapbox.places/$query.json?access_token=$mapboxApiKey&autocomplete=true&limit=5");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['features'];
    } else {
      print("Erreur Mapbox: ${response.statusCode}");
      return [];
    }
  }

  Widget sectionTitle(String title, Color color) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: color,
      ),
    );
  }

  Widget coloredStepper(
      String label, int value, Color color, Function(int) onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 16)),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.remove_circle, color: color),
                onPressed: value > 0 ? () => onChanged(value - 1) : null,
              ),
              Text("$value",
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w600)),
              IconButton(
                icon: Icon(Icons.add_circle, color: color),
                onPressed: () => onChanged(value + 1),
              ),
            ],
          ),
        ],
      ),
    );
  }

// ☑️ Widget pour gérer les CheckboxListTile
  Widget buildCheckbox(String label, bool value, Function(bool) onChanged) {
    return CheckboxListTile(
      title: Text(label),
      value: value,
      onChanged: (val) => onChanged(val!),
    );
  }

  // 📌 Widget d'une carte hébergement
  Widget stayCard(BuildContext context, Stay stay) {
    final exchangeRates = context.watch<ExchangeRateProvider>().rates;

    final displayPrice = CurrencyConverter.format(stay.price.toDouble(),
        from: stay.currency, // Exemple: 'CFA' ou 'EUR'
        to: context.read<CurrencyProvider>().currency, // Ex: 'GBP', 'USD'
        rates: exchangeRates);
    final lang = context.read<LanguageProvider>();
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0), // Animation de 0% à 100%
      duration: const Duration(milliseconds: 500), // ⏳ Durée de l’animation
      curve: Curves.easeOut, // Effet de fluidité
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity, // 🎭 Apparition progressive
          child: Transform.translate(
            offset:
                Offset((1 - opacity) * 50, 0), // 🚀 Glissement depuis la droite
            child: child,
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
                color: Colors.grey.withOpacity(0.3),
                blurRadius: 5,
                spreadRadius: 2),
          ],
        ),
        child: GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AccommodationDetails(
                  accommodationId: stay.id,
                  dayPrice: stay.price,
                  currency: stay.currency,
                ),
              ),
            );
          },
          child: Row(
            children: [
              // 📷 Image à gauche
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: OptimizedNetworkImage(
                  imageUrl: stay.thumbnailUrl,
                  width: 100,
                  height: 100,
                  fit: BoxFit.cover,
                  memCacheWidth: 240,
                  memCacheHeight: 240,
                  maxWidthDiskCache: 360,
                  maxHeightDiskCache: 360,
                ),
              ),
              const SizedBox(width: 10),
              // 🏡 Informations à droite
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      stay.title,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      stay.location,
                      style: const TextStyle(color: Colors.grey, fontSize: 14),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      stay.price > 0
                          ? "$displayPrice / ${lang.t("night")}"
                          : "📞 Contact us",
                      style: const TextStyle(
                          color: Colors.blue,
                          fontSize: 14,
                          fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🎨 Widget Shimmer Loader
  Widget buildShimmerLoader() {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      itemCount: 6, // 6 éléments fictifs pour le shimmer
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: Colors.grey.shade300,
          highlightColor: Colors.grey.shade100,
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            padding: const EdgeInsets.all(8),
            height: 110, // Taille d'une carte
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
          ),
        );
      },
    );
  }

  void showLoginPromptFavorites(BuildContext context) {
    final lang = context.read<LanguageProvider>();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lang.t("connection_required")),
        content: Text(lang.t("connection_required_message")),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        actions: [
          TextButton(
            child: Text(lang.t("cancelled")),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF244B6B),
            ),
            child: Text(
              lang.t("login"),
              style: const TextStyle(color: Colors.white),
            ),
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, "/login");
            },
          ),
        ],
      ),
    );
  }
}
