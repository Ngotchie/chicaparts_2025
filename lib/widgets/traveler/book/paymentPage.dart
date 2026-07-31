import 'package:chicaparts_partner/api/traveler/api_booking_traveler.dart';
import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/exchange_rate_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/utils/currency_converter.dart';
import 'package:chicaparts_partner/widgets/traveler/book/billingInfos.dart';
import 'package:chicaparts_partner/widgets/traveler/book/book_app_bar.dart';
import 'package:chicaparts_partner/widgets/traveler/book/booking_step_indicator.dart';
import 'package:chicaparts_partner/widgets/traveler/book/payment_processing_page.dart';
import 'package:chicaparts_partner/widgets/traveler/book/selectBookingDetails.dart';
import 'package:chicaparts_partner/widgets/traveler/my_account/bookingDetails.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum _BookingPaymentChoice { online, cash, other }

class PaymentPage extends StatefulWidget {
  final BookingDetails bookingDetails;
  final BillingInfo billingInfo;

  const PaymentPage({
    super.key,
    required this.bookingDetails,
    required this.billingInfo,
  });

  @override
  _PaymentPageState createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  TimeOfDay? _arrivalTime;
  final ApiBooking apiBooking = ApiBooking();
  bool isLoading = false;
  bool _showFullLoader = false;
  bool _rulesAccepted = false;

  @override
  Widget build(BuildContext context) {
    final exchangeRates = context.watch<ExchangeRateProvider>().rates;
    final selectedCurrency = context.watch<CurrencyProvider>().currency;
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final colors = Theme.of(context).colorScheme;
    final total = CurrencyConverter.format(
      widget.bookingDetails.finalPrice,
      from: widget.bookingDetails.currency,
      to: selectedCurrency,
      rates: exchangeRates,
    );

    return Stack(
      children: [
        Scaffold(
          backgroundColor: colors.surface,
          appBar: buildBookAppBar(lang.t('payment')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 112),
              children: [
                const BookingStepIndicator(currentStep: 3),
                const SizedBox(height: 14),
                _infoCard(
                  title: lang.t('bookong_details'),
                  icon: Icons.event_available_outlined,
                  children: [
                    _buildDetailRow(
                      lang.t('check_in'),
                      _formatDate(widget.bookingDetails.checkIn),
                      icon: Icons.login_outlined,
                    ),
                    _buildDetailRow(
                      lang.t('check_out'),
                      _formatDate(widget.bookingDetails.checkOut),
                      icon: Icons.logout_outlined,
                    ),
                    _buildDetailRow(
                      lang.t('travelers'),
                      "${widget.bookingDetails.adults} ${lang.t('adults')}, ${widget.bookingDetails.children} ${lang.t('children')}",
                      icon: Icons.groups_2_outlined,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _buildArrivalTimeSelector(lang),
                const SizedBox(height: 14),
                _buildHouseRulesAcceptance(lang),
                const SizedBox(height: 14),
                _infoCard(
                  title: lang.t('payment_sommary'),
                  icon: Icons.receipt_long_outlined,
                  children: [
                    _buildDetailRow(
                      lang.t('base_price'),
                      CurrencyConverter.format(
                        widget.bookingDetails.totalPrice,
                        from: widget.bookingDetails.currency,
                        to: selectedCurrency,
                        rates: exchangeRates,
                      ),
                    ),
                    _buildDetailRow(
                      lang.t('cleaning_fees'),
                      CurrencyConverter.format(
                        widget.bookingDetails.cleaningFees,
                        from: widget.bookingDetails.currency,
                        to: selectedCurrency,
                        rates: exchangeRates,
                      ),
                    ),
                    _buildDetailRow(
                      lang.t('city_taxe'),
                      CurrencyConverter.format(
                        widget.bookingDetails.cityTaxe,
                        from: widget.bookingDetails.currency,
                        to: selectedCurrency,
                        rates: exchangeRates,
                      ),
                    ),
                    _buildDetailRow(
                      lang.t('chicaparts_fees'),
                      CurrencyConverter.format(
                        widget.bookingDetails.chicapartsFees,
                        from: widget.bookingDetails.currency,
                        to: selectedCurrency,
                        rates: exchangeRates,
                      ),
                    ),
                    const Divider(height: 24),
                    _buildDetailRow(
                      lang.t('total_price'),
                      total,
                      isTotal: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
          bottomNavigationBar: _buildBottomBar(lang, total),
        ),
        if (_showFullLoader)
          Container(
            color: colors.scrim.withOpacity(0.32),
            child: const Center(child: CircularProgressIndicator()),
          ),
      ],
    );
  }

  Future<void> _confirmBooking(LanguageProvider lang) async {
    if (!_rulesAccepted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(lang.t('accept_house_rules_required')),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() {
      isLoading = true;
      _showFullLoader = true;
    });

    try {
      final bookingResult = await apiBooking.submitReservation(
        booking: widget.bookingDetails,
        billing: widget.billingInfo,
        arrivalTime: _arrivalTime?.format(context),
      );

      final bookingId = _extractBookingId(bookingResult);

      if (!mounted) return;

      if (bookingId != null) {
        final paymentChoice = await _showPaymentChoiceSheet(lang);
        if (!mounted || paymentChoice == null) return;

        await _savePaymentChoice(bookingId, paymentChoice);
        if (!mounted) return;

        if (paymentChoice != _BookingPaymentChoice.online) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            '/reservations/$bookingId',
            (route) => false,
          );
          return;
        }

        final paid = await Navigator.push<bool>(
          context,
          MaterialPageRoute(
            builder: (_) => PaymentProcessingPage(
              bookingId: bookingId,
              amount: widget.bookingDetails.finalPrice,
              currency: widget.bookingDetails.currency,
              customerEmail: widget.billingInfo.email,
              customerPhoneNumber: widget.billingInfo.phone,
              checkInFormatted: _formatDate(widget.bookingDetails.checkIn),
            ),
          ),
        );

        if (!mounted) return;

        if (paid == true) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(
              builder: (_) => BookingDetailsPage(bookingId: '$bookingId'),
            ),
            (route) => route.isFirst,
          );
        }
      } else {
        _showError(context, lang.t('booking_save_error'));
      }
    } catch (e) {
      debugPrint('Booking confirmation error: $e');
      if (mounted) {
        _showError(context, lang.t('booking_save_error_with_details'));
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
          _showFullLoader = false;
        });
      }
    }
  }

  Widget _buildHouseRulesAcceptance(LanguageProvider lang) {
    final colors = Theme.of(context).colorScheme;
    final rulesSummary = _houseRulesSummary(lang);

    return Container(
      decoration: BoxDecoration(
        color: _rulesAccepted
            ? colors.primaryContainer.withOpacity(0.32)
            : colors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: _rulesAccepted ? colors.primary : colors.outlineVariant,
        ),
      ),
      child: CheckboxListTile(
        value: _rulesAccepted,
        onChanged: (value) =>
            setState(() => _rulesAccepted = value ?? false),
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        title: Text(
          lang.t('accept_house_rules'),
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 5),
          child: InkWell(
            onTap: () => _showHouseRules(lang, rulesSummary),
            child: Text(
              lang.t('read_house_rules'),
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w600,
                decoration: TextDecoration.underline,
                decorationColor: colors.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  String _houseRulesSummary(LanguageProvider lang) {
    final lines = <String>[];
    final text = widget.bookingDetails.houseRulesText.trim();
    if (text.isNotEmpty) lines.add(text);

    final rules = widget.bookingDetails.houseRules;
    final arrival = rules['arrival_time'];
    final departure = rules['departure_time'];
    if (arrival is List && arrival.isNotEmpty) {
      lines.add('${lang.t('check-in')}: ${arrival.join(' – ')}');
    }
    if (departure is List && departure.isNotEmpty) {
      lines.add('${lang.t('check-out')}: ${departure.join(' – ')}');
    }
    if (rules.containsKey('pets_allowed')) {
      lines.add(
        rules['pets_allowed'] == true
            ? lang.t('pets_allowed')
            : lang.t('pets_not_allowed'),
      );
    }

    return lines.isEmpty ? lang.t('house_rules_default_text') : lines.join('\n\n');
  }

  Future<void> _showHouseRules(
    LanguageProvider lang,
    String rulesSummary,
  ) {
    final colors = Theme.of(context).colorScheme;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 5,
                    decoration: BoxDecoration(
                      color: colors.outlineVariant,
                      borderRadius: BorderRadius.circular(999),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Icon(Icons.gavel_rounded, color: colors.primary),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Text(
                        lang.t('house_rules'),
                        style: Theme.of(context)
                            .textTheme
                            .titleLarge
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.sizeOf(context).height * 0.48,
                  ),
                  child: SingleChildScrollView(
                    child: Text(
                      rulesSummary,
                      style: TextStyle(
                        color: colors.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() => _rulesAccepted = true);
                      Navigator.pop(sheetContext);
                    },
                    child: Text(lang.t('accept_and_close')),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _savePaymentChoice(
    int bookingId,
    _BookingPaymentChoice choice,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      'booking_payment_preference_$bookingId',
      choice.name,
    );
  }

  Future<_BookingPaymentChoice?> _showPaymentChoiceSheet(
    LanguageProvider lang,
  ) {
    _BookingPaymentChoice selected = _BookingPaymentChoice.online;
    final colors = Theme.of(context).colorScheme;

    return showModalBottomSheet<_BookingPaymentChoice>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 20),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 5,
                      decoration: BoxDecoration(
                        color: colors.outlineVariant,
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: colors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.task_alt_rounded,
                        color: colors.onPrimaryContainer,
                        size: 31,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      lang.t('booking_saved_title'),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 7),
                    Text(
                      lang.t('booking_saved_payment_text'),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: colors.onSurfaceVariant,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 18),
                    _PaymentChoiceTile(
                      icon: Icons.credit_card_rounded,
                      title: lang.t('pay_online_now'),
                      subtitle: lang.t('pay_online_now_text'),
                      selected: selected == _BookingPaymentChoice.online,
                      onTap: () => setSheetState(
                        () => selected = _BookingPaymentChoice.online,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PaymentChoiceTile(
                      icon: Icons.payments_outlined,
                      title: lang.t('pay_cash'),
                      subtitle: lang.t('pay_cash_text'),
                      selected: selected == _BookingPaymentChoice.cash,
                      onTap: () => setSheetState(
                        () => selected = _BookingPaymentChoice.cash,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _PaymentChoiceTile(
                      icon: Icons.more_horiz_rounded,
                      title: lang.t('other_payment_method'),
                      subtitle: lang.t('other_payment_method_text'),
                      selected: selected == _BookingPaymentChoice.other,
                      onTap: () => setSheetState(
                        () => selected = _BookingPaymentChoice.other,
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: () => Navigator.pop(sheetContext, selected),
                        icon: const Icon(Icons.check_rounded),
                        label: Text(lang.t('confirm_choice')),
                        style: FilledButton.styleFrom(
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showError(BuildContext context, String msg) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(lang.t('booking_error_title')),
        content: Text(msg),
        actions: [
          TextButton(
            child: Text(lang.t('close')),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
    );
  }

  int? _extractBookingId(dynamic bookingResult) {
    if (bookingResult is! Map) return null;

    final directId = bookingResult['id'];
    if (directId != null) return int.tryParse(directId.toString());

    final data = bookingResult['data'];
    if (data is Map && data['id'] != null) {
      return int.tryParse(data['id'].toString());
    }

    final booking = bookingResult['booking'];
    if (booking is Map && booking['id'] != null) {
      return int.tryParse(booking['id'].toString());
    }

    return null;
  }

  Widget _buildBottomBar(LanguageProvider lang, String total) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          border: Border(
            top: BorderSide(color: colors.outlineVariant),
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.t('total_price'),
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    total,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            SizedBox(
              height: 48,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: colors.primary,
                  foregroundColor: colors.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                onPressed: isLoading || !_rulesAccepted
                    ? null
                    : () => _confirmBooking(lang),
                icon: isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Icon(Icons.lock_outline, size: 18),
                label: Text(
                  lang.t('confirm_pay'),
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool isTotal = false,
    IconData? icon,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: colors.onSurfaceVariant),
            const SizedBox(width: 8),
          ],
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                color: isTotal ? colors.onSurface : colors.onSurfaceVariant,
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w500,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isTotal ? const Color(0xFF21A35B) : colors.onSurface,
                fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
                fontSize: isTotal ? 17 : 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildArrivalTimeSelector(LanguageProvider lang) {
    final colors = Theme.of(context).colorScheme;
    final hasArrivalTime = _arrivalTime != null;
    final value = hasArrivalTime
        ? _formatTime(_arrivalTime!)
        : lang.t('arrival_time_not_selected');

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () async {
        final picked = await showTimePicker(
          context: context,
          initialTime: _arrivalTime ?? const TimeOfDay(hour: 14, minute: 0),
        );
        if (picked != null) {
          setState(() => _arrivalTime = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasArrivalTime
              ? const Color(0xFF21A35B).withOpacity(0.12)
              : colors.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: hasArrivalTime
                ? const Color(0xFF21A35B)
                : colors.outlineVariant,
            width: hasArrivalTime ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: hasArrivalTime
                    ? const Color(0xFF21A35B)
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                hasArrivalTime ? Icons.check : Icons.access_time,
                color: hasArrivalTime ? Colors.white : colors.primary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lang.t('arrival_time'),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    style: TextStyle(
                      color: hasArrivalTime
                          ? const Color(0xFF167A3B)
                          : colors.onSurfaceVariant,
                      fontWeight:
                          hasArrivalTime ? FontWeight.w800 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(Icons.edit_calendar_outlined, color: colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) => DateFormat("dd MMM yyyy").format(date);

  String _formatTime(TimeOfDay time) => time.format(context);
}

class _PaymentChoiceTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _PaymentChoiceTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected
              ? colors.primaryContainer.withOpacity(0.55)
              : colors.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? colors.primary : colors.outlineVariant,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: selected
                    ? colors.primary
                    : colors.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: selected ? colors.onPrimary : colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 12,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              selected
                  ? Icons.radio_button_checked
                  : Icons.radio_button_off,
              color: selected ? colors.primary : colors.outline,
            ),
          ],
        ),
      ),
    );
  }
}
