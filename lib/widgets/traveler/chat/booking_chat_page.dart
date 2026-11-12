import 'dart:async';

import 'package:chicaparts_partner/api/traveler/api_chat_traveler.dart';
import 'package:chicaparts_partner/models/traveler/chat_message.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class BookingChatPage extends StatefulWidget {
  final int bookingId;
  final String? bookingReference;
  final String? accommodationName;
  final DateTime? firstNight;
  final DateTime? lastNight;

  const BookingChatPage({
    super.key,
    required this.bookingId,
    this.bookingReference,
    this.accommodationName,
    this.firstNight,
    this.lastNight,
  });

  @override
  State<BookingChatPage> createState() => _BookingChatPageState();
}

class _BookingChatPageState extends State<BookingChatPage> {
  final _api = ApiChatTraveler();
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  final List<ChatMessage> _messages = [];
  Timer? _refreshTimer;
  bool _loading = true;
  bool _sending = false;
  String? _error;

  bool get _isFrench => context.read<LanguageProvider>().currentLang == 'fr';

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _refreshTimer = Timer.periodic(
      const Duration(seconds: 15),
      (_) => _loadMessages(silent: true),
    );
  }

  Future<void> _loadMessages({bool silent = false}) async {
    if (!silent && mounted) setState(() => _loading = true);
    try {
      final page = await _api.getMessages(widget.bookingId);
      if (!mounted) return;
      setState(() {
        _messages
          ..clear()
          ..addAll(page.messages);
        _error = null;
        _loading = false;
      });
      unawaited(_api.markAllAsRead(widget.bookingId).catchError((_) {}));
      if (!silent) _scrollToBottom();
    } catch (error) {
      if (!mounted || silent) return;
      setState(() {
        _loading = false;
        _error = error.toString();
      });
    }
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending) return;

    setState(() => _sending = true);
    try {
      final message = await _api.sendMessage(widget.bookingId, text);
      if (!mounted) return;
      _controller.clear();
      setState(() {
        if (!_messages.any((item) => item.id == message.id)) {
          _messages.add(message);
        }
      });
      _scrollToBottom();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error.toString())),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _controller.dispose();
    _scrollController.dispose();
    _api.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final reference = widget.bookingReference?.trim();
    final stayDates = widget.firstNight != null && widget.lastNight != null
        ? '${DateFormat('dd MMM').format(widget.firstNight!)} – ${DateFormat('dd MMM yyyy').format(widget.lastNight!.add(const Duration(days: 1)))}'
        : null;
    final subtitleParts = <String>[
      if (widget.accommodationName?.trim().isNotEmpty == true)
        widget.accommodationName!.trim(),
      if (stayDates != null) stayDates,
    ];
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_isFrench ? 'Service réservation' : 'Booking support'),
            Text(
              subtitleParts.isNotEmpty
                  ? subtitleParts.join(' · ')
                  : reference != null && reference.isNotEmpty
                      ? (_isFrench
                          ? 'Réservation $reference'
                          : 'Booking $reference')
                      : '#${widget.bookingId}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 12, color: colors.onSurfaceVariant),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: _isFrench ? 'Actualiser' : 'Refresh',
            onPressed: _loading ? null : _loadMessages,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            Expanded(child: _buildContent()),
            _buildComposer(),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded, size: 48),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: _loadMessages,
                child: Text(_isFrench ? 'Réessayer' : 'Try again'),
              ),
            ],
          ),
        ),
      );
    }
    if (_messages.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.forum_outlined, size: 52),
              const SizedBox(height: 12),
              Text(
                _isFrench
                    ? 'Démarrer la conversation'
                    : 'Start the conversation',
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                _isFrench
                    ? 'Posez une question au service réservation concernant ce séjour.'
                    : 'Ask booking support a question about this stay.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMessages,
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
        itemCount: _messages.length,
        itemBuilder: (_, index) => _MessageBubble(message: _messages[index]),
      ),
    );
  }

  Widget _buildComposer() {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: colors.surface,
      elevation: 8,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          12,
          10,
          12,
          10 + MediaQuery.paddingOf(context).bottom,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: _controller,
                minLines: 1,
                maxLines: 5,
                maxLength: 5000,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText: _isFrench ? 'Votre message…' : 'Your message…',
                  counterText: '',
                  filled: true,
                  fillColor: colors.surfaceContainerHighest,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton.filled(
              onPressed: _sending ? null : _send,
              icon: _sending
                  ? const SizedBox.square(
                      dimension: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send_rounded),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;

  const _MessageBubble({required this.message});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final mine = message.isFromCustomer;
    final time = message.createdAt == null
        ? ''
        : DateFormat('dd/MM · HH:mm').format(message.createdAt!.toLocal());

    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints:
            BoxConstraints(maxWidth: MediaQuery.sizeOf(context).width * .78),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
        decoration: BoxDecoration(
          color: mine ? colors.primary : colors.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(18).copyWith(
            bottomRight: mine ? const Radius.circular(4) : null,
            bottomLeft: mine ? null : const Radius.circular(4),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                message.message,
                style: TextStyle(
                    color: mine ? colors.onPrimary : colors.onSurface),
              ),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                time,
                style: TextStyle(
                  fontSize: 10,
                  color: mine
                      ? colors.onPrimary.withValues(alpha: .72)
                      : colors.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
