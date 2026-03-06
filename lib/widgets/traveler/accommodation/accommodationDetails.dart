import 'dart:convert';

import 'package:chicaparts_partner/api/traveler/api_accommodation_traveler.dart';
import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/exchange_rate_provider.dart';
import 'package:chicaparts_partner/providers/favorite_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/utils/currency_converter.dart';
import 'package:chicaparts_partner/widgets/traveler/book/selectBookingDetails.dart';
import 'package:chicaparts_partner/widgets/traveler/accommodation/equipments.dart';
import 'package:chicaparts_partner/widgets/traveler/accommodation/fullImageGallery.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:provider/provider.dart';
import 'package:chicaparts_partner/methodTraveler.dart';

class AccommodationDetails extends StatefulWidget {
  final int accommodationId;
  final double dayPrice;
  final String currency;

  const AccommodationDetails(
      {super.key,
      required this.accommodationId,
      required this.dayPrice,
      required this.currency});

  @override
  _AccommodationDetailsState createState() => _AccommodationDetailsState();
}

class _AccommodationDetailsState extends State<AccommodationDetails> {
  Map<String, dynamic>? accommodation;
  bool _isLoading = true;
  bool _isExpanded = false;
  int _currentImageIndex = 0;
  final apiAcc = ApiAccommodationTraveler();
  final mthTr = MethodsTraveler();

  bool isGuest = true;
  dynamic user;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    fetchAccommodationDetails();
  }

  void fetchAccommodationDetails() async {
    try {
      final data =
          await apiAcc.fetchAccommodationDetails(widget.accommodationId);
      setState(() {
        accommodation = data;
        _isLoading = false;
      });
    } catch (e) {
      print("Erreur: $e");
    }
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson != null) {
      final decoded = jsonDecode(userJson);
      setState(() {
        user = decoded;
        isGuest = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final exchangeRates = context.watch<ExchangeRateProvider>().rates;

    final displayPrice = CurrencyConverter.format(widget.dayPrice.toDouble(),
        from: widget.currency, // Exemple: 'CFA' ou 'EUR'
        to: context.read<CurrencyProvider>().currency, // Ex: 'GBP', 'USD'
        rates: exchangeRates);
    final lang = context.read<LanguageProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? Center(child: _buildLoadingDetails())
            : Stack(
                children: [
                  SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // 📸 Carrousel d'images avec boutons de navigation
                        Stack(
                          children: [
                            CarouselSlider(
                              options: CarouselOptions(
                                height: 250,
                                autoPlay: true,
                                viewportFraction: 1.0,
                                enableInfiniteScroll:
                                    true, // ✅ Permet une transition fluide en boucle
                                autoPlayAnimationDuration: const Duration(
                                    milliseconds:
                                        800), // ✅ Animation plus fluide
                                autoPlayCurve:
                                    Curves.easeInOut, // ✅ Rendu plus naturel
                                onPageChanged: (index, reason) {
                                  setState(() {
                                    _currentImageIndex = index;
                                  });
                                },
                              ),
                              items: accommodation!['photos_site']
                                  .map<Widget>((photo) => GestureDetector(
                                        onTap: () {
                                          // 🚀 Ouvrir la page avec toutes les images
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  FullImageGallery(
                                                      images: List<String>.from(
                                                          accommodation![
                                                              'photos_site'])),
                                            ),
                                          );
                                        },
                                        child: CachedNetworkImage(
                                          imageUrl: photo,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                          fadeInDuration: const Duration(
                                              milliseconds:
                                                  500), // ✅ Transition fluide
                                          placeholder: (context, url) =>
                                              Shimmer.fromColors(
                                            baseColor: Colors.grey[300]!,
                                            highlightColor: Colors.white,
                                            child: Container(
                                              width: double.infinity,
                                              height: 250,
                                              color: Colors.white,
                                            ),
                                          ), // ✅ Loader au chargement
                                          errorWidget: (context, url, error) =>
                                              const Icon(Icons.broken_image,
                                                  size: 50,
                                                  color: Colors
                                                      .grey), // ✅ Gestion des erreurs
                                        ),
                                      ))
                                  .toList(),
                            ),
                            Positioned(
                              left: 10,
                              top: 100,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_back_ios,
                                    color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _currentImageIndex = ((_currentImageIndex -
                                                1) %
                                            List<String>.from(accommodation![
                                                    'photos_site'])
                                                .length)
                                        .toInt();
                                  });
                                },
                              ),
                            ),
                            Positioned(
                              right: 10,
                              top: 100,
                              child: IconButton(
                                icon: const Icon(Icons.arrow_forward_ios,
                                    color: Colors.white),
                                onPressed: () {
                                  setState(() {
                                    _currentImageIndex = ((_currentImageIndex +
                                                1) %
                                            List<String>.from(accommodation![
                                                    'photos_site'])
                                                .length)
                                        .toInt();
                                  });
                                },
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 10),

                        // 🏡 Informations principales
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                accommodation!['external_name'][0]
                                        .toUpperCase() +
                                    accommodation!['external_name'].substring(
                                        1), // ✅ Met la 1ʳᵉ lettre en majuscule
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow
                                    .ellipsis, // ✅ Coupe le texte avec "..."
                                softWrap: true, // ✅ Permet le retour à la ligne
                              ),
                              Row(
                                children: [
                                  Text(accommodation!['standing'].toUpperCase(),
                                      style:
                                          const TextStyle(color: Colors.blue)),
                                  const SizedBox(width: 10),
                                  Text(
                                      accommodation!['type_accommodation']
                                          .toUpperCase(),
                                      style:
                                          const TextStyle(color: Colors.grey)),
                                  const SizedBox(width: 10),
                                  const Icon(Icons.star,
                                      color: Colors.amber, size: 20),
                                  const Text(" 4.5/5"),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: SingleChildScrollView(
                            scrollDirection: Axis
                                .horizontal, // ✅ Permet le défilement horizontal
                            child: Row(
                              children: [
                                _featureIcon(Icons.people,
                                    "${accommodation!['capacity']} People"),
                                const SizedBox(width: 15),
                                _featureIcon(Icons.bed,
                                    "${(accommodation!['spaces']['bedrooms'] as List).length} Beds"),
                                const SizedBox(width: 15),
                                _featureIcon(Icons.bathtub,
                                    "${(accommodation!['spaces']['bathrooms'] as List).length} Bathrooms"),
                                const SizedBox(width: 15),
                                _featureIcon(Icons.meeting_room,
                                    "${(accommodation!['spaces']['bedrooms'] as List).length} Rooms"),
                                const SizedBox(width: 15),
                                _featureIcon(Icons.square_foot,
                                    "${accommodation!['area']} m²"),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 📝 Description HTML avec Read More
                        _sectionTitle("Description"),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // 📜 Affichage du texte avec HTML
                              HtmlWidget(
                                _isExpanded ||
                                        accommodation!['about_accommodation']
                                                .length <=
                                            100
                                    ? accommodation![
                                        'about_accommodation'] // ✅ Affiche tout le texte si Read More est activé ou si texte court
                                    : accommodation!['about_accommodation']
                                            .substring(0, 100) +
                                        "...",
                              ),

                              // 🔽 Afficher "Read More" uniquement si le texte est long
                              if (accommodation!['about_accommodation'].length >
                                  100)
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      _isExpanded = !_isExpanded;
                                    });
                                  },
                                  child: Text(
                                      _isExpanded ? "Voir moins" : "Voir plus"),
                                ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // 🏢 Lieux à proximité
                        _sectionTitle("Nearby Places"),
                        _placeList(accommodation!['backery'], "Bakeries"),
                        _placeList(accommodation!['restaurant'], "Restaurants"),
                        _placeList(accommodation!['public_transport'],
                            "Public Transport"),
                        _placeList(
                            accommodation!['tourist_site'], "Touristic Sites"),
                        _placeList(accommodation!['hangout'], "Hangouts"),
                        _placeList(accommodation!['grocery'], "Grocery Stores"),
                        _placeList(accommodation!['pharmacy'], "Pharmacies"),

                        const SizedBox(height: 10),

                        // 🔹 Équipements
                        _sectionTitle("Amenities"),
                        EquipmentsList(
                            equipments: categorizeEquipments(
                                List<String>.from(
                                    accommodation!['standard_equipments']),
                                List<String>.from(
                                    accommodation!['special_equipments']))),
                      ],
                    ),
                  ),

                  // Barre transparente avec retour et favori
                  Positioned(
                    top: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.2),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () {
                              Navigator.pop(context);
                            },
                          ),
                          Consumer<FavoriteProvider>(
                            builder: (context, favoriteProvider, _) {
                              final id = accommodation!['id'].toString();
                              final isFav = favoriteProvider.isFavorite(id);
                              final lang = context.read<LanguageProvider>();

                              return IconButton(
                                icon: Icon(
                                  isFav
                                      ? Icons.favorite
                                      : Icons.favorite_border,
                                  color: isFav ? Colors.red : Colors.white,
                                ),
                                onPressed: () async {
                                  if (isGuest) {
                                    mthTr.showLoginPromptFavorites(context);
                                    return;
                                  }

                                  await favoriteProvider.toggleFavorite(id,
                                      isGuest: isGuest, user: user);

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Row(
                                        children: [
                                          Icon(
                                            isFav
                                                ? Icons.favorite_border
                                                : Icons.favorite,
                                            color: Colors.white,
                                          ),
                                          const SizedBox(width: 10),
                                          Text(
                                            isFav
                                                ? lang.t("favorite_remove")
                                                : lang.t("favorite_add"),
                                            style: const TextStyle(
                                                color: Colors.white),
                                          ),
                                        ],
                                      ),
                                      backgroundColor: isFav
                                          ? Colors.redAccent
                                          : Colors.green,
                                      duration: const Duration(seconds: 2),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ),

                  //Bouton pour reserver
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: const BoxDecoration(
                        color: Colors.white, // ✅ Fond légèrement transparent
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(0),
                          topRight: Radius.circular(0),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // 🔹 Affichage du prix
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Price", // ✅ Label
                                style: TextStyle(
                                    fontSize: 14, color: Color(0xFF244B6B)),
                              ),
                              Text(
                                widget.dayPrice > 0
                                    ? "$displayPrice / ${lang.t("night")}"
                                    : "📞 Contact us",
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blueAccent,
                                ),
                              ),
                            ],
                          ),

                          // 🔹 Bouton BOOK
                          widget.dayPrice > 0
                              ? ElevatedButton(
                                  onPressed: () {
                                    // 🚀 Ouvrir la page de réservation ici
                                    Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              SelectBookingDetailsPage(
                                                  idAcc: accommodation!["id"],
                                                  roomId:
                                                      accommodation!["roomId"],
                                                  propId:
                                                      accommodation!["propId"],
                                                  pricePerNight:
                                                      widget.dayPrice,
                                                  currency: widget.currency,
                                                  cleaningFees: (accommodation![
                                                          "cleaning_fees"])
                                                      .toDouble(),
                                                  capacity: accommodation![
                                                      "capacity"]),
                                        ));
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(
                                        0xFF244B6B), // ✅ Couleur du bouton
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: const Text(
                                    "BOOK",
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white),
                                  ),
                                )
                              : const Text(""),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _featureIcon(IconData icon, String text) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.blue, size: 28), // ✅ Icône bien visible
        const SizedBox(height: 5),
        Text(
          text,
          style: const TextStyle(
              fontSize: 12, fontWeight: FontWeight.w500), // ✅ Texte lisible
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 3), // ✅ Ajoute un petit espace avant la ligne
          Container(
            height: 3,
            width: 40, // ✅ Petite ligne bleue sous le titre
            decoration: BoxDecoration(
              color: Colors.blueAccent,
              borderRadius: BorderRadius.circular(5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeList(List<dynamic>? places, String title) {
    if (places == null || places.isEmpty) {
      return Container(); // ✅ Évite l'erreur si vide
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 📌 Titre du bloc (Ex: "Bakeries")
          Text(title,
              style:
                  const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 5), // ✅ Espace après le titre

          // 🏢 Liste des lieux
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: places.map((place) {
              // 🔹 Extraire dynamiquement le `nameKey` (toujours premier élément)
              String nameKey = place.keys.first;
              String name = place[nameKey]; // 🔥 Nom du lieu
              String distance = place["distance"] ?? "N/A"; // 🔥 Distance
              List<String> otherDetails =
                  []; // 🔥 Contiendra les labels intermédiaires

              // 🔹 Extraire tous les autres labels sauf `nameKey` et `distance`
              place.forEach((key, value) {
                if (key != nameKey && key != "distance") {
                  otherDetails.add(value);
                }
              });

              return Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 📌 Icône correspondante
                    Icon(_getPlaceIcon(title), color: Colors.blue, size: 30),
                    const SizedBox(width: 10),

                    // 📍 Détails du lieu
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 📌 Nom du lieu + distance
                          Text(
                            "$name à $distance min",
                            style: const TextStyle(
                                fontSize: 14, fontWeight: FontWeight.bold),
                          ),

                          // 📌 Autres détails avec séparateur "#"
                          if (otherDetails.isNotEmpty)
                            Text(
                              otherDetails.join("  #  "),
                              style: const TextStyle(
                                  fontSize: 12, color: Colors.grey),
                            ),

                          // ➖ Séparateur cool entre les éléments
                          Divider(color: Colors.grey[300]),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  IconData _getPlaceIcon(String title) {
    switch (title.toLowerCase()) {
      case "bakeries":
        return Icons.local_cafe; // 🥐 Boulangerie
      case "restaurants":
        return Icons.restaurant; // 🍽 Restaurants
      case "public transport":
        return Icons.directions_bus; // 🚌 Transport
      case "touristic sites":
        return Icons.place; // 🏛 Sites touristiques
      case "hangouts":
        return Icons.nightlife; // 🍹 Bars / Clubs
      case "grocery stores":
        return Icons.local_grocery_store; // 🛒 Supermarché
      case "pharmacies":
        return Icons.local_pharmacy; // 💊 Pharmacies
      default:
        return Icons.location_on; // 📍 Par défaut
    }
  }

  Map<String, List<String>> categorizeEquipments(
      List<String> standard, List<String> special) {
    // Initialisation des catégories avec des listes vides
    Map<String, List<String>> categories = {
      "Parking": [],
      "Chambre": [],
      "Salon": [],
      "Cuisine": [],
      "High-Tech": [],
      "Salle de bain": [],
      "Nettoyage": [],
      "Sécurité": [],
      "Extérieur": [],
      "Connectivité": [],
      "Autres": []
    };

    // Map d’équipements pour trouver leur catégorie
    Map<String, String> equipmentToCategory = {};

    // On remplit un dictionnaire inverse
    categories.forEach((category, _) {
      List<String> mappedItems;
      switch (category) {
        case "Parking":
          mappedItems = [
            "Parking privé",
            "Parking intérieur",
            "Parking gratuit sur place",
            "Service de voiturier"
          ];
          break;
        case "Chambre":
          mappedItems = [
            "Draps supplementaire",
            "Lit bébé",
            "Lit parapluie",
            "Espace de rangement pour les vêtements"
          ];
          break;
        case "Salon":
          mappedItems = ["Salon privé", "Canapé", "Table à manger"];
          break;
        case "Cuisine":
          mappedItems = [
            "Cafetière",
            "Micro-ondes",
            "Réfrigérateur",
            "Cuisinière"
          ];
          break;
        case "High-Tech":
          mappedItems = ["Télévision", "Télévision à écran plat", "Cable TV"];
          break;
        case "Salle de bain":
          mappedItems = [
            "Sèche-cheveux",
            "Gel douche",
            "Serviettes, draps, savon et papier toilette"
          ];
          break;
        case "Nettoyage":
          mappedItems = [
            "Fer à repasser",
            "Matériel de repassage",
            "Lave-linge",
            "Produits de nettoyage"
          ];
          break;
        case "Sécurité":
          mappedItems = [
            "Détecteur de fumée",
            "Extincteur",
            "Kit de premier secours"
          ];
          break;
        case "Extérieur":
          mappedItems = ["Terrasse", "Vue sur la ville"];
          break;
        case "Connectivité":
          mappedItems = ["WiFi", "Espace de travail"];
          break;
        default:
          mappedItems = [];
      }

      for (String item in mappedItems) {
        equipmentToCategory[item] = category;
      }
    });

    // Classement des équipements
    for (String item in standard + special) {
      final category = equipmentToCategory[item];
      if (category != null) {
        categories[category]!.add(item);
      } else {
        categories["Autres"]!.add(item);
      }
    }

    return categories;
  }

  Widget _buildLoadingDetails() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🔹 Image en chargement
          Container(
            height: 250,
            width: double.infinity,
            decoration: BoxDecoration(
              color:
                  Colors.grey[300], // ✅ Fond gris pour simulation de chargement
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),

          // 🔹 Titre en chargement
          Container(
            height: 20,
            width: 200,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(5),
            ),
          ),
          const SizedBox(height: 10),

          // 🔹 Détails des équipements (lignes fictives)
          Row(
            children: List.generate(
              4,
              (index) => Padding(
                padding: const EdgeInsets.only(right: 10),
                child: Container(
                  height: 15,
                  width: 70,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 🔹 Bloc description simulé
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(
              3,
              (index) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Container(
                  height: 15,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(5),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
