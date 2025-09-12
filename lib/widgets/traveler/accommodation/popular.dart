import 'package:chicaparts_partner/api/traveler/api_accommodation_traveler.dart';
import 'package:chicaparts_partner/methodTraveler.dart';
import 'package:chicaparts_partner/models/traveler/model_accommodation_traveler.dart';
import 'package:chicaparts_partner/widgets/traveler/accommodation/accommodationDetails.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shimmer/shimmer.dart';

class AllPopularStaysPage extends StatefulWidget {
  const AllPopularStaysPage({super.key});

  @override
  _AllPopularStaysPageState createState() => _AllPopularStaysPageState();
}

class _AllPopularStaysPageState extends State<AllPopularStaysPage> {
  List<Stay> _stays = [];
  List<Stay> _filteredStays = [];
  final TextEditingController _searchController = TextEditingController();
  List<Stay> stays = [];
  final apiAcc = ApiAccommodationTraveler();
  bool _isLoading = true;
  MethodsTraveler mthTr = MethodsTraveler();

  @override
  void initState() {
    super.initState();
    fetchStays();
  }

  // Charger les hébergements populaires
  void fetchStays() async {
    try {
      List<Stay> data = await apiAcc.fetchStays();
      setState(() {
        _stays = data;
        _filteredStays = List.from(_stays);
        _isLoading = false;
      });
    } catch (e) {
      print("Erreur: $e");
    }
  }

  // Fonction de recherche
  void _filterStays(String query) {
    setState(() {
      _filteredStays = _stays
          .where((stay) =>
              stay.location.toLowerCase().contains(query.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🔝 Barre de navigation avec bouton retour et titre
            Container(
              height: 50,
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // 🔙 Bouton retour
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () {
                        Navigator.pop(context); // Retour à la page précédente
                      },
                    ),
                    // 📌 Titre de la page
                    const Text(
                      "Best Stays", // 🔥 Titre sympa
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black),
                    ),
                    const SizedBox(width: 48), // Pour équilibrer l'espace
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
            // 🔍 Barre de recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                onChanged: _filterStays, // Filtrage en temps réel
                decoration: InputDecoration(
                  hintText: "Search location...",
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 10),

            // 🏡 Liste des hébergements
            Expanded(
              child: _isLoading && _filteredStays.isEmpty && _stays.isEmpty
                  ? mthTr.buildShimmerLoader() // Loader pendant le chargement
                  : _filteredStays.isEmpty
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24.0, vertical: 40.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.search_off_outlined,
                                  size: 60,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  "Aucun hébergement trouvé",
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color:
                                        Color(0xFF244B6B), // ton bleu principal
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Essayez de changer la localisation.",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey[600],
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ],
                            ),
                          ),
                        ) // 🔍 Message si la recherche ne trouve rien
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          itemCount: _filteredStays.length,
                          itemBuilder: (context, index) {
                            return mthTr.stayCard(
                                context, _filteredStays[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
