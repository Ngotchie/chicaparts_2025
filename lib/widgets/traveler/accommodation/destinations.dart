import 'package:chicaparts_partner/api/traveler/api_accommodation_traveler.dart';
import 'package:chicaparts_partner/models/traveler/model_accommodation_traveler.dart';
import 'package:chicaparts_partner/widgets/menu/bottomMenuTraveler.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:shimmer/shimmer.dart';

class DestinationsPage extends StatefulWidget {
  const DestinationsPage({super.key});

  @override
  _DestinationsPageState createState() => _DestinationsPageState();
}

class _DestinationsPageState extends State<DestinationsPage> {
  List<Destination> _destinations = [];
  List<Destination> _filteredDestinations = [];
  final TextEditingController _searchController = TextEditingController();
  final apiAcc = ApiAccommodationTraveler();

  @override
  void initState() {
    super.initState();
    loadDestinations();
  }

  // Récupérer les destinations depuis l'API
  // Charger les destinations
  void loadDestinations() async {
    try {
      List<Destination> data = await apiAcc.fetchDestinations();
      setState(() {
        _destinations = data;
        _filteredDestinations = List.from(_destinations);
      });
    } catch (e) {
      print("Erreur: $e");
    }
  }

  Future<List<Stay>> getDestinationStays(destination) async {
    List<Stay> response = [];
    try {
      response = await apiAcc.destinationStays(destination);
    } catch (e) {
      print("Erreur: $e");
    }
    return response;
  }

  // Fonction de recherche
  void _filterDestinations(String query) {
    setState(() {
      _filteredDestinations = _destinations
          .where((destination) =>
              destination.name.toLowerCase().contains(query.toLowerCase()))
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
            // 🔝 Barre de navigation avec ombre en arrière-plan
            Container(
              height: 50,
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
                    "Explore Destinations", // 🔥 Titre sympa
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black),
                  ),
                  const SizedBox(width: 48), // Pour équilibrer l'espace
                ],
              ),
            ),

            const SizedBox(height: 10),

            // 🔍 Barre de recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: TextField(
                controller: _searchController,
                onChanged: _filterDestinations, // Filtrage en temps réel
                decoration: InputDecoration(
                  hintText: "Search destinations...",
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

            // 🌍 Liste des destinations
            Expanded(
              child: _filteredDestinations.isEmpty && _destinations.isEmpty
                  ? Center(
                      child: Shimmer.fromColors(
                        baseColor: Colors.grey[300]!,
                        highlightColor: Colors.white,
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    )
                  : _filteredDestinations.isEmpty
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
                                  "Aucune destination corespondante",
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
                                  "Essayez de saisir une autre destination.",
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
                          itemCount: _filteredDestinations.length,
                          itemBuilder: (context, index) {
                            return destinationCard(
                                _filteredDestinations[index]);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  // 📌 Widget d'une carte destination
  Widget destinationCard(Destination destination) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0), // Animation de 0% à 100%
      duration: const Duration(milliseconds: 500),
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity,
          child: child,
        );
      },
      child: GestureDetector(
        onTap: () async {
          List<Stay> response = await getDestinationStays(destination.name);
          // 👇 Naviguer vers la page des résultats
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  BottomMenuTraveler(index: 1, results: response),
            ),
          );
        },
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                  color: Colors.grey.withOpacity(0.3),
                  blurRadius: 5,
                  spreadRadius: 2),
            ],
          ),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.network(
                  destination.imageUrl, // Utilisation du lien dynamique
                  width: double.infinity,
                  height: 200,
                  fit: BoxFit.cover,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.white,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        color: Colors.white,
                      ),
                    ); // Loader Shimmer ⏳
                  },
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.broken_image,
                        size: 160, color: Colors.grey); // Icône en cas d'erreur
                  },
                ),
              ),
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(15),
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.6), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                left: 15,
                bottom: 15,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      destination.name,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold),
                    ),
                    Text(
                      "${destination.accommodations} accommodations",
                      style: const TextStyle(color: Colors.white, fontSize: 14),
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
}
