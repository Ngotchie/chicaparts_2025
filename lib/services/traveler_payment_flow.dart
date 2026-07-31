import 'package:chicaparts_partner/api/traveler/api_payment_traveler.dart';
import 'package:chicaparts_partner/models/traveler/payment_models.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/services/pending_payment_store.dart';
import 'package:chicaparts_partner/widgets/traveler/book/in_app_payment_webview_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;
import 'package:provider/provider.dart';

export 'package:chicaparts_partner/models/traveler/payment_models.dart'
    show TravelerPaymentStatus;

class TravelerPaymentResult {
  final TravelerPaymentStatus status;
  final Map<String, dynamic>? transaction;
  final PaymentOrder? order;
  final String? message;

  const TravelerPaymentResult({
    required this.status,
    this.transaction,
    this.order,
    this.message,
  });

  bool get isPaid => status.isSuccessful;
}

class TravelerPaymentRequest {
  final int bookingId;
  final double amount;
  final String currency;
  final String customerEmail;
  final String label;
  final String method;
  final String paymentItemType;
  final String? customerPhoneNumber;
  final bool allowNewAttemptWhenExisting;
  final bool checkExistingBeforeCheckout;

  const TravelerPaymentRequest({
    required this.bookingId,
    required this.amount,
    required this.currency,
    required this.customerEmail,
    required this.label,
    required this.method,
    this.paymentItemType = 'booking',
    this.customerPhoneNumber,
    this.allowNewAttemptWhenExisting = true,
    this.checkExistingBeforeCheckout = true,
  });
}

class TravelerPaymentFlow {
  TravelerPaymentFlow({
    ApiPayment? apiPayment,
    PendingPaymentStore? pendingStore,
  })  : _apiPayment = apiPayment ?? ApiPayment(),
        _pendingStore = pendingStore ?? PendingPaymentStore();

  final ApiPayment _apiPayment;
  final PendingPaymentStore _pendingStore;

  Future<TravelerPaymentResult> startOrResume(
    BuildContext context,
    TravelerPaymentRequest request, {
    bool showSuccessDialog = true,
  }) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final provider = getPaymentService(request.method);

    try {
      final pendingAttempt = await _pendingStore.read(
        bookingId: request.bookingId,
        paymentItemType: request.paymentItemType,
        provider: provider,
      );
      if (pendingAttempt != null) {
        final resumed = await _checkOrder(
          request,
          provider,
          pendingAttempt.orderId,
        );
        if (resumed.status.isSuccessful) {
          await _pendingStore.clear(
            bookingId: request.bookingId,
            paymentItemType: request.paymentItemType,
            provider: provider,
          );
          if (context.mounted && showSuccessDialog) {
            _showSuccessDialog(context, lang);
          }
          return resumed;
        }

        if (context.mounted) {
          final resume = await _confirmResumeAttempt(context, lang);
          if (!resume) {
            return TravelerPaymentResult(
              status: resumed.status,
              transaction: resumed.transaction,
              message: lang.t('payment_pending_message'),
            );
          }
          if (provider != 'stripe') {
            // Les liens externes déjà ouverts ne sont pas conservés. La
            // vérification précédente évite toutefois un double encaissement.
            await _pendingStore.clear(
              bookingId: request.bookingId,
              paymentItemType: request.paymentItemType,
              provider: provider,
            );
          }
        }
      }

      if (request.checkExistingBeforeCheckout) {
        final existing = await checkExisting(request);
        final existingStatus = parseTravelerPaymentStatus(existing);
        if (existingStatus.isSuccessful) {
          if (context.mounted && showSuccessDialog) {
            _showSuccessDialog(context, lang);
          }
          return TravelerPaymentResult(
            status: existingStatus,
            transaction: existing,
          );
        }
        if (existing != null && !request.allowNewAttemptWhenExisting) {
          return TravelerPaymentResult(
            status: existingStatus,
            transaction: existing,
          );
        }
      }

      final money = PaymentMoney.fromMajor(request.amount, request.currency);
      final order = await _apiPayment.createPaymentOrder(
        service: provider,
        money: money,
        name: request.label,
        customerEmail: request.customerEmail,
        bookingId: request.bookingId,
        customerPhoneNumber: request.customerPhoneNumber,
        paymentItemType: request.paymentItemType,
      );

      if (order.orderId.isNotEmpty) {
        await _pendingStore.save(
          PendingPaymentAttempt(
            bookingId: request.bookingId,
            paymentItemType: request.paymentItemType,
            provider: provider,
            orderId: order.orderId,
            amount: money,
            createdAt: DateTime.now(),
            status: TravelerPaymentStatus.initiated,
          ),
        );
      }

      if (!context.mounted) {
        return TravelerPaymentResult(
          status: TravelerPaymentStatus.cancelled,
          order: order,
        );
      }
      return _presentOrder(
        context,
        request,
        order,
        showSuccessDialog: showSuccessDialog,
      );
    } on stripe.StripeException catch (error) {
      final cancelled = error.error.code == stripe.FailureCode.Canceled;
      return TravelerPaymentResult(
        status: cancelled
            ? TravelerPaymentStatus.cancelled
            : TravelerPaymentStatus.failed,
        message: lang.t(
          cancelled ? 'payment_cancelled_message' : 'payment_method_error',
        ),
      );
    } on PaymentApiException catch (error) {
      debugPrint(
        'Payment API error: code=${error.code} status=${error.statusCode}',
      );
      return TravelerPaymentResult(
        status: _statusForApiError(error),
        message: _messageForApiError(lang, error),
      );
    } catch (error, stackTrace) {
      debugPrint('Payment flow error: $error');
      debugPrintStack(stackTrace: stackTrace);
      return TravelerPaymentResult(
        status: TravelerPaymentStatus.failed,
        message: lang.t('payment_processing_error'),
      );
    }
  }

  Future<TravelerPaymentResult> _presentOrder(
    BuildContext context,
    TravelerPaymentRequest request,
    PaymentOrder order, {
    required bool showSuccessDialog,
  }) async {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final provider = order.provider;

    if (provider == 'stripe') {
      if (order.clientSecret?.isNotEmpty != true || order.orderId.isEmpty) {
        return TravelerPaymentResult(
          status: TravelerPaymentStatus.failed,
          order: order,
          message: lang.t('stripe_secret_missing'),
        );
      }

      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          paymentIntentClientSecret: order.clientSecret!,
          merchantDisplayName: 'Chicaparts',
          style: ThemeMode.system,
        ),
      );
      await stripe.Stripe.instance.presentPaymentSheet();

      final result = await _checkOrderWithShortRetry(
        request,
        provider,
        order.orderId,
      );
      return _finishResult(
        context,
        lang,
        request,
        provider,
        result,
        order,
        showSuccessDialog,
      );
    }

    if (order.paymentUrl?.isNotEmpty != true || order.orderId.isEmpty) {
      return TravelerPaymentResult(
        status: TravelerPaymentStatus.failed,
        order: order,
        message: _backendOrderMessage(order.raw) ??
            lang.t(
              order.orderId.isEmpty
                  ? 'payment_order_missing'
                  : 'payment_link_missing',
            ),
      );
    }

    final completed = await Navigator.push<Map<String, dynamic>?>(
      context,
      MaterialPageRoute(
        builder: (_) => InAppPaymentWebViewPage(
          paymentUrl: order.paymentUrl!,
          service: provider,
          bookingId: request.bookingId,
          orderId: order.orderId,
          paymentItemType: request.paymentItemType,
        ),
      ),
    );
    final status = parseTravelerPaymentStatus(completed);
    final result = TravelerPaymentResult(
      status: status == TravelerPaymentStatus.unknown
          ? TravelerPaymentStatus.pending
          : status,
      transaction: completed,
      order: order,
      message: status.isSuccessful ? null : lang.t('payment_pending_message'),
    );
    return _finishResult(
      context,
      lang,
      request,
      provider,
      result,
      order,
      showSuccessDialog,
    );
  }

  Future<TravelerPaymentResult> _checkOrderWithShortRetry(
    TravelerPaymentRequest request,
    String provider,
    String orderId,
  ) async {
    TravelerPaymentResult? latest;
    for (var attempt = 0; attempt < 3; attempt++) {
      if (attempt > 0) {
        await Future<void>.delayed(Duration(seconds: attempt));
      }
      latest = await _checkOrder(request, provider, orderId);
      if (latest.status.isTerminal) return latest;
    }
    return latest ??
        const TravelerPaymentResult(status: TravelerPaymentStatus.pending);
  }

  Future<TravelerPaymentResult> _checkOrder(
    TravelerPaymentRequest request,
    String provider,
    String orderId,
  ) async {
    final response = await _apiPayment.completePaymentOrder(
      service: provider,
      orderId: orderId,
    );
    final transactionValue = response?['transaction'];
    final transaction = transactionValue is Map
        ? Map<String, dynamic>.from(transactionValue)
        : response;
    var status = parseTravelerPaymentStatus(transaction);
    if (status == TravelerPaymentStatus.unknown) {
      status = TravelerPaymentStatus.pending;
    }
    return TravelerPaymentResult(
      status: status,
      transaction: transaction,
    );
  }

  Future<TravelerPaymentResult> _finishResult(
    BuildContext context,
    LanguageProvider lang,
    TravelerPaymentRequest request,
    String provider,
    TravelerPaymentResult result,
    PaymentOrder order,
    bool showSuccessDialog,
  ) async {
    final attempt = await _pendingStore.read(
      bookingId: request.bookingId,
      paymentItemType: request.paymentItemType,
      provider: provider,
    );
    if (attempt != null) {
      await _pendingStore.markStatus(attempt, result.status);
    }
    if (result.isPaid && context.mounted && showSuccessDialog) {
      _showSuccessDialog(context, lang);
    }
    return TravelerPaymentResult(
      status: result.status,
      transaction: result.transaction,
      order: order,
      message: result.message,
    );
  }

  Future<Map<String, dynamic>?> checkExisting(
    TravelerPaymentRequest request,
  ) {
    return _apiPayment.checkExistingTransaction(
      service: getPaymentService(request.method),
      bookingId: request.bookingId,
      paymentItemType: request.paymentItemType,
    );
  }

  static bool isSuccessfulTransaction(Map<String, dynamic>? transaction) =>
      parseTravelerPaymentStatus(transaction).isSuccessful;

  static String getPaymentService(String paymentMethod) {
    switch (paymentMethod) {
      case 'Credit Card':
        return 'stripe';
      case 'Mobile Money':
        return 'cinetpay';
      case 'PayPal':
        return 'paypal';
      default:
        throw ArgumentError.value(
          paymentMethod,
          'paymentMethod',
          'Unsupported payment method',
        );
    }
  }

  TravelerPaymentStatus _statusForApiError(PaymentApiException error) {
    if (error.code == 'conflict') return TravelerPaymentStatus.pending;
    return TravelerPaymentStatus.failed;
  }

  String _messageForApiError(
    LanguageProvider lang,
    PaymentApiException error,
  ) {
    switch (error.code) {
      case 'timeout':
      case 'network':
        return lang.t('payment_network_error');
      case 'invalid_amount':
      case 'validation':
        return lang.t('payment_amount_error');
      case 'conflict':
        return lang.t('payment_already_exists_message');
      case 'rate_limited':
        return lang.t('payment_too_many_attempts');
      case 'unauthorized':
      case 'server':
      case 'invalid_response':
        return lang.t('payment_service_unavailable');
      default:
        return lang.t('payment_processing_error');
    }
  }

  String? _backendOrderMessage(Map<String, dynamic> response) {
    final error = response['error'];
    final values = [
      response['message'],
      if (error is Map) error['message'],
      if (error is Map && error['details'] is Map) error['details']['message'],
    ];
    for (final value in values) {
      if (value is String && value.trim().isNotEmpty) return value.trim();
    }
    return null;
  }

  Future<bool> _confirmResumeAttempt(
    BuildContext context,
    LanguageProvider lang,
  ) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            icon: const Icon(Icons.schedule_rounded),
            title: Text(lang.t('payment_pending_title')),
            content: Text(lang.t('payment_resume_existing_message')),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: Text(lang.t('pay_later_view_bookings')),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(lang.t('check_again')),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showSuccessDialog(
    BuildContext context,
    LanguageProvider lang,
  ) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: Colors.green),
        title: Text(lang.t('payment_success_title')),
        content: Text(lang.t('payment_success_message')),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(lang.t('close')),
          ),
        ],
      ),
    );
  }
}
