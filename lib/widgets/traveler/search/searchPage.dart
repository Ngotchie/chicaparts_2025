import 'package:chicaparts_partner/api/traveler/api_accommodation_traveler.dart';
import 'package:chicaparts_partner/methodTraveler.dart';
import 'package:chicaparts_partner/models/traveler/model_accommodation_traveler.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class SearchPage extends StatefulWidget {
  final List<Stay> results;

  const SearchPage({super.key, required this.results});

  @override
  State<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends State<SearchPage> {
  final TextEditingController searchController = TextEditingController();
  List<dynamic> suggestions = [];
  AccommodationFilter? currentFilter;
  MethodsTraveler mthTr = MethodsTraveler();
  final apiAcc = ApiAccommodationTraveler();
  late List<Stay> popularStays;
  List<Stay> stays = [];
  bool _isLoading = true;

  // Filtres
  int nbAdultes = 1;
  int nbEnfants = 0;
  int nbChambres = 1;
  int nbLits = 1;
  String typeLogement = "apartment";
  DateTime? startDate;
  DateTime? endDate;
  bool wifi = false;
  bool ascenseur = false;
  bool parking = false;
  bool entirePlace = false;
  bool disabledAccess = false;

  double? selectedLat;
  double? selectedLon;

  bool _isSearch = true;

  @override
  void initState() {
    super.initState();
    if (widget.results.isEmpty) {
      loadStays();
      _isSearch = false;
    } else {
      stays = widget.results;
      _isLoading = false;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  // Charger les hébergements populaires
  void loadStays() async {
    try {
      List<Stay> data = await apiAcc.fetchStays();
      setState(() {
        stays = data;
        _isLoading = false;
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

  @override
  Widget build(BuildContext context) {
    final lang = context.read<LanguageProvider>();
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "🔎 ${lang.t("search")}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF244B6B), // Bleu principal
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        lang.t("ideal_stay"),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_alt_outlined,
                        size: 28, color: Color(0xFF244B6B)),
                    onPressed: () {
                      openFilterModal(); // Ta fonction de filtre existante
                    },
                    tooltip: "Filtres",
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 🔍 Barre de recherche
              TextField(
                controller: searchController,
                onChanged: (value) {
                  getSuggestion(value);
                },
                decoration: InputDecoration(
                  hintText: lang.t("text_search_bar"),
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
              // const SizedBox(height: 10),
              !_isSearch && !_isLoading
                  ? Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12.0),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "🏡 ${lang.t("popular_stay")}",
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF244B6B), // Couleur bleu principal
                          ),
                        ),
                      ),
                    )
                  : const Text(""),
              // const SizedBox(height: 10),
              Expanded(
                child: _isLoading
                    ? mthTr.buildShimmerLoader()
                    : stays.isNotEmpty
                        ? ListView.builder(
                            itemCount: stays.length,
                            itemBuilder: (context, index) {
                              return mthTr.stayCard(context, stays[index]);
                            },
                          )
                        : Center(
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
                                  Text(
                                    lang.t("no_stay_found"),
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(
                                          0xFF244B6B), // ton bleu principal
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    lang.t("filter_adjust"),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[600],
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ],
                              ),
                            ),
                          ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void openFilterModal() {
    const Color primaryBlue = Color(0xFF244B6B);
    const Color accentOrange = Color(0xFFF37540);
    const Color yellow = Color(0xFFFBD107);
    const Color turquoise = Color(0xFF05A8CF);
    const Color vert = Color(0xFF54bf31);

    final lang = context.read<LanguageProvider>();

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
                                    : lang.t("date_select"),
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
                      mthTr.sectionTitle(
                          "👤 ${lang.t('capacity')}", primaryBlue),
                      const SizedBox(height: 8),
                      mthTr.coloredStepper(lang.t("bed"), nbChambres, yellow,
                          (val) => setStateModal(() => nbChambres = val)),
                      mthTr.coloredStepper(
                          lang.t("adult"),
                          nbAdultes,
                          turquoise,
                          (val) => setStateModal(() => nbAdultes = val)),
                      mthTr.coloredStepper(
                          lang.t("child"),
                          nbEnfants,
                          accentOrange,
                          (val) => setStateModal(() => nbEnfants = val)),
                      mthTr.coloredStepper(lang.t("bed"), nbLits, vert,
                          (val) => setStateModal(() => nbLits = val)),

                      const SizedBox(height: 24),

                      /// 🏡 Type de logement
                      mthTr.sectionTitle(
                          "🏡 ${lang.t("type_accommodation")}", primaryBlue),
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
                      mthTr.sectionTitle(
                          "⚙️ ${lang.t("conveniance")}", primaryBlue),
                      mthTr.buildCheckbox("Wi-Fi", wifi,
                          (val) => setStateModal(() => wifi = val)),
                      mthTr.buildCheckbox(lang.t("elevator"), ascenseur,
                          (val) => setStateModal(() => ascenseur = val)),
                      mthTr.buildCheckbox("Parking", parking,
                          (val) => setStateModal(() => parking = val)),

                      const SizedBox(height: 24),

                      /// ♿ Accessibilité
                      mthTr.sectionTitle(
                          "♿ ${lang.t('accessibility')}", primaryBlue),
                      mthTr.buildCheckbox(lang.t("entire_place"), entirePlace,
                          (val) => setStateModal(() => entirePlace = val)),
                      mthTr.buildCheckbox(
                          lang.t("desabled_access"),
                          disabledAccess,
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
                                  wifi = ascenseur = parking = false;
                                  entirePlace = disabledAccess = false;
                                  startDate = endDate = null;
                                });
                              },
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryBlue,
                                side: BorderSide(color: primaryBlue),
                              ),
                              child: Text(lang.t("reset")),
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
                              child: Text(
                                lang.t("apply"),
                                style: const TextStyle(color: Colors.white),
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

  void applyFiltersAndFetchResults() async {
    if (selectedLat == null || selectedLon == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text("Veuillez d'abord sélectionner une adresse."),
      ));
      return;
    }
    try {
      final response = await apiAcc.fetchFilteredStays(currentFilter!.toJson());
      setState(() {
        _isSearch = true;
        stays = response;
      });
    } catch (e) {
      print("Erreur lors de l'appel API: $e");
    }
  }
}
