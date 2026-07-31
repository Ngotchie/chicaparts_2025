import 'dart:convert';

import 'package:chicaparts_partner/models/traveler/model_accommodation_traveler.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/exchange_rate_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/services/favorite_repository.dart';
import 'package:chicaparts_partner/utils/currency_converter.dart';
import 'package:chicaparts_partner/widgets/traveler/accommodation/accommodationDetails.dart';
import 'package:chicaparts_partner/widgets/traveler/accommodation/optimized_network_image.dart';
import 'package:chicaparts_partner/widgets/traveler/common/login_required_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class FavoritesPages extends StatefulWidget {
  const FavoritesPages({super.key});

  @override
  State<FavoritesPages> createState() => _FavoritesPagesState();
}

class _FavoritesPagesState extends State<FavoritesPages> {
  User? user;
  Future<List<Stay>>? futureFavorites;

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
      if (mounted) setState(() => futureFavorites = null);
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
    if (!mounted) return;
    setState(() {
      futureFavorites =
          FavoriteRepository.getFavoritesStays(user) as Future<List<Stay>>?;
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(lang),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: user == null
                    ? _buildLoginPrompt(lang)
                    : FutureBuilder<List<Stay>>(
                        future: futureFavorites,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState ==
                              ConnectionState.waiting) {
                            return _buildLoadingList();
                          }
                          if (snapshot.hasError) {
                            return _buildMessageState(
                              icon: Icons.wifi_off_outlined,
                              title: lang.t('error'),
                              message: lang.t('error_network'),
                            );
                          }
                          if (snapshot.data == null || snapshot.data!.isEmpty) {
                            return _buildEmptyState(lang);
                          }

                          final favorites = snapshot.data!;
                          return ListView.separated(
                            padding: const EdgeInsets.only(bottom: 24),
                            itemCount: favorites.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 14),
                            itemBuilder: (context, index) {
                              return _buildStayCard(context, favorites[index]);
                            },
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(LanguageProvider lang) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFEEF1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.favorite, color: Color(0xFFE53935)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.t('my_favorites'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lang.t('my_favorites_text'),
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoginPrompt(LanguageProvider lang) {
    return const LoginRequiredState(padding: EdgeInsets.zero);
  }

  Widget _buildEmptyState(LanguageProvider lang) {
    return _buildMessageState(
      icon: Icons.favorite_border,
      title: lang.t('no_stay_found'),
      message: lang.t('my_favorites_text'),
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
    Widget? action,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 34, color: colors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.35),
            ),
            if (action != null) ...[
              const SizedBox(height: 18),
              action,
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingList() {
    final colors = Theme.of(context).colorScheme;

    return ListView.separated(
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 14),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: colors.surfaceContainerHighest,
          highlightColor: colors.surfaceContainer,
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStayCard(BuildContext context, Stay stay) {
    final lang = context.read<LanguageProvider>();
    final exchangeRates = context.watch<ExchangeRateProvider>().rates;
    final colors = Theme.of(context).colorScheme;
    final displayPrice = CurrencyConverter.format(
      stay.price.toDouble(),
      from: stay.currency,
      to: context.read<CurrencyProvider>().currency,
      rates: exchangeRates,
    );

    return InkWell(
      borderRadius: BorderRadius.circular(8),
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
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                ClipRRect(
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
                  child: OptimizedNetworkImage(
                    imageUrl: stay.thumbnailUrl,
                    height: 170,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    memCacheWidth: 720,
                    memCacheHeight: 420,
                    maxWidthDiskCache: 900,
                    maxHeightDiskCache: 540,
                  ),
                ),
                Positioned(
                  top: 10,
                  right: 10,
                  child: Material(
                    color: colors.surface.withOpacity(0.94),
                    borderRadius: BorderRadius.circular(8),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(8),
                      onTap: () async {
                        await _removeFavorite(stay.id.toString());
                        if (!mounted) return;

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(lang.t('favorite_remove')),
                            backgroundColor: Colors.redAccent,
                            duration: const Duration(seconds: 2),
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                        );
                      },
                      child: const SizedBox(
                        width: 42,
                        height: 42,
                        child: Icon(Icons.favorite, color: Color(0xFFE53935)),
                      ),
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
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.location_on_outlined,
                        size: 16,
                        color: colors.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          stay.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 13,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    stay.price > 0
                        ? '$displayPrice / ${lang.t('night')}'
                        : lang.t('contact_us'),
                    style: TextStyle(
                      fontSize: 14,
                      color: colors.primary,
                      fontWeight: FontWeight.w800,
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
