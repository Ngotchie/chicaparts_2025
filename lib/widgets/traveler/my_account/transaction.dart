import 'dart:convert';

import 'package:chicaparts_partner/api/traveler/api_booking_traveler.dart';
import 'package:chicaparts_partner/api/traveler/api_user_traveler.dart';
import 'package:chicaparts_partner/models/model_booking.dart';
import 'package:chicaparts_partner/models/traveler/model_transaction_traveler.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/exchange_rate_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/services/api.dart';
import 'package:chicaparts_partner/utils/currency_converter.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/account_class.dart';
import 'package:chicaparts_partner/widgets/traveler/common/login_required_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class TransactionPage extends StatefulWidget {
  final String? paymentType;
  final String? status;
  final String titleKey;
  final String fallbackTitleFr;
  final String fallbackTitleEn;

  const TransactionPage({
    super.key,
    this.paymentType,
    this.status,
    this.titleKey = 'my_transactions',
    this.fallbackTitleFr = 'Transactions',
    this.fallbackTitleEn = 'Transactions',
  });

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final ApiUserTraveler _apiUser = ApiUserTraveler();
  final ApiBooking _apiBooking = ApiBooking();
  late Future<List<TravelerTransaction>> _futureTransactions;
  late Future<List<Booking>> _futureTipCandidates;

  bool get _isTipsPage => widget.paymentType == 'tip';

  @override
  void initState() {
    super.initState();
    _futureTransactions = _loadTransactions();
    _futureTipCandidates = _loadTipCandidates();
  }

  Future<List<TravelerTransaction>> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson == null || userJson.isEmpty) {
      throw Exception('LOGIN_REQUIRED');
    }

    final currentUser = User.fromJson(jsonDecode(userJson));
    return _apiUser.getUserTransactions(
      currentUser,
      widget.paymentType,
      widget.status,
    );
  }

  Future<List<Booking>> _loadTipCandidates() async {
    if (!_isTipsPage) return const [];

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson == null || userJson.isEmpty) {
      throw Exception('LOGIN_REQUIRED');
    }

    final currentUser = User.fromJson(jsonDecode(userJson));
    final bookings = await _apiBooking.getUserReservations(currentUser);

    final candidates = bookings.where((booking) {
      final status = booking.validationStatus.trim().toLowerCase();
      final isConfirmed = status == 'confirmed' || status == 'accepted';
      return isConfirmed && !booking.hasTips;
    }).toList();

    candidates.sort((a, b) {
      final first = DateTime.tryParse(b.lastNight) ?? DateTime(1970);
      final second = DateTime.tryParse(a.lastNight) ?? DateTime(1970);
      return first.compareTo(second);
    });

    return candidates;
  }

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) return '-';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _formatAmount(num value, String currency) {
    return CurrencyConverter.format(
      value.toDouble(),
      from: currency,
      to: context.read<CurrencyProvider>().currency,
      rates: context.read<ExchangeRateProvider>().rates,
    );
  }

  String _pageTitle(LanguageProvider lang) {
    final translated = lang.t(widget.titleKey);
    if (translated != widget.titleKey) return translated;
    return lang.currentLang == 'fr'
        ? widget.fallbackTitleFr
        : widget.fallbackTitleEn;
  }

  void _refreshData() {
    setState(() {
      _futureTransactions = _loadTransactions();
      _futureTipCandidates = _loadTipCandidates();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final pageTitle = _pageTitle(lang);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(pageTitle),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        foregroundColor: const Color(0xFF244B6B),
      ),
      body: FutureBuilder<List<TravelerTransaction>>(
        future: _futureTransactions,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            final isLoginRequired =
                snapshot.error.toString().contains('LOGIN_REQUIRED');
            if (isLoginRequired) {
              return const LoginRequiredState();
            }
            return _StateMessage(
              title: lang.t('error'),
              message: '${lang.t('error')}: ${snapshot.error}',
              retryLabel: lang.t('see_all'),
              onRetry: () => setState(() {
                _futureTransactions = _loadTransactions();
              }),
            );
          }

          final transactions = snapshot.data ?? const [];
          if (transactions.isEmpty) {
            if (_isTipsPage) {
              return RefreshIndicator(
                onRefresh: () async {
                  _refreshData();
                  await Future.wait([
                    _futureTransactions,
                    _futureTipCandidates,
                  ]);
                },
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _TipCandidatesSection(
                      futureCandidates: _futureTipCandidates,
                      lang: lang,
                      formatDate: _formatTipDateRange,
                      onTip: (booking) => _showTipSheet(context, booking),
                    ),
                    const SizedBox(height: 14),
                    _StateMessage(
                      title: pageTitle,
                      message: lang.t('no_transactions'),
                    ),
                  ],
                ),
              );
            }

            return _StateMessage(
              title: pageTitle,
              message: lang.t('no_transactions'),
            );
          }

          final summary = _TransactionSummary.fromTransactions(transactions);

          return RefreshIndicator(
            onRefresh: () async {
              _refreshData();
              await Future.wait([
                _futureTransactions,
                _futureTipCandidates,
              ]);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (_isTipsPage) ...[
                  _TipCandidatesSection(
                    futureCandidates: _futureTipCandidates,
                    lang: lang,
                    formatDate: _formatTipDateRange,
                    onTip: (booking) => _showTipSheet(context, booking),
                  ),
                  const SizedBox(height: 14),
                ],
                _TransactionSummaryPanel(
                  title: pageTitle,
                  totalLabel: _formatAmount(
                    summary.totalAmount,
                    summary.currency,
                  ),
                  successfulCount: summary.successfulCount,
                  failedCount: summary.failedCount,
                  pendingCount: summary.pendingCount,
                  lang: lang,
                ),
                const SizedBox(height: 14),
                ...transactions.map((tx) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _TransactionCard(
                      tx: tx,
                      canOpenInvoice: _canOpenInvoice(tx),
                      canRetryPayment: _canRetryPayment(tx),
                      amountLabel: _formatAmount(tx.amount, tx.currency),
                      feesLabel: _formatAmount(tx.fees, tx.currency),
                      dateLabel: _formatDate(
                        tx.paymentDate.isNotEmpty
                            ? tx.paymentDate
                            : tx.createdAt,
                      ),
                      lang: lang,
                      onView: () => _showTransactionDetails(
                        context,
                        tx,
                        amountLabel: _formatAmount(tx.amount, tx.currency),
                        feesLabel: _formatAmount(tx.fees, tx.currency),
                        dateLabel: _formatDate(
                          tx.paymentDate.isNotEmpty
                              ? tx.paymentDate
                              : tx.createdAt,
                        ),
                        lang: lang,
                      ),
                      onInvoice: () => _showInvoiceOptions(context, tx, lang),
                      onRetryPayment: () =>
                          _showRetryPaymentHint(context, lang),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  String _formatTipDateRange(Booking booking) {
    final first = DateTime.tryParse(booking.firstNight);
    final last = DateTime.tryParse(booking.lastNight);
    if (first == null || last == null) return '-';
    final checkout = last.add(const Duration(days: 1));
    return '${DateFormat('dd MMM').format(first)} - ${DateFormat('dd MMM yyyy').format(checkout)}';
  }

  void _showTipSheet(BuildContext context, Booking booking) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (_) => TipWidget(booking: booking),
    ).then((_) => _refreshData());
  }

  bool _canOpenInvoice(TravelerTransaction tx) {
    return tx.status.trim().toLowerCase() == 'paid';
  }

  bool _canRetryPayment(TravelerTransaction tx) {
    final status = tx.status.trim().toLowerCase();
    return status == 'failed' ||
        status == 'failure' ||
        status == 'error' ||
        status == 'cancelled' ||
        status == 'canceled';
  }

  String _fallbackText(
    LanguageProvider lang, {
    required String fr,
    required String en,
  }) {
    return lang.currentLang == 'fr' ? fr : en;
  }

  void _showRetryPaymentHint(BuildContext context, LanguageProvider lang) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          _fallbackText(
            lang,
            fr: 'Paiement échoué. Ouvrez la réservation concernée pour relancer le paiement.',
            en: 'Payment failed. Open the related booking to retry the payment.',
          ),
        ),
        backgroundColor: const Color(0xFFD32F2F),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _invoiceUrl(TravelerTransaction tx, String action) {
    final baseUrl = ApiUrl().getChicapartsUrl();
    final type =
        (tx.paymentItemType == 'booking' || tx.paymentItemType == 'tip')
            ? tx.paymentItemType
            : 'transaction';
    final id = type == 'transaction' ? tx.id : _paymentItemId(tx);
    return '${baseUrl}invoices/$type/$id/$action?locale=${Uri.encodeComponent(context.read<LanguageProvider>().currentLang)}';
  }

  int _paymentItemId(TravelerTransaction tx) {
    try {
      final value = (tx as dynamic).paymentItemId;
      if (value is int && value > 0) return value;
      if (value is num && value > 0) return value.toInt();
      final parsed = int.tryParse('$value');
      if (parsed != null && parsed > 0) return parsed;
    } catch (_) {
      // Older app state/model fallback.
    }
    return tx.id;
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  void _showInvoiceOptions(
    BuildContext context,
    TravelerTransaction tx,
    LanguageProvider lang,
  ) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: const Color(0xFF244B6B).withOpacity(0.08),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.receipt_long_outlined,
                        color: Color(0xFF244B6B),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            lang.t('invoice'),
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1D3550),
                            ),
                          ),
                          Text(
                            tx.transactionRef.isNotEmpty
                                ? tx.transactionRef
                                : '#${tx.id}',
                            style: TextStyle(color: Colors.grey[600]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _InvoiceAction(
                  icon: Icons.picture_as_pdf_outlined,
                  title: lang.t('preview_invoice'),
                  subtitle: lang.t('preview_invoice_text'),
                  onTap: () {
                    Navigator.pop(context);
                    _openExternalUrl(_invoiceUrl(tx, 'stream'));
                  },
                ),
                const SizedBox(height: 10),
                _InvoiceAction(
                  icon: Icons.download_rounded,
                  title: lang.t('download_invoice'),
                  subtitle: lang.t('download_invoice_text'),
                  onTap: () {
                    Navigator.pop(context);
                    _openExternalUrl(_invoiceUrl(tx, 'download'));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showTransactionDetails(
    BuildContext context,
    TravelerTransaction tx, {
    required String amountLabel,
    required String feesLabel,
    required String dateLabel,
    required LanguageProvider lang,
  }) {
    final successColor = tx.success ? const Color(0xFF1E8E5A) : Colors.red;
    final reference = tx.transactionRef.isNotEmpty
        ? tx.transactionRef
        : tx.operatorTransactionId;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 42,
                      height: 5,
                      margin: const EdgeInsets.only(bottom: 18),
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: successColor.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          tx.success
                              ? Icons.check_circle_outline
                              : Icons.error_outline,
                          color: successColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              lang.t('transaction_details'),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1D3550),
                              ),
                            ),
                            Text(
                              tx.success ? lang.t('paid') : lang.t('unpaid'),
                              style: TextStyle(
                                color: successColor,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _InfoLine(lang.t('amount_paid'), amountLabel),
                  _InfoLine(lang.t('transaction_fees'), feesLabel),
                  _InfoLine(lang.t('transaction_date'), dateLabel),
                  if (reference.isNotEmpty)
                    _InfoLine(lang.t('reference'), reference),
                  if (tx.status.isNotEmpty)
                    _InfoLine(lang.t('status'), tx.status),
                  if (tx.operatorName.isNotEmpty)
                    _InfoLine(lang.t('operator'), tx.operatorName),
                  if (tx.payer.isNotEmpty) _InfoLine(lang.t('payer'), tx.payer),
                  if (tx.paymentItemType.isNotEmpty)
                    _InfoLine(lang.t('payment_type'), tx.paymentItemType),
                  if (tx.service.isNotEmpty)
                    _InfoLine(lang.t('service'), tx.service),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TransactionSummary {
  final num totalAmount;
  final String currency;
  final int successfulCount;
  final int failedCount;
  final int pendingCount;

  const _TransactionSummary({
    required this.totalAmount,
    required this.currency,
    required this.successfulCount,
    required this.failedCount,
    required this.pendingCount,
  });

  factory _TransactionSummary.fromTransactions(
    List<TravelerTransaction> transactions,
  ) {
    num totalAmount = 0;
    var successfulCount = 0;
    var failedCount = 0;
    var pendingCount = 0;
    var currency = 'EUR';

    for (final tx in transactions) {
      if (tx.currency.isNotEmpty) currency = tx.currency;
      if (tx.success) {
        totalAmount += tx.amount;
        successfulCount++;
        continue;
      }

      final status = tx.status.trim().toLowerCase();
      if (status == 'failed' ||
          status == 'failure' ||
          status == 'error' ||
          status == 'cancelled' ||
          status == 'canceled') {
        failedCount++;
      } else {
        pendingCount++;
      }
    }

    return _TransactionSummary(
      totalAmount: totalAmount,
      currency: currency,
      successfulCount: successfulCount,
      failedCount: failedCount,
      pendingCount: pendingCount,
    );
  }
}

class _TipCandidatesSection extends StatelessWidget {
  final Future<List<Booking>> futureCandidates;
  final LanguageProvider lang;
  final String Function(Booking booking) formatDate;
  final ValueChanged<Booking> onTip;

  const _TipCandidatesSection({
    required this.futureCandidates,
    required this.lang,
    required this.formatDate,
    required this.onTip,
  });

  String _fallbackText({required String fr, required String en}) {
    return lang.currentLang == 'fr' ? fr : en;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Booking>>(
      future: futureCandidates,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            ),
            child: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _TipInfoPanel(
            title: _fallbackText(
              fr: 'Pourboires disponibles',
              en: 'Available tips',
            ),
            message: _fallbackText(
              fr: 'Impossible de charger les reservations eligibles.',
              en: 'Unable to load eligible bookings.',
            ),
          );
        }

        final candidates = snapshot.data ?? const [];
        if (candidates.isEmpty) {
          return _TipInfoPanel(
            title: _fallbackText(
              fr: 'Aucun pourboire en attente',
              en: 'No pending tip',
            ),
            message: _fallbackText(
              fr: 'Apres un sejour confirme, vous pourrez remercier votre hote ou l equipe depuis cet espace.',
              en: 'After a confirmed stay, you can thank your host or the team from this space.',
            ),
          );
        }

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF244B6B).withOpacity(0.05),
                blurRadius: 14,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE91E63).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.volunteer_activism_outlined,
                      color: Color(0xFFE91E63),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _fallbackText(
                            fr: 'Donner un pourboire',
                            en: 'Leave a tip',
                          ),
                          style: const TextStyle(
                            color: Color(0xFF1D3550),
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          _fallbackText(
                            fr:
                                'Remerciez les personnes qui ont rendu votre sejour agreable',
                            en:
                                'Thank the people who made your stay feel special',
                          ),
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 12.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...candidates.take(4).map(
                    (booking) => Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: _TipCandidateCard(
                        booking: booking,
                        dateLabel: formatDate(booking),
                        lang: lang,
                        onTip: () => onTip(booking),
                      ),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}

class _TipInfoPanel extends StatelessWidget {
  final String title;
  final String message;

  const _TipInfoPanel({
    required this.title,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFF244B6B).withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.volunteer_activism_outlined,
              color: Color(0xFF244B6B),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF1D3550),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  message,
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 12.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TipCandidateCard extends StatelessWidget {
  final Booking booking;
  final String dateLabel;
  final LanguageProvider lang;
  final VoidCallback onTip;

  const _TipCandidateCard({
    required this.booking,
    required this.dateLabel,
    required this.lang,
    required this.onTip,
  });

  String _fallbackText({required String fr, required String en}) {
    return lang.currentLang == 'fr' ? fr : en;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.accommodation.isNotEmpty
                      ? booking.accommodation
                      : lang.t('accommodation'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1D3550),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  dateLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.grey[600], fontSize: 12.5),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          FilledButton.icon(
            onPressed: onTip,
            icon: const Icon(Icons.favorite_border, size: 18),
            label: Text(
              _fallbackText(fr: 'Pourboire', en: 'Tip'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF244B6B),
              foregroundColor: Colors.white,
              minimumSize: const Size(108, 40),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(999),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionSummaryPanel extends StatelessWidget {
  final String title;
  final String totalLabel;
  final int successfulCount;
  final int failedCount;
  final int pendingCount;
  final LanguageProvider lang;

  const _TransactionSummaryPanel({
    required this.title,
    required this.totalLabel,
    required this.successfulCount,
    required this.failedCount,
    required this.pendingCount,
    required this.lang,
  });

  String _fallbackText({required String fr, required String en}) {
    return lang.currentLang == 'fr' ? fr : en;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF244B6B),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _fallbackText(
              fr: 'Montant confirme',
              en: 'Confirmed amount',
            ),
            style: const TextStyle(color: Colors.white70, fontSize: 12.5),
          ),
          const SizedBox(height: 4),
          Text(
            totalLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Color(0xFFFBD107),
              fontSize: 24,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SummaryMiniTile(
                  label: lang.t('paid'),
                  value: '$successfulCount',
                  color: const Color(0xFFBFEAD1),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryMiniTile(
                  label: lang.t('pending'),
                  value: '$pendingCount',
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SummaryMiniTile(
                  label: _fallbackText(fr: 'Echoues', en: 'Failed'),
                  value: '$failedCount',
                  color: const Color(0xFFFFB4A8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMiniTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _SummaryMiniTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TravelerTransaction tx;
  final bool canOpenInvoice;
  final bool canRetryPayment;
  final String amountLabel;
  final String feesLabel;
  final String dateLabel;
  final LanguageProvider lang;
  final VoidCallback onView;
  final VoidCallback onInvoice;
  final VoidCallback onRetryPayment;

  const _TransactionCard({
    required this.tx,
    required this.canOpenInvoice,
    required this.canRetryPayment,
    required this.amountLabel,
    required this.feesLabel,
    required this.dateLabel,
    required this.lang,
    required this.onView,
    required this.onInvoice,
    required this.onRetryPayment,
  });

  String _fallbackText({required String fr, required String en}) {
    return lang.currentLang == 'fr' ? fr : en;
  }

  @override
  Widget build(BuildContext context) {
    final successColor = tx.success ? const Color(0xFF1E8E5A) : Colors.red;
    final statusLabel = tx.success ? lang.t('paid') : lang.t('unpaid');
    final title = tx.service.isNotEmpty
        ? tx.service
        : (tx.paymentItemType.isNotEmpty
            ? tx.paymentItemType
            : lang.t('my_transactions'));

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF244B6B).withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: successColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  tx.success ? Icons.check_circle_outline : Icons.error_outline,
                  color: successColor,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D3550),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      dateLabel,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              _StatusBadge(label: statusLabel, color: successColor),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: Text(
                  amountLabel,
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF244B6B),
                  ),
                ),
              ),
              _CircleAction(
                icon: Icons.visibility_outlined,
                tooltip: lang.t('view_all_details'),
                onTap: onView,
              ),
              if (canOpenInvoice) ...[
                const SizedBox(width: 8),
                _CircleAction(
                  icon: Icons.receipt_long_outlined,
                  tooltip: lang.t('invoice'),
                  onTap: onInvoice,
                ),
              ] else if (canRetryPayment) ...[
                const SizedBox(width: 8),
                _CircleAction(
                  icon: Icons.replay_rounded,
                  tooltip: _fallbackText(
                    fr: 'Réessayer le paiement',
                    en: 'Retry payment',
                  ),
                  onTap: onRetryPayment,
                  backgroundColor: const Color(0xFFD32F2F).withOpacity(0.08),
                  iconColor: const Color(0xFFD32F2F),
                ),
              ],
            ],
          ),
          if (canRetryPayment) ...[
            const SizedBox(height: 12),
            _RetryPaymentNotice(
              text: _fallbackText(
                fr: 'Paiement échoué. Vous pouvez réessayer depuis la réservation liée.',
                en: 'Payment failed. You can retry from the related booking.',
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w800,
          fontSize: 12,
        ),
      ),
    );
  }
}

class _CircleAction extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;
  final Color? backgroundColor;
  final Color? iconColor;

  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    this.backgroundColor,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: backgroundColor ?? const Color(0xFF244B6B).withOpacity(0.07),
            shape: BoxShape.circle,
          ),
          child:
              Icon(icon, color: iconColor ?? const Color(0xFF244B6B), size: 21),
        ),
      ),
    );
  }
}

class _RetryPaymentNotice extends StatelessWidget {
  final String text;

  const _RetryPaymentNotice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F).withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD32F2F).withOpacity(0.16)),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.info_outline,
            size: 18,
            color: Color(0xFFD32F2F),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFD32F2F),
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InvoiceAction extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _InvoiceAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF4F7FB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: const Color(0xFF244B6B)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D3550),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12.5, color: Colors.grey[650]),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF244B6B)),
          ],
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  final String label;
  final String value;

  const _InfoLine(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF1D3550),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final String title;
  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  const _StateMessage({
    required this.title,
    required this.message,
    this.retryLabel,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1D3550),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: onRetry,
                child: Text(retryLabel ?? 'Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

