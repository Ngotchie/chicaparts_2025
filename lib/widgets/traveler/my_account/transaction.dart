import 'dart:convert';

import 'package:chicaparts_partner/api/traveler/api_user_traveler.dart';
import 'package:chicaparts_partner/models/traveler/model_transaction_traveler.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TransactionPage extends StatefulWidget {
  const TransactionPage({super.key});

  @override
  State<TransactionPage> createState() => _TransactionPageState();
}

class _TransactionPageState extends State<TransactionPage> {
  final ApiUserTraveler _apiUser = ApiUserTraveler();
  late Future<List<TravelerTransaction>> _futureTransactions;

  @override
  void initState() {
    super.initState();
    _futureTransactions = _loadTransactions();
  }

  Future<List<TravelerTransaction>> _loadTransactions() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson == null || userJson.isEmpty) {
      throw Exception('LOGIN_REQUIRED');
    }

    final currentUser = User.fromJson(jsonDecode(userJson));
    return _apiUser.getUserTransactions(currentUser);
  }

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) return '-';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return DateFormat('dd/MM/yyyy HH:mm').format(date);
  }

  String _formatAmount(num value, String currency) {
    return '${NumberFormat('#,##0.##').format(value)} $currency';
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FB),
      appBar: AppBar(
        title: Text(lang.t('my_transactions')),
        elevation: 0,
        backgroundColor: Colors.white,
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
            return _StateMessage(
              title: isLoginRequired
                  ? lang.t('login_required')
                  : lang.t('error'),
              message: isLoginRequired
                  ? lang.t('login_required_text')
                  : '${lang.t('error')}: ${snapshot.error}',
              retryLabel: lang.t('see_all'),
              onRetry: isLoginRequired
                  ? null
                  : () => setState(() {
                        _futureTransactions = _loadTransactions();
                      }),
            );
          }

          final transactions = snapshot.data ?? const [];
          if (transactions.isEmpty) {
            return _StateMessage(
              title: lang.t('my_transactions'),
              message: lang.t('no_transactions'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              setState(() {
                _futureTransactions = _loadTransactions();
              });
              await _futureTransactions;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: transactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tx = transactions[index];
                return _TransactionCard(
                  tx: tx,
                  amountLabel: _formatAmount(tx.amount, tx.currency),
                  feesLabel: _formatAmount(tx.fees, tx.currency),
                  dateLabel: _formatDate(
                    tx.paymentDate.isNotEmpty ? tx.paymentDate : tx.createdAt,
                  ),
                  lang: lang,
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _TransactionCard extends StatelessWidget {
  final TravelerTransaction tx;
  final String amountLabel;
  final String feesLabel;
  final String dateLabel;
  final LanguageProvider lang;

  const _TransactionCard({
    required this.tx,
    required this.amountLabel,
    required this.feesLabel,
    required this.dateLabel,
    required this.lang,
  });

  @override
  Widget build(BuildContext context) {
    final successColor = tx.success ? const Color(0xFF1E8E5A) : Colors.red;
    final statusLabel = tx.success ? lang.t('paid') : lang.t('unpaid');
    final title = tx.service.isNotEmpty
        ? tx.service
        : (tx.paymentItemType.isNotEmpty
            ? tx.paymentItemType
            : lang.t('my_transactions'));
    final reference = tx.transactionRef.isNotEmpty
        ? tx.transactionRef
        : tx.operatorTransactionId;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE4EBF2)),
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
                  color: const Color(0xFF244B6B).withOpacity(0.08),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.account_balance_wallet_outlined,
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
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1D3550),
                      ),
                    ),
                    if (reference.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        reference,
                        style: TextStyle(
                          fontSize: 12.5,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: successColor.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  statusLabel,
                  style: TextStyle(
                    color: successColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _InfoLine(lang.t('amount_paid'), amountLabel),
          _InfoLine(lang.t('transaction_fees'), feesLabel),
          _InfoLine(lang.t('transaction_date'), dateLabel),
          if (tx.status.isNotEmpty) _InfoLine(lang.t('status'), tx.status),
          if (tx.operatorName.isNotEmpty)
            _InfoLine(lang.t('operator'), tx.operatorName),
          if (tx.payer.isNotEmpty) _InfoLine(lang.t('payer'), tx.payer),
          if (tx.paymentItemType.isNotEmpty)
            _InfoLine(lang.t('payment_type'), tx.paymentItemType),
        ],
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
