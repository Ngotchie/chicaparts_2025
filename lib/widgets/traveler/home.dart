import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:chicaparts_partner/api/traveler/api_accommodation_traveler.dart';
import 'package:chicaparts_partner/methodTraveler.dart';
import 'package:chicaparts_partner/models/traveler/model_accommodation_traveler.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/exchange_rate_provider.dart';
import 'package:chicaparts_partner/providers/favorite_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/services/favorite_repository.dart';
import 'package:chicaparts_partner/utils/currency_converter.dart';
import 'package:chicaparts_partner/widgets/menu/bottomMenuTraveler.dart';
import 'package:chicaparts_partner/widgets/traveler/accommodation/accommodationDetails.dart';
import 'package:chicaparts_partner/widgets/traveler/accommodation/destinations.dart';
import 'package:chicaparts_partner/widgets/traveler/accommodation/popular.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/setting.dart';
import 'package:chicaparts_partner/widgets/traveler/search/searchPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

// final places = GoogleMapsPlaces(apiKey: kGoogleApiKey);

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late ScrollController _scrollController;
  late Timer _timer;
  List<Destination> destinations = [];
  List<Stay> stays = [];
  final apiAcc = ApiAccommodationTraveler();
  String userName = "Invité";
  final bool hasNotification = true; // À récupérer dynamiquement depuis l'API
  String currency =
      "EUR"; // Devise par défaut (modifiable plus tard dans Account)
  bool isGuest = true;
  dynamic user;
  // final List<Map<String, String>> destinations = [
  //   {"name": "Paris", "image": "images/chambre.png"},
  //   {"name": "Dubai", "image": "images/cuisine.png"},
  //   {"name": "New York", "image": "images/terrasse.png"},
  // ];

  final TextEditingController searchController = TextEditingController();
  List<dynamic> suggestions = [];
  AccommodationFilter? currentFilter;

  // Filtres
  int nbAdultes = 1;
  int nbEnfants = 0;
  int nbChambres = 1;
  int nbLits = 1;
  String? typeLogement;
  DateTime? startDate;
  DateTime? endDate;
  bool wifi = true;
  bool ascenseur = false;
  bool parking = true;
  bool entirePlace = false;
  bool disabledAccess = false;

  double? selectedLat;
  double? selectedLon;
  MethodsTraveler mthTr = MethodsTraveler();

  var lang;

  @override
  void initState() {
    super.initState();
    _loadUserInfo();
    loadDestinations();
    loadStays();
    _scrollController = ScrollController();
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_scrollController.hasClients &&
          _scrollController.position.haveDimensions) {
        double nextOffset = _scrollController.offset + 200;

        if (nextOffset >= _scrollController.position.maxScrollExtent) {
          nextOffset = 0;
        }

        _scrollController.animateTo(
          nextOffset,
          duration: const Duration(seconds: 1),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson != null && userJson.isNotEmpty) {
      final decoded = jsonDecode(userJson);
      user = User.fromJson(decoded);
      setState(() {
        userName = decoded['name'] ?? decoded['first_name'] ?? lang.t("guest");
        user = user;
        isGuest = false;
      });
    } else {
      userName = lang.t("guest");
    }
  }

// Charger les destinations
  void loadDestinations() async {
    try {
      List<Destination> data = await apiAcc.fetchDestinations();
      setState(() {
        destinations = data;
      });
    } catch (e) {
      print("Erreur: $e");
    }
  }

  // Charger les hébergements populaires
  void loadStays() async {
    try {
      List<Stay> data = await apiAcc.fetchStays();
      setState(() {
        stays = data;
      });
    } catch (e) {
      print("Erreur: $e");
    }
  }

  void getSuggestion(query) async {
    if (query.length < 3) {
      setState(() {
        suggestions = [];
      });
      return;
    }
    List<dynamic> results = await mthTr.fetchSuggestions(query);
    setState(() {
      suggestions = results;
    });
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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    lang = context.read<LanguageProvider>();
    currency = context.read<CurrencyProvider>().currency;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Bloc non scrollable
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      "👋 ${lang.t("welcome")}, $userName!",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Stack(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.notifications, size: 28),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SettingsPage()),
                          );
                        },
                      ),
                      if (hasNotification)
                        Positioned(
                          right: 6,
                          top: 6,
                          child: Container(
                            width: 10,
                            height: 10,
                            decoration: const BoxDecoration(
                              color: Colors.red,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),

            // 🔍 Barre de recherche
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                controller: searchController,
                onChanged: (value) {
                  getSuggestion(value);
                },
                decoration: InputDecoration(
                  hintText: lang.t("text_search_bar"),
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: openFilterModal,
                  ),
                  filled: true,
                  fillColor: Colors.grey[200],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            if (suggestions.isNotEmpty)
              Expanded(
                child: ListView.builder(
                  itemCount: suggestions.length,
                  itemBuilder: (context, index) {
                    final place = suggestions[index];
                    return ListTile(
                      title: Text(place['place_name']),
                      onTap: () {
                        searchController.text = place['place_name'];

                        // Récupérer la latitude et longitude
                        final lat = place['geometry']['coordinates'][1];
                        final lon = place['geometry']['coordinates'][0];
                        setState(() {
                          suggestions = [];
                          selectedLat = lat;
                          selectedLon = lon;
                        });
                        if (currentFilter == null) {
                          currentFilter = AccommodationFilter(
                            lon: lon,
                            lat: lat,
                          );
                        } else {
                          currentFilter = AccommodationFilter(
                            lon: lon,
                            lat: lat,
                            typeAcc: currentFilter!.typeAcc,
                            wifi: currentFilter!.wifi,
                            disabledAccess: currentFilter!.disabledAccess,
                            hasElevator: currentFilter!.hasElevator,
                            entirePlace: currentFilter!.entirePlace,
                            nbAdult: currentFilter!.nbAdult,
                            nbChild: currentFilter!.nbChild,
                            nbBed: currentFilter!.nbBed,
                            startDate: currentFilter!.startDate,
                            endDate: currentFilter!.endDate,
                          );
                        }
                        // 👇 Appel de la recherche automatique
                        applyFiltersAndFetchResults();
                      },
                    );
                  },
                ),
              ),
            // Partie scrollable
            Expanded(
                child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 🌍 Destinations
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "🌍 ${lang.t('popular_destination')}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF244B6B),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DestinationsPage(),
                              ));
                        },
                        child: Text(lang.t("show_all")),
                      ),
                    ],
                  ),

                  SizedBox(
                    height: 180,
                    child: ListView.builder(
                      controller: _scrollController,
                      scrollDirection: Axis.horizontal,
                      itemCount: destinations.length,
                      itemBuilder: (context, index) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: destinationCard(destinations[index]),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 20),

                  // 🏡 Hébergements populaires
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "🏡 ${lang.t("popular_stay")}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF244B6B),
                        ),
                      ),
                      TextButton(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const AllPopularStaysPage(),
                              ));
                        },
                        child: Text(lang.t("show_all")),
                      ),
                    ],
                  ),

                  MasonryGridView.count(
                    crossAxisCount:
                        MediaQuery.of(context).size.width > 600 ? 3 : 2,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.only(bottom: 32),
                    itemCount: stays.length,
                    itemBuilder: (context, index) {
                      return stayCard(stays[index]);
                    },
                  ),
                ],
              ),
            )),
          ],
        ),
      ),
    );
  }

  void applyFiltersAndFetchResults() async {
    if (selectedLat == null || selectedLon == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Veuillez d'abord sélectionner une adresse."),
      ));
      return;
    }
    try {
      final response = await apiAcc.fetchFilteredStays(currentFilter?.toJson());

      // 👇 Naviguer vers la page des résultats
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BottomMenuTraveler(index: 1, results: response),
        ),
      );
    } catch (e) {
      print("Erreur lors de l'appel API: $e");
    }
  }

  void openFilterModal() {
    const Color primaryBlue = Color(0xFF244B6B);
    const Color accentOrange = Color(0xFFF37540);
    const Color yellow = Color(0xFFFBD107);
    const Color turquoise = Color(0xFF05A8CF);
    const Color vert = Color(0xFF54bf31);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return FractionallySizedBox(
          heightFactor: 0.95,
          child: StatefulBuilder(
            builder: (context, setStateModal) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 5,
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.grey[300],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),

                      /// 🗓️ Dates
                      mthTr.sectionTitle("🗓️ Dates", primaryBlue),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          DateTimeRange? picked = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime.now(),
                            lastDate: DateTime(2100),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: primaryBlue,
                                  ),
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (picked != null) {
                            setStateModal(() {
                              startDate = picked.start;
                              endDate = picked.end;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 14),
                          decoration: BoxDecoration(
                            border: Border.all(color: primaryBlue, width: 1.3),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                (startDate != null && endDate != null)
                                    ? "${DateFormat.yMMMd().format(startDate!)} - ${DateFormat.yMMMd().format(endDate!)}"
                                    : "Sélectionner les dates",
                                style: TextStyle(
                                  color: Colors.grey[800],
                                  fontSize: 16,
                                ),
                              ),
                              Icon(Icons.calendar_today, color: primaryBlue),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      /// 👤 Capacité
                      mthTr.sectionTitle("👤 Capacité", primaryBlue),
                      const SizedBox(height: 8),
                      mthTr.coloredStepper("Chambres", nbChambres, yellow,
                          (val) => setStateModal(() => nbChambres = val)),
                      mthTr.coloredStepper("Adultes", nbAdultes, turquoise,
                          (val) => setStateModal(() => nbAdultes = val)),
                      mthTr.coloredStepper("Enfants", nbEnfants, accentOrange,
                          (val) => setStateModal(() => nbEnfants = val)),
                      mthTr.coloredStepper("Lits", nbLits, vert,
                          (val) => setStateModal(() => nbLits = val)),

                      const SizedBox(height: 24),

                      /// 🏡 Type de logement
                      mthTr.sectionTitle("🏡 Type de logement", primaryBlue),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          "apartment",
                          "studio",
                          "house",
                          "villa",
                          "loft",
                        ]
                            .map((type) => ChoiceChip(
                                  label: Text(type),
                                  selected: typeLogement == type,
                                  selectedColor: turquoise,
                                  labelStyle: TextStyle(
                                      color: typeLogement == type
                                          ? Colors.white
                                          : Colors.black),
                                  onSelected: (selected) => setStateModal(() =>
                                      typeLogement = selected ? type : ""),
                                ))
                            .toList(),
                      ),

                      const SizedBox(height: 24),

                      /// ⚙️ Commodités
                      mthTr.sectionTitle("⚙️ Commodités", primaryBlue),
                      mthTr.buildCheckbox("Wi-Fi", wifi,
                          (val) => setStateModal(() => wifi = val)),
                      mthTr.buildCheckbox("Ascenseur", ascenseur,
                          (val) => setStateModal(() => ascenseur = val)),
                      mthTr.buildCheckbox("Parking", parking,
                          (val) => setStateModal(() => parking = val)),

                      const SizedBox(height: 24),

                      /// ♿ Accessibilité
                      mthTr.sectionTitle("♿ Accessibilité", primaryBlue),
                      mthTr.buildCheckbox(
                          "Espace entier (Entire Place)",
                          entirePlace,
                          (val) => setStateModal(() => entirePlace = val)),
                      mthTr.buildCheckbox("Accès handicapé", disabledAccess,
                          (val) => setStateModal(() => disabledAccess = val)),

                      const SizedBox(height: 32),

                      /// 🔘 Boutons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () {
                                setStateModal(() {
                                  nbChambres = 1;
                                  nbAdultes = 1;
                                  nbEnfants = 0;
                                  typeLogement = "";
                                  nbLits = 0;
                                  wifi =
                                      ascenseur = entirePlace = parking = true;
                                  disabledAccess = false;
                                  startDate = endDate = null;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryBlue,
                                side: BorderSide(color: primaryBlue),
                              ),
                              child: const Text("Réinitialiser"),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // TODO: appliquer les filtres
                                currentFilter = AccommodationFilter(
                                    lon: selectedLon ??
                                        0, // par défaut 0 si pas encore sélectionné
                                    lat: selectedLat ?? 0,
                                    typeAcc: typeLogement,
                                    wifi: wifi,
                                    disabledAccess: disabledAccess,
                                    hasElevator: ascenseur,
                                    entirePlace: entirePlace,
                                    nbAdult: nbAdultes,
                                    nbChild: nbEnfants,
                                    nbBed: nbLits,
                                    startDate: startDate,
                                    endDate: endDate);
                                Navigator.pop(context);
                                applyFiltersAndFetchResults();
                              },
                              style: ElevatedButton.styleFrom(
                                  backgroundColor: primaryBlue),
                              child: const Text(
                                "Appliquer",
                                style: TextStyle(color: Colors.white),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                    ],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  // 📌 Widget pour une destination populaire (images agrandies)
  Widget destinationCard(Destination destination) {
    return GestureDetector(
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
      child: Padding(
        padding: const EdgeInsets.only(right: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Stack(
            children: [
              // 📌 Augmenter la taille des images
              Image.network(
                destination.imageUrl, // Utilisation du lien dynamique
                width: 160,
                height: 180,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    width: 160,
                    height: 200,
                    child: Shimmer.fromColors(
                      baseColor: Colors.grey[300]!,
                      highlightColor: Colors.white,
                      child: Container(
                        height: 200,
                        color: Colors.white,
                      ),
                    ),
                  ); // Loader Shimmer ⏳
                },
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(Icons.broken_image,
                      size: 160, color: Colors.grey); // Icône en cas d'erreur
                },
              ),
              Container(
                width: 160,
                height: 180,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.black.withOpacity(0.3), Colors.transparent],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                ),
              ),
              Positioned(
                left: 10,
                bottom: 10,
                child: Text(
                  destination.name,
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 📌 Widget pour un hébergement populaire avec favori + devise dynamique
  Widget stayCard(Stay stay) {
    final exchangeRates = context.watch<ExchangeRateProvider>().rates;

    final displayPrice = CurrencyConverter.format(stay.price.toDouble(),
        from: stay.currency, // Exemple: 'CFA' ou 'EUR'
        to: context.read<CurrencyProvider>().currency, // Ex: 'GBP', 'USD'
        rates: exchangeRates);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: 1.0), // Animation de 0% à 100%
      duration: const Duration(milliseconds: 500), // ⏳ Durée de l'animation
      curve: Curves.easeOut, // Effet naturel
      builder: (context, opacity, child) {
        return Opacity(
          opacity: opacity, // 🔥 Apparition progressive
          child: Transform.translate(
            offset:
                Offset((1 - opacity) * 50, 0), // 🚀 Glissement depuis la droite
            child: child,
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: Stack(
          children: [
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Stack(
                    children: [
                      GestureDetector(
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
                        child: Image.network(
                          stay.imageUrl, // Utilisation du lien dynamique
                          width: double.infinity,
                          height: 140,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return SizedBox(
                              width: double.infinity,
                              height: 140,
                              child: Shimmer.fromColors(
                                baseColor: Colors.grey[300]!,
                                highlightColor: Colors.white,
                                child: Container(
                                  height: 140,
                                  color: Colors.white,
                                ),
                              ),
                            ); // Loader Shimmer ⏳
                          },
                          errorBuilder: (context, error, stackTrace) {
                            return const Icon(Icons.broken_image,
                                size: 140,
                                color: Colors.grey); // Icône en cas d'erreur
                          },
                        ),
                      ),
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Consumer<FavoriteProvider>(
                          builder: (context, favoriteProvider, _) {
                            final isFav =
                                favoriteProvider.isFavorite(stay.id.toString());

                            return GestureDetector(
                              onTap: () async {
                                if (isGuest) {
                                  mthTr.showLoginPromptFavorites(context);
                                  return;
                                }
                                await favoriteProvider.toggleFavorite(
                                  stay.id.toString(),
                                  isGuest: isGuest,
                                  user: user,
                                );

                                final lang = context.read<LanguageProvider>();

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
                                    backgroundColor:
                                        isFav ? Colors.redAccent : Colors.green,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    duration: const Duration(seconds: 2),
                                  ),
                                );
                              },
                              child: Icon(
                                isFav ? Icons.favorite : Icons.favorite_border,
                                color: isFav ? Colors.red : Colors.white,
                                size: 30,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.all(5.0),
                    child: Text(
                      stay.title,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Text(
                      stay.location,
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.normal),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 5.0),
                    child: Text(
                      stay.price > 0
                          ? "$displayPrice / ${lang.t("night")}"
                          : "📞 Contact us", // "$currency$stay.price",
                      style: const TextStyle(fontSize: 14, color: Colors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
