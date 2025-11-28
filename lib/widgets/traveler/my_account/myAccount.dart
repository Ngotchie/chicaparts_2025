import 'dart:convert';

import 'package:chicaparts_partner/api/traveler/api_booking_traveler.dart';
import 'package:chicaparts_partner/models/model_booking.dart';
import 'package:chicaparts_partner/models/traveler/modele_booking_traveler.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/widgets/login/welcome.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/account_class.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/myBooking.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/profile.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/setting.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  bool isGuest = true;
  String? userName;
  String? email;
  int _countFavorites = 0;
  int _countBookings = 0;
  int _countReviews = 0;

  Map<String, dynamic>? _pendingReservation;
  List<Booking> _recentBookings = [];
  var lang;
  Booking? _recentlyFinishedBooking;
  bool _tipShown = false;

  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadUserSession();
    _loadRecentBookings();
  }

  ApiBooking apiBooking = ApiBooking();

  bool _showProfileBanner = false;
  bool _isProfileIncomplete(Map<String, dynamic> u) {
    // Adapte aux clés de ton JSON utilisateur
    final first = (u['name'] ?? '').toString().trim();
    return first.isEmpty;
  }

  Future<void> _loadUserSession() async {
    setState(() => _isLoadingUser = true);

    final prefs = await SharedPreferences.getInstance();

    // 1) Lire la session locale
    final rawUser = prefs.getString('user');
    Map<String, dynamic>? userMap;

    if (rawUser != null && rawUser.isNotEmpty) {
      try {
        final decoded = jsonDecode(rawUser);
        if (decoded is Map<String, dynamic>) {
          userMap = decoded;
        }
      } catch (e) {
        debugPrint('rawUser jsonDecode error: $e');
        userMap = null;
      }
    }

    // 2) Valeurs par défaut
    bool computedIsGuest = userMap == null;
    String? computedName;
    String? computedEmail;

    int favCount = 0;
    int bookingsCount = 0;
    int reviewsCount = 0;

    // 3) Si connecté, fetch du profil étendu (protégé)
    if (!computedIsGuest) {
      try {
        // Construire ton modèle User depuis userMap (pas de double jsonDecode)
        final user = User.fromJson(userMap!);

        // Peut throw / renvoyer des champs null → on entoure de try
        final UserProfile userProfile = await apiBooking.fetchUserProfile(user);

        favCount = userProfile.favorisCount;
        bookingsCount = userProfile.bookingCount;
        reviewsCount = userProfile.reviewCount;

        // Nom / email depuis la session locale
        computedName =
            (userMap['name'] ?? userMap['first_name'] ?? 'Utilisateur')
                .toString();
        computedEmail = (userMap['email'] ?? '').toString();
      } catch (e) {
        // On log mais on ne casse pas l’écran
        debugPrint('fetchUserProfile error: $e');
        // computedName/computedEmail si possible depuis userMap
        if (userMap != null) {
          computedName ??=
              (userMap['name'] ?? userMap['first_name'] ?? 'Utilisateur')
                  .toString();
          computedEmail ??= (userMap['email'] ?? '').toString();
        }
      }
    }

    // 4) Rappel "plus tard"
    final remindLater = prefs.getBool('profile_remind_later') ?? false;

    // 5) Bannière profil incomplet (robuste)
    bool computedShowBanner = false;
    try {
      computedShowBanner = (!computedIsGuest) &&
          (!remindLater) &&
          (userMap != null && _isProfileIncomplete(userMap!));
    } catch (e) {
      debugPrint('_isProfileIncomplete error: $e');
      computedShowBanner = false;
    }

    // 6) Un seul setState final
    if (!mounted) return;
    setState(() {
      isGuest = computedIsGuest;
      userName = computedName;
      email = computedEmail;

      _countFavorites = favCount;
      _countBookings = bookingsCount;
      _countReviews = reviewsCount;

      _showProfileBanner = computedShowBanner;

      _isLoadingUser = false;
    });
  }

  Future<void> _loadRecentBookings() async {
    final prefs = await SharedPreferences.getInstance();

    // --- 1️⃣ Vérifier s’il y a une réservation non finalisée ---
    final pendingJson = prefs.getString('reservation_data');
    Map<String, dynamic>? pendingReservation;
    if (pendingJson != null && pendingJson.isNotEmpty) {
      try {
        pendingReservation = jsonDecode(pendingJson);
      } catch (e) {
        debugPrint('Erreur décodage pending: $e');
      }
    }

    // --- 2️⃣ Charger l'utilisateur ---
    final userJson = prefs.getString('user');
    if (userJson == null || userJson.isEmpty) return;

    final user = User.fromJson(jsonDecode(userJson));

    // --- 3️⃣ Récupérer les réservations depuis ton API ---
    try {
      final allBookings = await apiBooking.getUserReservations(user);

      // Tri décroissant par date de réservation
      allBookings.sort((a, b) {
        final da = DateTime.tryParse(a.bookedAt ?? '') ?? DateTime(2000);
        final db = DateTime.tryParse(b.bookedAt ?? '') ?? DateTime(2000);
        return db.compareTo(da);
      });

      // Ne garder que les 5 dernières
      final recentBookings = allBookings.take(5).toList();
      detectTipOpportunity(recentBookings);

      if (_recentlyFinishedBooking != null && !_tipShown) {
        _tipShown = true;
        Future.delayed(const Duration(milliseconds: 300), () {
          if (mounted) showTipSheet(context, _recentlyFinishedBooking!);
        });
      }
      if (!mounted) return;
      setState(() {
        _pendingReservation = pendingReservation;
        _recentBookings = recentBookings;
      });
    } catch (e) {
      debugPrint('Erreur chargement réservations : $e');
    }
  }

  Booking? get _currentReservation {
    if (_recentBookings.isEmpty) return null;

    final now = DateTime.now();
    // ⚠️ Si tes dates sont en string dans le modèle, adapte ici.
    for (final b in _recentBookings) {
      final start = DateTime.parse(b.firstNight); // ex: "2025-10-24"
      final end = DateTime.parse(b.lastNight); // ex: "2025-10-26"

      // 👉 Cas 1 : tu veux considérer "en cours" = séjour actif OU à venir
      // (tant que la date de fin n'est pas dépassée)
      if (!end.isBefore(now)) {
        return b;
      }

      // 👉 Variante stricte (si tu veux vraiment "en cours" = aujourd'hui ∈ [start, end])
      // if (!now.isBefore(start) && !now.isAfter(end)) {
      //   return b;
      // }
    }

    return null;
  }

  List<Booking> get _otherBookings {
    final current = _currentReservation;
    if (current == null) return _recentBookings;
    return _recentBookings.where((b) => b.id != current.id).toList();
  }

  Widget _buildHeader() {
    lang = Provider.of<LanguageProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("👤 ${lang.t('account')}",
                  style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF244B6B))),
              const SizedBox(height: 2),
              Text(lang.t('my_space'),
                  style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            ],
          ),
          IconButton(
            icon:
                const Icon(Icons.settings, size: 26, color: Color(0xFF244B6B)),
            onPressed: () {
              Navigator.pushNamed(
                  context, '/account/settings'); // ✅ exécuter la nav
            },
          ),
        ],
      ),
    );
  }

  Future<void> _changeDates(Booking d) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    // Numéro du service client WhatsApp
    const supportNumber = "+33612781715"; // 🔥 MODIFIER ICI

    final oldStart = DateTime.parse(d.firstNight);
    final oldEnd = DateTime.parse(d.lastNight);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 730)),
      initialDateRange: DateTimeRange(start: oldStart, end: oldEnd),
      helpText: lang.t('select_dates'),
      saveText: lang.t('validate'),
    );

    if (picked == null) return;
    if (!picked.start.isBefore(picked.end)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.t('invalid_dates_range'))),
      );
      return;
    }

    final newStart = picked.start;
    final newEnd = picked.end;

    // ---------------------------------------------------------------------------
    // 🔥 TRADUCTION AUTOMATIQUE FR / EN
    // ---------------------------------------------------------------------------
    final isFr = lang.currentLang == "fr";

    final message = Uri.encodeComponent(
      isFr
          ? """
Bonjour Chicaparts 👋,

Je souhaite modifier les dates de ma réservation à ${d.accommodation}.

📅 *Dates actuelles :*
- Du ${DateFormat('dd MMM yyyy').format(oldStart)}
- Au ${DateFormat('dd MMM yyyy').format(oldEnd)}

📅 *Nouvelles dates souhaitées :*
- Du ${DateFormat('dd MMM yyyy').format(newStart)}
- Au ${DateFormat('dd MMM yyyy').format(newEnd)}

Merci de revenir vers moi 😊
"""
          : """
Hello Chicaparts 👋,

I would like to change the dates of my reservation at ${d.accommodation}.

📅 *Current dates:*
- From ${DateFormat('dd MMM yyyy').format(oldStart)}
- To ${DateFormat('dd MMM yyyy').format(oldEnd)}

📅 *New requested dates:*
- From ${DateFormat('dd MMM yyyy').format(newStart)}
- To ${DateFormat('dd MMM yyyy').format(newEnd)}

Thank you for your assistance 😊
""",
    );

    // ---------------------------------------------------------------------------
    // 🔥 URLs avec numéro
    // ---------------------------------------------------------------------------
    final whatsappUrl =
        Uri.parse("whatsapp://send?phone=$supportNumber&text=$message");
    final whatsappWebUrl =
        Uri.parse("https://wa.me/$supportNumber?text=$message");

    // ---------------------------------------------------------------------------
    // 🔥 Ouverture WhatsApp
    // ---------------------------------------------------------------------------
    try {
      final opened =
          await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);

      if (!opened) {
        await launchUrl(whatsappWebUrl, mode: LaunchMode.externalApplication);
      }
    } catch (_) {
      await launchUrl(whatsappWebUrl, mode: LaunchMode.externalApplication);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isFr
              ? "Votre demande a été envoyée au service client."
              : "Your request has been sent to customer service.",
        ),
      ),
    );
  }

  bool justFinished(Booking b) {
    final now = DateTime.now();
    final lastNight = DateTime.parse(b.lastNight);
    // return true;
    // Séjour terminé il y a <= 1 jour
    return now.isAfter(lastNight) && now.difference(lastNight).inHours <= 24;
  }

  void detectTipOpportunity(List<Booking> bookings) {
    for (var b in bookings) {
      if (justFinished(b)) {
        _recentlyFinishedBooking = b;
        return;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final current = _currentReservation;

    return Scaffold(
        body: SafeArea(
      child: Column(
        children: [
          _buildHeader(),

          // ⬇️ Espace principal
          Expanded(
            child: _isLoadingUser
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF244B6B)),
                  )
                : !isGuest
                    ? RefreshIndicator(
                        onRefresh: _loadUserSession,
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            const SliverToBoxAdapter(
                                child: SectionSpacer(height: 12)),

                            // Header compact
                            SliverToBoxAdapter(
                              child: HeaderCompact(
                                isGuest: isGuest,
                                userName: userName,
                                email: email,
                                onEdit: () => Navigator.pushNamed(
                                    context, '/account/profile'),
                                onLogin: () =>
                                    Navigator.pushNamed(context, '/login'),
                                onCompleteProfile: () => Navigator.pushNamed(
                                    context, '/account/profile'),
                                onLater: () async {
                                  final prefs =
                                      await SharedPreferences.getInstance();
                                  await prefs.setBool(
                                      'profile_remind_later', true);
                                  if (!mounted) return;
                                  setState(() => _showProfileBanner = false);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                        content: Text(lang.t('remind_late'))),
                                  );
                                },
                                showBanner: _showProfileBanner,
                              ),
                            ),
                            const SliverToBoxAdapter(
                                child: SectionSpacer(height: 12)),

                            // ✅ Stats (uniquement connectés)
                            SliverToBoxAdapter(
                              child: MiniStatsRow(
                                reservations: _countBookings,
                                favorites: _countFavorites,
                                reviews: _countReviews,
                              ),
                            ),

                            const SliverToBoxAdapter(
                                child: SectionSpacer(height: 12)),

                            // Raccourcis
                            SliverToBoxAdapter(
                              child: QuickActions(actions: [
                                QuickAction(
                                  Icons.receipt_long_outlined,
                                  lang.t('my_bookings'),
                                  () => Navigator.pushNamed(
                                      context, '/reservations'),
                                ),
                                QuickAction(
                                  Icons.chat_bubble_outline,
                                  lang.t('my_reviews'),
                                  () => Navigator.pushNamed(context, '/avis'),
                                ),
                                QuickAction(
                                  Icons.favorite_border,
                                  lang.t('favotite'),
                                  () => Navigator.pushNamed(
                                      context, '/favorites'),
                                ),
                                QuickAction(
                                  Icons.person_outline,
                                  lang.t('my_profile'),
                                  () => Navigator.pushNamed(
                                      context, '/account/profile'),
                                ),
                              ]),
                            ),

                            const SliverToBoxAdapter(
                                child: SectionSpacer(height: 12)),

                            // ✅ Dernières réservations (uniquement connectés)
                            if (current != null || _otherBookings.isNotEmpty)
                              SliverToBoxAdapter(
                                child: SectionHeader(
                                  title: lang.t('recent_booking'),
                                  actionLabel: lang.t('see_all'),
                                ),
                              ),

                            // ✅ Réservation en cours (grosse carte)
                            if (current != null)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: ReservationInProgressCard(
                                    title: current.accommodation,
                                    city: current.city,
                                    firstNight:
                                        DateTime.parse(current.firstNight),
                                    lastNight:
                                        DateTime.parse(current.lastNight),
                                    currency: current.currency,
                                    totalAmount: current.price ?? 0,
                                    travelers: (current.adult ?? 1) +
                                        (current.child ?? 0),
                                    // 👇 ici on met bien le statut de paiement
                                    paymentStatus: current.validationStatus,
                                    // 👇 et ici le label d'affichage (validation)
                                    statusLabel:
                                        current.validationStatus == "confirmed"
                                            ? lang.t('confirmed')
                                            : lang.t('waitting'),
                                    imageUrl: current.img,
                                    onChangeDates: () => _changeDates(current),
                                    onTip: () => Navigator.pushNamed(
                                        context, '/tips/${current.id}'),
                                    onReview: () => Navigator.pushNamed(
                                      context,
                                      '/reservations/${current.id}#review',
                                    ),
                                    onMore: () => Navigator.pushNamed(
                                      context,
                                      '/reservations/${current.id}#review',
                                    ),
                                  ),
                                ),
                              ),

                            // ✅ Liste des autres réservations (sans celle en cours)
                            SliverList.builder(
                              itemCount: _otherBookings.length,
                              itemBuilder: (_, i) {
                                final booking = _otherBookings[i];
                                return BookingTile(
                                  title: booking.accommodation,
                                  city: booking.city,
                                  dates:
                                      "${DateFormat('dd MMM').format(DateTime.parse(booking.firstNight))} – ${DateFormat('dd MMM yyyy').format(DateTime.parse(booking.lastNight))}",
                                  status: booking.validationStatus,
                                  imageUrl: booking.img,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    '/reservations/${booking.id}',
                                  ),
                                );
                              },
                            ),

                            const SliverToBoxAdapter(
                                child: SizedBox(height: 24)),
                          ],
                        ),
                      )
                    : _buildLoginPrompt(),
          ),
        ],
      ),
    ));
  }

  void showTipSheet(BuildContext context, Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => TipWidget(booking: booking),
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

  void logoutUser(BuildContext context) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // 🔐 Supprime toute la session
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (route) => false,
    );
  }
}
