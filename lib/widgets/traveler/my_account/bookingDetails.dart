import 'dart:convert';

import 'package:chicaparts_partner/models/traveler/modele_booking_details.dart';
import 'package:chicaparts_partner/models/traveler/modele_review.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/account_class.dart';
import 'package:chicaparts_partner/widgets/traveler/book/payment_processing_page.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

// Branche ces imports vers TES services/modèles
import 'package:chicaparts_partner/api/traveler/api_booking_traveler.dart';
import 'package:chicaparts_partner/models/model_booking.dart';
import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/exchange_rate_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/utils/currency_converter.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BookingDetailsPage extends StatefulWidget {
  final String bookingId;
  const BookingDetailsPage({super.key, required this.bookingId});

  @override
  State<BookingDetailsPage> createState() => _BookingDetailsPageState();
}

class _BookingDetailsPageState extends State<BookingDetailsPage>
    with SingleTickerProviderStateMixin {
  final api = ApiBooking();
  final _apiReview = ApiReview();

  Future<OneBookingDetails>? _future; // loaded after user bootstrap

  User? _currentUser;
  Review? _myReview;
  bool _loadingReview = true;

  var lang;

  String _formatMoney(num amount, String currency) {
    return CurrencyConverter.format(
      amount.toDouble(),
      from: currency,
      to: context.read<CurrencyProvider>().currency,
      rates: context.read<ExchangeRateProvider>().rates,
    );
  }

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// Charge le currentUser puis les détails
  Future<void> _init() async {
    await _loadUserForReview();
    setState(() {
      _future = _load(); // maintenant user est dispo
    });
  }

  /// Rafraîchit les détails après un update de review
  Future<void> _refreshDetails() async {
    if (_currentUser == null) return;
    setState(() {
      _future = _load();
    });
    await _future;
  }

  /// Charge les détails en utilisant le currentUser
  Future<OneBookingDetails> _load() async {
    if (_currentUser == null) {
      throw Exception("Connection required");
    }
    return api.getOneBooking(widget.bookingId, _currentUser!);
  }

  /// Charge le user local
  Future<void> _loadUserForReview() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson == null) {
      _currentUser = null;
      _loadingReview = false;
      return;
    }

    _currentUser = User.fromJson(jsonDecode(userJson));
  }

  Future<void> _checkExistingReview(OneBookingDetails d) async {
    if (_currentUser == null) {
      setState(() => _loadingReview = false);
      return;
    }
    try {
      final r = await _apiReview.getUserReviewForAccommodation(
        customerId: _currentUser!.id,
        accommodationId: int.tryParse(d.accommodationId) ?? 0,
      );
      setState(() {
        _myReview = r;
        _loadingReview = false;
      });
    } catch (_) {
      setState(() => _loadingReview = false);
    }
  }

  Future<void> _submitReview({
    required OneBookingDetails d,
    required int confort,
    required int staf,
    required int facilities,
    required int cleanliness,
    required String comment,
  }) async {
    if (_currentUser == null) return;
    final base = Review(
      id: 0,
      customerId: _currentUser!.id,
      accommodationId: int.tryParse(d.accommodationId) ?? 0,
      reviewer: _currentUser!.name,
      comment: comment,
      confort: confort,
      staf: staf,
      facilities: facilities,
      cleanliness: cleanliness,
      score: 0, accommodation: null, // côté backend append
    );
    try {
      Review saved;
      if (_myReview == null) {
        saved = await _apiReview.createReview(base);
      } else {
        saved = await _apiReview.updateReview(_myReview!.id, base);
      }
      _checkExistingReview(d);
      setState(() => _myReview = saved);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review save. Thanks !')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review error')),
      );
    }
  }

  Future<void> _deleteMyReview() async {
    if (_myReview == null) return;
    try {
      await _apiReview.deleteReview(_myReview!.id);
      setState(() => _myReview = null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review deleted.')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error')),
      );
    }
  }

  void _leaveBookingDetails() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      navigator.pushReplacementNamed('/reservations');
    }
  }

  Future<bool> _handleSystemBack() async {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) return true;
    navigator.pushReplacementNamed('/reservations');
    return false;
  }

  Future<void> _openPayment(OneBookingDetails d) async {
    if (_currentUser == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentProcessingPage(
          bookingId: int.tryParse(d.id) ?? 0,
          amount: (d.total - d.paidAmount).clamp(0, d.total).toDouble(),
          currency: d.currency,
          customerEmail: d.guestEmail,
          customerPhoneNumber: d.guestPhone,
          checkInFormatted: DateFormat('dd MMM yyyy').format(d.firstNight),
          resumeMode: true,
        ),
      ),
    );

    if (!mounted) return;
    _refreshDetails();
  }

  Future<void> _requestBookingChange(OneBookingDetails d) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    if (_currentUser == null) return;

    final currentCheckout = d.lastNight.add(const Duration(days: 1));
    DateTime selectedDate = currentCheckout.add(const Duration(days: 1));
    final reasonController = TextEditingController();
    // Une prolongation est estimée sur le tarif d'hébergement moyen.
    // Les taxes et frais ponctuels du séjour existant ne doivent pas être
    // redistribués artificiellement sur chaque nuit supplémentaire.
    final dailyTotal = d.nights > 0 ? d.price / d.nights : d.price;

    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final extraNights = selectedDate.difference(currentCheckout).inDays;
            final supplement = dailyTotal * extraNights;

            Future<void> pickDate() async {
              final picked = await showDatePicker(
                context: context,
                firstDate: currentCheckout.add(const Duration(days: 1)),
                lastDate: DateTime.now().add(const Duration(days: 730)),
                initialDate: selectedDate,
              );

              if (picked != null) {
                setModalState(() => selectedDate = picked);
              }
            }

            return AlertDialog(
              insetPadding: const EdgeInsets.symmetric(horizontal: 18),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
              contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              actionsPadding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
              title: _RequestDialogTitle(
                icon: Icons.event_repeat_outlined,
                title: lang.t('extend_booking'),
                color: const Color(0xFF244B6B),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF6F8FA),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color:
                                Theme.of(context).colorScheme.outlineVariant),
                      ),
                      child: _DialogInfoLine(
                        label: lang.t('current_checkout'),
                        value: DateFormat('dd MMM yyyy').format(
                          currentCheckout,
                        ),
                        bold: true,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      lang.t('extend_booking_intro'),
                      style: const TextStyle(
                        color: Color(0xFF667085),
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      lang.t('new_checkout_date'),
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: pickDate,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color:
                                  Theme.of(context).colorScheme.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.event_outlined,
                              color: Color(0xFF244B6B),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                DateFormat('dd MMM yyyy').format(selectedDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const Icon(Icons.expand_more),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEAF6EF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFC8EAD6)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _DialogInfoLine(
                            label: lang.t('additional_nights'),
                            value: '$extraNights',
                          ),
                          const SizedBox(height: 8),
                          _DialogInfoLine(
                            label: lang.t('estimated_supplement'),
                            value: _formatMoney(supplement, d.currency),
                            bold: true,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: reasonController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        labelText: lang.t('reason'),
                        hintText: lang.t('change_reason_hint'),
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: Theme.of(context)
                            .colorScheme
                            .surfaceContainerHighest
                            .withOpacity(0.55),
                        border: _requestInputBorder(),
                        enabledBorder: _requestInputBorder(),
                        focusedBorder: _requestInputBorder(
                          const Color(0xFF244B6B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(ctx, false),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFF244B6B),
                          side: const BorderSide(color: Color(0xFFE4EAF0)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(lang.t('cancel')),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        onPressed: () {
                          final reason = reasonController.text.trim();

                          if (!selectedDate.isAfter(currentCheckout)) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  lang.t('checkout_date_must_be_after'),
                                ),
                              ),
                            );
                            return;
                          }

                          if (reason.isNotEmpty && reason.length < 10) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(lang.t('reason_too_short')),
                              ),
                            );
                            return;
                          }

                          Navigator.pop(ctx, true);
                        },
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF244B6B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(lang.t('send')),
                      ),
                    ),
                  ],
                ),
              ],
            );
          },
        );
      },
    );

    if (submitted != true) {
      reasonController.dispose();
      return;
    }

    try {
      await api.requestCheckoutChange(
        bookingId: int.tryParse(d.id) ?? 0,
        user: _currentUser!,
        lastNight: selectedDate,
        reason: reasonController.text.trim().isEmpty
            ? null
            : reasonController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.t('booking_change_requested'))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${lang.t('error')}: $e')),
      );
    } finally {
      reasonController.dispose();
    }
  }

  Future<void> _requestCancellationRefund(OneBookingDetails d) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    if (_currentUser == null) return;

    final reasonController = TextEditingController();
    final submitted = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 18),
          backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 18, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          actionsPadding: const EdgeInsets.fromLTRB(20, 14, 20, 18),
          title: _RequestDialogTitle(
            icon: Icons.cancel_outlined,
            title: lang.t('cancel_refund_booking'),
            color: const Color(0xFFD74A4A),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF4F4),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFFFD6D6)),
                  ),
                  child: Text(
                    lang.t('cancel_refund_message'),
                    style: const TextStyle(
                      color: Color(0xFF7A2E2E),
                      height: 1.35,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: reasonController,
                  maxLines: 4,
                  decoration: InputDecoration(
                    labelText: lang.t('reason'),
                    hintText: lang.t('cancel_refund_reason_hint'),
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest
                        .withOpacity(0.55),
                    border: _requestInputBorder(),
                    enabledBorder: _requestInputBorder(),
                    focusedBorder: _requestInputBorder(
                      const Color(0xFFD74A4A),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF244B6B),
                      side: const BorderSide(color: Color(0xFFE4EAF0)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(lang.t('cancel')),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      final reason = reasonController.text.trim();
                      if (reason.isNotEmpty && reason.length < 10) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(lang.t('reason_too_short'))),
                        );
                        return;
                      }
                      Navigator.pop(ctx, true);
                    },
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFFD74A4A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(lang.t('send')),
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );

    if (submitted != true) {
      reasonController.dispose();
      return;
    }

    try {
      await api.requestCancellationRefund(
        bookingId: int.tryParse(d.id) ?? 0,
        user: _currentUser!,
        reason: reasonController.text.trim().isEmpty
            ? null
            : reasonController.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.t('cancel_refund_requested'))),
      );
      _refreshDetails();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${lang.t('error')}: $e')),
      );
    } finally {
      reasonController.dispose();
    }
  }

  OutlineInputBorder _requestInputBorder([
    Color color = const Color(0xFFE4EAF0),
  ]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide(color: color, width: 1.1),
    );
  }

  @override
  void dispose() {
    super.dispose();
  }

  Widget _reviewSection(OneBookingDetails d) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    // si pas connecté
    if (_currentUser == null) {
      return CardSection(
        title: lang.t('review'),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(lang.t('booking_connect_text')),
        ),
      );
    }

    if (_loadingReview) {
      return CardSection(
        title: lang.t('review'),
        child: const Padding(
          padding: EdgeInsets.all(12),
          child: LinearProgressIndicator(),
        ),
      );
    }

    // si avis existant -> affiche carte + actions
    if (_myReview != null) {
      final r = _myReview!;
      return CardSection(
        title: lang.t('your_review'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RatingLine(label: lang.t('comfort'), value: r.confort),
            RatingLine(label: lang.t('staf'), value: r.staf),
            RatingLine(label: lang.t('amenities'), value: r.facilities),
            RatingLine(label: lang.t('cleanliness'), value: r.cleanliness),
            const SizedBox(height: 8),
            ExpandableComment(
              text: r.comment,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  onPressed: () async {
                    // ouvre un petit éditeur avec les valeurs actuelles
                    final edited = await showDialog<ReviewFormData>(
                      context: context,
                      builder: (_) => ReviewDialog(
                        initial: ReviewFormData(
                          confort: r.confort,
                          staf: r.staf,
                          facilities: r.facilities,
                          cleanliness: r.cleanliness,
                          comment: r.comment,
                        ),
                      ),
                    );
                    if (edited != null) {
                      _submitReview(
                        d: d,
                        confort: edited.confort,
                        staf: edited.staf,
                        facilities: edited.facilities,
                        cleanliness: edited.cleanliness,
                        comment: edited.comment,
                      );
                    }
                  },
                  icon: const Icon(Icons.edit),
                  label: Text(lang.t('update')),
                ),
                const SizedBox(width: 12),
                TextButton.icon(
                  onPressed: _deleteMyReview,
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: Text(lang.t('delete'),
                      style: TextStyle(color: Colors.red)),
                ),
              ],
            )
          ],
        ),
      );
    }

    // sinon -> formulaire création
    return CardSection(
      title: lang.t('give_feedback'),
      child: ReviewForm(
        onSubmit: (data) => _submitReview(
          d: d,
          confort: data.confort,
          staf: data.staf,
          facilities: data.facilities,
          cleanliness: data.cleanliness,
          comment: data.comment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final future = _future;

    if (future == null) {
      return const Scaffold(
        body: SafeArea(
          child: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return FutureBuilder<OneBookingDetails>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: SafeArea(
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            body: SafeArea(
              child: Center(child: Text(lang.t('error_network'))),
            ),
          );
        }

        final d = snapshot.data!;
        final bool isConfirmed = d.validationStatus == 'confirmed';
        final status = d.validationStatus.toLowerCase();
        final bool canPay = d.paymentStatus != 'paid' && status != 'cancelled';
        final today = DateTime.now();
        final todayDate = DateTime(today.year, today.month, today.day);
        final checkInDate =
            DateTime(d.firstNight.year, d.firstNight.month, d.firstNight.day);
        final checkoutDate = DateTime(
          d.lastNight.year,
          d.lastNight.month,
          d.lastNight.day,
        ).add(const Duration(days: 1));
        final bool isCurrentBooking = status == 'confirmed' &&
            !todayDate.isBefore(checkInDate) &&
            todayDate.isBefore(checkoutDate);
        final bool canRequestCancellation =
            status != 'cancelled' && todayDate.isBefore(checkInDate);

        if (_currentUser != null && _loadingReview && isConfirmed) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _checkExistingReview(d);
          });
        }

        final tabWidgets = <Tab>[
          Tab(text: lang.t('booking')),
          if (isConfirmed) Tab(text: lang.t('useful_info')),
          if (isConfirmed) Tab(text: lang.t('Check-in_Check-out')),
          Tab(text: lang.t('accommodation')),
        ];

        final tabViews = <Widget>[
          _ReservationTab(
            d: d,
            lang: lang,
            canPay: canPay,
            canExtend: isCurrentBooking,
            canRequestCancellation: canRequestCancellation,
            onPay: canPay ? () => _openPayment(d) : null,
            onExtend: isCurrentBooking ? () => _requestBookingChange(d) : null,
            onCancelRefund: canRequestCancellation
                ? () => _requestCancellationRefund(d)
                : null,
            reviewBuilder: isConfirmed ? () => _reviewSection(d) : null,
          ),
          if (isConfirmed)
            _UsefulInfoTab(
              d: d,
              lang: lang,
            ),
          if (isConfirmed)
            _AccessTab(
              d: d,
              lang: lang,
            ),
          _AccommodationTab(
            d: d,
            lang: lang,
          ),
        ];

        return WillPopScope(
          onWillPop: _handleSystemBack,
          child: DefaultTabController(
            length: tabWidgets.length,
            child: Scaffold(
              backgroundColor: Colors.grey[100],
              body: SafeArea(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back_ios_new_rounded,
                              color: Color(0xFF244B6B),
                              size: 22,
                            ),
                            onPressed: _leaveBookingDetails,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            lang.t('booking_details'),
                            style: const TextStyle(
                              color: Color(0xFF244B6B),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      color: Colors.white,
                      child: TabBar(
                        isScrollable: true,
                        indicatorColor: const Color(0xFF244B6B),
                        labelColor: const Color(0xFF244B6B),
                        unselectedLabelColor: Colors.grey,
                        indicatorWeight: 3,
                        tabAlignment: TabAlignment.start,
                        padding: EdgeInsets.zero,
                        labelStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        unselectedLabelStyle: const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontSize: 14,
                        ),
                        tabs: tabWidgets,
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: tabViews,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

// ---------- Onglet 1 : Réservation ----------
String _formatBookingMoney(BuildContext context, num amount, String currency) {
  return CurrencyConverter.format(
    amount.toDouble(),
    from: currency,
    to: context.read<CurrencyProvider>().currency,
    rates: context.read<ExchangeRateProvider>().rates,
  );
}

class _ReservationTab extends StatelessWidget {
  final OneBookingDetails d;
  final LanguageProvider lang;
  final bool canPay;
  final bool canExtend;
  final bool canRequestCancellation;
  final VoidCallback? onPay;
  final VoidCallback? onExtend;
  final VoidCallback? onCancelRefund;
  final Widget Function()? reviewBuilder; // 👈 optionnel
  const _ReservationTab(
      {required this.d,
      required this.lang,
      required this.canPay,
      required this.canExtend,
      required this.canRequestCancellation,
      this.onPay,
      this.onExtend,
      this.onCancelRefund,
      this.reviewBuilder});

  @override
  Widget build(BuildContext context) {
    final f = DateFormat('dd MMM yyyy');
    final range =
        "${f.format(d.firstNight)} → ${f.format(d.lastNight.add(const Duration(days: 1)))}";

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (canPay) ...[
          const SizedBox(height: 12),
          CardSection(
            title: lang.t('account_actions'),
            child: SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: onPay,
                icon: const Icon(Icons.payment),
                label: Text(lang.t('pay_now')),
              ),
            ),
          ),
        ],
        CardSection(
          title: lang.t('stay_information'),
          child: _twoCols(
            left: InfoColumn(items: [
              InfoRow(lang.t('stay_date'), range, boldValue: true),
              InfoRow(lang.t('duration'), "${d.nights} nuit(s)"),
            ]),
            right: InfoColumn(items: [
              InfoRow(lang.t('travelers'), d.travelersLabel, boldValue: true),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        CardSection(
          title: lang.t('status_information'),
          child: _twoCols(
            left: InfoColumn(items: [
              InfoHeader(lang.t('booking')),
              InfoRow(lang.t('booking_date'),
                  DateFormat('dd MMM yyyy – HH:mm').format(d.createdAt)),
              InfoRowGlobal(lang.t('payment_status'), d.paymentStatusLabel,
                  badgeColor: d.paymentStatusColor),
              InfoRow(
                lang.t('amount_paid'),
                _formatBookingMoney(context, d.paidAmount, d.currency),
              ),
              InfoRow(lang.t('reference'), d.reference ?? "N/A"),
              InfoRow("Source", d.source),
            ]),
            right: InfoColumn(items: [
              const InfoHeader("Client"),
              InfoRow(lang.t('full_name'), d.guestFullName, boldValue: true),
              InfoRow(lang.t('email'), d.guestEmail),
              InfoRow(lang.t('phone'), d.guestPhone),
              InfoRow(lang.t('address'), d.guestAddress ?? "—"),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        CardSection(
          title: lang.t('payment_sommary'),
          child: InfoColumn(items: [
            MoneyRow(lang.t('base_price'), d.price, d.currency),
            MoneyRow(lang.t('cleaning_fees'), d.cleaningFee, d.currency),
            MoneyRow(lang.t('chicaparts_fees'), d.serviceFee, d.currency),
            MoneyRow(lang.t('city_taxe'), d.tax, d.currency),
            const Divider(),
            MoneyRow(lang.t('total_price'), d.total, d.currency, bold: true),
          ]),
        ),
        const SizedBox(height: 12),
        _StayExtensionSection(
          d: d,
          lang: lang,
          canExtend: canExtend,
          onExtend: onExtend,
        ),
        const SizedBox(height: 12),
        if (reviewBuilder != null) reviewBuilder!(),
        const SizedBox(height: 12),
        _CancellationSection(
          lang: lang,
          canRequestCancellation: canRequestCancellation,
          checkIn: d.firstNight,
          paymentStatus: d.paymentStatus,
          onCancelRefund: onCancelRefund,
        ),
      ],
    );
  }
}

class _StayExtensionSection extends StatelessWidget {
  final OneBookingDetails d;
  final LanguageProvider lang;
  final bool canExtend;
  final VoidCallback? onExtend;

  const _StayExtensionSection({
    required this.d,
    required this.lang,
    required this.canExtend,
    required this.onExtend,
  });

  @override
  Widget build(BuildContext context) {
    final checkout = d.lastNight.add(const Duration(days: 1));
    final dailyTotal = d.nights > 0 ? d.price / d.nights : d.price;

    return CardSection(
      title: lang.t('extend_stay'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            canExtend
                ? lang.t('extend_stay_available')
                : lang.t('extend_stay_unavailable'),
            style: TextStyle(color: Colors.grey[700], height: 1.35),
          ),
          const SizedBox(height: 8),
          InfoRow(
            lang.t('current_checkout'),
            DateFormat('dd MMM yyyy').format(checkout),
            boldValue: true,
          ),
          InfoRow(
            lang.t('estimated_daily_rate'),
            _formatBookingMoney(context, dailyTotal, d.currency),
            boldValue: true,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: canExtend ? onExtend : null,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF244B6B),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: const Icon(Icons.edit_calendar_outlined),
              label: Text(lang.t('request_stay_extension')),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogInfoLine extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;

  const _DialogInfoLine({
    required this.label,
    required this.value,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[700]),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF1D3550),
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RequestDialogTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _RequestDialogTitle({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _CancellationSection extends StatelessWidget {
  final LanguageProvider lang;
  final bool canRequestCancellation;
  final DateTime checkIn;
  final String paymentStatus;
  final VoidCallback? onCancelRefund;

  const _CancellationSection({
    required this.lang,
    required this.canRequestCancellation,
    required this.checkIn,
    required this.paymentStatus,
    required this.onCancelRefund,
  });

  @override
  Widget build(BuildContext context) {
    final normalizedPaymentStatus = paymentStatus.toLowerCase();
    final isPaid = normalizedPaymentStatus == 'paid' ||
        normalizedPaymentStatus == 'partial';

    return CardSection(
      title: lang.t('cancel_refund_booking'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            canRequestCancellation
                ? (isPaid
                    ? lang.t('cancel_refund_available')
                    : lang.t('cancel_booking_available'))
                : lang.t('cancel_refund_unavailable'),
            style: TextStyle(color: Colors.grey[700], height: 1.35),
          ),
          const SizedBox(height: 8),
          InfoRow(
            lang.t('check-in'),
            DateFormat('dd MMM yyyy').format(checkIn),
            boldValue: true,
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: canRequestCancellation ? onCancelRefund : null,
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFD74A4A),
                side: BorderSide(
                  color: canRequestCancellation
                      ? const Color(0xFFD74A4A)
                      : Colors.grey.shade300,
                ),
                padding: const EdgeInsets.symmetric(vertical: 13),
              ),
              icon: const Icon(Icons.cancel_outlined),
              label: Text(lang.t('request_cancellation_refund')),
            ),
          ),
        ],
      ),
    );
  }
}

// ---------- Onglet 2 : Infos utiles ----------
class _UsefulInfoTab extends StatelessWidget {
  final OneBookingDetails d;
  final LanguageProvider lang;
  const _UsefulInfoTab({
    required this.d,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        // 1 col <560px, 2 colonnes <900px, 3 colonnes au-delà
        final cols = w >= 900 ? 3 : (w >= 560 ? 2 : 1);

        final sections = <Widget>[
          _InfoSection(
            title: lang.t('wifi_access'),
            children: const [],
            rows: [
              InfoRow(lang.t('wifi_identifier'), d.wifiSsid ?? "—",
                  boldValue: true),
              InfoRow(lang.t('password'), d.wifiPassword ?? "—",
                  boldValue: true),
            ],
          ),
          _InfoSection(
            title: lang.t('accessibility'),
            rows: [
              InfoRow(lang.t('floor_number'), d.floor ?? "—"),
              InfoRow(lang.t('door_number'), d.door ?? "—"),
            ],
          ),
          _InfoSection(
            title: lang.t('parking'),
            rows: [
              InfoRow(lang.t('parking_type'), d.parkingType ?? "—",
                  boldValue: true),
              InfoRow(lang.t('location'), d.parkingLocation ?? "—",
                  boldValue: true),
              InfoRow(lang.t('access_method'), d.parkingAccess ?? "—"),
              InfoRow(lang.t('parking_spot'), d.parkingSlot ?? "—"),
            ],
          ),
          // Décommente si tu ajoutes ces champs côté modèle
          // _InfoSection(
          //   title: "Équipements",
          //   rows: [
          //     InfoRow("Chauffage", d.heating ?? "—"),
          //     InfoRow("Eau chaude", d.hotWater ?? "—"),
          //     InfoRow("Plaque", d.stove ?? "—"),
          //     InfoRow("Machine à café", d.coffeeMachine ?? "—"),
          //   ],
          // ),
        ];

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            CardSection(
              title: lang.t('useful_info'),
              child: _ResponsiveColumns(children: sections, columns: cols),
            ),
            const SizedBox(height: 12),
            CardSection(
              title: lang.t('house_rules'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  for (final rule in d.houseRules)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text("• $rule"),
                    ),
                  const SizedBox(height: 12),
                  InfoHeader(lang.t('timetable')),
                  InfoRow(lang.t('check-in'), d.checkinTime ?? "—",
                      boldValue: true),
                  InfoRow(lang.t('check-out'), d.checkoutTime ?? "—",
                      boldValue: true),
                  InfoRow(lang.t('quiet_hours'), d.quietHours ?? "—"),
                  if (d.specificRules.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    InfoHeader(lang.t('additional_rules')),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: d.specificRules
                          .map((e) => Chip(label: Text(e)))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

// ---------- Onglet 3 : Accès & sortie ----------
class _AccessTab extends StatelessWidget {
  final OneBookingDetails d;
  final LanguageProvider lang;
  const _AccessTab({required this.d, required this.lang});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CardSection(
          title: lang.t('check-in_instructions'),
          child: SelectableText(d.accessInstructions ?? "—"),
        ),
        const SizedBox(height: 12),
        CardSection(
          title: lang.t('check-out_instructions'),
          child: SelectableText(d.checkoutInstructions ?? "—"),
        ),
      ],
    );
  }
}

// ---------- Onglet 4 : Hébergement ----------
class _AccommodationTab extends StatelessWidget {
  final OneBookingDetails d;
  final LanguageProvider lang;
  const _AccommodationTab({required this.d, required this.lang});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        CardSection(
          title: d.accommodationTitle,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (d.accommodationImage != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(d.accommodationImage!),
                ),
              const SizedBox(height: 12),
              InfoColumn(items: [
                InfoRow(lang.t('capacity'), d.capacityLabel ?? "—"),
                InfoRow(lang.t('total_space'), d.surfaceLabel ?? "—"),
                InfoRow("Type", d.typeLabel ?? "—"),
                InfoRow(lang.t('entire_place'),
                    d.isEntirePlace ? lang.t('yes') : lang.t('no')),
                InfoRow(lang.t('desabled_access'),
                    d.isAccessible ? lang.t('yes') : lang.t('no')),
              ]),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () {
                    if (d.accommodationId != null) {
                      Navigator.pushNamed(
                        context,
                        '/acc/${d.accommodationId}/${d.currency}/${d.price}',
                      );
                    }
                  },
                  icon: const Icon(Icons.home_outlined),
                  label: Text(lang.t('view_all_details')),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Colonnage responsive (évite les overflow)
class _ResponsiveColumns extends StatelessWidget {
  final List<Widget> children;
  final int columns;
  const _ResponsiveColumns({required this.children, required this.columns});

  @override
  Widget build(BuildContext context) {
    if (columns == 1) {
      return Column(
        children: children
            .map((w) =>
                Padding(padding: const EdgeInsets.only(bottom: 12), child: w))
            .toList(),
      );
    }
    final spacing = 16.0;
    final totalSpacing = spacing * (columns - 1);
    final width = (MediaQuery.of(context).size.width - totalSpacing - 32) /
        columns; // -32 padding card

    return Wrap(
      spacing: spacing,
      runSpacing: 12,
      children: children.map((w) => SizedBox(width: width, child: w)).toList(),
    );
  }
}

/// Petit wrapper visuel pour une “sous-carte” de la section
class _InfoSection extends StatelessWidget {
  final String title;
  final List<Widget>? children;
  final List<InfoRow> rows;
  const _InfoSection({required this.title, this.children, required this.rows});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InfoHeader(title),
        ...rows,
        if (children != null) ...children!,
      ],
    );
  }
}

/// == MISE À JOUR d’InfoRow ==
///  - largeur fixe pour le label (évite “lignes verticales”)
///  - la valeur wrap dans l’espace restant
class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final bool boldValue;
  const InfoRow(this.label, this.value, {this.boldValue = false});

  @override
  Widget build(BuildContext context) {
    final labelStyle = TextStyle(color: Colors.grey[700], height: 1.2);
    final valueStyle = TextStyle(
      fontWeight: boldValue ? FontWeight.w600 : FontWeight.w400,
      height: 1.2,
    );

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140, // <- clé : colonne label stable
            child: Text(label, style: labelStyle, softWrap: true),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              value,
              style: valueStyle,
              softWrap: true,
              overflow: TextOverflow.visible,
            ),
          ),
        ],
      ),
    );
  }
}

/// Titre de sous-section (inchangé si tu as déjà cette classe)
class InfoHeader extends StatelessWidget {
  final String text;
  const InfoHeader(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 6),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
      ),
    );
  }
}

Widget _twoCols({required Widget left, required Widget right}) {
  return LayoutBuilder(
    builder: (context, c) {
      final narrow = c.maxWidth < 360; // ajuste 360–400 selon ton design
      if (narrow) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            left,
            const SizedBox(height: 12),
            right,
          ],
        );
      }
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: left),
          const SizedBox(width: 16),
          Expanded(child: right),
        ],
      );
    },
  );
}
