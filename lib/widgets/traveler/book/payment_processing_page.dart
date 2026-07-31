import 'package:chicaparts_partner/models/traveler/payment_models.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/services/traveler_payment_flow.dart';
import 'package:chicaparts_partner/widgets/traveler/book/book_app_bar.dart';
import 'package:chicaparts_partner/widgets/traveler/book/booking_step_indicator.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class PaymentProcessingPage extends StatefulWidget {
  final double amount;
  final String currency;
  final String customerEmail;
  final String? customerPhoneNumber;
  final int bookingId;
  final String checkInFormatted;
  final bool resumeMode;
  final String paymentItemType;
  final bool returnToInvoices;

  const PaymentProcessingPage({
    super.key,
    required this.amount,
    required this.currency,
    required this.customerEmail,
    this.customerPhoneNumber,
    required this.bookingId,
    required this.checkInFormatted,
    this.resumeMode = false,
    this.paymentItemType = 'booking',
    this.returnToInvoices = false,
  });

  @override
  State<PaymentProcessingPage> createState() => _PaymentProcessingPageState();
}

class _PaymentMethodOption {
  final String method;
  final String asset;
  final bool available;
  final String? unavailableReasonKey;

  const _PaymentMethodOption({
    required this.method,
    required this.asset,
    this.available = true,
    this.unavailableReasonKey,
  });
}

class _PaymentProcessingPageState extends State<PaymentProcessingPage> {
  late String selectedMethod;
  bool _isProcessing = false;
  final TravelerPaymentFlow _paymentFlow = TravelerPaymentFlow();

  String get _currency => normalizePaymentCurrency(widget.currency);

  @override
  void initState() {
    super.initState();
    selectedMethod = _recommendedMethods().first.method;
  }

  List<_PaymentMethodOption> _recommendedMethods() {
    final mobileMoneyCurrencies = {'XAF', 'XOF', 'CDF', 'GNF'};
    final paypalCurrencies = {'EUR', 'USD'};
    final mobileAvailable = mobileMoneyCurrencies.contains(_currency);
    final paypalNative = paypalCurrencies.contains(_currency);

    final mobile = _PaymentMethodOption(
      method: 'Mobile Money',
      asset: 'assets/payment/mobile.jpeg',
      available: mobileAvailable,
      unavailableReasonKey: 'mobile_money_currency_unavailable',
    );
    const card = _PaymentMethodOption(
      method: 'Credit Card',
      asset: 'assets/payment/cartes.png',
    );
    final paypal = _PaymentMethodOption(
      method: 'PayPal',
      asset: 'assets/payment/paypal.png',
      // Le backend convertit les autres devises en EUR. L'option reste donc
      // fonctionnelle, mais elle est placée après les moyens natifs.
      available: true,
      unavailableReasonKey:
          paypalNative ? null : 'paypal_currency_conversion_notice',
    );

    return mobileAvailable ? [mobile, card, paypal] : [card, paypal, mobile];
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final methods = _recommendedMethods();

    return Scaffold(
      backgroundColor: colors.surface,
      appBar: buildBookAppBar(lang.t('select_payment_method')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
          children: [
            const BookingStepIndicator(currentStep: 4),
            const SizedBox(height: 20),
            Icon(
              Icons.account_balance_wallet_outlined,
              color: colors.primary,
              size: 48,
            ),
            const SizedBox(height: 10),
            Text(
              lang.t('select_payment_method'),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 6),
            Text(
              lang.t('online_payment_intro'),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colors.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 18),
            _AmountSummary(
              amount: widget.amount,
              currency: _currency,
              showCurrencyNotice: _currency != 'EUR',
              selectedMethod: selectedMethod,
              lang: lang,
            ),
            const SizedBox(height: 18),
            Text(
              lang.t('recommended_payment_methods'),
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            ...methods.map((option) => _paymentButton(option, lang)),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: _isProcessing ? null : _pay,
              icon: _isProcessing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.lock_outline_rounded),
              label: Text(
                _isProcessing
                    ? lang.t('payment_preparing')
                    : widget.resumeMode
                        ? lang.t('resume_payment')
                        : lang.t('pay_now'),
              ),
            ),
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: _isProcessing ? null : _openFinancialHome,
              icon: const Icon(Icons.event_note_outlined, size: 18),
              label: Text(
                widget.returnToInvoices
                    ? lang.t('back_to_invoices')
                    : lang.t('pay_later_view_bookings'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pay() async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    setState(() => _isProcessing = true);
    try {
      final result = await _paymentFlow.startOrResume(
        context,
        TravelerPaymentRequest(
          bookingId: widget.bookingId,
          amount: widget.amount,
          currency: _currency,
          customerEmail: widget.customerEmail,
          customerPhoneNumber: widget.customerPhoneNumber,
          method: selectedMethod,
          label: 'Checkin: ${widget.checkInFormatted}',
          paymentItemType: widget.paymentItemType,
        ),
        showSuccessDialog: false,
      );
      if (!mounted) return;

      if (result.isPaid) {
        await _showResultDialog(
          status: result.status,
          message: lang.t('payment_success_message'),
        );
        if (mounted) Navigator.pop(context, true);
        return;
      }

      await _showResultDialog(
        status: result.status,
        message: result.message ?? lang.t('payment_pending_message'),
      );
    } catch (error, stackTrace) {
      debugPrint('Unexpected payment UI error: $error');
      debugPrintStack(stackTrace: stackTrace);
      if (mounted) {
        await _showResultDialog(
          status: TravelerPaymentStatus.failed,
          message: lang.t('payment_processing_error'),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _showResultDialog({
    required TravelerPaymentStatus status,
    required String message,
  }) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final isPaid = status.isSuccessful;
    final isPending = status == TravelerPaymentStatus.pending ||
        status == TravelerPaymentStatus.processing ||
        status == TravelerPaymentStatus.initiated ||
        status == TravelerPaymentStatus.unknown;
    final icon = isPaid
        ? Icons.check_circle_rounded
        : isPending
            ? Icons.schedule_rounded
            : status == TravelerPaymentStatus.cancelled
                ? Icons.info_outline_rounded
                : Icons.error_outline_rounded;
    final color = isPaid
        ? Colors.green
        : isPending
            ? Colors.orange
            : status == TravelerPaymentStatus.cancelled
                ? Colors.blueGrey
                : Colors.red;
    final title = isPaid
        ? lang.t('payment_success_title')
        : isPending
            ? lang.t('payment_pending_title')
            : status == TravelerPaymentStatus.cancelled
                ? lang.t('payment_cancelled_title')
                : lang.t('payment_error_title');

    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        icon: Icon(icon, color: color, size: 42),
        title: Text(title),
        content: Text(message),
        actions: [
          if (!isPaid)
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _openFinancialHome();
              },
              child: Text(
                widget.returnToInvoices
                    ? lang.t('back_to_invoices')
                    : lang.t('view_my_bookings'),
              ),
            ),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isPaid ? lang.t('continue') : lang.t('close')),
          ),
        ],
      ),
    );
  }

  void _openFinancialHome() {
    Navigator.of(context).pushNamedAndRemoveUntil(
      widget.returnToInvoices ? '/account/invoices' : '/reservations',
      (route) => false,
    );
  }

  Widget _paymentButton(
    _PaymentMethodOption option,
    LanguageProvider lang,
  ) {
    final colors = Theme.of(context).colorScheme;
    final selected = selectedMethod == option.method;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Material(
        color: selected
            ? colors.primaryContainer.withOpacity(0.45)
            : colors.surfaceContainer,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: option.available
              ? () => setState(() => selectedMethod = option.method)
              : () => ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(lang.t(option.unavailableReasonKey!)),
                      behavior: SnackBarBehavior.floating,
                    ),
                  ),
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: selected ? colors.primary : colors.outlineVariant,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Opacity(
                  opacity: option.available ? 1 : 0.45,
                  child: Image.asset(option.asset, width: 48, height: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _methodLabel(option.method, lang),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: option.available
                              ? colors.onSurface
                              : colors.onSurfaceVariant,
                        ),
                      ),
                      if (option.unavailableReasonKey != null)
                        Text(
                          lang.t(option.unavailableReasonKey!),
                          style: TextStyle(
                            color: colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                    ],
                  ),
                ),
                Radio<String>(
                  value: option.method,
                  groupValue: selectedMethod,
                  onChanged: option.available
                      ? (value) => setState(() => selectedMethod = value!)
                      : null,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _methodLabel(String method, LanguageProvider lang) {
    switch (method) {
      case 'Credit Card':
        return lang.t('credit_card');
      case 'Mobile Money':
        return lang.t('mobile_money');
      case 'PayPal':
        return lang.t('paypal');
      default:
        return method;
    }
  }
}

class _AmountSummary extends StatelessWidget {
  final double amount;
  final String currency;
  final bool showCurrencyNotice;
  final String selectedMethod;
  final LanguageProvider lang;

  const _AmountSummary({
    required this.amount,
    required this.currency,
    required this.showCurrencyNotice,
    required this.selectedMethod,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final formatted = NumberFormat.currency(
      name: currency,
      symbol: currency,
      decimalDigits: isZeroDecimalPaymentCurrency(currency) ? 0 : 2,
    ).format(amount);
    final paypalConversion =
        selectedMethod == 'PayPal' && currency != 'EUR' && currency != 'USD';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.primaryContainer.withOpacity(0.32),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primary.withOpacity(0.28)),
      ),
      child: Column(
        children: [
          Text(
            lang.t('amount_to_pay'),
            style: TextStyle(color: colors.onSurfaceVariant),
          ),
          const SizedBox(height: 5),
          Text(
            formatted,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w900,
                  color: colors.onSurface,
                ),
          ),
          if (showCurrencyNotice) ...[
            const SizedBox(height: 10),
            Text(
              lang.t(
                paypalConversion
                    ? 'paypal_currency_conversion_notice'
                    : 'charged_currency_notice',
              ),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colors.onSurfaceVariant,
                fontSize: 12,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
