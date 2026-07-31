import 'dart:convert';

import 'package:chicaparts_partner/api/traveler/api_user_traveler.dart';
import 'package:chicaparts_partner/models/traveler/model_invoice_traveler.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/exchange_rate_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/services/api.dart';
import 'package:chicaparts_partner/utils/currency_converter.dart';
import 'package:chicaparts_partner/widgets/traveler/book/payment_processing_page.dart';
import 'package:chicaparts_partner/widgets/traveler/common/login_required_state.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class InvoicesPage extends StatefulWidget {
  const InvoicesPage({super.key});

  @override
  State<InvoicesPage> createState() => _InvoicesPageState();
}

class _InvoicesPageState extends State<InvoicesPage> {
  final ApiUserTraveler _apiUser = ApiUserTraveler();
  late Future<_InvoicePageData> _futureData;
  String _status = 'all';

  @override
  void initState() {
    super.initState();
    _futureData = _loadData();
  }

  Future<_InvoicePageData> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson == null || userJson.isEmpty) {
      throw Exception('LOGIN_REQUIRED');
    }

    final currentUser = User.fromJson(jsonDecode(userJson));
    final results = await Future.wait([
      _apiUser.getUserInvoices(currentUser, status: _status),
      _apiUser.getUserInvoiceStats(currentUser),
    ]);

    return _InvoicePageData(
      invoices: results[0] as List<TravelerInvoice>,
      stats: results[1] as TravelerInvoiceStats,
      user: currentUser,
    );
  }

  String _fallbackText(
    LanguageProvider lang, {
    required String fr,
    required String en,
  }) {
    return lang.currentLang == 'fr' ? fr : en;
  }

  String _formatAmount(num value, String currency) {
    return CurrencyConverter.format(
      value.toDouble(),
      from: currency,
      to: context.read<CurrencyProvider>().currency,
      rates: context.read<ExchangeRateProvider>().rates,
    );
  }

  Future<void> _openExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _invoiceUrl(TravelerInvoice invoice, String action) {
    final baseUrl = ApiUrl().getChicapartsUrl();
    final locale = Uri.encodeComponent(
      context.read<LanguageProvider>().currentLang,
    );
    return '${baseUrl}invoices/invoice/${invoice.id}/$action?locale=$locale';
  }

  void _reload() {
    setState(() {
      _futureData = _loadData();
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(_fallbackText(lang, fr: 'Factures', en: 'Invoices')),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        foregroundColor: const Color(0xFF244B6B),
      ),
      body: FutureBuilder<_InvoicePageData>(
        future: _futureData,
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
              retryLabel: lang.t('retry'),
              onRetry: _reload,
            );
          }

          final data = snapshot.data!;

          return RefreshIndicator(
            onRefresh: () async {
              _reload();
              await _futureData;
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _InvoiceStatsPanel(
                  stats: data.stats,
                  totalLabel: _formatAmount(
                    data.stats.totalAmount,
                    data.stats.currency,
                  ),
                  paidLabel: _formatAmount(
                    data.stats.totalPaid,
                    data.stats.currency,
                  ),
                  unpaidLabel: _formatAmount(
                    data.stats.totalUnpaid,
                    data.stats.currency,
                  ),
                  lang: lang,
                ),
                const SizedBox(height: 14),
                _StatusFilters(
                  selected: _status,
                  lang: lang,
                  onChanged: (value) {
                    setState(() {
                      _status = value;
                      _futureData = _loadData();
                    });
                  },
                ),
                const SizedBox(height: 14),
                if (data.invoices.isEmpty)
                  _StateMessage(
                    title: _fallbackText(lang, fr: 'Factures', en: 'Invoices'),
                    message: _fallbackText(
                      lang,
                      fr: 'Aucune facture trouvee.',
                      en: 'No invoice found.',
                    ),
                  )
                else
                  ...data.invoices.map(
                    (invoice) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _InvoiceCard(
                        invoice: invoice,
                        amountLabel: _formatAmount(
                          invoice.totalAmount,
                          invoice.currency,
                        ),
                        paidLabel: _formatAmount(
                          invoice.paidAmount,
                          invoice.currency,
                        ),
                        remainingLabel: _formatAmount(
                          invoice.remainingAmount,
                          invoice.currency,
                        ),
                        lang: lang,
                        onPreview: () => _openExternalUrl(
                          _invoiceUrl(invoice, 'stream'),
                        ),
                        onDownload: () => _openExternalUrl(
                          _invoiceUrl(invoice, 'download'),
                        ),
                        onPay: () => _payInvoice(invoice, data.user, lang),
                        onDetails: () => _showInvoiceDetails(
                          invoice,
                          lang,
                          totalLabel: _formatAmount(
                            invoice.totalAmount,
                            invoice.currency,
                          ),
                          paidLabel: _formatAmount(
                            invoice.paidAmount,
                            invoice.currency,
                          ),
                          remainingLabel: _formatAmount(
                            invoice.remainingAmount,
                            invoice.currency,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showInvoiceDetails(
    TravelerInvoice invoice,
    LanguageProvider lang, {
    required String totalLabel,
    required String paidLabel,
    required String remainingLabel,
  }) {
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
                          color: const Color(0xFF244B6B).withOpacity(0.10),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: Color(0xFF244B6B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              invoice.invoiceNumber.isNotEmpty
                                  ? invoice.invoiceNumber
                                  : invoice.ref,
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1D3550),
                              ),
                            ),
                            Text(
                              _invoiceStatusLabel(invoice, lang),
                              style: TextStyle(
                                color: _invoiceStatusColor(invoice),
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _InfoLine(lang.t('total_price'), totalLabel),
                  _InfoLine(lang.t('amount_paid'), paidLabel),
                  _InfoLine(
                    _fallbackText(lang, fr: 'Reste a payer', en: 'Remaining'),
                    remainingLabel,
                  ),
                  if (invoice.dueDateFormatted.isNotEmpty)
                    _InfoLine(
                      _fallbackText(lang, fr: 'Echeance', en: 'Due date'),
                      invoice.dueDateFormatted,
                    ),
                  if (invoice.createdAtFormatted.isNotEmpty)
                    _InfoLine(lang.t('created_at'), invoice.createdAtFormatted),
                  if (invoice.paidAtFormatted.isNotEmpty)
                    _InfoLine(lang.t('paid'), invoice.paidAtFormatted),
                  if (invoice.accommodationName.isNotEmpty)
                    _InfoLine(lang.t('accommodation'), invoice.accommodationName),
                  if (invoice.bookingRef.isNotEmpty)
                    _InfoLine(lang.t('booking'), invoice.bookingRef),
                  if (invoice.description.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Text(
                      invoice.description,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        height: 1.4,
                      ),
                    ),
                  ],
                  if (invoice.paymentAttempts.isNotEmpty) ...[
                    const SizedBox(height: 20),
                    Text(
                      _fallbackText(
                        lang,
                        fr: 'Historique des paiements',
                        en: 'Payment history',
                      ),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 8),
                    ...invoice.paymentAttempts.map(
                      (attempt) => _PaymentAttemptTile(
                        attempt: attempt,
                        amountLabel: _formatAmount(
                          attempt.amount,
                          attempt.currency,
                        ),
                        lang: lang,
                      ),
                    ),
                  ],
                  const SizedBox(height: 12),
                  if (_invoiceCanOpenPdf(invoice))
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _openExternalUrl(
                              _invoiceUrl(invoice, 'stream'),
                            ),
                            icon: const Icon(Icons.visibility_outlined),
                            label: Text(lang.t('preview_invoice')),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _openExternalUrl(
                              _invoiceUrl(invoice, 'download'),
                            ),
                            icon: const Icon(Icons.download_rounded),
                            label: Text(lang.t('download_invoice')),
                          ),
                        ),
                      ],
                    ),
                  if (_invoiceCanBePaid(invoice)) ...[
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          Navigator.pop(context);
                          _payInvoice(invoice, null, lang);
                        },
                        icon: const Icon(Icons.payment_outlined),
                        label: Text(
                          _fallbackText(
                            lang,
                            fr: invoice.paymentAttempts.isEmpty
                                ? 'Payer la facture'
                                : 'Reprendre le paiement',
                            en: invoice.paymentAttempts.isEmpty
                                ? 'Pay invoice'
                                : 'Resume payment',
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _payInvoice(
    TravelerInvoice invoice,
    User? user,
    LanguageProvider lang,
  ) async {
    if (invoice.bookingId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _fallbackText(
              lang,
              fr: 'Cette facture ne contient pas de reservation liee pour lancer le paiement.',
              en: 'This invoice has no linked booking to start payment.',
            ),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    User? currentUser = user;
    if (currentUser == null) {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('user');
      if (userJson != null && userJson.isNotEmpty) {
        currentUser = User.fromJson(jsonDecode(userJson));
      }
    }

    if (!mounted || currentUser == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PaymentProcessingPage(
          amount: invoice.remainingAmount.toDouble(),
          currency: invoice.currency,
          customerEmail: currentUser!.email,
          customerPhoneNumber: _extractUserPhoneNumber(currentUser),
          bookingId: invoice.bookingId,
          checkInFormatted: invoice.dueDateFormatted.isNotEmpty
              ? invoice.dueDateFormatted
              : invoice.createdAtFormatted,
          resumeMode: true,
          returnToInvoices: true,
        ),
      ),
    );

    if (mounted) _reload();
  }

  String? _extractUserPhoneNumber(User? user) {
    final thirdParty = user?.thirdParty;
    if (thirdParty is Map) {
      final candidates = [
        thirdParty['mobile_phone_number'],
        thirdParty['phone'],
        thirdParty['mobile'],
      ];

      for (final value in candidates) {
        final phone = value?.toString().trim();
        if (phone != null && phone.isNotEmpty) return phone;
      }
    }

    return null;
  }
}

class _InvoicePageData {
  final List<TravelerInvoice> invoices;
  final TravelerInvoiceStats stats;
  final User user;

  const _InvoicePageData({
    required this.invoices,
    required this.stats,
    required this.user,
  });
}

class _InvoiceStatsPanel extends StatelessWidget {
  final TravelerInvoiceStats stats;
  final String totalLabel;
  final String paidLabel;
  final String unpaidLabel;
  final LanguageProvider lang;

  const _InvoiceStatsPanel({
    required this.stats,
    required this.totalLabel,
    required this.paidLabel,
    required this.unpaidLabel,
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
            _fallbackText(fr: 'Synthese des factures', en: 'Invoice summary'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: _fallbackText(fr: 'Total', en: 'Total'),
                  value: totalLabel,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: lang.t('paid'),
                  value: paidLabel,
                  color: const Color(0xFFFBD107),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  label: lang.t('unpaid'),
                  value: unpaidLabel,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _StatTile(
                  label: _fallbackText(fr: 'En retard', en: 'Overdue'),
                  value: '${stats.overdueCount}',
                  color: stats.overdueCount > 0
                      ? const Color(0xFFFFB4A8)
                      : Colors.white,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _StatTile({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 5),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusFilters extends StatelessWidget {
  final String selected;
  final LanguageProvider lang;
  final ValueChanged<String> onChanged;

  const _StatusFilters({
    required this.selected,
    required this.lang,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final items = <String, String>{
      'all': lang.currentLang == 'fr' ? 'Toutes' : 'All',
      'paid': lang.t('paid'),
      'unpaid': lang.t('unpaid'),
      'partially_paid': lang.t('partial'),
    };

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: items.entries.map((entry) {
          final isSelected = selected == entry.key;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: isSelected,
              label: Text(entry.value),
              onSelected: (_) => onChanged(entry.key),
              selectedColor: const Color(0xFF244B6B),
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : const Color(0xFF244B6B),
                fontWeight: FontWeight.w700,
              ),
              backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
              side: const BorderSide(color: Color(0xFFD8E1EA)),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final TravelerInvoice invoice;
  final String amountLabel;
  final String paidLabel;
  final String remainingLabel;
  final LanguageProvider lang;
  final VoidCallback onPreview;
  final VoidCallback onDownload;
  final VoidCallback onPay;
  final VoidCallback onDetails;

  const _InvoiceCard({
    required this.invoice,
    required this.amountLabel,
    required this.paidLabel,
    required this.remainingLabel,
    required this.lang,
    required this.onPreview,
    required this.onDownload,
    required this.onPay,
    required this.onDetails,
  });

  String _fallbackText({required String fr, required String en}) {
    return lang.currentLang == 'fr' ? fr : en;
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final color = _invoiceStatusColor(invoice);
    final title = invoice.label.isNotEmpty
        ? invoice.label
        : (invoice.invoiceNumber.isNotEmpty ? invoice.invoiceNumber : invoice.ref);
    final percent = (invoice.paymentPercentage / 100).clamp(0, 1).toDouble();
    final canPay = _invoiceCanBePaid(invoice);
    final canOpenPdf = _invoiceCanOpenPdf(invoice);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(Icons.description_outlined, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      invoice.createdAtFormatted.isNotEmpty
                          ? invoice.createdAtFormatted
                          : invoice.createdAt,
                      style: TextStyle(fontSize: 12.5, color: Colors.grey[600]),
                    ),
                  ],
                ),
              ),
              _StatusBadge(
                label: _invoiceStatusLabel(invoice, lang),
                color: color,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            amountLabel,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: percent,
              backgroundColor: const Color(0xFFE8EEF5),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _MiniLine(label: lang.t('paid'), value: paidLabel),
              ),
              Expanded(
                child: _MiniLine(
                  label: _fallbackText(fr: 'Restant', en: 'Remaining'),
                  value: remainingLabel,
                  alignEnd: true,
                ),
              ),
            ],
          ),
          if (invoice.isOverdue) ...[
            const SizedBox(height: 10),
            _Notice(
              text: _fallbackText(
                fr: 'Cette facture est arrivee a echeance.',
                en: 'This invoice is overdue.',
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              _CircleAction(
                icon: Icons.visibility_outlined,
                tooltip: lang.t('view_all_details'),
                onTap: onDetails,
              ),
              if (canOpenPdf) ...[
                const SizedBox(width: 8),
                _CircleAction(
                  icon: Icons.picture_as_pdf_outlined,
                  tooltip: lang.t('preview_invoice'),
                  onTap: onPreview,
                ),
                const SizedBox(width: 8),
                _CircleAction(
                  icon: Icons.download_rounded,
                  tooltip: lang.t('download_invoice'),
                  onTap: onDownload,
                ),
              ],
              if (canPay) ...[
                const Spacer(),
                _PayInvoiceAction(
                  label: _fallbackText(
                    fr: invoice.paymentAttempts.isEmpty
                        ? 'Payer'
                        : 'Reprendre',
                    en: invoice.paymentAttempts.isEmpty ? 'Pay' : 'Resume',
                  ),
                  onTap: onPay,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

bool _invoiceCanOpenPdf(TravelerInvoice invoice) {
  return invoice.status.trim().toLowerCase() == 'paid';
}

bool _invoiceCanBePaid(TravelerInvoice invoice) {
  final status = invoice.status.trim().toLowerCase();
  return invoice.remainingAmount > 0 &&
      (invoice.isPayable ||
          status == 'unpaid' ||
          status == 'partially_paid' ||
          status == 'partial');
}

String _invoiceStatusLabel(TravelerInvoice invoice, LanguageProvider lang) {
  final status = invoice.status.trim().toLowerCase();
  if (status == 'paid') return lang.t('paid');
  if (status == 'unpaid') return lang.t('unpaid');
  if (status == 'partially_paid' || status == 'partial') {
    return lang.t('partial');
  }
  if (invoice.statusLabel.isNotEmpty) return invoice.statusLabel;
  return invoice.status;
}

Color _invoiceStatusColor(TravelerInvoice invoice) {
  final status = invoice.status.trim().toLowerCase();
  if (invoice.isOverdue) return const Color(0xFFD32F2F);
  if (status == 'paid') return const Color(0xFF1E8E5A);
  if (status == 'partially_paid') return const Color(0xFFF79009);
  return const Color(0xFFD32F2F);
}

class _PayInvoiceAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _PayInvoiceAction({
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: FilledButton.icon(
        onPressed: onTap,
        icon: const Icon(Icons.payment_outlined, size: 18),
        label: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF244B6B),
          foregroundColor: Colors.white,
          minimumSize: const Size(92, 42),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
    );
  }
}

class _PaymentAttemptTile extends StatelessWidget {
  final InvoicePaymentAttempt attempt;
  final String amountLabel;
  final LanguageProvider lang;

  const _PaymentAttemptTile({
    required this.attempt,
    required this.amountLabel,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final normalizedStatus = attempt.status.trim().toUpperCase();
    final isFailed = normalizedStatus.contains('FAIL') ||
        normalizedStatus.contains('CANCEL') ||
        normalizedStatus.contains('ERROR');
    final color = attempt.success
        ? const Color(0xFF1E8E5A)
        : isFailed
            ? const Color(0xFFD32F2F)
            : const Color(0xFFF79009);
    final statusLabel = attempt.success
        ? lang.t('paid')
        : isFailed
            ? (lang.currentLang == 'fr' ? 'Échoué' : 'Failed')
            : (lang.currentLang == 'fr' ? 'En attente' : 'Pending');
    final method = attempt.paymentMethod.isNotEmpty
        ? attempt.paymentMethod
        : attempt.service.toUpperCase();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              attempt.success
                  ? Icons.check_rounded
                  : isFailed
                      ? Icons.close_rounded
                      : Icons.schedule_rounded,
              color: color,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  method,
                  style: TextStyle(
                    color: colors.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (attempt.paymentDate.isNotEmpty)
                  Text(
                    attempt.paymentDate,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amountLabel,
                style: TextStyle(
                  color: colors.onSurface,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                statusLabel,
                style: TextStyle(
                  color: color,
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MiniLine extends StatelessWidget {
  final String label;
  final String value;
  final bool alignEnd;

  const _MiniLine({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment:
          alignEnd ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(color: colors.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 3),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.onSurface,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _Notice extends StatelessWidget {
  final String text;

  const _Notice({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
      decoration: BoxDecoration(
        color: const Color(0xFFD32F2F).withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Color(0xFFD32F2F),
          fontSize: 12.5,
          fontWeight: FontWeight.w700,
        ),
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
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
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

  const _CircleAction({
    required this.icon,
    required this.tooltip,
    required this.onTap,
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
            color: const Color(0xFF244B6B).withOpacity(0.07),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: const Color(0xFF244B6B), size: 21),
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

