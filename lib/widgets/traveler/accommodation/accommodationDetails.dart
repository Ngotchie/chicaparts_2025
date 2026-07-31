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
import 'package:chicaparts_partner/widgets/traveler/accommodation/optimized_network_image.dart';
import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter_widget_from_html/flutter_widget_from_html.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:chicaparts_partner/methodTraveler.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:chicaparts_partner/widgets/traveler/accommodation/map_webview_page.dart';

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
  static const int _descriptionPreviewLines = 4;
  static const double _descriptionLineHeight = 20;

  Map<String, dynamic>? accommodation;
  bool _isLoading = true;
  bool _isExpanded = false;
  int _currentImageIndex = 0;
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  final Set<String> _precachedPhotos = {};
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
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        _precacheNearbyPhotos(_asStringList(data['photos_site']), 0);
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

  void _precacheNearbyPhotos(List<String> photos, int index) {
    if (!mounted || photos.isEmpty) return;

    final candidates = <int>{
      index,
      if (index + 1 < photos.length) index + 1,
      if (index + 2 < photos.length) index + 2,
    };

    for (final candidate in candidates) {
      final url = photos[candidate];
      if (url.trim().isEmpty || _precachedPhotos.contains(url)) continue;

      _precachedPhotos.add(url);
      precacheImage(
        OptimizedNetworkImage.provider(
          url,
          maxWidth: 1200,
          maxHeight: 760,
        ),
        context,
      );
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
    final details = accommodation ?? {};
    final title =
        _asString(details['external_name'], fallback: 'Accommodation');
    final standing = _asString(details['standing']).toUpperCase();
    final type = _asString(details['type_accommodation']).toUpperCase();
    final address = _asString(details['full_address']);
    final city = _asString(details['city']);
    final score = _reviewScore(details['reviews']);
    final photos = _asStringList(details['photos_site']);
    final about = _asString(details['about_accommodation']);
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surface,
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
                            if (photos.isEmpty)
                              Container(
                                height: 250,
                                width: double.infinity,
                                color: colors.surfaceContainerHighest,
                                child: Icon(Icons.apartment,
                                    color: colors.onSurfaceVariant, size: 56),
                              )
                            else
                              CarouselSlider.builder(
                                carouselController: _carouselController,
                                itemCount: photos.length,
                                options: CarouselOptions(
                                  height: 250,
                                  autoPlay: false,
                                  viewportFraction: 1.0,
                                  enableInfiniteScroll: photos.length > 1,
                                  onPageChanged: (index, reason) {
                                    setState(() {
                                      _currentImageIndex = index;
                                    });
                                    _precacheNearbyPhotos(photos, index);
                                  },
                                ),
                                itemBuilder: (context, index, realIndex) {
                                  final photo = photos[index];
                                  return GestureDetector(
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) =>
                                              FullImageGallery(
                                            images: photos,
                                            initialIndex: index,
                                          ),
                                        ),
                                      );
                                    },
                                    child: OptimizedNetworkImage(
                                      imageUrl: photo,
                                      width: double.infinity,
                                      height: 250,
                                      fit: BoxFit.cover,
                                      memCacheWidth: 900,
                                      memCacheHeight: 560,
                                      maxWidthDiskCache: 1200,
                                      maxHeightDiskCache: 760,
                                    ),
                                  );
                                },
                              ),
                            if (photos.length > 1)
                              Positioned(
                                left: 10,
                                top: 100,
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_back_ios,
                                      color: Colors.white),
                                  onPressed: () =>
                                      _carouselController.previousPage(),
                                ),
                              ),
                            if (photos.length > 1)
                              Positioned(
                                right: 10,
                                top: 100,
                                child: IconButton(
                                  icon: const Icon(Icons.arrow_forward_ios,
                                      color: Colors.white),
                                  onPressed: () =>
                                      _carouselController.nextPage(),
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
                                _capitalize(title),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  height: 1.15,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                softWrap: true,
                              ),
                              const SizedBox(height: 10),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (standing.isNotEmpty)
                                    _infoChip(standing, Icons.verified,
                                        colors.primary),
                                  if (type.isNotEmpty)
                                    _infoChip(
                                        type, Icons.apartment, Colors.blueGrey),
                                  _infoChip(
                                      score > 0
                                          ? score.toStringAsFixed(1)
                                          : lang.t('no_reviews'),
                                      Icons.star,
                                      Colors.amber.shade700),
                                ],
                              ),
                              if (address.isNotEmpty || city.isNotEmpty) ...[
                                const SizedBox(height: 12),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Icon(Icons.location_on_outlined,
                                        color: colors.primary, size: 20),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        address.isNotEmpty ? address : city,
                                        style: TextStyle(
                                          color: colors.onSurfaceVariant,
                                          fontSize: 14,
                                          height: 1.35,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (_hasHighlights(details)) ...[
                                const SizedBox(height: 16),
                                _buildHighlights(details, lang),
                              ],
                              const SizedBox(height: 12),
                              _buildLocationCard(details, lang),
                              const SizedBox(height: 12),
                              _buildRulesCard(details, lang),
                              const SizedBox(height: 6),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (details['has_wifi'] == true ||
                                      details['wifi_identifiers'] != null)
                                    _amenityPill(Icons.wifi, lang.t('wifi')),
                                  if (details['has_parking'] == true)
                                    _amenityPill(
                                        Icons.local_parking, lang.t('parking')),
                                  if (details['has_elevator'] == true)
                                    _amenityPill(
                                        Icons.elevator, lang.t('elevator')),
                                  if (details['entire_place'] == true)
                                    _amenityPill(Icons.home_work_outlined,
                                        lang.t('entire_place')),
                                  if (details['disabled_access'] == true)
                                    _amenityPill(Icons.accessible,
                                        lang.t('desabled_access')),
                                ],
                              ),
                            ],
                          ),
                        ),

                        if (about.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          _sectionTitle(lang.t("description")),
                          Padding(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16.0),
                            child: _buildDescription(about, lang),
                          ),
                        ],
                        _buildNearbyPlacesSection(details, lang),
                        _buildEquipmentsSection(details, lang),
                        const SizedBox(height: 92),
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
                      decoration: BoxDecoration(
                        color: colors.surfaceContainer,
                        border: Border(
                          top: BorderSide(color: colors.outlineVariant),
                        ),
                        borderRadius: const BorderRadius.only(
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
                              Text(
                                lang.t("price"),
                                style: TextStyle(
                                    fontSize: 14, color: colors.primary),
                              ),
                              Text(
                                widget.dayPrice > 0
                                    ? "$displayPrice / ${lang.t("night")}"
                                    : "📞 ${lang.t("contact_us")}",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: colors.primary,
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
                                    backgroundColor: colors.primary,
                                    foregroundColor: colors.onPrimary,
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 20, vertical: 8),
                                    shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text(
                                    lang.t("book_now"),
                                    style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: colors.onPrimary),
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

  String _asString(dynamic value, {String fallback = ''}) {
    if (value == null) return fallback;
    final text = value.toString().trim();
    return text.isEmpty ? fallback : text;
  }

  List<String> _asStringList(dynamic value) {
    if (value is List) {
      return value
          .where((item) => item != null && item.toString().trim().isNotEmpty)
          .map((item) => item.toString())
          .toList();
    }
    return [];
  }

  String _capitalize(String value) {
    if (value.isEmpty) return value;
    return value[0].toUpperCase() + value.substring(1);
  }

  int _spaceCount(Map<String, dynamic> details, String key) {
    final spaces = details['spaces'];
    if (spaces is Map && spaces[key] is List) {
      return (spaces[key] as List).length;
    }
    return 0;
  }

  int _bedCount(Map<String, dynamic> details) {
    final spaces = details['spaces'];
    if (spaces is Map && spaces['nbr_bed'] is num) {
      return (spaces['nbr_bed'] as num).toInt();
    }
    return _spaceCount(details, 'bedrooms');
  }

  double _reviewScore(dynamic reviews) {
    if (reviews is Map) {
      return double.tryParse('${reviews['score'] ?? '0'}') ?? 0;
    }
    return 0;
  }

  bool _hasHighlights(Map<String, dynamic> details) {
    return details['capacity'] != null ||
        _bedCount(details) > 0 ||
        _spaceCount(details, 'bedrooms') > 0 ||
        _spaceCount(details, 'bathrooms') > 0 ||
        details['area'] != null;
  }

  bool _hasNearbyPlaces(Map<String, dynamic> details) {
    const keys = [
      'backery',
      'restaurant',
      'public_transport',
      'tourist_site',
      'hangout',
      'grocery',
      'pharmacy',
    ];

    return keys.any((key) {
      final places = details[key];
      return places is List && places.isNotEmpty;
    });
  }

  bool _hasEquipments(Map<String, dynamic> details) {
    return _asStringList(details['standard_equipments']).isNotEmpty ||
        _asStringList(details['special_equipments']).isNotEmpty;
  }

  Widget _infoChip(String label, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _amenityPill(IconData icon, String label) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: colors.primary),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _compactInfoPill(IconData icon, String label, Color color) {
    return Container(
      constraints: const BoxConstraints(minHeight: 36),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 15, color: color),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w700,
                height: 1.1,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHighlights(Map<String, dynamic> details, LanguageProvider lang) {
    final capacity = details['capacity'];
    final beds = _bedCount(details);
    final bedrooms = _spaceCount(details, 'bedrooms');
    final bathrooms = _spaceCount(details, 'bathrooms');
    final area = details['area'];
    final items = <Widget>[];

    void addItem(Widget item) {
      if (items.isNotEmpty) items.add(const SizedBox(width: 12));
      items.add(item);
    }

    if (capacity != null) {
      addItem(_featureIcon(Icons.people, "$capacity ${lang.t('traveler')}"));
    }

    if (beds > 0) {
      addItem(_featureIcon(Icons.bed, "$beds ${lang.t('bed')}"));
    }

    if (bedrooms > 0) {
      addItem(_featureIcon(Icons.meeting_room, "$bedrooms ${lang.t('room')}"));
    }

    if (bathrooms > 0) {
      addItem(_featureIcon(Icons.bathtub, "$bathrooms ${lang.t('bathroom')}"));
    }

    if (area != null) {
      addItem(_featureIcon(Icons.square_foot, "$area m²"));
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: items),
    );
  }

  Widget _buildLocationCard(
      Map<String, dynamic> details, LanguageProvider lang) {
    final colors = Theme.of(context).colorScheme;
    final address = _asString(details['full_address']);
    final city = _asString(details['city']);
    final floor = _asString(details['floor_number']);
    final door = _asString(details['door_number']);
    final hasCoordinates =
        details['latitude'] != null && details['longitude'] != null;

    if (address.isEmpty && city.isEmpty && !hasCoordinates) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withOpacity(0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.map_outlined, color: colors.primary),
              const SizedBox(width: 8),
              Text(
                lang.t('location'),
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: colors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (address.isNotEmpty || city.isNotEmpty)
            Text(
              address.isNotEmpty ? address : city,
              style: TextStyle(color: colors.onSurface, height: 1.35),
            ),
          if (floor.isNotEmpty || door.isNotEmpty) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (floor.isNotEmpty)
                  Expanded(
                    child: _compactInfoPill(
                      Icons.layers_outlined,
                      "${lang.t('floor_number')}: $floor",
                      Colors.blueGrey,
                    ),
                  ),
                if (floor.isNotEmpty && door.isNotEmpty)
                  const SizedBox(width: 8),
                if (door.isNotEmpty)
                  Expanded(
                    child: _compactInfoPill(
                      Icons.door_front_door_outlined,
                      "${lang.t('door_number')}: $door",
                      Colors.blueGrey,
                    ),
                  ),
              ],
            ),
          ],
          if (hasCoordinates) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _openInGoogleMaps(details),
              icon: const Icon(Icons.map_outlined, size: 18),
              label: Text(lang.t('view_on_map')),
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.primary,
                side: BorderSide(color: colors.primary),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRulesCard(Map<String, dynamic> details, LanguageProvider lang) {
    final colors = Theme.of(context).colorScheme;
    final rules = details['house_rules'];
    if (rules is! Map) return const SizedBox.shrink();

    final arrival = rules['arrival_time'] is List
        ? (rules['arrival_time'] as List).join(' - ')
        : '';
    final departure = rules['departure_time'] is List
        ? (rules['departure_time'] as List).join(' - ')
        : '';
    final hasPetsRule = rules.containsKey('pets_allowed');
    final petsAllowed = rules['pets_allowed'] == true;

    if (arrival.isEmpty && departure.isEmpty && !hasPetsRule) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (arrival.isNotEmpty || departure.isNotEmpty)
            Row(
              children: [
                if (arrival.isNotEmpty)
                  Expanded(
                    child: _compactInfoPill(
                      Icons.login,
                      "${lang.t('check-in')}: $arrival",
                      colors.primary,
                    ),
                  ),
                if (arrival.isNotEmpty && departure.isNotEmpty)
                  const SizedBox(width: 8),
                if (departure.isNotEmpty)
                  Expanded(
                    child: _compactInfoPill(
                      Icons.logout,
                      "${lang.t('check-out')}: $departure",
                      colors.primary,
                    ),
                  ),
              ],
            ),
          if (hasPetsRule) ...[
            if (arrival.isNotEmpty || departure.isNotEmpty)
              const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _amenityPill(
                  petsAllowed ? Icons.pets : Icons.do_not_disturb_alt,
                  petsAllowed
                      ? lang.t('pets_allowed')
                      : lang.t('pets_not_allowed'),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildNearbyPlacesSection(
      Map<String, dynamic> details, LanguageProvider lang) {
    if (!_hasNearbyPlaces(details)) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _sectionTitle(lang.t("nearby_places")),
        _placeList(details['backery'], "Bakeries"),
        _placeList(details['restaurant'], "Restaurants"),
        _placeList(details['public_transport'], "Public Transport"),
        _placeList(details['tourist_site'], "Touristic Sites"),
        _placeList(details['hangout'], "Hangouts"),
        _placeList(details['grocery'], "Grocery Stores"),
        _placeList(details['pharmacy'], "Pharmacies"),
      ],
    );
  }

  Widget _buildEquipmentsSection(
      Map<String, dynamic> details, LanguageProvider lang) {
    if (!_hasEquipments(details)) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 10),
        _sectionTitle(lang.t("amenities")),
        EquipmentsList(
          equipments: categorizeEquipments(
            _asStringList(details['standard_equipments']),
            _asStringList(details['special_equipments']),
          ),
        ),
      ],
    );
  }

  Widget _buildDescription(String about, LanguageProvider lang) {
    final colors = Theme.of(context).colorScheme;
    final shouldShowToggle = _isLongDescription(about);
    final previewHeight = _descriptionPreviewLines * _descriptionLineHeight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSize(
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeInOutCubic,
            alignment: Alignment.topCenter,
            child: ClipRect(
              child: Stack(
                children: [
                  ConstrainedBox(
                    constraints: shouldShowToggle && !_isExpanded
                        ? BoxConstraints(maxHeight: previewHeight)
                        : const BoxConstraints(),
                    child: HtmlWidget(
                      about.trim(),
                      textStyle: TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: colors.onSurface,
                      ),
                      onTapUrl: _openDescriptionLink,
                    ),
                  ),
                  if (shouldShowToggle && !_isExpanded)
                    Positioned(
                      left: 0,
                      right: 0,
                      bottom: 0,
                      height: 38,
                      child: IgnorePointer(
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                colors.surfaceContainer.withOpacity(0),
                                colors.surfaceContainer,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (shouldShowToggle) ...[
            const SizedBox(height: 4),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: () => setState(() => _isExpanded = !_isExpanded),
                label: Text(
                  _isExpanded ? lang.t("show_less") : lang.t("show_more"),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                icon: AnimatedRotation(
                  turns: _isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: const Icon(Icons.keyboard_arrow_down_rounded),
                ),
                style: TextButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Future<bool> _openDescriptionLink(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null || (uri.scheme != 'http' && uri.scheme != 'https')) {
      return false;
    }
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  bool _isLongDescription(String html) {
    final textWithLineBreaks = html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n');
    final lineBreakCount = '\n'.allMatches(textWithLineBreaks).length;
    final text = _stripHtmlTags(textWithLineBreaks);

    return text.length > 180 || lineBreakCount >= _descriptionPreviewLines;
  }

  String _stripHtmlTags(String html) {
    return html
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'</p\s*>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  Future<void> _openInGoogleMaps(Map<String, dynamic> details) async {
    final lat = details['latitude'];
    final lon = details['longitude'];
    if (lat == null || lon == null) return;

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lon',
    );

    if (!mounted) return;
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => MapWebViewPage(
          mapUri: uri,
          title: lang.t('location'),
        ),
      ),
    );
  }

  Widget _featureIcon(IconData icon, String text) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: colors.primary, size: 28),
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
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 7),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 3), // ✅ Ajoute un petit espace avant la ligne
          Container(
            height: 3,
            width: 40, // ✅ Petite ligne bleue sous le titre
            decoration: BoxDecoration(
              color: colors.primary,
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
                          Divider(
                            color: Theme.of(context).colorScheme.outlineVariant,
                          ),
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
    final placeholderColor =
        Theme.of(context).colorScheme.surfaceContainerHighest;
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
              color: placeholderColor,
              borderRadius: BorderRadius.circular(10),
            ),
          ),
          const SizedBox(height: 20),

          // 🔹 Titre en chargement
          Container(
            height: 20,
            width: 200,
            decoration: BoxDecoration(
              color: placeholderColor,
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
                    color: placeholderColor,
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
                    color: placeholderColor,
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
