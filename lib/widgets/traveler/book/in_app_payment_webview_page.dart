import 'package:chicaparts_partner/api/traveler/api_payment_traveler.dart';
import 'package:chicaparts_partner/models/traveler/payment_models.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/widgets/traveler/book/book_app_bar.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

class InAppPaymentWebViewPage extends StatefulWidget {
  const InAppPaymentWebViewPage({
    super.key,
    required this.paymentUrl,
    required this.service,
    required this.bookingId,
    this.orderId,
    this.paymentItemType = 'booking',
  });

  final String paymentUrl;
  final String service;
  final int bookingId;
  final String? orderId;
  final String paymentItemType;

  @override
  State<InAppPaymentWebViewPage> createState() =>
      _InAppPaymentWebViewPageState();
}

class _InAppPaymentWebViewPageState extends State<InAppPaymentWebViewPage>
    with WidgetsBindingObserver {
  final ApiPayment _apiPayment = ApiPayment();
  late final WebViewController _controller;
  late final String _initialHost;
  int _progress = 0;
  bool _checkingPayment = false;
  bool _terminalSignalReceived = false;
  DateTime? _lastAutomaticCheck;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initialHost = Uri.tryParse(widget.paymentUrl)?.host.toLowerCase() ?? '';

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (progress) {
            if (mounted) setState(() => _progress = progress);
          },
          onNavigationRequest: _handleNavigationRequest,
          onUrlChange: (change) {
            if (change.url != null) _handleNavigationSignal(change.url!);
          },
          onWebResourceError: (error) {
            debugPrint(
              'Payment WebView error: code=${error.errorCode} '
              'mainFrame=${error.isForMainFrame}',
            );
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || _checkingPayment) return;
    final lastCheck = _lastAutomaticCheck;
    if (lastCheck != null &&
        DateTime.now().difference(lastCheck) < const Duration(seconds: 3)) {
      return;
    }
    _lastAutomaticCheck = DateTime.now();
    _checkPayment(silentWhenPending: true);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final keyboardVisible = MediaQuery.viewInsetsOf(context).bottom > 0;
    final colors = Theme.of(context).colorScheme;

    return WillPopScope(
      onWillPop: _confirmClose,
      child: Scaffold(
        resizeToAvoidBottomInset: true,
        backgroundColor: colors.surface,
        appBar: buildBookAppBar(
          lang.t('secure_payment'),
          onBack: _checkingPayment ? () {} : _requestClose,
          actions: [
            IconButton(
              tooltip: lang.t('close'),
              onPressed: _checkingPayment ? null : _requestClose,
              icon: const Icon(Icons.close),
            ),
          ],
        ),
        body: Column(
          children: [
            if (_progress < 100)
              LinearProgressIndicator(value: _progress / 100),
            if (_checkingPayment)
              Material(
                color: colors.primaryContainer.withOpacity(0.55),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 12),
                      Expanded(child: Text(lang.t('payment_verifying'))),
                    ],
                  ),
                ),
              ),
            Expanded(child: WebViewWidget(controller: _controller)),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 180),
              child: keyboardVisible
                  ? const SizedBox.shrink()
                  : SafeArea(
                      top: false,
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          boxShadow: [
                            BoxShadow(
                              blurRadius: 12,
                              color: colors.shadow.withOpacity(0.12),
                              offset: const Offset(0, -4),
                            ),
                          ],
                        ),
                        child: FilledButton.icon(
                          onPressed:
                              _checkingPayment ? null : () => _checkPayment(),
                          icon: const Icon(Icons.verified_outlined),
                          label: Text(lang.t('payment_completed_action')),
                        ),
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  NavigationDecision _handleNavigationRequest(NavigationRequest request) {
    final uri = Uri.tryParse(request.url);
    if (uri == null) return NavigationDecision.prevent;

    _handleNavigationSignal(request.url);
    if (_isAllowedUri(uri)) return NavigationDecision.navigate;

    launchUrl(uri, mode: LaunchMode.externalApplication);
    return NavigationDecision.prevent;
  }

  bool _isAllowedUri(Uri uri) {
    if (uri.scheme != 'https') return false;
    final host = uri.host.toLowerCase();
    return _matchesHost(host, _initialHost) ||
        _matchesHost(host, 'chic-aparts.com') ||
        _matchesHost(host, 'chicaparts.com') ||
        _matchesHost(host, 'cinetpay.net') ||
        _matchesHost(host, 'paypal.com') ||
        _matchesHost(host, 'paypalobjects.com');
  }

  bool _matchesHost(String host, String expected) {
    if (expected.isEmpty) return false;
    return host == expected || host.endsWith('.$expected');
  }

  void _handleNavigationSignal(String url) {
    if (_terminalSignalReceived) return;
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    final signal = '${uri.path} ${uri.query}'.toLowerCase();
    final hasTerminalSignal = signal.contains('success') ||
        signal.contains('approved') ||
        signal.contains('completed') ||
        signal.contains('cancel') ||
        signal.contains('failed') ||
        signal.contains('error');

    if (hasTerminalSignal) {
      _terminalSignalReceived = true;
      // Le signal URL ne constitue jamais une preuve de paiement.
      _checkPayment();
    }
  }

  Future<void> _checkPayment({bool silentWhenPending = false}) async {
    if (_checkingPayment || !mounted) return;
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    setState(() => _checkingPayment = true);
    try {
      final transaction = await _completeOrderOrCheckExisting();
      if (!mounted) return;

      final status = parseTravelerPaymentStatus(transaction);
      if (status.isSuccessful) {
        Navigator.pop(context, transaction);
        return;
      }
      if (!silentWhenPending) {
        await _showDialog(
          title: lang.t('payment_pending_title'),
          message: lang.t('payment_pending_message'),
        );
      }
    } on PaymentApiException catch (error) {
      debugPrint(
        'Payment status error: code=${error.code} status=${error.statusCode}',
      );
      if (!mounted || silentWhenPending) return;
      await _showDialog(
        title: lang.t('payment_error_title'),
        message: lang.t(
          error.code == 'network' || error.code == 'timeout'
              ? 'payment_network_error'
              : 'payment_status_unavailable',
        ),
      );
    } finally {
      if (mounted) setState(() => _checkingPayment = false);
    }
  }

  Future<Map<String, dynamic>?> _completeOrderOrCheckExisting() async {
    final orderId = widget.orderId?.trim();
    if (orderId != null && orderId.isNotEmpty) {
      final result = await _apiPayment.completePaymentOrder(
        service: widget.service,
        orderId: orderId,
      );
      final transaction = result?['transaction'];
      if (transaction is Map) return Map<String, dynamic>.from(transaction);
      return result;
    }

    return _apiPayment.checkExistingTransaction(
      service: widget.service,
      bookingId: widget.bookingId,
      paymentItemType: widget.paymentItemType,
    );
  }

  void _requestClose() async {
    if (await _confirmClose() && mounted) Navigator.pop(context);
  }

  Future<bool> _confirmClose() async {
    if (_checkingPayment) return false;
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final close = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        icon: const Icon(Icons.info_outline_rounded),
        title: Text(lang.t('leave_payment_title')),
        content: Text(lang.t('leave_payment_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.t('continue_payment')),
          ),
          FilledButton.tonal(
            onPressed: () => Navigator.pop(context, true),
            child: Text(lang.t('pay_later_view_bookings')),
          ),
        ],
      ),
    );
    return close == true;
  }

  Future<void> _showDialog({
    required String title,
    required String message,
  }) {
    return showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              Provider.of<LanguageProvider>(context, listen: false).t('close'),
            ),
          ),
        ],
      ),
    );
  }
}
