import 'dart:convert';
import 'package:chicaparts_partner/methodTraveler.dart';
import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/exchange_rate_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/utils/currency_converter.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chicaparts_partner/models/traveler/model_accommodation_traveler.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/services/favorite_repository.dart';
import 'package:chicaparts_partner/widgets/traveler/accommodation/accommodationDetails.dart';

class FavoritesPages extends StatefulWidget {
  const FavoritesPages({super.key});

  @override
  State<FavoritesPages> createState() => _FavoritesPagesState();
}

class _FavoritesPagesState extends State<FavoritesPages> {
  User? user;
  Future<List<Stay>>? futureFavorites;
  MethodsTraveler mthTr = MethodsTraveler();
  var lang;

  @override
  void initState() {
    super.initState();
    _loadUserAndFavorites();
  }

  Future<void> _loadUserAndFavorites() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson != null && userJson.isNotEmpty) {
      final currentUser = jsonDecode(userJson);
      user = User.fromJson(currentUser);
    } else {
      return;
    }

    setState(() {
      futureFavorites =
          FavoriteRepository.getFavoritesStays(user) as Future<List<Stay>>?;
    });
  }

  Future<void> _removeFavorite(String stayId) async {
    if (user == null) return;
    await FavoriteRepository.removeFavorite(stayId, isGuest: false, user: user);
    _loadUserAndFavorites(); // Rafraîchit les favoris
  }

  @override
  Widget build(BuildContext context) {
    lang = Provider.of<LanguageProvider>(context, listen: false);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              _buildHeader(),
              Expanded(
                child: user == null
                    ? _buildLoginPrompt()
                    : FutureBuilder<List<Stay>>(
                        future: futureFavorites,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return mthTr.buildShimmerLoader();
                          } else if (snapshot.hasError) {
                            return Center(
                                child: Text(
                                    "${lang.t('error')}: ${lang.t('error_network') ?? lang.t('unknow_error')}"));
                          } else if (snapshot.data == null ||
                              snapshot.data!.isEmpty) {
                            return _buildEmptyState();
                          }
                          final favorites = snapshot.data!;
                          return ListView.separated(
                            itemCount: favorites.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final stay = favorites[index];
                              return _buildStayCard(context, stay);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoginPrompt() {
    lang = Provider.of<LanguageProvider>(context, listen: false);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline,
                  size: 80, color: Color(0xFF244B6B)),
              const SizedBox(height: 16),
              Text(
                lang.t('login_required'),
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                lang.t('login_required_text'),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/login');
                },
                icon: const Icon(Icons.login, color: Colors.white),
                label: Text(lang.t('login'),
                    style: const TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF244B6B),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    lang = Provider.of<LanguageProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("❤️ ${lang.t('my_favorites')}",
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF244B6B))),
              const SizedBox(height: 2),
              Text(lang.t('my_favorites_text'),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.sort_rounded,
                size: 26, color: Color(0xFF244B6B)),
            onPressed: () {
              // TODO: Ajout tri ou filtre
            },
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.favorite_border, size: 80, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text("Aucun favori enregistré.",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[700])),
            const SizedBox(height: 8),
            Text(
                "Ajoutez des hébergements à vos favoris pour les retrouver ici.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: Colors.grey[500])),
          ],
        ),
      ),
    );
  }

  Widget _buildStayCard(BuildContext context, Stay stay) {
    lang = context.read<LanguageProvider>();

    final exchangeRates = context.watch<ExchangeRateProvider>().rates;

    final displayPrice = CurrencyConverter.format(stay.price.toDouble(),
        from: stay.currency, // Exemple: 'CFA' ou 'EUR'
        to: context.read<CurrencyProvider>().currency, // Ex: 'GBP', 'USD'
        rates: exchangeRates);

    return GestureDetector(
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
      child: Card(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    stay.imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: CircleAvatar(
                    backgroundColor: Colors.white.withOpacity(0.9),
                    child: IconButton(
                      icon: const Icon(Icons.favorite, color: Colors.red),
                      onPressed: () async {
                        await _removeFavorite(stay.id.toString());

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text("Supprimé des favoris"),
                            backgroundColor: Colors.redAccent,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            margin: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                          ),
                        );

                        // Optionnel : rafraîchir la liste
                        setState(() {
                          futureFavorites =
                              FavoriteRepository.getFavoritesStays(user)
                                  as Future<List<Stay>>?;
                        });
                      },
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    stay.title,
                    style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF244B6B)),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    stay.location,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stay.price > 0
                        ? "$displayPrice / ${lang.t("night")}"
                        : "📞 Contact us",
                    style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFF37540),
                        fontWeight: FontWeight.w600),
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
