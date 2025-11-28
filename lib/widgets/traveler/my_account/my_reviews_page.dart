import 'dart:convert';

import 'package:chicaparts_partner/api/traveler/api_booking_traveler.dart';
import 'package:chicaparts_partner/models/traveler/modele_review.dart';
import 'package:chicaparts_partner/models/user/user.dart';
import 'package:chicaparts_partner/providers/language_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MyReviewsPage extends StatefulWidget {
  const MyReviewsPage({super.key});

  @override
  State<MyReviewsPage> createState() => _MyReviewsPageState();
}

class _MyReviewsPageState extends State<MyReviewsPage> {
  final ApiReview api = ApiReview();
  Future<List<Review>>? _future;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user');
    if (userJson == null) return;

    final user = User.fromJson(jsonDecode(userJson));

    setState(() {
      _future = api.getUserReviews(user.id);
    });
  }

  @override
  Widget build(BuildContext context) {
    final lang = Provider.of<LanguageProvider>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // 🔵 HEADER UNIFORME
            _buildHeader(context, "⭐ ${lang.t('my_reviews')}"),

            // ligne de séparation
            Container(height: 1, color: Colors.grey[300]),

            // --------------------------
            // CONTENU SCROLLABLE
            // --------------------------
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async => _load(),
                child: FutureBuilder<List<Review>>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                            "${lang.t('error')} : ${lang.t('error_network')}"),
                      );
                    }

                    final reviews = snapshot.data ?? [];

                    if (reviews.isEmpty) {
                      return Center(
                        child: Text(lang.t('no_reviews')),
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: reviews.length,
                      itemBuilder: (_, i) => ReviewCard(review: reviews[i]),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --------------------------
// HEADER RÉUTILISÉ
// --------------------------
Widget _buildHeader(BuildContext context, String title) {
  return Container(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
    color: Colors.white,
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              size: 20, color: Color(0xFF244B6B)),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 4),
        Text(
          title,
          style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF244B6B)),
        ),
      ],
    ),
  );
}

// =============================================
//   WIDGET : REVIEW CARD
// =============================================
class ReviewCard extends StatefulWidget {
  final Review review;
  const ReviewCard({super.key, required this.review});

  @override
  State<ReviewCard> createState() => _ReviewCardState();
}

class _ReviewCardState extends State<ReviewCard> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final r = widget.review;
    final acc = r.accommodation;

    final commentTooLong = r.comment.trim().length > 220;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ---------- PHOTO + TITRE ----------
            if (acc != null)
              Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: acc.image != null
                        ? Image.network(
                            acc.image!.replaceFirst("http://", "https://"),
                            width: 70,
                            height: 70,
                            fit: BoxFit.cover,
                          )
                        : Container(
                            width: 70,
                            height: 70,
                            color: Colors.grey[300],
                            child: const Icon(Icons.photo, size: 32),
                          ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      acc.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  )
                ],
              ),

            const SizedBox(height: 12),

            // ----------- NOTE MOYENNE ----------
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber[700], size: 22),
                const SizedBox(width: 6),
                Text(
                  r.score!.toStringAsFixed(2),
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ----------- COMMENTAIRE (SEE MORE) ----------
            ExpandableText(
              r.comment,
              maxLines: 3,
            ),

            // ---------- NOTES INDIVIDUELLES --------
            Column(
              children: [
                // Ligne 1 → gauche / droite
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _tag("Confort: ${r.confort}"),
                    _tag("Personnel: ${r.staf}"),
                  ],
                ),
                const SizedBox(height: 8),

                // Ligne 2 → gauche / droite
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _tag("Équipements: ${r.facilities}"),
                    _tag("Propreté: ${r.cleanliness}"),
                  ],
                ),
              ],
            )
          ],
        ),
      ),
    );
  }

// -----------------------------------------------------------------------------
  // 🔹 HEADER
  // -----------------------------------------------------------------------------
  Widget _buildHeader() {
    final lang = Provider.of<LanguageProvider>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.only(top: 16.0, bottom: 12, right: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new,
                    color: Color(0xFF244B6B)),
                onPressed: () => Navigator.pop(context),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "⭐ ${lang.t('my_reviews')}",
                    style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF244B6B)),
                  ),
                  const SizedBox(height: 2),
                  Text(lang.t('my_reviews_text'),
                      style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _tag(String text) {
    return Chip(
      label: Text(text),
      backgroundColor: Colors.blueGrey[50],
    );
  }
}

class ExpandableText extends StatefulWidget {
  final String text;
  final int maxLines;

  const ExpandableText(this.text, {this.maxLines = 5, super.key});

  @override
  State<ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<ExpandableText> {
  bool expanded = false;

  @override
  Widget build(BuildContext context) {
    final textWidget = Text(
      widget.text,
      maxLines: expanded ? null : widget.maxLines,
      overflow: expanded ? TextOverflow.visible : TextOverflow.ellipsis,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        textWidget,
        const SizedBox(height: 6),
        InkWell(
          onTap: () => setState(() => expanded = !expanded),
          child: Text(
            expanded ? "Voir moins ▲" : "Voir plus ▼",
            style: const TextStyle(
              color: Color(0xFF244B6B),
              fontWeight: FontWeight.bold,
            ),
          ),
        )
      ],
    );
  }
}
