import 'dart:convert';

import 'package:chicaparts_partner/api/traveler/api_booking_traveler.dart';
import 'package:chicaparts_partner/api/traveler/api_user_traveler.dart';
import 'package:chicaparts_partner/models/model_booking.dart';
import 'package:chicaparts_partner/models/traveler/model_claim_traveler.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/providers/currency_provider.dart';
import 'package:chicaparts_partner/providers/exchange_rate_provider.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/utils/currency_converter.dart';
import 'package:chicaparts_partner/widgets/traveler/common/login_required_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

class ClaimsPage extends StatefulWidget {
  final int? initialBookingId;
  final int? initialAccommodationId;

  const ClaimsPage({
    super.key,
    this.initialBookingId,
    this.initialAccommodationId,
  });

  @override
  State<ClaimsPage> createState() => _ClaimsPageState();
}

class _ClaimsPageState extends State<ClaimsPage> {
  final ApiUserTraveler _apiUser = ApiUserTraveler();
  final ApiBooking _apiBooking = ApiBooking();
  late Future<List<TravelerClaim>> _futureClaims;
  late Future<List<Booking>> _futureBookings;
  User? _currentUser;
  bool _isDeleting = false;

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
    _futureClaims = _loadClaims();
    _futureBookings = _loadBookings();
    if (widget.initialBookingId != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        final lang = Provider.of<LanguageProvider>(context, listen: false);
        _openClaimForm(
          lang: lang,
          initialBookingId: widget.initialBookingId,
          initialAccommodationId: widget.initialAccommodationId,
        );
      });
    }
  }

  Future<User> _loadCurrentUser() async {
    if (_currentUser != null) return _currentUser!;

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson == null || userJson.isEmpty) {
      throw Exception('LOGIN_REQUIRED');
    }

    _currentUser = User.fromJson(jsonDecode(userJson));
    return _currentUser!;
  }

  Future<List<TravelerClaim>> _loadClaims() async {
    final currentUser = await _loadCurrentUser();
    return _apiUser.getUserClaims(currentUser);
  }

  Future<List<Booking>> _loadBookings() async {
    final currentUser = await _loadCurrentUser();
    final bookings = await _apiBooking.getUserReservations(currentUser);
    bookings.sort((a, b) {
      final da = DateTime.tryParse(a.bookedAt) ?? DateTime(2000);
      final db = DateTime.tryParse(b.bookedAt) ?? DateTime(2000);
      return db.compareTo(da);
    });
    return bookings;
  }

  void _refreshClaims() {
    setState(() {
      _futureClaims = _loadClaims();
      _futureBookings = _loadBookings();
    });
  }

  String _formatDate(String raw) {
    if (raw.trim().isEmpty) return '-';
    final date = DateTime.tryParse(raw);
    if (date == null) return raw;
    return DateFormat('dd/MM/yyyy').format(date);
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(lang.t('my_claims')),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
        foregroundColor: const Color(0xFF244B6B),
        actions: [
          IconButton(
            tooltip: lang.t('add_claim'),
            onPressed: () => _openClaimForm(lang: lang),
            icon: const Icon(Icons.add_circle_outline),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openClaimForm(lang: lang),
        backgroundColor: const Color(0xFF244B6B),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: Text(lang.t('add_claim')),
      ),
      body: FutureBuilder<List<TravelerClaim>>(
        future: _futureClaims,
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
              icon: Icons.wifi_off_outlined,
              title: lang.t('error'),
              message: '${lang.t('error')}: ${snapshot.error}',
              retryLabel: lang.t('retry'),
              onRetry: _refreshClaims,
            );
          }

          final claims = snapshot.data ?? const [];
          if (claims.isEmpty) {
            return _StateMessage(
              icon: Icons.report_problem_outlined,
              title: lang.t('no_claims'),
              message: lang.t('no_claims_text'),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              _refreshClaims();
              await _futureClaims;
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: claims.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final claim = claims[index];
                return _ClaimCard(
                  claim: claim,
                  createdAt: _formatDate(claim.createdAt),
                  typeLabel: _claimTypeLabel(claim.type, lang),
                  statusLabel: _claimStatusLabel(claim.status, lang),
                  statusColor: _claimStatusColor(claim.status),
                  onTap: () => _showClaimDetails(context, claim, lang),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _showClaimDetails(
      BuildContext context, TravelerClaim claim, LanguageProvider lang) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.72,
          minChildSize: 0.45,
          maxChildSize: 0.92,
          builder: (context, controller) {
            return SafeArea(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
                      _ClaimIcon(color: _claimStatusColor(claim.status)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${lang.t('claim')} #${claim.ref.isNotEmpty ? claim.ref : claim.id}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF1D3550),
                              ),
                            ),
                            const SizedBox(height: 5),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                _ClaimChip(
                                  label: _claimTypeLabel(claim.type, lang),
                                  color: const Color(0xFF244B6B),
                                ),
                                _ClaimChip(
                                  label: _claimStatusLabel(claim.status, lang),
                                  color: _claimStatusColor(claim.status),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            _openClaimForm(lang: lang, claim: claim);
                          },
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: Text(lang.t('update')),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _isDeleting
                              ? null
                              : () => _confirmDeleteClaim(claim, lang),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: const Color(0xFFD74A4A),
                            side: const BorderSide(color: Color(0xFFD74A4A)),
                          ),
                          icon: const Icon(Icons.delete_outline, size: 18),
                          label: Text(lang.t('delete')),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  if (claim.accommodationName.isNotEmpty)
                    _InfoLine(lang.t('accommodation'), claim.accommodationName),
                  if (claim.accommodationCity.isNotEmpty)
                    _InfoLine(lang.t('city'), claim.accommodationCity),
                  if (claim.accommodationAddress.isNotEmpty)
                    _InfoLine(lang.t('address'), claim.accommodationAddress),
                  _InfoLine(lang.t('booking'), '#${claim.bookingId}'),
                  _InfoLine(lang.t('created_at'), _formatDate(claim.createdAt)),
                  if (claim.incidentDate.isNotEmpty)
                    _InfoLine(lang.t('incident_date'),
                        _formatDate(claim.incidentDate)),
                  const SizedBox(height: 12),
                  _TextBlock(
                    title: lang.t('description'),
                    text: claim.description,
                  ),
                  if (claim.desiredSolution.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _TextBlock(
                      title: lang.t('desired_solution'),
                      text: claim.desiredSolution,
                    ),
                  ],
                  if (claim.adminNotes.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _TextBlock(
                      title: lang.t('admin_notes'),
                      text: claim.adminNotes,
                    ),
                  ],
                  if (claim.compensationAmount > 0) ...[
                    const SizedBox(height: 12),
                    _InfoLine(
                      lang.t('compensation'),
                      _formatMoney(
                        claim.compensationAmount,
                        claim.compensationCurrency,
                      ),
                    ),
                  ],
                  if (claim.attachments.isNotEmpty) ...[
                    const SizedBox(height: 18),
                    Text(
                      lang.t('attachments'),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1D3550),
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...claim.attachments.map(
                      (attachment) => _AttachmentTile(
                        attachment: attachment,
                        onTap: () => _openAttachment(attachment.url),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _openClaimForm({
    required LanguageProvider lang,
    TravelerClaim? claim,
    int? initialBookingId,
    int? initialAccommodationId,
  }) async {
    final saved = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _ClaimFormSheet(
        lang: lang,
        bookingsFuture: _futureBookings,
        initialClaim: claim,
        initialBookingId: initialBookingId,
        initialAccommodationId: initialAccommodationId,
        typeLabel: (type) => _claimTypeLabel(type, lang),
        onSubmit: (payload) => _saveClaim(payload, claim),
      ),
    );

    if (saved == true && mounted) {
      _refreshClaims();
    }
  }

  Future<void> _saveClaim(
    Map<String, dynamic> payload,
    TravelerClaim? claim,
  ) async {
    final user = await _loadCurrentUser();
    if (claim == null) {
      await _apiUser.createClaim(user, payload);
    } else {
      await _apiUser.updateClaim(user, claim.id, payload);
    }
  }

  Future<void> _confirmDeleteClaim(
    TravelerClaim claim,
    LanguageProvider lang,
  ) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(lang.t('delete_claim')),
        content: Text(lang.t('delete_claim_message')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(lang.t('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD74A4A),
            ),
            child: Text(lang.t('delete')),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isDeleting = true);
    try {
      final user = await _loadCurrentUser();
      await _apiUser.deleteClaim(user, claim.id);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(lang.t('claim_deleted'))),
      );
      _refreshClaims();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${lang.t('error')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  Future<void> _openAttachment(String url) async {
    if (url.trim().isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  String _claimTypeLabel(String type, LanguageProvider lang) {
    switch (type) {
      case 'cleanliness':
        return lang.t('claim_cleanliness');
      case 'equipment':
        return lang.t('claim_equipment');
      case 'noise':
        return lang.t('claim_noise');
      case 'safety':
        return lang.t('claim_safety');
      case 'service':
        return lang.t('claim_service');
      case 'other':
        return lang.t('claim_other');
      default:
        return type.isEmpty ? lang.t('claim') : type;
    }
  }

  String _claimStatusLabel(String status, LanguageProvider lang) {
    switch (status.toLowerCase()) {
      case 'pending':
        return lang.t('pending');
      case 'in_progress':
      case 'processing':
        return lang.t('processing');
      case 'resolved':
        return lang.t('resolved');
      case 'rejected':
        return lang.t('rejected');
      case 'closed':
        return lang.t('closed');
      default:
        return status.isEmpty ? lang.t('status') : status;
    }
  }

  Color _claimStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'resolved':
      case 'closed':
        return const Color(0xFF1E8E5A);
      case 'rejected':
        return const Color(0xFFD74A4A);
      case 'in_progress':
      case 'processing':
        return const Color(0xFF0B7BA8);
      case 'pending':
      default:
        return const Color(0xFFF37540);
    }
  }
}

class _ClaimFormSheet extends StatefulWidget {
  final LanguageProvider lang;
  final Future<List<Booking>> bookingsFuture;
  final TravelerClaim? initialClaim;
  final int? initialBookingId;
  final int? initialAccommodationId;
  final String Function(String type) typeLabel;
  final Future<void> Function(Map<String, dynamic> payload) onSubmit;

  const _ClaimFormSheet({
    required this.lang,
    required this.bookingsFuture,
    required this.initialClaim,
    this.initialBookingId,
    this.initialAccommodationId,
    required this.typeLabel,
    required this.onSubmit,
  });

  @override
  State<_ClaimFormSheet> createState() => _ClaimFormSheetState();
}

class _ClaimFormSheetState extends State<_ClaimFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _solutionController;
  int? _bookingId;
  int? _accommodationId;
  String _type = 'cleanliness';
  DateTime? _incidentDate;
  bool _saving = false;

  static const _types = [
    'cleanliness',
    'equipment',
    'noise',
    'safety',
    'service',
    'other',
  ];

  @override
  void initState() {
    super.initState();
    final claim = widget.initialClaim;
    _bookingId = claim == null
        ? widget.initialBookingId
        : (claim.bookingId == 0 ? null : claim.bookingId);
    _accommodationId = claim == null
        ? widget.initialAccommodationId
        : (claim.accommodationId == 0 ? null : claim.accommodationId);
    _type = _types.contains(claim?.type) ? claim!.type : 'cleanliness';
    _incidentDate = DateTime.tryParse(claim?.incidentDate ?? '');
    _descriptionController =
        TextEditingController(text: claim?.description ?? '');
    _solutionController =
        TextEditingController(text: claim?.desiredSolution ?? '');
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _solutionController.dispose();
    super.dispose();
  }

  Future<void> _pickIncidentDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _incidentDate ?? now,
      firstDate: DateTime(now.year - 5),
      lastDate: now,
    );
    if (picked != null) {
      setState(() => _incidentDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      await widget.onSubmit({
        'booking_id': _bookingId,
        'accommodation_id': _accommodationId,
        'type': _type,
        'description': _descriptionController.text.trim(),
        'desired_solution': _solutionController.text.trim(),
        'incident_date': _incidentDate == null
            ? null
            : DateFormat('yyyy-MM-dd').format(_incidentDate!),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${widget.lang.t('error')}: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final bottom = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.initialClaim != null;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: bottom),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.86,
          minChildSize: 0.55,
          maxChildSize: 0.95,
          builder: (context, controller) {
            return Form(
              key: _formKey,
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
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
                  Text(
                    isEditing ? lang.t('edit_claim') : lang.t('add_claim'),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1D3550),
                    ),
                  ),
                  const SizedBox(height: 18),
                  FutureBuilder<List<Booking>>(
                    future: widget.bookingsFuture,
                    builder: (context, snapshot) {
                      final bookings = snapshot.data ?? const <Booking>[];
                      final selectedBookingId =
                          bookings.any((booking) => booking.id == _bookingId)
                              ? _bookingId
                              : null;
                      return DropdownButtonFormField<int>(
                        value: selectedBookingId,
                        isExpanded: true,
                        decoration: _fieldDecoration(lang.t('booking')),
                        items: bookings.map((booking) {
                          return DropdownMenuItem<int>(
                            value: booking.id,
                            child: Text(
                              '#${booking.id} - ${booking.accommodation}',
                              overflow: TextOverflow.ellipsis,
                            ),
                          );
                        }).toList(),
                        onChanged: _saving
                            ? null
                            : (value) {
                                final booking = bookings.firstWhere(
                                  (item) => item.id == value,
                                  orElse: () => bookings.first,
                                );
                                setState(() {
                                  _bookingId = value;
                                  _accommodationId = booking.propId;
                                });
                              },
                        validator: (value) =>
                            value == null ? lang.t('required') : null,
                      );
                    },
                  ),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<String>(
                    value: _type,
                    isExpanded: true,
                    decoration: _fieldDecoration(lang.t('claim_type')),
                    items: _types
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(widget.typeLabel(type)),
                          ),
                        )
                        .toList(),
                    onChanged: _saving
                        ? null
                        : (value) => setState(() => _type = value!),
                  ),
                  const SizedBox(height: 14),
                  InkWell(
                    onTap: _saving ? null : _pickIncidentDate,
                    borderRadius: BorderRadius.circular(14),
                    child: InputDecorator(
                      decoration: _fieldDecoration(lang.t('incident_date')),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              _incidentDate == null
                                  ? lang.t('select_date')
                                  : DateFormat('dd/MM/yyyy')
                                      .format(_incidentDate!),
                              style: TextStyle(
                                color: _incidentDate == null
                                    ? Colors.grey[600]
                                    : const Color(0xFF1D3550),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const Icon(Icons.calendar_today_outlined, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _descriptionController,
                    enabled: !_saving,
                    minLines: 4,
                    maxLines: 6,
                    decoration: _fieldDecoration(lang.t('description')),
                    validator: (value) {
                      if ((value ?? '').trim().isEmpty) {
                        return lang.t('required');
                      }
                      if ((value ?? '').trim().length < 10) {
                        return lang.t('claim_description_too_short');
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _solutionController,
                    enabled: !_saving,
                    minLines: 3,
                    maxLines: 5,
                    decoration: _fieldDecoration(lang.t('desired_solution')),
                  ),
                  const SizedBox(height: 22),
                  FilledButton.icon(
                    onPressed: _saving ? null : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF244B6B),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    icon: _saving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Icon(isEditing
                            ? Icons.save_outlined
                            : Icons.send_outlined),
                    label: Text(_saving ? lang.t('saving') : lang.t('save')),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: Theme.of(context)
          .colorScheme
          .surfaceContainerHighest
          .withOpacity(0.55),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE4EBF2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE4EBF2)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFF244B6B), width: 1.5),
      ),
    );
  }
}

class _ClaimCard extends StatelessWidget {
  final TravelerClaim claim;
  final String createdAt;
  final String typeLabel;
  final String statusLabel;
  final Color statusColor;
  final VoidCallback onTap;

  const _ClaimCard({
    required this.claim,
    required this.createdAt,
    required this.typeLabel,
    required this.statusLabel,
    required this.statusColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final title = claim.accommodationName.isNotEmpty
        ? claim.accommodationName
        : '${lang.t('claim')} #${claim.ref.isNotEmpty ? claim.ref : claim.id}';

    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border:
              Border.all(color: Theme.of(context).colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF244B6B).withOpacity(0.05),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            _ClaimIcon(color: statusColor),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF1D3550),
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    claim.description,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.grey[650],
                      fontSize: 12.5,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      _ClaimChip(
                          label: typeLabel, color: const Color(0xFF244B6B)),
                      _ClaimChip(label: statusLabel, color: statusColor),
                      Text(
                        createdAt,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right, color: Color(0xFF244B6B)),
          ],
        ),
      ),
    );
  }
}

class _ClaimIcon extends StatelessWidget {
  final Color color;

  const _ClaimIcon({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Icon(Icons.report_problem_outlined, color: color),
    );
  }
}

class _ClaimChip extends StatelessWidget {
  final String label;
  final Color color;

  const _ClaimChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11.5,
          fontWeight: FontWeight.w800,
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
                fontWeight: FontWeight.w700,
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
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TextBlock extends StatelessWidget {
  final String title;
  final String text;

  const _TextBlock({required this.title, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF244B6B),
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            text,
            style: const TextStyle(
              color: Color(0xFF1D3550),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentTile extends StatelessWidget {
  final ClaimAttachment attachment;
  final VoidCallback onTap;

  const _AttachmentTile({required this.attachment, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FB),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: ListTile(
        onTap: onTap,
        leading: const Icon(Icons.attach_file, color: Color(0xFF244B6B)),
        title: Text(
          attachment.name.isNotEmpty ? attachment.name : attachment.path,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontWeight: FontWeight.w700),
        ),
        trailing: const Icon(Icons.open_in_new, size: 18),
      ),
    );
  }
}

class _StateMessage extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? retryLabel;
  final VoidCallback? onRetry;

  const _StateMessage({
    required this.icon,
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
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: const Color(0xFF244B6B).withOpacity(0.08),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Icon(icon, size: 34, color: const Color(0xFF244B6B)),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF1D3550),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[700], height: 1.4),
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
