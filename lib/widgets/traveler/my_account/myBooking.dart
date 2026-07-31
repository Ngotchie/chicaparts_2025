import 'dart:convert';

import 'package:chicaparts_partner/api/traveler/api_booking_traveler.dart';
import 'package:chicaparts_partner/models/model_booking.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/exchange_rate_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/utils/currency_converter.dart';
import 'package:chicaparts_partner/widgets/traveler/common/login_required_state.dart';
import 'package:chicaparts_partner/widgets/traveler/accommodation/optimized_network_image.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/account_class.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class MyReservationsPage extends StatefulWidget {
  const MyReservationsPage({super.key});

  @override
  State<MyReservationsPage> createState() => _MyReservationsPageState();
}

class _MyReservationsPageState extends State<MyReservationsPage> {
  User? user;
  final ApiBooking apiResa = ApiBooking();
  Future<List<Booking>> _allBookings = Future.value([]);
  Booking? _currentReservation;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    loadUserAndReservations();
  }

  Future<void> loadUserAndReservations() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson != null && userJson.isNotEmpty) {
      user = User.fromJson(jsonDecode(userJson));
      if (mounted) {
        setState(() {
          _isLoadingUser = false;
          _allBookings = _fetchAllBookings();
        });
      }
    } else if (mounted) {
      setState(() => _isLoadingUser = false);
    }
  }

  Future<List<Booking>> _fetchAllBookings() async {
    if (user == null) return [];

    final list = await apiResa.getUserReservations(user!);
    list.sort((a, b) {
      final da = DateTime.tryParse(a.bookedAt) ?? DateTime(2000);
      final db = DateTime.tryParse(b.bookedAt) ?? DateTime(2000);
      return db.compareTo(da);
    });

    _detectCurrentReservation(list);
    return list;
  }

  void _detectCurrentReservation(List<Booking> all) {
    final now = DateTime.now();
    Booking? current;

    for (final booking in all) {
      final start = DateTime.tryParse(booking.firstNight);
      final end = DateTime.tryParse(booking.lastNight);

      if (start != null && end != null) {
        if (now.isAfter(start) &&
            now.isBefore(end.add(const Duration(days: 1)))) {
          current = booking;
          break;
        }
      }
    }

    if (mounted) setState(() => _currentReservation = current);
  }

  Future<void> _loadAllBookings() async {
    setState(() => _allBookings = _fetchAllBookings());
  }

  Future<void> _changeDates(Booking booking) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    if (booking.validationStatus.trim().toLowerCase() != 'confirmed') {
      await showDialog<void>(
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
      return;
    }

    await Navigator.pushNamed(
      context,
      '/reservations/${booking.id}',
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(lang),
            Expanded(
              child: _isLoadingUser
                  ? _buildLoadingList()
                  : user == null
                      ? LoginRequiredState(
                          message: lang.t('booking_connect_text'),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadAllBookings,
                          child: FutureBuilder<List<Booking>>(
                            future: _allBookings,
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return _buildLoadingList();
                              }

                              if (snapshot.hasError) {
                                return ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(16),
                                  children: [
                                    _buildMessageState(
                                      icon: Icons.wifi_off_outlined,
                                      title: lang.t('error'),
                                      message: lang.t('error_network'),
                                    ),
                                  ],
                                );
                              }

                              final bookings = snapshot.data ?? [];
                              final otherBookings = bookings.where((booking) {
                                if (_currentReservation == null) return true;
                                return booking.id != _currentReservation!.id;
                              }).toList();

                              if (_currentReservation == null &&
                                  otherBookings.isEmpty) {
                                return ListView(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.all(16),
                                  children: [
                                    _buildMessageState(
                                      icon: Icons.event_busy_outlined,
                                      title: lang.t('no_booking'),
                                      message: lang.t('booking_empty'),
                                    ),
                                  ],
                                );
                              }

                              return ListView(
                                physics: const AlwaysScrollableScrollPhysics(),
                                padding:
                                    const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                children: [
                                  if (_currentReservation != null) ...[
                                    _buildSectionLabel(
                                        lang.t('active_booking')),
                                    _buildBookingCard(
                                      _currentReservation!,
                                      highlighted: true,
                                      onChangeDates: () =>
                                          _changeDates(_currentReservation!),
                                      onTip: () => Navigator.pushNamed(
                                        context,
                                        '/tips/${_currentReservation!.id}',
                                      ),
                                    ),
                                    const SizedBox(height: 18),
                                  ],
                                  ...otherBookings.map(
                                    (booking) => Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 12),
                                      child: _buildBookingCard(booking),
                                    ),
                                  ),
                                ],
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
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 14),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: colors.primary),
            onPressed: _leaveBookings,
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.event_note_outlined, color: colors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.t('my_bookings'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lang.t('my_bookings_text'),
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
            tooltip: lang.t('sync_my_resa'),
            icon: Icon(
              Icons.sync,
              size: 26,
              color: user == null ? colors.onSurfaceVariant : colors.primary,
            ),
            onPressed: user == null
                ? null
                : () => showSyncReservationsSheet(context, apiResa, user!),
          ),
        ],
      ),
    );
  }

  void _leaveBookings() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed('/my-account');
    }
  }

  Widget _buildSectionLabel(String title) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w800,
          color: colors.onSurface,
        ),
      ),
    );
  }

  Widget _buildBookingCard(
    Booking booking, {
    bool highlighted = false,
    VoidCallback? onChangeDates,
    VoidCallback? onTip,
  }) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final colors = Theme.of(context).colorScheme;
    final amount = _money(booking.price, booking.currency);
    final first = _parseDate(booking.firstNight);
    final checkout = _checkoutDate(booking.lastNight);
    final dates =
        '${DateFormat('dd MMM').format(first)} - ${DateFormat('dd MMM yyyy').format(checkout)}';
    final statusColor = _statusColor(booking.validationStatus);

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () => Navigator.pushNamed(context, '/reservations/${booking.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color:
                highlighted ? const Color(0xFF21A35B) : colors.outlineVariant,
            width: highlighted ? 1.3 : 1,
          ),
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
                    imageUrl: booking.img,
                    width: double.infinity,
                    height: highlighted ? 150 : 124,
                    fit: BoxFit.cover,
                    memCacheWidth: 720,
                    memCacheHeight: 420,
                    maxWidthDiskCache: 900,
                    maxHeightDiskCache: 540,
                    errorWidget: const Icon(
                      Icons.apartment_outlined,
                      size: 42,
                      color: Color(0xFF98A2B3),
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
                    booking.accommodation.isNotEmpty
                        ? booking.accommodation
                        : lang.t('accommodation'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: colors.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _InfoLine(
                    icon: Icons.location_on_outlined,
                    text: booking.city.isNotEmpty ? booking.city : '-',
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _InfoLine(
                          icon: Icons.calendar_month_outlined,
                          text: dates,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusPill(
                        label: _statusLabel(booking.validationStatus, lang),
                        color: statusColor,
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          amount,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: colors.primary,
                          ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => Navigator.pushNamed(
                          context,
                          '/reservations/${booking.id}',
                        ),
                        icon: const Icon(Icons.chevron_right, size: 18),
                        label: Text(lang.t('details')),
                        style: TextButton.styleFrom(
                          foregroundColor: colors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),
                  if (highlighted) ...[
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: onChangeDates,
                            icon: const Icon(Icons.calendar_month_outlined,
                                size: 18),
                            label: Text(lang.t('update')),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: colors.primary,
                              side: BorderSide(color: colors.outlineVariant),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: onTip,
                            icon: const Icon(Icons.payments_outlined, size: 18),
                            label: Text(lang.t('tip')),
                            style: FilledButton.styleFrom(
                              backgroundColor: colors.primary,
                              foregroundColor: colors.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingList() {
    final colors = Theme.of(context).colorScheme;

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: colors.surfaceContainerHighest,
          highlightColor: colors.surfaceContainer,
          child: Container(
            height: index == 0 ? 250 : 210,
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
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
          ],
        ),
      ),
    );
  }

  String _money(num amount, String currency) {
    final selectedCurrency = context.watch<CurrencyProvider>().currency;
    final exchangeRates = context.watch<ExchangeRateProvider>().rates;
    return CurrencyConverter.format(
      amount.toDouble(),
      from: currency,
      to: selectedCurrency,
      rates: exchangeRates,
    );
  }

  DateTime _parseDate(String value) {
    return DateTime.tryParse(value) ?? DateTime(1970);
  }

  DateTime _checkoutDate(String lastNight) {
    return _parseDate(lastNight).add(const Duration(days: 1));
  }

  Color _statusColor(String status) {
    final normalized = status.toLowerCase();
    if (normalized == 'confirmed' ||
        normalized == 'accepted' ||
        normalized == 'paid') {
      return const Color(0xFF21A35B);
    }
    if (normalized == 'expired' ||
        normalized == 'cancelled' ||
        normalized == 'canceled') {
      return const Color(0xFFE53935);
    }
    return const Color(0xFFF79009);
  }

  String _statusLabel(String status, LanguageProvider lang) {
    final normalized = status.toLowerCase();
    if (normalized == 'confirmed' || normalized == 'accepted') {
      return lang.t('confirmed');
    }
    if (normalized == 'expired') return lang.t('expired');
    return lang.t('waitting').trim();
  }

  void showSyncReservationsSheet(
    BuildContext context,
    ApiBooking api,
    User user,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (context) {
        return SyncReservationsWidget(api: api, user: user);
      },
    );
  }
}

class _InfoLine extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoLine({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Row(
      children: [
        Icon(icon, size: 16, color: colors.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 13, color: colors.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusPill({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

