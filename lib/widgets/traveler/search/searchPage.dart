import 'package:chicaparts_partner/api/traveler/api_accommodation_traveler.dart';
import 'package:chicaparts_partner/methodTraveler.dart';
import 'package:chicaparts_partner/models/traveler/model_accommodation_traveler.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/widgets/traveler/search/accommodationMapView.dart';
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
  int nbAdultes = 0;
  int nbEnfants = 0;
  int nbChambres = 0;
  int nbLits = 0;
  String typeLogement = "";
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
  bool _showMap = false;

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
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
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
                          color: colors.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.filter_alt_outlined,
                      size: 28,
                      color: colors.primary,
                    ),
                    onPressed: () {
                      openFilterModal(); // Ta fonction de filtre existante
                    },
                    tooltip: lang.t("filters"),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // 🔍 Barre de recherche
              TextField(
                controller: searchController,
                onChanged: (value) {
                  selectedLat = null;
                  selectedLon = null;
                  getSuggestion(value);
                },
                onSubmitted: (_) => applyFiltersAndFetchResults(),
                decoration: InputDecoration(
                  hintText: lang.t("text_search_bar"),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.filter_list),
                    onPressed: openFilterModal,
                  ),
                  filled: true,
                  fillColor: colors.surfaceContainerHighest.withOpacity(0.65),
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
                              city: place['text'] ?? place['place_name'],
                            );
                          } else {
                            currentFilter = AccommodationFilter(
                              lon: lon,
                              lat: lat,
                              city: place['text'] ?? place['place_name'],
                              typeAcc: currentFilter!.typeAcc,
                              wifi: currentFilter!.wifi,
                              hasParking: currentFilter!.hasParking,
                              disabledAccess: currentFilter!.disabledAccess,
                              hasElevator: currentFilter!.hasElevator,
                              entirePlace: currentFilter!.entirePlace,
                              nbAdult: currentFilter!.nbAdult,
                              nbChild: currentFilter!.nbChild,
                              nbBed: currentFilter!.nbBed,
                              nbBedrooms: currentFilter!.nbBedrooms,
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
              if (!_isSearch && !_isLoading)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: colors.primary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.primary.withOpacity(0.16),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.tune, color: colors.primary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          lang.t("search_refine_hint"),
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurfaceVariant,
                            height: 1.3,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (!_isLoading && stays.isNotEmpty) ...[
                // const SizedBox(height: 10),
                _buildViewSwitcher(lang),
              ],
              // const SizedBox(height: 10),
              Expanded(
                child: _isLoading
                    ? mthTr.buildShimmerLoader()
                    : stays.isNotEmpty
                        ? _showMap
                            ? AccommodationMapView(stays: stays)
                            : ListView.builder(
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
                                    color: colors.onSurfaceVariant,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    lang.t("no_stay_found"),
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: colors.primary,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    lang.t("filter_adjust"),
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: colors.onSurfaceVariant,
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

  Widget _buildViewSwitcher(LanguageProvider lang) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: _ViewSwitchButton(
              icon: Icons.view_list_rounded,
              label: lang.t('list'),
              selected: !_showMap,
              onTap: () => setState(() => _showMap = false),
            ),
          ),
          Expanded(
            child: _ViewSwitchButton(
              icon: Icons.map_outlined,
              label: lang.t('map'),
              selected: _showMap,
              onTap: () => setState(() => _showMap = true),
            ),
          ),
        ],
      ),
    );
  }

  void openFilterModal() {
    final colors = Theme.of(context).colorScheme;
    final primaryBlue = colors.primary;
    const Color accentOrange = Color(0xFFF37540);
    const Color yellow = Color(0xFFFBD107);
    const Color turquoise = Color(0xFF05A8CF);
    const Color vert = Color(0xFF54bf31);

    final lang = context.read<LanguageProvider>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
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
                      mthTr.sectionTitle("🗓️ ${lang.t("dates")}", primaryBlue),
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
                                  colorScheme: Theme.of(context)
                                      .colorScheme
                                      .copyWith(primary: primaryBlue),
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
                                  color: colors.onSurface,
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
                      mthTr.coloredStepper(lang.t("room"), nbChambres, yellow,
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
                                  label: Text(lang.t(type)),
                                  selected: typeLogement == type,
                                  selectedColor: turquoise,
                                  labelStyle: TextStyle(
                                      color: typeLogement == type
                                          ? Colors.white
                                          : colors.onSurface),
                                  onSelected: (selected) => setStateModal(() =>
                                      typeLogement = selected ? type : ""),
                                ))
                            .toList(),
                      ),

                      const SizedBox(height: 24),

                      /// ⚙️ Commodités
                      mthTr.sectionTitle(
                          "⚙️ ${lang.t("conveniance")}", primaryBlue),
                      mthTr.buildCheckbox(lang.t("wifi"), wifi,
                          (val) => setStateModal(() => wifi = val)),
                      mthTr.buildCheckbox(lang.t("elevator"), ascenseur,
                          (val) => setStateModal(() => ascenseur = val)),
                      mthTr.buildCheckbox(lang.t("parking"), parking,
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
                                  nbChambres = 0;
                                  nbAdultes = 0;
                                  nbEnfants = 0;
                                  typeLogement = "";
                                  nbLits = 0;
                                  wifi = ascenseur = parking = false;
                                  entirePlace = disabledAccess = false;
                                  startDate = endDate = null;
                                  selectedLat = selectedLon = null;
                                  searchController.clear();
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

  AccommodationFilter _buildCurrentFilter() {
    final locationText = searchController.text.trim();

    return AccommodationFilter(
      lon: selectedLon,
      lat: selectedLat,
      city:
          selectedLat == null && locationText.isNotEmpty ? locationText : null,
      typeAcc: typeLogement,
      wifi: wifi,
      hasParking: parking,
      disabledAccess: disabledAccess,
      hasElevator: ascenseur,
      entirePlace: entirePlace,
      nbAdult: nbAdultes,
      nbChild: nbEnfants,
      nbBed: nbLits,
      nbBedrooms: nbChambres,
      startDate: startDate,
      endDate: endDate,
    );
  }

  void applyFiltersAndFetchResults() async {
    final lang = context.read<LanguageProvider>();
    currentFilter = _buildCurrentFilter();

    if (!currentFilter!.hasActiveFilters) {
      setState(() {
        _isLoading = true;
        _isSearch = false;
        suggestions = [];
      });
      try {
        final response = await apiAcc.fetchFilteredStays({});
        if (!mounted) return;
        setState(() {
          stays = response;
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(lang.t("popular_search_hint")),
        ));
      } catch (e) {
        setState(() => _isLoading = false);
        print("Erreur lors du chargement des logements populaires: $e");
      }
      return;
    }

    setState(() {
      _isLoading = true;
      suggestions = [];
    });
    try {
      final response = await apiAcc.fetchFilteredStays(currentFilter!.toJson());
      setState(() {
        _isSearch = true;
        stays = response;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      print("Erreur lors de l'appel API: $e");
    }
  }
}

class _ViewSwitchButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ViewSwitchButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: selected ? colors.surface : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: colors.shadow.withOpacity(0.12),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: selected ? colors.primary : colors.onSurfaceVariant,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                color: selected ? colors.primary : colors.onSurfaceVariant,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
