import 'dart:convert';

import 'package:chicaparts_partner/api/traveler/api_booking_traveler.dart';
import 'package:chicaparts_partner/models/traveler/modele_review.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:chicaparts_partner/widgets/traveler/common/login_required_state.dart';
import 'package:chicaparts_partner/widgets/traveler/accommodation/optimized_network_image.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shimmer/shimmer.dart';

class MyReviewsPage extends StatefulWidget {
  const MyReviewsPage({super.key});

  @override
  State<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage> {
  final ApiReview api = ApiReview();
  Future<List<Review>>? _future;
  User? _user;
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');

    if (userJson == null || userJson.isEmpty) {
      if (!mounted) return;
      setState(() {
        _user = null;
        _future = null;
        _isLoadingUser = false;
      });
      return;
    }

    final user = User.fromJson(jsonDecode(userJson));
    if (!mounted) return;
    setState(() {
      _user = user;
      _future = api.getUserReviews(user.id);
      _isLoadingUser = false;
    });
  }

  Future<void> _refresh() async {
    if (_user == null) {
      await _load();
      return;
    }

    setState(() {
      _future = api.getUserReviews(_user!.id);
    });
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colors.surface,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(lang),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _isLoadingUser
                    ? _buildLoadingList()
                    : _user == null
                        ? LoginRequiredState(
                            message: lang.t('booking_connect_text'),
                            padding: EdgeInsets.zero,
                          )
                        : RefreshIndicator(
                            onRefresh: _refresh,
                            color: const Color(0xFF244B6B),
                            child: FutureBuilder<List<Review>>(
                              future: _future,
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.waiting) {
                                  return _buildLoadingList();
                                }

                                if (snapshot.hasError) {
                                  return ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      _buildMessageState(
                                        icon: Icons.wifi_off_outlined,
                                        title: lang.t('error'),
                                        message: lang.t('error_network'),
                                      ),
                                    ],
                                  );
                                }

                                final reviews = snapshot.data ?? [];
                                if (reviews.isEmpty) {
                                  return ListView(
                                    physics:
                                        const AlwaysScrollableScrollPhysics(),
                                    children: [
                                      _buildMessageState(
                                        icon: Icons.rate_review_outlined,
                                        title: lang.t('no_reviews'),
                                        message: lang.t('my_reviews_text'),
                                      ),
                                    ],
                                  );
                                }

                                return ListView.separated(
                                  physics:
                                      const AlwaysScrollableScrollPhysics(),
                                  padding: const EdgeInsets.only(bottom: 24),
                                  itemCount: reviews.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 12),
                                  itemBuilder: (_, i) {
                                    return ReviewCard(review: reviews[i]);
                                  },
                                );
                              },
                            ),
                          ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(LanguageProvider lang) {
    final colors = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 16, 14),
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new, color: colors.primary),
            onPressed: () => Navigator.pop(context),
          ),
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF6E5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.star_rounded, color: Color(0xFFF59E0B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lang.t('my_reviews'),
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: colors.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  lang.t('my_reviews_text'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingList() {
    final colors = Theme.of(context).colorScheme;

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      itemCount: 4,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        return Shimmer.fromColors(
          baseColor: colors.surfaceContainerHighest,
          highlightColor: colors.surfaceContainer,
          child: Container(
            height: 172,
            decoration: BoxDecoration(
              color: colors.surfaceContainer,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageState({
    required IconData icon,
    required String title,
    required String message,
  }) {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Container(
        width: double.infinity,
        margin: const EdgeInsets.only(top: 32),
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: colors.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: colors.outlineVariant),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, size: 34, color: colors.primary),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(color: colors.onSurfaceVariant, height: 1.35),
            ),
          ],
        ),
      ),
    );
  }
}

class ReviewCard extends StatelessWidget {
  final Review review;
  const ReviewCard({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    final acc = review.accommodation;
    final colors = Theme.of(context).colorScheme;
    final score = (review.score ?? 0).toDouble();
    final title =
        acc?.name.trim().isNotEmpty == true ? acc!.name : 'Hebergement';
    final city = acc?.city.trim().isNotEmpty == true ? acc!.city : null;

    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: OptimizedNetworkImage(
                    imageUrl: acc?.image ?? '',
                    width: 82,
                    height: 82,
                    fit: BoxFit.cover,
                    memCacheWidth: 260,
                    memCacheHeight: 260,
                    maxWidthDiskCache: 420,
                    maxHeightDiskCache: 420,
                    errorWidget: Container(
                      width: 82,
                      height: 82,
                      color: const Color(0xFFF2F4F7),
                      child: const Icon(
                        Icons.apartment_outlined,
                        color: Color(0xFF98A2B3),
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                color: colors.onSurface,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          _ScorePill(score: score),
                        ],
                      ),
                      if (city != null) ...[
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              size: 16,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                city,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 10),
                      _StarRow(score: score),
                    ],
                  ),
                ),
              ],
            ),
            if (review.comment.trim().isNotEmpty) ...[
              const SizedBox(height: 14),
              _ExpandableReviewText(review.comment),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _ReviewMetricChip(label: 'Confort', value: review.confort),
                _ReviewMetricChip(label: 'Staff', value: review.staf),
                _ReviewMetricChip(label: 'Equip.', value: review.facilities),
                _ReviewMetricChip(label: 'Clean', value: review.cleanliness),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ScorePill extends StatelessWidget {
  final double score;
  const _ScorePill({required this.score});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6E5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFFE2A8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF59E0B)),
          const SizedBox(width: 3),
          Text(
            score.toStringAsFixed(1),
            style: const TextStyle(
              color: Color(0xFF8A4B00),
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StarRow extends StatelessWidget {
  final double score;
  const _StarRow({required this.score});

  @override
  Widget build(BuildContext context) {
    final rounded = score.round().clamp(0, 5);
    return Row(
      children: List.generate(5, (index) {
        return Icon(
          index < rounded ? Icons.star_rounded : Icons.star_border_rounded,
          size: 18,
          color: const Color(0xFFF59E0B),
        );
      }),
    );
  }
}

class _ReviewMetricChip extends StatelessWidget {
  final String label;
  final int value;

  const _ReviewMetricChip({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest.withOpacity(0.55),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.outlineVariant),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              color: colors.onSurfaceVariant,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '$value/5',
            style: TextStyle(
              color: colors.primary,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _ExpandableReviewText extends StatefulWidget {
  final String text;
  const _ExpandableReviewText(this.text);

  @override
  State<_ExpandableReviewText> createState() => _ExpandableReviewTextState();
}

class _ExpandableReviewTextState extends State<_ExpandableReviewText> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    final colors = Theme.of(context).colorScheme;
    final isFr = lang.currentLang == 'fr';
    final canExpand = widget.text.trim().length > 150;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.text.trim(),
          maxLines: expanded ? null : 3,
          overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
          style: TextStyle(
            color: colors.onSurfaceVariant,
            height: 1.35,
          ),
        ),
        if (canExpand) ...[
          const SizedBox(height: 6),
          InkWell(
            onTap: () => setState(() => expanded = !expanded),
            child: Text(
              expanded
                  ? (isFr ? 'Voir moins' : 'Show less')
                  : (isFr ? 'Voir plus' : 'Show more'),
              style: TextStyle(
                color: colors.primary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}
