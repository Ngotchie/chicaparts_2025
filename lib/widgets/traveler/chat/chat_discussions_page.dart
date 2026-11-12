import 'package:chicaparts_partner/api/traveler/api_chat_traveler.dart';
import 'package:chicaparts_partner/models/traveler/chat_message.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/widgets/traveler/chat/booking_chat_page.dart';
import 'package:chicaparts_partner/widgets/traveler/common/login_required_state.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ChatDiscussionsPage extends StatefulWidget {
  const ChatDiscussionsPage({super.key});

  @override
  State<ChatDiscussionsPage> createState() => _ChatDiscussionsPageState();
}

class _ChatDiscussionsPageState extends State<ChatDiscussionsPage> {
  final _api = ApiChatTraveler();
  final _searchController = TextEditingController();
  Future<List<ChatDiscussion>>? _future;
  bool _sessionLoading = true;
  bool _isLoggedIn = false;
  bool _searching = false;
  String _query = '';

  bool get _isFrench => context.read<LanguageProvider>().currentLang == 'fr';

  @override
  void initState() {
    super.initState();
    _loadSessionAndDiscussions();
  }

  Future<void> _loadSessionAndDiscussions() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    final isLoggedIn = userJson != null && userJson.isNotEmpty;

    if (!mounted) return;
    setState(() {
      _isLoggedIn = isLoggedIn;
      _sessionLoading = false;
      _future = isLoggedIn ? _api.getDiscussions() : null;
    });
  }

  Future<void> _refresh() async {
    if (!_isLoggedIn) return;
    final future = _api.getDiscussions();
    setState(() => _future = future);
    await future;
  }

  Future<void> _open(ChatDiscussion discussion) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BookingChatPage(
          bookingId: discussion.bookingId,
          bookingReference: discussion.bookingReference,
          accommodationName: discussion.accommodationName,
          firstNight: discussion.firstNight,
          lastNight: discussion.lastNight,
        ),
      ),
    );
    if (mounted) _refresh();
  }

  void _openSearch() {
    setState(() => _searching = true);
  }

  void _closeSearch() {
    _searchController.clear();
    setState(() {
      _searching = false;
      _query = '';
    });
  }

  List<ChatDiscussion> _filterDiscussions(
    List<ChatDiscussion> discussions,
  ) {
    final query = _query.trim().toLowerCase();
    if (query.isEmpty) return discussions;

    return discussions.where((discussion) {
      final searchable = <String>[
        discussion.accommodationName,
        discussion.city,
        discussion.bookingReference,
        if (discussion.firstNight != null) ...[
          DateFormat('dd/MM/yyyy').format(discussion.firstNight!),
          DateFormat('yyyy-MM-dd').format(discussion.firstNight!),
          DateFormat('dd MMM yyyy').format(discussion.firstNight!),
        ],
        if (discussion.lastNight != null) ...[
          DateFormat('dd/MM/yyyy').format(discussion.lastNight!),
          DateFormat('yyyy-MM-dd').format(discussion.lastNight!),
          DateFormat('dd MMM yyyy').format(discussion.lastNight!),
        ],
      ].join(' ').toLowerCase();
      return searchable.contains(query);
    }).toList();
  }

  @override
  void dispose() {
    _api.close();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 80,
        backgroundColor: colors.surface,
        surfaceTintColor: colors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 70,
        leading: _searching
            ? Padding(
                padding: const EdgeInsets.only(left: 12),
                child: IconButton(
                  tooltip: _isFrench ? 'Fermer la recherche' : 'Close search',
                  onPressed: _closeSearch,
                  style: IconButton.styleFrom(
                    backgroundColor: colors.surfaceContainerHighest,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  icon: const Icon(Icons.arrow_back_rounded),
                ),
              )
            : Padding(
                padding: const EdgeInsets.only(left: 16),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: colors.primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.forum_rounded, color: colors.primary),
                  ),
                ),
              ),
        titleSpacing: 0,
        title: _searching
            ? TextField(
                controller: _searchController,
                autofocus: true,
                textInputAction: TextInputAction.search,
                onChanged: (value) => setState(() => _query = value),
                decoration: InputDecoration(
                  hintText: _isFrench
                      ? 'Logement, ville ou dates…'
                      : 'Stay, city or dates…',
                  border: InputBorder.none,
                  isDense: true,
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Messages',
                    style: TextStyle(
                      color: colors.onSurface,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _isFrench
                        ? 'Vos échanges par séjour'
                        : 'Your conversations by stay',
                    style: TextStyle(
                      color: colors.onSurfaceVariant,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
        actions: _isLoggedIn
            ? [
                IconButton(
                  tooltip: _searching
                      ? (_isFrench ? 'Effacer' : 'Clear')
                      : (_isFrench ? 'Rechercher' : 'Search'),
                  onPressed: _searching
                      ? () {
                          if (_query.isEmpty) {
                            _closeSearch();
                          } else {
                            _searchController.clear();
                            setState(() => _query = '');
                          }
                        }
                      : _openSearch,
                  icon: Icon(
                      _searching ? Icons.close_rounded : Icons.search_rounded),
                  style: IconButton.styleFrom(
                    backgroundColor: colors.primary.withOpacity(0.10),
                    foregroundColor: colors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ]
            : null,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(
            height: 1,
            thickness: 1,
            color: colors.outlineVariant,
          ),
        ),
      ),
      body: _sessionLoading
          ? const Center(child: CircularProgressIndicator())
          : !_isLoggedIn
              ? const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  child: LoginRequiredState(padding: EdgeInsets.zero),
                )
              : FutureBuilder<List<ChatDiscussion>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return _ChatState(
                        icon: Icons.cloud_off_rounded,
                        title: _isFrench
                            ? 'Conversations indisponibles'
                            : 'Conversations unavailable',
                        message: snapshot.error.toString(),
                        actionLabel: _isFrench ? 'Réessayer' : 'Try again',
                        onAction: _refresh,
                      );
                    }
                    final allDiscussions = snapshot.data ?? const [];
                    final discussions = _filterDiscussions(allDiscussions);
                    if (allDiscussions.isEmpty) {
                      return _ChatState(
                        icon: Icons.forum_outlined,
                        title: _isFrench ? 'Aucun séjour' : 'No stay yet',
                        message: _isFrench
                            ? 'Vos conversations apparaîtront ici dès qu’une réservation sera associée à votre compte.'
                            : 'Your conversations will appear here once a booking is linked to your account.',
                      );
                    }
                    if (discussions.isEmpty) {
                      return _ChatState(
                        icon: Icons.search_off_rounded,
                        title: _isFrench ? 'Aucun résultat' : 'No result',
                        message: _isFrench
                            ? 'Essayez avec le nom du logement, la ville ou les dates du séjour.'
                            : 'Try the accommodation name, city, or stay dates.',
                        actionLabel:
                            _isFrench ? 'Effacer la recherche' : 'Clear search',
                        onAction: () async => _closeSearch(),
                      );
                    }
                    return RefreshIndicator(
                      onRefresh: _refresh,
                      child: ListView.separated(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
                        itemCount: discussions.length,
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemBuilder: (_, index) => _DiscussionTile(
                          discussion: discussions[index],
                          isFrench: _isFrench,
                          onTap: () => _open(discussions[index]),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}

class _DiscussionTile extends StatelessWidget {
  final ChatDiscussion discussion;
  final bool isFrench;
  final VoidCallback onTap;

  const _DiscussionTile({
    required this.discussion,
    required this.isFrench,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final lastMessage = discussion.lastMessage;
    final date = lastMessage?.createdAt;
    final stayDates = discussion.firstNight != null &&
            discussion.lastNight != null
        ? '${DateFormat('dd MMM').format(discussion.firstNight!)} – ${DateFormat('dd MMM').format(discussion.lastNight!.add(const Duration(days: 1)))}'
        : '';

    return Material(
      color: colors.surface,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
          child: Row(
            children: [
              CircleAvatar(
                radius: 29,
                backgroundColor: colors.primaryContainer,
                backgroundImage: discussion.imageUrl?.isNotEmpty == true
                    ? NetworkImage(
                        discussion.imageUrl!
                            .replaceFirst('http://', 'https://'),
                      )
                    : null,
                child: discussion.imageUrl?.isNotEmpty == true
                    ? null
                    : Icon(Icons.apartment_rounded, color: colors.primary),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            discussion.accommodationName.isNotEmpty
                                ? discussion.accommodationName
                                : '${isFrench ? 'Réservation' : 'Booking'} #${discussion.bookingReference}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (date != null)
                          Text(
                            DateFormat('dd/MM').format(date.toLocal()),
                            style: TextStyle(
                              fontSize: 11,
                              color: discussion.unreadCount > 0
                                  ? colors.primary
                                  : colors.onSurfaceVariant,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [stayDates, discussion.city]
                          .where((value) => value.isNotEmpty)
                          .join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontSize: 11, color: colors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            lastMessage?.message ??
                                (isFrench
                                    ? 'Démarrer une conversation'
                                    : 'Start a conversation'),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                              fontWeight: discussion.unreadCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.w400,
                            ),
                          ),
                        ),
                        if (discussion.unreadCount > 0) ...[
                          const SizedBox(width: 8),
                          Container(
                            constraints: const BoxConstraints(minWidth: 22),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: colors.primary,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              discussion.unreadCount > 99
                                  ? '99+'
                                  : '${discussion.unreadCount}',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: colors.onPrimary,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChatState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final Future<void> Function()? onAction;

  const _ChatState({
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(message, textAlign: TextAlign.center),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonal(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
