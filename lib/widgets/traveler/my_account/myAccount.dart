import 'dart:convert';

import 'package:chicaparts_partner/api/traveler/api_booking_traveler.dart';
import 'package:chicaparts_partner/models/model_booking.dart';
import 'package:chicaparts_partner/models/traveler/modele_booking_traveler.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/exchange_rate_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/utils/currency_converter.dart';
import 'package:chicaparts_partner/widgets/traveler/accommodation/optimized_network_image.dart';
import 'package:chicaparts_partner/widgets/traveler/common/login_required_state.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/account_class.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/claims.dart';
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
  List<Booking> _allBookings = [];
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
        _allBookings = allBookings;
      });
    } catch (e) {
      debugPrint('Erreur chargement réservations : $e');
    }
  }

  Booking? get _currentReservation {
    if (_allBookings.isEmpty) return null;

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final candidates = _allBookings.where((booking) {
      final checkout = _checkoutDate(booking.lastNight);
      if (checkout == null || checkout.isBefore(today)) return false;

      final status = booking.validationStatus.trim().toLowerCase();
      return status != 'cancelled' &&
          status != 'canceled' &&
          status != 'expired';
    }).toList()
      ..sort((a, b) {
        final checkoutA = _checkoutDate(a.lastNight)!;
        final checkoutB = _checkoutDate(b.lastNight)!;
        return checkoutA.compareTo(checkoutB);
      });

    return candidates.isEmpty ? null : candidates.first;
  }

  Future<void> _showBookingActions(Booking booking) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final isConfirmed =
        booking.validationStatus.trim().toLowerCase() == 'confirmed';
    final action = await showModalBottomSheet<_BookingAction>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(top: 10, bottom: 8),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.calendar_month_outlined),
                title: Text(lang.t('update')),
                onTap: () =>
                    Navigator.pop(sheetContext, _BookingAction.changeDates),
              ),
              ListTile(
                leading: const Icon(Icons.chat_outlined),
                title: Text(
                  lang.currentLang == 'fr'
                      ? 'Contacter via WhatsApp'
                      : 'Contact via WhatsApp',
                ),
                onTap: () =>
                    Navigator.pop(sheetContext, _BookingAction.whatsApp),
              ),
              ListTile(
                leading: const Icon(Icons.forum_outlined),
                title: Text(
                  lang.currentLang == 'fr'
                      ? 'Chat dans l’application'
                      : 'In-app chat',
                ),
                subtitle: Text(
                  lang.currentLang == 'fr'
                      ? 'Bientôt disponible'
                      : 'Coming soon',
                ),
                onTap: () => Navigator.pop(sheetContext, _BookingAction.chat),
              ),
              if (isConfirmed) ...[
                ListTile(
                  leading: const Icon(Icons.volunteer_activism_outlined),
                  title: Text(
                    lang.currentLang == 'fr'
                        ? 'Laisser un pourboire'
                        : 'Leave a tip',
                  ),
                  onTap: () => Navigator.pop(sheetContext, _BookingAction.tip),
                ),
                ListTile(
                  leading: const Icon(Icons.report_problem_outlined),
                  title: Text(
                    lang.currentLang == 'fr'
                        ? 'Faire une réclamation'
                        : 'Make a claim',
                  ),
                  onTap: () =>
                      Navigator.pop(sheetContext, _BookingAction.claim),
                ),
                ListTile(
                  leading: const Icon(Icons.rate_review_outlined),
                  title: Text(
                    lang.currentLang == 'fr'
                        ? 'Laisser un avis'
                        : 'Leave a review',
                  ),
                  onTap: () =>
                      Navigator.pop(sheetContext, _BookingAction.review),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    if (!mounted || action == null) return;
    switch (action) {
      case _BookingAction.changeDates:
        await _changeDates(booking);
        break;
      case _BookingAction.whatsApp:
        await _openBookingWhatsApp(booking, lang);
        break;
      case _BookingAction.chat:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              lang.currentLang == 'fr'
                  ? 'Le chat dans l’application sera bientôt disponible.'
                  : 'In-app chat will be available soon.',
            ),
          ),
        );
        break;
      case _BookingAction.tip:
        showTipSheet(context, booking);
        break;
      case _BookingAction.claim:
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ClaimsPage(
              initialBookingId: booking.id,
              initialAccommodationId: booking.propId,
            ),
          ),
        );
        break;
      case _BookingAction.review:
        Navigator.pushNamed(context, '/reservations/${booking.id}#review');
        break;
    }
  }

  Future<void> _openBookingWhatsApp(
    Booking booking,
    LanguageProvider lang,
  ) async {
    const supportNumber = '+33612781715';
    final message = Uri.encodeComponent(
      lang.currentLang == 'fr'
          ? 'Bonjour Chicaparts, je souhaite obtenir de l’aide concernant ma réservation ${booking.accommodation} (#${booking.id}).'
          : 'Hello Chicaparts, I need assistance with my booking ${booking.accommodation} (#${booking.id}).',
    );
    final appUri =
        Uri.parse('whatsapp://send?phone=$supportNumber&text=$message');
    final webUri = Uri.parse('https://wa.me/$supportNumber?text=$message');
    final opened =
        await launchUrl(appUri, mode: LaunchMode.externalApplication);
    if (!opened) {
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  DateTime? _bookingDate(String value) => DateTime.tryParse(value);

  Future<void> _openProfile() async {
    final updated = await Navigator.pushNamed(context, '/account/profile');
    if (updated == true && mounted) {
      await _loadUserSession();
      await _loadRecentBookings();
    }
  }

  DateTime? _checkoutDate(String value) {
    final lastNight = _bookingDate(value);
    return lastNight?.add(const Duration(days: 1));
  }

  String _bookingDatesLabel(Booking booking) {
    final currentLang = Provider.of<LanguageProvider>(context, listen: false);
    final first = _bookingDate(booking.firstNight);
    final checkout = _checkoutDate(booking.lastNight);

    if (first == null || checkout == null) {
      return currentLang.currentLang == 'fr'
          ? 'Date non disponible'
          : 'Date not available';
    }

    return "${DateFormat('dd MMM').format(first)} - ${DateFormat('dd MMM yyyy').format(checkout)}";
  }

  Widget _buildRecentBookingCard(Booking booking) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final colors = Theme.of(context).colorScheme;
    final statusColor = _bookingStatusColor(booking.validationStatus);
    final selectedCurrency = context.watch<CurrencyProvider>().currency;
    final exchangeRates = context.watch<ExchangeRateProvider>().rates;
    final amount = _bookingAmountLabel(
      booking,
      selectedCurrency,
      exchangeRates,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () =>
            Navigator.pushNamed(context, '/reservations/${booking.id}'),
        child: Container(
          decoration: BoxDecoration(
            color: colors.surfaceContainer,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.outlineVariant),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 112,
                height: 112,
                child: ClipRRect(
                  borderRadius: const BorderRadius.horizontal(
                    left: Radius.circular(8),
                  ),
                  child: OptimizedNetworkImage(
                    imageUrl: booking.img,
                    width: 112,
                    height: 112,
                    fit: BoxFit.cover,
                    memCacheWidth: 320,
                    memCacheHeight: 320,
                    maxWidthDiskCache: 520,
                    maxHeightDiskCache: 520,
                    errorWidget: const Icon(
                      Icons.apartment_outlined,
                      color: Color(0xFF98A2B3),
                      size: 34,
                    ),
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              booking.accommodation.isNotEmpty
                                  ? booking.accommodation
                                  : lang.t('accommodation'),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _MiniStatusPill(
                            label: _bookingStatusLabel(
                              booking.validationStatus,
                              lang,
                            ),
                            color: statusColor,
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      _MiniInfoLine(
                        icon: Icons.location_on_outlined,
                        text: booking.city.isNotEmpty ? booking.city : '-',
                      ),
                      const SizedBox(height: 5),
                      _MiniInfoLine(
                        icon: Icons.calendar_month_outlined,
                        text: _bookingDatesLabel(booking),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              amount,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: colors.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Icon(Icons.chevron_right,
                              color: colors.onSurfaceVariant),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _bookingAmountLabel(
    Booking booking,
    String selectedCurrency,
    Map<String, double> exchangeRates,
  ) {
    return CurrencyConverter.format(
      booking.price.toDouble(),
      from: booking.currency,
      to: selectedCurrency,
      rates: exchangeRates,
    );
  }

  Color _bookingStatusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'confirmed' || normalized == 'accepted') {
      return const Color(0xFF21A35B);
    }
    if (normalized == 'expired' ||
        normalized == 'cancelled' ||
        normalized == 'canceled') {
      return const Color(0xFFE53935);
    }
    return const Color(0xFFF79009);
  }

  String _bookingStatusLabel(String status, LanguageProvider lang) {
    final normalized = status.toLowerCase();
    if (normalized == 'confirmed' || normalized == 'accepted') {
      return lang.t('confirmed');
    }
    if (normalized == 'expired') return lang.t('expired');
    return lang.t('waitting').trim();
  }

  List<Booking> get _otherBookings {
    final current = _currentReservation;
    if (current == null) return _recentBookings;
    return _recentBookings.where((b) => b.id != current.id).toList();
  }

  Widget _buildHeader() {
    lang = Provider.of<LanguageProvider>(context, listen: false);
    final colors = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 12, 14),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.person_outline,
              color: colors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "${lang.t('account')}",
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lang.t('my_space'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(Icons.settings, size: 26, color: colors.primary),
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
    if (d.validationStatus.trim().toLowerCase() != 'confirmed') {
      await _showDateChangeUnavailable(lang);
      return;
    }

    // Numéro du service client WhatsApp
    const supportNumber = "+33612781715"; // 🔥 MODIFIER ICI

    final oldStart = _bookingDate(d.firstNight);
    final oldEnd = _checkoutDate(d.lastNight);

    if (oldStart == null || oldEnd == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            lang.currentLang == 'fr'
                ? 'Date non disponible'
                : 'Date not available',
          ),
        ),
      );
      return;
    }

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
Bonjour Chicaparts�,

Je souhaite modifier les dates de ma r�servation � ${d.accommodation}.
 *Dates actuelles :*
- Du ${DateFormat('dd MMM yyyy').format(oldStart)}
- Au ${DateFormat('dd MMM yyyy').format(oldEnd)}

*Nouvelles dates souhait�es :*
- Du ${DateFormat('dd MMM yyyy').format(newStart)}
- Au ${DateFormat('dd MMM yyyy').format(newEnd)}

Merci de revenir vers moi
"""
          : """
Hello Chicaparts,

I would like to change the dates of my reservation at ${d.accommodation}.

*Current dates:*
- From ${DateFormat('dd MMM yyyy').format(oldStart)}
- To ${DateFormat('dd MMM yyyy').format(oldEnd)}

*New requested dates:*
- From ${DateFormat('dd MMM yyyy').format(newStart)}
- To ${DateFormat('dd MMM yyyy').format(newEnd)}

Thank you for your assistance
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
              ? "Votre demande a �t� envoy�e au service client."
              : "Your request has been sent to customer service.",
        ),
      ),
    );
  }

  Future<void> _showDateChangeUnavailable(LanguageProvider lang) {
    return showDialog<void>(
      context: context,
      builder: (dialogContext) {
        final colors = Theme.of(dialogContext).colorScheme;
        return AlertDialog(
          icon: Icon(
            Icons.info_outline_rounded,
            color: colors.primary,
            size: 34,
          ),
          title: Text(
            lang.currentLang == 'fr'
                ? 'Modification indisponible'
                : 'Changes unavailable',
            textAlign: TextAlign.center,
          ),
          content: Text(
            lang.currentLang == 'fr'
                ? 'Les dates peuvent être modifiées uniquement lorsque la réservation est confirmée. Le statut actuel de cette réservation ne permet pas encore cette action.'
                : 'Dates can only be changed once the booking is confirmed. The current booking status does not allow this action yet.',
            textAlign: TextAlign.center,
          ),
          actionsAlignment: MainAxisAlignment.center,
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(lang.t('close')),
            ),
          ],
        );
      },
    );
  }

  bool justFinished(Booking b) {
    final status = b.validationStatus.toLowerCase();
    final isConfirmed = status == 'confirmed' || status == 'accepted';
    if (!isConfirmed) return false;
    if (b.hasTips) return false;

    final now = DateTime.now();
    final checkout = _checkoutDate(b.lastNight);
    if (checkout == null) return false;
    // return true;
    // Séjour terminé il y a <= 1 jour
    return now.isAfter(checkout) && now.difference(checkout).inHours <= 24;
  }

  void detectTipOpportunity(List<Booking> bookings) {
    _recentlyFinishedBooking = null;
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
    final currentFirst =
        current == null ? null : _bookingDate(current.firstNight);
    final currentLast =
        current == null ? null : _bookingDate(current.lastNight);

    return Scaffold(
        body: SafeArea(
      child: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: _isLoadingUser
                ? const Center(
                    child: CircularProgressIndicator(color: Color(0xFF244B6B)),
                  )
                : !isGuest
                    ? RefreshIndicator(
                        onRefresh: () async {
                          await _loadUserSession();
                          await _loadRecentBookings();
                        },
                        child: CustomScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          slivers: [
                            // Header compact
                            SliverToBoxAdapter(
                              child: HeaderCompact(
                                isGuest: isGuest,
                                userName: userName,
                                email: email,
                                onEdit: _openProfile,
                                onLogin: () =>
                                    Navigator.pushNamed(context, '/login'),
                                onCompleteProfile: _openProfile,
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

                            SliverToBoxAdapter(
                              child: MiniStatsRow(
                                reservations: _countBookings,
                                favorites: _countFavorites,
                                reviews: _countReviews,
                              ),
                            ),

                            if (current != null &&
                                currentFirst != null &&
                                currentLast != null)
                              SliverToBoxAdapter(
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  child: ActiveBookingCard(
                                    title: current.accommodation,
                                    city: current.city,
                                    firstNight: currentFirst,
                                    lastNight: currentLast,
                                    currency: current.currency,
                                    totalAmount: current.price,
                                    travelers: current.adult + current.child,
                                    paymentStatus: current.validationStatus,
                                    statusLabel:
                                        current.validationStatus == "confirmed"
                                            ? lang.t('confirmed')
                                            : lang.t('waitting'),
                                    imageUrl: current.img,
                                    onChangeDates: () =>
                                        _showBookingActions(current),
                                    onTip: () => showTipSheet(context, current),
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

                            const SliverToBoxAdapter(
                                child: SectionSpacer(height: 12)),

                            SliverToBoxAdapter(
                              child: QuickActions(actions: [
                                QuickAction(
                                  Icons.report_problem_outlined,
                                  lang.t('my_claims'),
                                  () => Navigator.pushNamed(
                                      context, '/account/claims'),
                                ),
                                QuickAction(
                                  Icons.description_outlined,
                                  _accountLabel(
                                    lang,
                                    'invoices',
                                    fr: 'Factures',
                                    en: 'Invoices',
                                  ),
                                  () => Navigator.pushNamed(
                                      context, '/account/invoices'),
                                ),
                                QuickAction(
                                  Icons.volunteer_activism_outlined,
                                  _accountLabel(
                                    lang,
                                    'tips',
                                    fr: 'Pourboires',
                                    en: 'Tips',
                                  ),
                                  () => Navigator.pushNamed(
                                      context, '/account/tips'),
                                ),
                                QuickAction(
                                  Icons.person_outline,
                                  lang.t('my_profile'),
                                  _openProfile,
                                ),
                              ]),
                            ),

                            const SliverToBoxAdapter(
                                child: SectionSpacer(height: 12)),

                            if (current != null || _otherBookings.isNotEmpty)
                              SliverToBoxAdapter(
                                child: SectionHeader(
                                  title: lang.t('recent_booking'),
                                  actionLabel: lang.t('see_all'),
                                  onAction: () => Navigator.pushNamed(
                                      context, '/reservations'),
                                ),
                              ),

                            SliverList.builder(
                              itemCount: _otherBookings.length,
                              itemBuilder: (_, i) {
                                final booking = _otherBookings[i];
                                return _buildRecentBookingCard(booking);
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
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => TipWidget(booking: booking),
    );
  }

  String _accountLabel(
    LanguageProvider lang,
    String key, {
    required String fr,
    required String en,
  }) {
    final translated = lang.t(key);
    if (translated != key) return translated;
    return lang.currentLang == 'fr' ? fr : en;
  }

  Widget _buildLoginPrompt() {
    return const LoginRequiredState();
  }
}

class _MiniInfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _MiniInfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: 15, color: Theme.of(context).colorScheme.onSurfaceVariant),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: 12.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _MiniStatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _MiniStatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

enum _BookingAction { changeDates, whatsApp, chat, tip, claim, review }
